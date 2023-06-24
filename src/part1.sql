-- CREATE DATABASE IF NOT EXISTS data_based;

CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

CREATE TABLE peers
    (
    nickname VARCHAR NOT NULL PRIMARY KEY,
    birthday date    NOT NULL
    );

INSERT INTO peers
VALUES ('tandrasc', '1997-08-07'),
       ('shanelac', '1995-05-29'),
       ('elenemar', '2001-06-18'),
       ('romildab', '2003-09-14'),
       ('papawfen', '1999-04-14');


CREATE TABLE tasks
    (
    title      VARCHAR NOT NULL PRIMARY KEY,
    parenttask VARCHAR REFERENCES tasks (title),
    maxxp      BIGINT  NOT NULL
    );

INSERT INTO tasks
VALUES ('C3_SimpleBashUtils', NULL, 350),
       ('C2_s21_stringplus', 'C3_SimpleBashUtils', 740),
       ('C6_s21_matrix', 'C5_s21_decimal', 200),
       ('C5_s21_decimal', 'C3_SimpleBashUtils', 350),
       ('C7_SmartCalc_v1.0', 'C6_s21_matrix', 650),
       ('C8_3DViewer_v1.0', 'C7_SmartCalc_v1.0', 1043),
       ('CPP1_s21_matrixplus', 'C8_3DViewer_v1.0', 300),
       ('SQL1_bootcamp', 'C8_3DViewer_v1.0', 1500),
       ('SQL2_Info21_v1.0-0', 'SQL1_bootcamp', 600);


CREATE TABLE checks
    (
    id     serial  NOT NULL PRIMARY KEY,
    peer   VARCHAR NOT NULL REFERENCES peers (nickname),
    task   VARCHAR NOT NULL REFERENCES tasks (title),
    "Date" date    NOT NULL
    );

INSERT INTO checks
VALUES (1, 'tandrasc', 'C3_SimpleBashUtils', '2023-01-01'),
       (2, 'shanelac', 'C3_SimpleBashUtils', '2023-01-03'),
       (3, 'tandrasc', 'C2_s21_stringplus', '2023-01-20'),
       (4, 'shanelac', 'C2_s21_stringplus', '2023-01-20'),
       (5, 'tandrasc', 'C2_s21_stringplus', '2023-01-25'),
       (6, 'shanelac', 'C2_s21_stringplus', '2023-01-25'),
       (7, 'elenemar', 'C7_SmartCalc_v1.0', '2023-01-10'),
       (8, 'papawfen', 'C7_SmartCalc_v1.0', '2023-01-15'),
       (9, 'elenemar', 'C8_3DViewer_v1.0', '2023-01-21'),
       (10, 'papawfen', 'C8_3DViewer_v1.0', '2023-01-21'),
       (11, 'romildab', 'C5_s21_decimal', '2023-01-27'),
       (12, 'romildab', 'C5_s21_decimal', '2023-01-28'),
       (13, 'romildab', 'C5_s21_decimal', '2023-01-29'),
       (14, 'romildab', 'C6_s21_matrix', '2023-01-30'),
       (15, 'elenemar', 'SQL1_bootcamp', '2023-02-21');


CREATE UNIQUE INDEX idx_checks_peer_task ON checks (peer, task, "Date");

CREATE TABLE xp
    (
    id       serial  NOT NULL PRIMARY KEY,
    "Check"  integer NOT NULL REFERENCES checks (id),
    xpamount numeric NOT NULL
    );

INSERT INTO xp
VALUES (1, 1, 324),
       (2, 2, 300),
       (3, 5, 550),
       (4, 6, 550),
       (5, 7, 650),
       (6, 8, 640),
       (7, 9, 1043),
       (8, 10, 1043),
       (9, 13, 310),
       (10, 14, 200),
       (11, 15, 1240);

CREATE TABLE verter
    (
    id      serial  NOT NULL PRIMARY KEY,
    "Check" integer NOT NULL REFERENCES checks (id),
    state   check_status,
    "Time"  time    NOT NULL
    );

