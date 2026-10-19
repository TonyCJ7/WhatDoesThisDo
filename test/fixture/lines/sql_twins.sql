SELECT sql_twin(1), sql_twin(1, 2);

CREATE FUNCTION sql_twin(n int) RETURNS int AS $$ SELECT n $$ LANGUAGE sql;

CREATE FUNCTION sql_twin(n int, m int) RETURNS int AS $$ SELECT n + m $$ LANGUAGE sql;
