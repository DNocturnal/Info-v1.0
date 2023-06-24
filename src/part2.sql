--1) Написать процедуру добавления P2P проверки
--Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P проверки, время.
CREATE
OR REPLACE PROCEDURE p2p_reviews(IN checked_peer varchar, IN checking_peer varchar, IN task_name varchar,
                                        IN p2p_status check_status, IN "time" time) AS
$$
BEGIN
    IF
(p2p_status = 'Start') THEN
        IF (SELECT COUNT(*)
              FROM p2p
                    JOIN checks c
                       ON c.id = p2p."Check"
             WHERE p2p.checkingpeer = checking_peer
               AND c.peer = checked_peer
               AND c.task = task_name) = 1 THEN
            RAISE EXCEPTION 'The check has already started!';
ELSE
            INSERT INTO checks VALUES ((SELECT MAX(id) + 1 FROM checks), checked_peer, task_name, NOW());
INSERT INTO p2p
VALUES ((SELECT MAX(id) + 1 FROM p2p), (SELECT MAX(id) FROM checks),
        checking_peer, p2p_status, time);
END IF;

ELSE
        INSERT INTO p2p
            VALUES ((SELECT MAX(id) FROM p2p) + 1,
                    (SELECT "Check" FROM p2p
                     JOIN checks ch ON p2p."Check" = ch.id
                     WHERE p2p.checkingpeer = checking_peer AND ch.peer = checked_peer
                       AND ch.task = task_name),
                    checking_peer, p2p_status, time);

END IF;
END;
$$
LANGUAGE plpgsql;

-- check
CALL p2p_reviews('tandrasc', 'shanelac', 'C5_s21_decimal', 'Start'::check_status, '12:00:00');
CALL p2p_reviews('romildab', 'tandrasc', 'C5_s21_decimal', 'Start', '16:45:00');
CALL p2p_reviews('romildab', 'tandrasc', 'C2_s21_stringplus', 'Start', '06:45:00');
CALL p2p_reviews('romildab', 'tandrasc', 'C2_s21_stringplus', 'Success', '07:15:00');
CALL p2p_reviews('shanelac', 'elenemar', 'C3_SimpleBashUtils', 'Start', '15:10:00');
CALL p2p_reviews('papawfen', 'romildab', 'C8_3DViewer_v1.0', 'Start',  '23:45:00');
CALL p2p_reviews('elenemar', 'papawfen', 'SQL1_bootcamp', 'Start'::check_status, '09:00:00');
CALL p2p_reviews('elenemar', 'papawfen', 'SQL1_bootcamp', 'Success'::check_status, '09:30:00');
CALL p2p_reviews('papawfen', 'shanelac', 'CPP1_s21_matrixplus', 'Failure'::check_status, '13:50:00');
CALL p2p_reviews('romildab', 'papawfen', 'SQL1_bootcamp', 'Failure'::check_status, '12:00:00');

DELETE
FROM p2p
WHERE id BETWEEN 31 and 40;
DELETE
FROM checks
WHERE id BETWEEN 16 AND 35;
DROP PROCEDURE p2p_reviews(checked_peer varchar, checking_peer varchar, task_name varchar, p2p_status check_status, "Time" time);


--2)Verters check - Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время.
CREATE
OR REPLACE PROCEDURE verter_reviews(IN checked_peer varchar, IN task_name varchar, IN v_status check_status,
                                       IN "v_time" time) AS
$$
BEGIN
    IF
v_status = 'Start' THEN
        IF ((SELECT MAX(p2p."Time") FROM p2p
            LEFT JOIN checks c ON p2p."Check" = c.id
            WHERE p2p.state = 'Success' AND c.task = task_name AND c.peer = checked_peer) IS NOT NULL ) THEN
            INSERT INTO verter VALUES ((SELECT MAX(id) FROM verter) + 1,
                                       (SELECT DISTINCT c2.id FROM p2p
                                           LEFT JOIN checks c2 ON p2p."Check" = c2.id
                                                     WHERE c2.peer = checked_peer
                                                       AND p2p.state = 'Success'
                                                       AND c2.task = task_name), v_status, v_time);
ELSE
                RAISE EXCEPTION 'The project has not been checked by another peer yet!';
END IF;
ELSE
            INSERT INTO verter
            VALUES ((SELECT MAX(id) FROM verter) + 1,
                    (SELECT "Check" FROM verter
                     GROUP BY "Check" ), v_status, v_time);
END IF;
END;
$$
LANGUAGE plpgsql;

DROP PROCEDURE verter_reviews(checked_peer varchar, task_name varchar, v_status check_status, v_time time);
CALL verter_reviews('romildab', 'C2_stringplus', 'Start', '15:02:00');
CALL verter_reviews('romildab', 'C6_s21_matrix', 'Failure', '15:02:00');
CALL verter_reviews('tandrasc', 'C5_s21_decimal', 'Start', '13:10:00'); --with exception
CALL verter_reviews('elenemar', 'SQL1_bootcamp', 'Start', '17:25:00');
CALL verter_reviews('elenemar', 'SQL1_bootcamp', 'Success', '17:35:00');
DELETE
from verter
where id BETWEEN 27 and 35;


--3)триггер: после добавления записи со статутом "начало" в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints

CREATE
OR REPLACE FUNCTION fnc_trg_p2p_transferred_points() RETURNS TRIGGER AS $trg_p2p_transferred_points$
BEGIN
       IF
NEW.state = 'Start' THEN
           WITH update_table AS (
               SELECT c.peer AS peer FROM p2p
               JOIN checks c ON p2p."Check" = c.id
               WHERE state = 'Start' AND NEW."Check" = c.id
           )
UPDATE transferredpoints
SET pointsamount = pointsamount + 1 FROM update_table ut
WHERE ut.peer = transferredpoints.checkedpeer AND NEW.checkingpeer = transferredpoints.checkingpeer;
END IF;
RETURN NULL;
END;
$trg_p2p_transferred_points$
LANGUAGE plpgsql;

CREATE
OR REPLACE TRIGGER trg_p2p_transferred_points
    AFTER INSERT ON p2p
    FOR EACH ROW
    EXECUTE FUNCTION fnc_trg_p2p_transferred_points();


--4)триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи

CREATE
OR REPLACE TRIGGER trg_check_correct_value
    BEFORE INSERT ON xp
    FOR EACH ROW
    EXECUTE FUNCTION fnc_trg_check_correct_value();


CREATE
OR REPLACE FUNCTION fnc_trg_check_correct_value() RETURNS TRIGGER AS $trg_check_correct_value$
BEGIN

           IF
(
SELECT maxxp
FROM tasks t
         LEFT JOIN checks c ON c.task = t.title
WHERE NEW."Check" = c.id) >= NEW.xpamount
        AND (SELECT state FROM verter v
            LEFT JOIN xp ON xp."Check" = v."Check"
                         WHERE v.state IN ('Success', 'Failure') AND NEW."Check" = v."Check") = 'Success' OR -- ссылаемся на успешную проверку вертера
              (SELECT state FROM p2p p
            LEFT JOIN xp ON xp."Check" = p."Check"
                         where p.state IN ('Success', 'Failure') AND NEW."Check" = p."Check") = 'Success' -- или успешную проверку пира(ветка плюсов)
            THEN
               RAISE EXCEPTION 'The number of XP exceed the maximum available or state is falure';
ELSE
                RETURN (NEW.id, NEW."Check", NEW.xpamount);
END IF;
END;
$trg_check_correct_value$
LANGUAGE plpgsql;

