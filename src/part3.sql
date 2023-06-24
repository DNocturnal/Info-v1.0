-- FIRST TASK --
-- Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде --
DROP FUNCTION IF EXISTS human_readable_func();
CREATE
OR REPLACE FUNCTION human_readable_func()
    RETURNS TABLE
                (
                    peer1 varchar,
                    peer2 varchar,
                    points_amount integer
                )
AS
$$
BEGIN
RETURN QUERY SELECT t.checkingpeer, t.checkedpeer, SUM(t.pointsamount)::INTEGER AS pointsamount
                   FROM ((SELECT tp1.checkingpeer, tp1.checkedpeer, tp1.pointsamount
                            FROM transferredpoints tp1
                                     LEFT JOIN transferredpoints tp2
                                     ON tp1.checkingpeer = tp2.checkedpeer AND tp1.checkedpeer = tp2.checkingpeer
                           WHERE tp2.id IS NULL)
                    UNION ALL
                   (SELECT tp1.checkingpeer, tp1.checkedpeer, tp1.pointsamount - tp2.pointsamount AS pointsamount
                      FROM transferredpoints tp1
                               LEFT JOIN transferredpoints tp2
                               ON tp1.checkingpeer = tp2.checkedpeer AND tp1.checkedpeer = tp2.checkingpeer
                     WHERE tp2.checkingpeer IS NOT NULL
                       AND tp1.id > tp2.id)) t
                  GROUP BY t.checkingpeer, t.checkedpeer;
END;
$$
LANGUAGE plpgsql;


-- SECOND TASK --
-- Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP --
DROP FUNCTION IF EXISTS get_peers_successfully_checks();

CREATE
OR REPLACE FUNCTION get_peers_successfully_checks()
    RETURNS TABLE
                (
                    peer VARCHAR,
                    task VARCHAR,
                    xp numeric
                )
AS
$$
BEGIN
SELECT checks.peer AS peer, checks.task AS task, x.xpamount AS xp
FROM checks
         JOIN xp x ON checks.id = x."Check";
END;
$$
LANGUAGE plpgsql;


-- THIRD TASK --
-- Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня --
DROP FUNCTION IF EXISTS "peers_who_didn't_leave_from_campus"(searching_date date);

CREATE
OR REPLACE FUNCTION "peers_who_didn't_leave_from_campus"(IN searching_date date) RETURNS SETOF VARCHAR AS
$$
BEGIN
RETURN QUERY(SELECT peer
                    FROM timetracking
                   WHERE timetracking."Date" = searching_date
                   GROUP BY peer
                  HAVING COUNT(state) < 3);
END;
$$
LANGUAGE plpgsql;

-- FOURTH TASK --
-- Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints --
DROP PROCEDURE IF EXISTS proc_transferred_points(rc refcursor);

CREATE
OR REPLACE PROCEDURE proc_transferred_points(rc refcursor) AS
$$
BEGIN
OPEN rc FOR SELECT t.checkingpeer AS peer, SUM(sum) AS points_change
                  FROM (SELECT tp.checkingpeer, SUM(tp.pointsamount) AS sum
                          FROM transferredpoints tp
                         GROUP BY tp.checkingpeer
                         UNION
                        SELECT tp.checkedpeer AS peer, SUM(-1 * tp.pointsamount) AS sum
                          FROM transferredpoints tp
                         GROUP BY tp.checkedpeer) t
                 GROUP BY t.checkingpeer
                 ORDER BY points_change DESC;
END;
$$
LANGUAGE plpgsql;

-- FIFTH TASK --
-- Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3 --
DROP PROCEDURE IF EXISTS proc_transferred_points2(rc2 refcursor) CASCADE;

CREATE
OR REPLACE PROCEDURE proc_transferred_points2(rc2 refcursor) AS
$$
BEGIN
OPEN rc2 FOR SELECT t.peer1 AS peer, SUM(sum) AS points_change
                   FROM (SELECT peer1, SUM(points_amount) AS sum
                           FROM human_readable_func()
                          GROUP BY peer1
                          UNION
                         SELECT peer2 AS peer, SUM(-1 * points_amount) AS sum
                           FROM human_readable_func()
                          GROUP BY peer2) t
                  GROUP BY t.peer1
                  ORDER BY points_change DESC;
