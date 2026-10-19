SELECT n FROM sql_limit WHERE n > sql_attempt(1) AND n IN (SELECT n FROM sql_config);

CREATE VIEW sql_limit AS SELECT 3 AS n;

CREATE FUNCTION sql_attempt(n int) RETURNS int AS $$ SELECT n $$ LANGUAGE sql;

CREATE TABLE sql_config (n int);
