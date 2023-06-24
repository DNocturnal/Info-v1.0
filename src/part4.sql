CREATE TABLE table_testing_one
    (
    cols_one   int,
    cols_two   varchar,
    cols_three date
    );

CREATE TABLE table_testing_two
    (
    cols_one   varchar,
    cols_two   timetz,
    cols_three bool,
    cols_four  inet
    );

CREATE TABLE table_testing_three
    (
    cols_one   bigint,
    cols_two   timestamp,
    cols_three int,
    cols_four  cidr
    );

CREATE TABLE table_testing_four
    (
    cols_one   point,
    cols_two   box,
    cols_three circle,
    cols_four  line
    );

CREATE TABLE testing_21_school
    (
    cols_one   point,
    cols_two   int,
    cols_three circle,
    cols_four  float
    );

CREATE TABLE testing_flashern
    (
    cols_one   point,
    cols_two   box,
    cols_three circle,
    cols_four  line
    );

CREATE TABLE testing_shanelac
    (
    cols_one   point,
    cols_two   box,
    cols_three circle,
    cols_four  line
    );

CREATE TABLE testing_tandrasc
    (
    cols_one   point,
    cols_two   box,
    cols_three circle,
    cols_four  line
    );

DROP PROCEDURE IF EXISTS drop_tables CASCADE;

CREATE
OR REPLACE PROCEDURE drop_tables(IN TableName text) AS $$
BEGIN
FOR TableName IN
	(SELECT CONCAT( 'DROP TABLE ', table_name, ';' ) 
		FROM information_schema.tables 
	WHERE table_schema = 'public' AND table_name LIKE CONCAT(TableName, '%'))
	LOOP
		EXECUTE TableName;
END LOOP;
END;
$$
LANGUAGE plpgsql;

CALL drop_tables('table');
CALL drop_tables('testing');

--2
CREATE
OR REPLACE FUNCTION size_table() RETURNS bigint
AS $$
SELECT count(*)
FROM table_testing_one;
$$
LANGUAGE 'sql';

 CREATE
OR REPLACE FUNCTION mul() RETURNS int
AS $$
SELECT cols_one * cols_three "mul"
FROM table_testing_three;
$$
LANGUAGE sql;

CREATE
OR REPLACE FUNCTION div_21() RETURNS point
 AS $$
SELECT (cols_one / point(2, 2))
FROM testing_21_school;
$$
LANGUAGE sql;

CREATE
OR REPLACE FUNCTION round_21() RETURNS int
 AS $$
SELECT round(cols_four) "round"
FROM testing_21_school;
$$
LANGUAGE sql;

CREATE FUNCTION calc(integer, integer, integer) RETURNS integer AS $$
select ($1 + $2) * $3 $$ LANGUAGE 'sql';

CREATE FUNCTION func_xyz_test(bool, bool, bool) RETURNS bool AS $$
select ($1 OR $2) AND $3 $$ LANGUAGE 'sql';

CREATE FUNCTION testing_func(point, point) RETURNS point AS $$
select $1 * ts.cols_one + $2 * tt.cols_one
from testing_shanelac ts,
     testing_tandrasc tt $$
LANGUAGE 'sql';

--2) Создать хранимую процедуру с выходным параметром, которая выводит список имен и параметров всех скалярных SQL функций
-- пользователя в текущей базе данных. Имена функций без параметров не выводить.
-- Имена и список параметров должны выводиться в одну строку.
-- Выходной параметр возвращает количество найденных функций

CREATE
OR REPLACE FUNCTION list_names(OUT counter INT) AS $$
DECLARE
f_info RECORD;
    f_name
TEXT;
    f_args
TEXT;
BEGIN
    counter
:= 0;
FOR f_info IN (
        SELECT p.proname, pg_get_function_identity_arguments(p.oid) AS args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        ORDER BY p.proname
    ) LOOP
        f_name := f_info.proname;
        f_args
:= f_info.args;
        IF
f_args <> '' THEN
            counter := counter + 1;
            RAISE
NOTICE '%(%): %', f_name, f_args, f_name || '(' || f_args || ')';
END IF;
END LOOP;
END;
$$
LANGUAGE plpgsql;

SELECT list_names();
--3
--Создать хранимую процедуру с выходным параметром, которая уничтожает все SQL DML триггеры в текущей базе данных.
-- Выходной параметр возвращает количество уничтоженных триггеров.

--DDL
CREATE TABLE log
    (
    id      int,
    what    text,
    command text
    );

CREATE
OR REPLACE FUNCTION to_log()
RETURNS event_trigger AS $$
BEGIN
INSERT INTO log (what, command)
values (tg_event, tg_tag);
END;
$$
LANGUAGE plpgsql;

CREATE
EVENT TRIGGER logging ON ddl_command_start
EXECUTE FUNCTION to_log();

--DML
CREATE FUNCTION trigger_21_function() RETURNS TRIGGER AS $$
BEGIN
UPDATE table_testing_one
SET cols_three = now()
WHERE cols_one = NEW.cols_one;
END;
$$
LANGUAGE PLPGSQL;

CREATE
OR REPLACE TRIGGER trigger_21_test AFTER
UPDATE ON table_testing_one EXECUTE FUNCTION trigger_21_function();
--
DROP PROCEDURE IF EXISTS drop_triggers CASCADE;

CREATE
OR REPLACE PROCEDURE drop_triggers(OUT counter int) AS $$
 DECLARE
trigg_name text;
table_name text;
BEGIN
SELECT COUNT(DISTINCT trigger_name) INTO counter
FROM information_schema.triggers
WHERE trigger_schema = 'public';
FOR trigg_name, table_name IN (SELECT DISTINCT trigger_name, event_object_table
                         FROM information_schema.triggers
                         WHERE trigger_schema = 'public')
        LOOP
            EXECUTE CONCAT('DROP TRIGGER ', trigg_name, ' ON ', table_name);
END LOOP;
END;
$$
LANGUAGE plpgsql;

CALL drop_triggers(NULL);

--4
--Создать хранимую процедуру с входным параметром, которая выводит имена и описания типа объектов
--(только хранимых процедур и скалярных функций), в тексте которых на языке SQL встречается строка,
-- задаваемая параметром процедуры.
DROP PROCEDURE IF EXISTS name_and_description(text) CASCADE;
CREATE TABLE result_table
    (
    r_name text,
    r_type text
    );
DROP TABLE result_table;

CREATE
OR REPLACE PROCEDURE name_and_description(IN str text) AS $$
BEGIN
INSERT INTO result_table(r_name, r_type)
SELECT routine_name "r_name", routine_type "r_type"
FROM information_schema.routines
WHERE specific_schema = 'public'
  AND routine_definition LIKE CONCAT('%', str, '%');

RETURN;
END
    $$
LANGUAGE plpgsql;

CALL name_and_description('21');
CALL name_and_description('f');
SELECT *
FROM result_table;