END;
$$
LANGUAGE plpgsql;

-- SIXTH TASK --
-- Определить самое часто проверяемое задание за каждый день --
DROP PROCEDURE IF EXISTS proc_most_checkable_task(rc3 refcursor);

CREATE
OR REPLACE PROCEDURE proc_most_checkable_task(rc3 refcursor) AS
$$
BEGIN
OPEN rc3 FOR SELECT t."Date" AS day, t.task
                   FROM (SELECT "Date", task, COUNT(task) AS count FROM checks GROUP BY "Date", task) AS t
                  ORDER BY t.count DESC;
END;

$$
LANGUAGE plpgsql;

-- SEVENTH TASK --
-- Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания --
DROP PROCEDURE IF EXISTS proc_completed_branch(rc4 refcursor, branch varchar);

CREATE
OR REPLACE PROCEDURE proc_completed_branch(rc4 refcursor, branch varchar) AS
$$
BEGIN
OPEN rc4 FOR WITH block AS (SELECT tasks.title FROM tasks WHERE tasks.title SIMILAR TO CONCAT(branch, '[0-9]_%')),
                      branch_parent AS (SELECT MAX(title) AS title FROM block),
                      project_completed AS (SELECT checks.peer AS peer, checks."Date" AS day, checks.task
                                              FROM checks
                                                       JOIN p2p p
                                                       ON checks.id = p."Check" AND state = 'Success'
                                             GROUP BY checks.id)
SELECT peer, day
FROM project_completed JOIN branch_parent
ON project_completed.task = branch_parent.title;
END;
$$
LANGUAGE plpgsql;



--8  Определить, к какому пиру стоит идти на проверку каждому обучающемуся

DROP PROCEDURE IF EXISTS RecommendedPeerReview CASCADE;
CREATE
OR REPLACE PROCEDURE RecommendedPeerReview(IN r refcursor)AS $$
BEGIN
OPEN r FOR
        WITH friend_recommendations AS (
            SELECT DISTINCT ON (peer1, peer2) * FROM (
            (SELECT peer1, peer2 FROM friends)
            UNION ALL
            (SELECT peer2, peer1 FROM friends ) ) AS all_friends
        ),
            count_rec AS (
                SELECT f.peer1 AS peer, r.recommendedpeer, COUNT(*) AS num_recommendations
                FROM friend_recommendations f
                RIGHT JOIN Recommendations r ON (f.peer1 = r.peer  OR f.peer2 = r.peer)
                GROUP BY f.peer1, r.recommendedpeer
            ),
            all_rec AS (
                SELECT peer, recommendedpeer, num_recommendations,
                ROW_NUMBER() OVER
                ( PARTITION BY peer ORDER BY num_recommendations DESC ) AS row_number
                FROM count_rec
                WHERE peer != recommendedpeer
            )
SELECT peer, recommendedpeer
FROM all_rec
WHERE row_number = 1
ORDER BY peer DESC;
END;
$$
LANGUAGE plpgsql;

BEGIN;
CALL RecommendedPeerReview('r');
FETCH ALL IN "r";
END;