INSERT INTO verter
VALUES (1, 1, 'Start', '23:15:00'),
       (2, 1, 'Success', '23:31:15'),

       (3, 2, 'Start', '18:00:00'),
       (4, 2, 'Success', '18:04:30'),

       (5, 3, 'Start', '15:00:00'),
       (6, 3, 'Failure', '15:01:30'),

       (7, 4, 'Start', '15:00:00'),
       (8, 4, 'Failure', '15:01:30'),

       (9, 5, 'Start', '05:14:27'),
       (10, 5, 'Success', '05:20:03'),

       (11, 6, 'Start', '05:14:27'),
       (12, 6, 'Success', '05:20:03'),

       (13, 7, 'Start', '19:33:33'),
       (14, 7, 'Success', '19:34:00'),

       (15, 8, 'Start', '23:33:33'),
       (16, 8, 'Success', '23:37:06'),

       (17, 9, 'Start', '21:05:00'),
       (18, 9, 'Success', '23:59:00'),

       (19, 10, 'Start', '21:05:00'),
       (20, 10, 'Success', '23:59:00'),

       (21, 12, 'Start', '12:05:04'),
       (22, 12, 'Failure', '12:05:59'),

       (23, 13, 'Start', '02:00:00'),
       (24, 13, 'Success', '02:05:30'),

       (25, 14, 'Start', '22:00:00'),
       (26, 14, 'Success', '22:05:59');

CREATE TABLE p2p
    (
    id           serial  NOT NULL PRIMARY KEY,
    "Check"      integer NOT NULL REFERENCES checks (id),
    checkingpeer VARCHAR NOT NULL REFERENCES peers (nickname),
    state        check_status,
    "Time"       time    NOT NULL
    );

INSERT INTO p2p
VALUES (1, 1, 'shanelac', 'Start', '22:00:00'),
       (2, 1, 'shanelac', 'Success', '22:30:00'),

       (3, 2, 'tandrasc', 'Start', '16:15:00'),
       (4, 2, 'tandrasc', 'Success', '16:45:00'),

       (5, 3, 'elenemar', 'Start', '13:05:00'),     -- Тут вертер поставил оценку "Фейл"
       (6, 3, 'elenemar', 'Success', '14:05:00'),   -- Тут вертер поставил оценку "Фейл"

       (7, 4, 'elenemar', 'Start', '13:05:00'),     -- Тут вертер поставил оценку "Фейл"
       (8, 4, 'elenemar', 'Success', '14:05:00'),   -- Тут вертер поставил оценку "Фейл"

       (9, 5, 'romildab', 'Start', '03:15:00'),     -- Тут вертер поставил оценку "Успех"
       (10, 5, 'romildab', 'Success', '04:15:00'),  -- Тут вертер поставил оценку "Успех"

       (11, 6, 'romildab', 'Start', '03:15:00'),    -- Тут вертер поставил оценку "Успех"
       (12, 6, 'romildab', 'Success', '04:15:00'),  -- Тут вертер поставил оценку "Успех"

       (13, 7, 'papawfen', 'Start', '18:00:00'),
       (14, 7, 'papawfen', 'Success', '19:00:00'),

       (15, 8, 'tandrasc', 'Start', '22:00:00'),
       (16, 8, 'tandrasc', 'Success', '23:00:00'),

       (17, 9, 'shanelac', 'Start', '20:05:00'),
       (18, 9, 'shanelac', 'Success', '21:05:00'),

       (19, 10, 'shanelac', 'Start', '20:05:00'),
       (20, 10, 'shanelac', 'Success', '21:05:00'),

       (21, 11, 'elenemar', 'Start', '12:00:00'),   -- Студент поставил "Фейл"
       (22, 11, 'elenemar', 'Failure', '12:30:00'), -- Студент поставил "Фейл"

       (23, 12, 'papawfen', 'Start', '11:05:00'),   -- Вертер поставил "Фейл"
       (24, 12, 'papawfen', 'Success', '12:05:00'), -- Вертер поставил "фейл"

       (25, 13, 'tandrasc', 'Start', '01:00:00'),   -- Вертер поставил "Успех"
       (26, 13, 'tandrasc', 'Success', '02:00:00'), -- Вертер поставил "Успех"

       (27, 14, 'elenemar', 'Start', '21:30:00'),
       (28, 14, 'elenemar', 'Success', '22:00:00'),

       (29, 15, 'papawfen', 'Start', '15:00:00'),
       (30, 15, 'papawfen', 'Success', '20:04:00');



