SELECT grand_total(1);

CREATE FUNCTION grand_total(n int) RETURNS int AS $$ SELECT n $$ LANGUAGE sql;