--9  Определить процент пиров, которые: Приступили только к блоку 1
-- Приступили только к блоку 2
-- Приступили к обоим
-- Не приступили ни к одному
DROP PROCEDURE IF EXISTS BlocksStart CASCADE;
CREATE
OR REPLACE PROCEDURE BlocksStart(IN block1 text, in block2 text, IN r refcursor) AS $$
BEGIN
OPEN r FOR
    WITH starts AS (
        SELECT COUNT(DISTINCT peer ) AS total,
    ( SELECT COUNT(DISTINCT peer) FROM Checks WHERE task LIKE  CONCAT('%', block1, '%') AND peer NOT IN (SELECT DISTINCT peer FROM Checks WHERE task LIKE CONCAT('%', block2, '%')) ) AS block1_only,
    ( SELECT COUNT(DISTINCT peer) FROM Checks WHERE task LIKE  CONCAT('%', block2, '%') AND peer NOT IN (SELECT DISTINCT peer FROM Checks WHERE task LIKE CONCAT('%', block1, '%')) ) AS block2_only,
    ( SELECT COUNT(DISTINCT peer) FROM Checks WHERE task LIKE  CONCAT('%', block1, '%') AND peer IN (SELECT DISTINCT peer FROM Checks WHERE task LIKE CONCAT('%', block2, '%')) ) AS boths,
    ( SELECT COUNT(DISTINCT peer) FROM Checks WHERE task LIKE  CONCAT('%', block1, '%') AND peer NOT IN (SELECT DISTINCT peer FROM Checks WHERE task NOT LIKE CONCAT('%', block2, '%')) ) AS none
  FROM Checks
)
SELECT CAST(block1_only AS float) / total * 100 as "StartedBlock1",
       CAST(block2_only AS float) / total * 100 as "StartedBlock2",
       CAST(boths AS float) / total * 100       as "StartedBothBlock",
       CAST(none AS float) / total * 100        as "DidntStartAnyBlock"
FROM starts;
END;
$$
LANGUAGE plpgsql;

BEGIN;
CALL BlocksStart('SQL', 'C', 'r');
FETCH ALL IN "r";
END;

BEGIN;
CALL BlocksStart('C', 'CPP', 'r');
FETCH ALL IN "r";
END;

BEGIN;
CALL BlocksStart('A', 'CPP', 'r');
FETCH ALL IN "r";
END;

--10 Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения

CREATE
OR REPLACE PROCEDURE part10(INOUT _result_one refcursor = 'rs_resultone')
    LANGUAGE plpgsql AS
$$
BEGIN
OPEN _result_one FOR WITH birthday_peers AS (SELECT "nickname", EXTRACT(DAY FROM "birthday") AS "day",
                                                     EXTRACT(MONTH FROM "birthday") AS "month" FROM "peers"),
                              check_day AS (SELECT "id", "peer", EXTRACT(DAY FROM "Date") AS "day",
                                                   EXTRACT(MONTH FROM "Date") AS "month" FROM "checks"),
                              needs_peer AS (SELECT "id", "peer"
                                               FROM check_day c_d
                                                        INNER JOIN birthday_peers b_p
                                                        ON c_d."day" = b_p."day" AND c_d."month" = b_p."month"),
                              count_p AS (SELECT ROW_NUMBER() OVER () AS c_p, "peer"
                                            FROM (SELECT DISTINCT "peer" FROM needs_peer) t),
                              success_p2p AS (SELECT n_p."id", n_p"peer", "state"
                                                FROM "p2p"
                                                         RIGHT JOIN needs_peer n_p
                                                         ON p2p."Check" = n_p."id"
                                               WHERE "state" = 'Success'),
                              success_no_verter AS (SELECT success_p2p."id", success_p2p."peer", success_p2p."state"
                                                      FROM success_p2p
                                                               LEFT JOIN "verter" v
                                                               ON success_p2p."id" = v."Check"
                                                     WHERE v."Check" IS NULL),
                              success_verter AS (SELECT success_p2p."id", success_p2p."peer", v."state"
                                                   FROM success_p2p
                                                            JOIN "verter" v
                                                            ON success_p2p."id" = v."Check"
                                                  WHERE v."state" = 'Success'),
                              success_peer AS (SELECT ROW_NUMBER() OVER () AS i, "peer"
                                                 FROM (SELECT "peer"
                                                         FROM success_no_verter
                                                        UNION
                                                       SELECT "peer"
                                                         FROM success_verter) t)
SELECT MAX(i) * 100 / MAX(c_p) AS SuccessfulChecks, (100 - MAX(i) * 100 / MAX(c_p)) AS UnsuccessfulChecks
FROM success_peer,
     count_p;
END
$$;
BEGIN;
CALL part10();
FETCH ALL FROM "rs_resultone";
END;