CREATE TABLE transferredpoints
    (
    id           serial  NOT NULL PRIMARY KEY,
    checkingpeer VARCHAR NOT NULL -- проверяющий
        REFERENCES peers (nickname),
    checkedpeer  VARCHAR NOT NULL -- проверяемый
        REFERENCES peers (nickname),
    pointsamount numeric NOT NULL
    );
INSERT INTO transferredpoints
VALUES (1, 'shanelac', 'tandrasc', 1),
       (2, 'tandrasc', 'shanelac', 1),
       (3, 'elenemar', 'tandrasc', 1),
       (4, 'romildab', 'tandrasc', 1),
       (5, 'papawfen', 'elenemar', 1),
       (6, 'tandrasc', 'papawfen', 1),
       (7, 'shanelac', 'elenemar', 1),
       (8, 'elenemar', 'romildab', 1),
       (9, 'papawfen', 'romildab', 1),
       (10, 'tandrasc', 'romildab', 1),
       (11, 'elenemar', 'romildab', 1),
       (12, 'papawfen', 'elenemar', 1);

CREATE TABLE friends
    (
    id    serial  NOT NULL PRIMARY KEY,
    peer1 VARCHAR NOT NULL REFERENCES peers (nickname),
    peer2 VARCHAR NOT NULL REFERENCES peers (nickname)
    );

CREATE UNIQUE INDEX idx_friends_peer1_peer2 ON friends (peer1, peer2);

INSERT INTO friends
VALUES (1, 'tandrasc', 'shanelac'),
       (2, 'tandrasc', 'elenemar'),
       (3, 'tandrasc', 'papawfen'),
       (4, 'shanelac', 'tandrasc'),
       (5, 'shanelac', 'elenemar'),
       (6, 'tandrasc', 'romildab'),
       (7, 'elenemar', 'papawfen');

CREATE TABLE recommendations
    (
    id              serial  NOT NULL PRIMARY KEY,
    peer            VARCHAR NOT NULL REFERENCES peers (nickname),
    recommendedpeer VARCHAR NOT NULL REFERENCES peers (nickname) CHECK (peer != recommendedpeer
    ) );

INSERT INTO recommendations
VALUES (1, 'tandrasc', 'elenemar'),
       (2, 'tandrasc', 'papawfen'),
       (3, 'tandrasc', 'shanelac'),
       (4, 'shanelac', 'elenemar'),
       (5, 'elenemar', 'papawfen'),
       (6, 'tandrasc', 'romildab');

CREATE TABLE timetracking
    (
    id     serial  NOT NULL PRIMARY KEY,
    peer   VARCHAR NOT NULL REFERENCES peers (nickname),
    "Date" date    NOT NULL,
    "Time" time    NOT NULL,
    state  char(1) CHECK (state IN ('1', '2'))
    );

INSERT INTO timetracking
VALUES (1, 'tandrasc', '2023-01-01', '14:00:00', 1),
       (2, 'tandrasc', '2023-01-01', '16:01:00', 2),
       (3, 'tandrasc', '2023-01-01', '16:30:00', 1),
       (4, 'tandrasc', '2023-01-01', '23:59:00', 2),

       (5, 'elenemar', '2023-01-10', '06:30:45', 1),
       (6, 'elenemar', '2023-01-11', '22:30:30', 2),

       (7, 'shanelac', '2023-01-25', '13:00:30', 1),
       (8, 'shanelac', '2023-01-25', '14:05:00', 2),
       (9, 'shanelac', '2023-01-25', '15:01:07', 1),
       (10, 'shanelac', '2023-01-26', '02:00:00', 2),

       (11, 'papawfen', '2023-01-21', '10:30:21', 1),
       (12, 'papawfen', '2023-01-21', '13:21:21', 2),
       (13, 'papawfen', '2023-01-21', '14:05:21', 1),
       (14, 'papawfen', '2023-01-21', '23:59:59', 2);


CREATE
OR REPLACE PROCEDURE import(IN tablename varchar, IN path text, IN separator char) AS
$$
BEGIN
EXECUTE FORMAT('COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER;', -- IMPORT
               tablename, path, separator);
END;

$$
LANGUAGE plpgsql;

CREATE
OR REPLACE PROCEDURE export(IN tablename varchar, IN path text, IN separator char) AS
$$
BEGIN
EXECUTE FORMAT('COPY %s TO ''%s'' DELIMITER ''%s'' CSV HEADER;', -- EXPORT
               tablename, path, separator);
END;

$$
LANGUAGE plpgsql;