-- 11 Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
DROP PROCEDURE IF EXISTS TaskOneTwo CASCADE;
CREATE
OR REPLACE PROCEDURE TaskOneTwo(IN taskone varchar, IN tasktwo varchar, IN taskthree varchar, IN r refcursor) AS $$
BEGIN
OPEN r FOR
        WITH t AS (SELECT peer, task FROM checks
               JOIN xp x ON checks.id = x."Check"),
            SuccessOne AS (SELECT peer FROM t WHERE taskone IN (SELECT task FROM t)),
            SuccessTwo AS (SELECT peer FROM t WHERE tasktwo IN (SELECT task FROM t)),
            FailureThree AS (SELECT peer FROM t WHERE taskthree NOT IN (SELECT task FROM t))
SELECT *
FROM ((SELECT * FROM SuccessOne) INTERSECT (SELECT * FROM SuccessTwo) INTERSECT (SELECT * FROM FailureThree)) AS result;
END;
    $$LANGUAGE
plpgsql;

BEGIN;
CALL TaskOneTwo('C2_s21_stringplus', 'C6_s21_matrix', 'SQL1_Bootcamp', 'r');
FETCH ALL IN "r";
END;


-- 12 Определить для каждой задачи кол-во предшествующих ей задач
DROP PROCEDURE IF EXISTS PrevCount CASCADE;
CREATE
OR REPLACE PROCEDURE PrevCount(IN r refcursor) AS $$
BEGIN
OPEN r FOR
    WITH RECURSIVE TaskCount(title, parenttask, countprev) AS (
  SELECT title, parenttask, 0
  FROM Tasks
  WHERE parenttask IS NULL
  UNION ALL
  SELECT Tasks.title, Tasks.parenttask, TaskCount.countprev + 1
  FROM Tasks
  JOIN TaskCount ON TaskCount.title = Tasks.parenttask
)
SELECT title, countprev
FROM TaskCount
ORDER BY title;
END;
$$LANGUAGE
plpgsql;

BEGIN;
CALL PrevCount('r');
FETCH ALL IN "r";
END;

-- THIRTEEN TASK --
-- Найти "удачные" для проверок дни. День считается "удачным", если в нем есть хотя бы N идущих подряд успешных проверки --
DROP PROCEDURE IF EXISTS successful_day(rc5 refcursor, streak integer);

CREATE
OR REPLACE PROCEDURE successful_day(rc5 refcursor, streak integer) AS
$$
BEGIN
OPEN rc5 FOR WITH temp AS (SELECT *
                                 FROM checks
                                          JOIN p2p p
                                          ON checks.id = p."Check"
                                          LEFT JOIN verter v
                                          ON checks.id = v."Check"
                                          JOIN tasks t
                                          ON t.title = checks.task
                                          JOIN xp x
                                          ON checks.id = x."Check"
                                WHERE p.state = 'Success'
                                  AND (v.state = 'Success' OR v.state IS NULL))
SELECT "Date"
FROM temp
WHERE temp.maxxp * 0.8 <= temp.xpamount
GROUP BY temp."Date"
HAVING COUNT("Date") >= streak;
END;
$$
LANGUAGE plpgsql;

--14 вывести пира с максимальным кол-вом xp
DROP PROCEDURE IF EXISTS MaxXp CASCADE;
CREATE
OR REPLACE PROCEDURE MaxXp(r refcursor) AS $$
BEGIN
OPEN r FOR SELECT peer, SUM(xpamount) AS xp
  FROM xp
           JOIN checks
           ON xp."Check" = checks.id
 GROUP BY peer
 ORDER BY xp DESC
 LIMIT 1;
END;
$$
LANGUAGE plpgsql;
BEGIN;
CALL MaxXp('r');
FETCH ALL IN "r";
END;

--15 Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
DROP PROCEDURE IF EXISTS PeersInCampusEarlyEntries CASCADE;
CREATE
OR REPLACE PROCEDURE PeersInCampusEarlyEntries(IN t time, IN N int, IN r refcursor) AS $$
BEGIN
OPEN r FOR
SELECT DISTINCT peer
FROM timetracking
WHERE state = '1'
  AND ("Time" < t)
group by peer
having count(state) >= N;
END;
    $$LANGUAGE
plpgsql;

BEGIN;
CALL PeersInCampusEarlyEntries('14:00:00', 1, 'r');
FETCH ALL IN "r";
END;

BEGIN;
CALL PeersInCampusEarlyEntries('12:00:00', 1, 'r');
FETCH ALL IN "r";
END;

--16 Определить пиров, выходивших за последние N дней из кампуса больше M раз
DROP PROCEDURE IF EXISTS PeersOutCampus CASCADE;
CREATE
OR REPLACE PROCEDURE PeersOutCampus(IN N int, IN M int, IN r refcursor) AS $$
BEGIN
OPEN r FOR
SELECT peer
FROM timetracking
WHERE state = '2'
  AND "Date" > (currect_date - N)
GROUP BY peer
HAVING (COUNT(state) - 1) > M;
END;
    $$LANGUAGE
plpgsql;
-- вместо currect_date для проверки поставить date('2023-01-25'), тк в таблице даты за январь либо n ~ 140
BEGIN;
CALL PeersOutCampus(3, 0, 'r');
FETCH ALL IN "r";
END;

--17 Определить для каждого месяца процент ранних входов

DROP PROCEDURE early_entries CASCADE;

CREATE
OR REPLACE PROCEDURE early_entries(IN r refcursor) AS $$
BEGIN
OPEN r FOR
    WITH all_month AS (
        SELECT month :: date AS month
        FROM generate_series('2023-01-01', '2023-12-01', interval '1 month') AS month
    ),
    all_entry AS (SELECT month, SUM(count) AS sum
        FROM ( SELECT t."peer", COUNT(*) AS count, TO_CHAR(t."Date", 'MM') AS month
                FROM timetracking t
                LEFT JOIN peers p on t."peer" = p."nickname"
                WHERE t."state" = '1'
                GROUP BY t."peer", TO_CHAR(t."Date", 'MM')
            ) AS entry
        GROUP BY month
    ),
    early_entry AS (SELECT month, SUM(count) AS sum
        FROM (SELECT t."peer", COUNT(*) AS count, TO_CHAR(t."Date", 'MM') AS month
                FROM timetracking t
                LEFT JOIN peers p on t."peer" = p."nickname"
                WHERE t."state" = '1' AND t."Time" < '12:00:00' AND TO_CHAR(t."Date", 'MM') = TO_CHAR(p.birthday, 'MM')
                GROUP BY t."peer", TO_CHAR(t."Date", 'MM')
            ) AS entry
        GROUP BY month
    )
SELECT TO_CHAR(am.month, 'Month') AS "Month", ROUND(COALESCE(ee.sum * 100 / ae.sum, 0)) AS "EarlyEntries"
FROM all_month am
         LEFT JOIN all_entry ae ON ae.month = TO_CHAR(am.month, 'MM')
         LEFT JOIN early_entry ee ON ee.month = TO_CHAR(am.month, 'MM');
END;
    $$
LANGUAGE plpgsql;

-- добавим новые записи чтобы посещения были не только в январе если нужно проверить
INSERT INTO timetracking
VALUES (15, 'elenemar', '2023-06-01', '17:04:00', 1);
INSERT INTO timetracking
VALUES (16, 'elenemar', '2023-06-20', '09:24:02', 1);
INSERT INTO timetracking
VALUES (17, 'tandrasc', '2023-08-04', '09:53:10', 1);
INSERT INTO timetracking
VALUES (18, 'shanelac', '2023-05-05', '10:04:00', 1);
INSERT INTO timetracking
VALUES (19, 'papawfen', '2023-04-03', '09:34:44', 1);
INSERT INTO timetracking
VALUES (20, 'papawfen', '2023-04-30', '15:07:09', 1);
--
BEGIN;
CALL early_entries('r');
FETCH ALL IN "r";
END;


