-- =====================================================================
-- Laboratory Work 9: Stored Procedures and User-Defined Functions

-- Part 1: Database Setup
-- =====================================================================
DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

CREATE TABLE stations (
    station_id   INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city         VARCHAR(40) NOT NULL,
    capacity     INT NOT NULL
);

CREATE TABLE bikes (
    bike_id    INT PRIMARY KEY,
    model      VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations(station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city      VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

CREATE TABLE rentals (
    rental_id  INT PRIMARY KEY,
    member_id  INT REFERENCES members(member_id),
    bike_id    INT REFERENCES bikes(bike_id),
    start_date DATE NOT NULL,
    end_date   DATE,
    fee        NUMERIC(8,2)
);

INSERT INTO stations VALUES
    (10, 'Central Park', 'Almaty',   4),
    (20, 'Riverside',    'Almaty',   3),
    (30, 'Expo Gate',    'Astana',   5),
    (40, 'Old Town',     'Shymkent', 2),
    (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
    (101, 'City Cruiser', 10,  4.50),
    (102, 'City Cruiser', 10,  4.50),
    (103, 'Mountain X',   20,  7.00),
    (104, 'Mountain X',   30,  7.00),
    (105, 'Road Sprint',  30,  9.25),
    (106, 'Folding Mini', 40,  3.75),
    (107, 'Cargo Hauler', 20, 12.00),
    (108, 'Road Sprint',  10,  9.25);

INSERT INTO members VALUES
    (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
    (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
    (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
    (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
    (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
    (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
    ( 1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
    ( 2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
    ( 3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
    ( 4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
    ( 5, 2, 101, DATE '2024-05-01', DATE '2024-05-02',  4.50),
    ( 6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
    ( 7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
    ( 8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
    ( 9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
    (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10',  7.00),
    (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
    (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
    (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
    (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
    (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
    (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20',  7.50),
    (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
    (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
    (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
    (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
    (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
    (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);

-- Verify the setup
SELECT (SELECT COUNT(*) FROM stations) AS stations,
       (SELECT COUNT(*) FROM bikes)    AS bikes,
       (SELECT COUNT(*) FROM members)  AS members,
       (SELECT COUNT(*) FROM rentals)  AS rentals;
-- Output:
--    stations | bikes | members | rentals
--   ----------+-------+---------+---------
--           5 |     8 |       6 |      22
--   (1 row)


-- =====================================================================
-- Part 2: Your First Function
-- =====================================================================

-- Worked example
CREATE OR REPLACE FUNCTION inc(val INTEGER) RETURNS INTEGER AS $$
DECLARE
    result INTEGER;
BEGIN
    result := val + 1;
    RETURN result;
END; $$
LANGUAGE plpgsql;

SELECT inc(10);
-- Output:
--    inc
--   -----
--     11
--   (1 row)

-- Exercise 2.1: A function over one row
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    RETURN v_days;
END; $$
LANGUAGE plpgsql;

SELECT rental_days(2);
-- Output:
--    rental_days
--   -------------
--              5
--   (1 row)
SELECT rental_days(11);
-- Output:
--    rental_days
--   -------------
--              8
--   (1 row)
SELECT rental_days(19);
-- Output:
--    rental_days
--   -------------
--           NULL
--   (1 row)
SELECT rental_days(999);
-- Output:
--    rental_days
--   -------------
--           NULL
--   (1 row)
-- Answer: both return NULL, but for different reasons. Rental 19 exists,
-- but its end_date is NULL (still open), so NULL - start_date = NULL.
-- Rental 999 does not exist: SELECT ... INTO finds no row and leaves
-- v_days NULL.

-- Exercise 2.2: A function over many rows
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_count;
END; $$
LANGUAGE plpgsql;

SELECT member_rental_count(1);
-- Output:
--    member_rental_count
--   ---------------------
--                      5
--   (1 row)
SELECT member_rental_count(5);
-- Output:
--    member_rental_count
--   ---------------------
--                      4
--   (1 row)
SELECT member_rental_count(6);
-- Output:
--    member_rental_count
--   ---------------------
--                      0
--   (1 row)
SELECT member_rental_count(99);
-- Output:
--    member_rental_count
--   ---------------------
--                      0
--   (1 row)
-- Answer: COUNT(*) is an aggregate without GROUP BY, so it always returns
-- exactly one row, even when no row matches - and the count of zero rows
-- is 0, not NULL. For the database member 6 (no rentals) and member 99
-- (does not exist) look the same: zero matching rentals.

-- Exercise 2.3: Returning text
CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city
    INTO v_city
    FROM stations
    WHERE station_id = p_station_id;

    RETURN v_city;
END; $$
LANGUAGE plpgsql;

SELECT station_city(30);
-- Output:
--    station_city
--   --------------
--    Astana
--   (1 row)
SELECT station_city(77);
-- Output:
--    station_city
--   --------------
--    NULL
--   (1 row)
-- Station 77 does not exist, so the result is NULL.

-- Exercise 2.4: Using a function inside a query
SELECT rental_id,
       member_id,
       rental_days(rental_id) AS duration
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration DESC;
-- Output:
--    rental_id | member_id | duration
--   -----------+-----------+----------
--           11 |         3 |        8
--            4 |         1 |        7
--           15 |         5 |        7
--           17 |         5 |        7
--           20 |         4 |        6
--            7 |         2 |        6
--           14 |         4 |        6
--            2 |         1 |        5
--   (8 rows)


-- =====================================================================
-- Part 3: Parameter Modes
-- =====================================================================

-- Exercise 3.1: IN parameters
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (100 - p_percent) / 100, 2);
END; $$
LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);
-- Output:
--    fee_with_discount
--   -------------------
--                62.90
--   (1 row)

-- Exercise 3.2: OUT parameters
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id    INT,
    OUT rental_cnt INT,
    OUT total_fee  NUMERIC,
    OUT last_start DATE)
AS $$
BEGIN
    SELECT COUNT(*), COALESCE(SUM(fee), 0), MAX(start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals
    WHERE member_id = p_member_id;
END; $$
LANGUAGE plpgsql;

SELECT member_stats(3);
-- Output:
--        member_stats
--   -----------------------
--    (5,164.75,2025-06-01)
--   (1 row)
SELECT * FROM member_stats(3);
-- Output:
--    rental_cnt | total_fee | last_start
--   ------------+-----------+------------
--             5 |    164.75 | 2025-06-01
--   (1 row)
SELECT * FROM member_stats(6);
-- Output:
--    rental_cnt | total_fee | last_start
--   ------------+-----------+------------
--             0 |         0 | NULL
--   (1 row)
-- Answer: SELECT member_stats(3) returns ONE column holding a composite
-- value (5,164.75,2025-06-01). SELECT * FROM member_stats(3) expands it into
-- three named columns. Inside a larger query the FROM form is better: its
-- columns can be selected, filtered and joined by name.
-- Member 6: rental_cnt 0, total_fee 0 (thanks to COALESCE), last_start NULL.

-- Exercise 3.3: INOUT parameters
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
AS $$
BEGIN
    p_fee := p_fee + 5.00;
END; $$
LANGUAGE plpgsql;

SELECT apply_late_fee(fee) AS fee_with_late_charge
FROM rentals
WHERE rental_id = 1;
-- Output:
--    fee_with_late_charge
--   ----------------------
--                   18.50
--   (1 row)
-- Answer: an INOUT parameter is also an output parameter. When the function
-- ends, PostgreSQL returns the final value of p_fee automatically, so no
-- RETURNS clause or RETURN statement is needed.

-- Exercise 3.4: VARIADIC parameters
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total   NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC)
AS $$
BEGIN
    SELECT SUM(p_fees[i]), ROUND(AVG(p_fees[i]), 2), MAX(p_fees[i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) g(i);
END; $$
LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
-- Output:
--    total | average | largest
--   -------+---------+---------
--    98.50 |   24.63 |   35.00
--   (1 row)

-- SELECT * FROM fee_summary();
-- ERROR:  function fee_summary() does not exist
-- LINE 1: SELECT * FROM fee_summary();
--                       ^
-- HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
-- Answer: a VARIADIC parameter needs at least one argument; with zero
-- arguments no function matches. It must be the last parameter because it
-- takes ALL remaining arguments: in f(VARIADIC a NUMERIC[], b NUMERIC) the
-- call f(1, 2, 3) could not tell where the array ends and b begins.

-- Exercise 3.5: Choosing a mode
-- (a) id of the row to look up      -> IN: the function only reads it.
-- (b) running balance passed in and
--     expected back updated         -> INOUT: one value goes in, is changed, comes back.
-- (c) list of station ids of
--     unknown length                -> VARIADIC: collects any number of arguments into an array.
-- (d) two statistics returned
--     together from one pass        -> OUT (two OUT parameters): one call returns both values.


-- =====================================================================
-- Part 4: Default Values and Function Overloading
-- =====================================================================

-- Exercise 4.1: A function with one parameter
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1);
-- Output:
--    total_fees
--   ------------
--         98.50
--   (1 row)
SELECT total_fees(6);
-- Output:
--    total_fees
--   ------------
--             0
--   (1 row)

-- Exercise 4.2: Overloading the name
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
-- Output:
--    total_fees
--   ------------
--         98.50
--   (1 row)
SELECT total_fees(1, DATE '2025-01-01');
-- Output:
--    total_fees
--   ------------
--         50.00
--   (1 row)

-- \df total_fees works only in psql; the same list from pg_proc:
SELECT proname, pg_get_function_identity_arguments(oid) AS arguments
FROM pg_proc
WHERE proname = 'total_fees';
-- Output:
--     proname   |               arguments
--   ------------+---------------------------------------
--    total_fees | p_member_id integer
--    total_fees | p_member_id integer, p_from_date date
--   (2 rows)

-- Exercise 4.3: Giving a parameter a default value
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT,
                                      p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END; $$
LANGUAGE plpgsql;

-- SELECT total_fees(1);
-- ERROR:  function total_fees(integer) is not unique
-- LINE 1: SELECT total_fees(1);
--                ^
-- HINT:  Could not choose a best candidate function. You might need to add explicit type casts.
-- Answer: a call with one integer now matches TWO functions equally well:
-- total_fees(integer) exactly, and total_fees(integer, date) with the date
-- taken from its DEFAULT. PostgreSQL has no rule to prefer one, so it refuses.

-- Exercise 4.4: Resolving the ambiguity
DROP FUNCTION total_fees(INTEGER);

SELECT total_fees(1);
-- Output:
--    total_fees
--   ------------
--         50.00
--   (1 row)
-- Answer: the two-parameter version answers, with p_from_date = 2025-01-01:
-- 18.50 + 31.50 = 50.00 (rental 19 has no fee yet). Dropping the other
-- version instead would have left total_fees(integer), which sums ALL
-- fees: 98.50 - a different answer to the same call.

-- Exercise 4.5: Overloading on type, not just on count
CREATE OR REPLACE FUNCTION total_fees(p_name VARCHAR) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
    INTO v_total
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    WHERE m.full_name = p_name;

    RETURN v_total;
END; $$
LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
-- Output:
--    total_fees
--   ------------
--         98.50
--   (1 row)
SELECT total_fees(1);
-- Output:
--    total_fees
--   ------------
--         50.00
--   (1 row)
-- Answer: no error, because the argument TYPES differ. total_fees(1) passes
-- an integer, and an integer is not implicitly converted to VARCHAR, so it
-- can only reach total_fees(integer, date DEFAULT '2025-01-01') -> 50.00
-- (2025 rentals only). total_fees('Aisha Nurlanova') passes a string
-- literal; PostgreSQL resolves it to the string-type candidate
-- total_fees(varchar), which has no date filter -> 98.50 (all rentals).


-- =====================================================================
-- Part 5: Functions That Return a Table
-- =====================================================================

-- Exercise 5.1: Search by pattern
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (found_id INT, found_model VARCHAR, found_rate NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model, daily_rate
    FROM bikes
    WHERE model ILIKE p_pattern          -- ILIKE = case-insensitive LIKE
    ORDER BY bike_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
-- Output:
--    found_id | found_model | found_rate
--   ----------+-------------+------------
--         105 | Road Sprint |       9.25
--         108 | Road Sprint |       9.25
--   (2 rows)
SELECT * FROM find_bikes('%Mini');
-- Output:
--    found_id | found_model  | found_rate
--   ----------+--------------+------------
--         106 | Folding Mini |       3.75
--   (1 row)
SELECT find_bikes('%road%');
-- Output:
--           find_bikes
--   --------------------------
--    (105,"Road Sprint",9.25)
--    (108,"Road Sprint",9.25)
--   (2 rows)
-- Answer: without FROM, each row comes back as ONE column of composite
-- type, e.g. (105,"Road Sprint",9.25). In the select list a set-returning
-- function returns whole rows as single values; only in FROM is it treated
-- like a table and expanded into its columns.

-- Exercise 5.2: A table from a join
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (h_rental_id INT, h_model VARCHAR, h_station VARCHAR,
               h_days INT, h_fee NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id, b.model, s.station_name,
           r.end_date - r.start_date, r.fee
    FROM rentals r
    JOIN bikes b    ON b.bike_id    = r.bike_id
    JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END; $$
LANGUAGE plpgsql;

SELECT * FROM member_history(3);
-- Output:
--    h_rental_id |   h_model   | h_station | h_days | h_fee
--   -------------+-------------+-----------+--------+-------
--              8 | Mountain X  | Expo Gate |      4 | 28.00
--              9 | Road Sprint | Expo Gate |      3 | 27.75
--             10 | Mountain X  | Expo Gate |      1 |  7.00
--             21 | Mountain X  | Riverside |      4 | 28.00
--             11 | Road Sprint | Expo Gate |      8 | 74.00
--   (5 rows)

-- Exercise 5.3: When the column names collide
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

-- SELECT * FROM bike_list(10);
-- ERROR:  column reference "bike_id" is ambiguous
-- LINE 1: SELECT bike_id, model FROM bikes WHERE station_id = p_statio...
--                ^
-- DETAIL:  It could refer to either a PL/pgSQL variable or a table column.
-- QUERY:  SELECT bike_id, model FROM bikes WHERE station_id = p_station_id
-- CONTEXT:  PL/pgSQL function bike_list(integer) line 3 at RETURN QUERY
-- Answer: the output columns of RETURNS TABLE are also PL/pgSQL variables.
-- PL/pgSQL checks only the syntax at CREATE time; the SQL inside the body is
-- parsed when it first runs, and only then does PostgreSQL see that
-- bike_id could be the variable or the bikes column.

-- Fix 1: rename the output columns (a changed OUT list needs DROP first)
DROP FUNCTION bike_list(INT);

CREATE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);
-- Output:
--    out_bike_id |  out_model
--   -------------+--------------
--            101 | City Cruiser
--            102 | City Cruiser
--            108 | Road Sprint
--   (3 rows)

-- Fix 2: keep the names, qualify the table columns with an alias
DROP FUNCTION bike_list(INT);

CREATE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT b.bike_id, b.model FROM bikes b WHERE b.station_id = p_station_id;
END; $$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);
-- Output:
--    bike_id |    model
--   ---------+--------------
--        101 | City Cruiser
--        102 | City Cruiser
--        108 | Road Sprint
--   (3 rows)

-- Exercise 5.4: Casting the output
-- Without casts (COUNT returns BIGINT, the columns are declared INT):
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           COUNT(b.bike_id),
           s.capacity - COUNT(b.bike_id)
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;

-- SELECT * FROM station_board('Almaty');
-- ERROR:  structure of query does not match function result type
-- DETAIL:  Returned type bigint does not match expected type integer in column 2.
-- CONTEXT:  SQL statement "SELECT s.station_name,
--            COUNT(b.bike_id),
--            s.capacity - COUNT(b.bike_id)
--     FROM stations s
--     LEFT JOIN bikes b ON b.station_id = s.station_id
--     WHERE s.city = p_city
--     GROUP BY s.station_id, s.station_name, s.capacity
--     ORDER BY s.station_id"
-- PL/pgSQL function station_board(character varying) line 3 at RETURN QUERY
-- Answer: RETURN QUERY does not convert types; COUNT gives BIGINT but the
-- column is INT, so the call fails. Fix: cast with ::INT.

CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           COUNT(b.bike_id)::INT,
           (s.capacity - COUNT(b.bike_id))::INT
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;
-- COUNT(b.bike_id), not COUNT(*): with the LEFT JOIN, COUNT(*) would count
-- the NULL row and show 1 bike at the empty Depot station.

SELECT * FROM station_board('Almaty');
-- Output:
--       s_name    | s_bikes | s_free
--   --------------+---------+--------
--    Central Park |       3 |      1
--    Riverside    |       2 |      1
--   (2 rows)
SELECT * FROM station_board('Astana');
-- Output:
--     s_name   | s_bikes | s_free
--   -----------+---------+--------
--    Expo Gate |       2 |      3
--    Depot     |       0 |      0
--   (2 rows)


-- =====================================================================
-- Part 6: Block Structure, DO Blocks and Subblocks
-- =====================================================================

-- Exercise 6.1: An anonymous block
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows', total_rentals;
END rental_report $$;
-- Output:
--   NOTICE:  The rentals table holds 22 rows

-- With a wrong label after END:
-- DO $$
-- <<rental_report>>
-- DECLARE
--     total_rentals INTEGER := 0;
-- BEGIN
--     SELECT COUNT(*) INTO total_rentals FROM rentals;
-- END wrong_label $$;
-- ERROR:  end label "wrong_label" differs from block's label "rental_report"
-- LINE 7: END wrong_label $$;
--             ^
-- Answer: the block is not even compiled - the labels must match.

-- Exercise 6.2: A subblock and a hidden variable
DO $$
<<rental_report>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT SUM(fee) INTO fee_total FROM rentals;
    RAISE NOTICE '1. Outer before subblock: %', fee_total;

    <<recent>>
    DECLARE
        fee_total NUMERIC;              -- same name: hides the outer variable
    BEGIN
        SELECT SUM(fee) INTO fee_total
        FROM rentals
        WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE '2. Subblock own value: %', fee_total;
        RAISE NOTICE '3. Outer value via label: %', rental_report.fee_total;
    END recent;

    RAISE NOTICE '4. Outer after subblock: %', fee_total;
END rental_report $$;
-- Output:
--   NOTICE:  1. Outer before subblock: 621.50
--   NOTICE:  2. Subblock own value: 369.00
--   NOTICE:  3. Outer value via label: 621.50
--   NOTICE:  4. Outer after subblock: 621.50
-- Answer: the assignment inside the subblock did NOT change the outer
-- variable (1 and 4 are equal). A declaration in a subblock creates a new,
-- separate variable that exists only inside that subblock; the outer one is
-- only hidden and can be reached as rental_report.fee_total.

-- Exercise 6.3: Declarations are local
-- Reading a variable of the first subblock from a second subblock:
-- DO $$
-- <<rental_report>>
-- BEGIN
--     <<first>>
--     DECLARE
--         recent_total NUMERIC;
--     BEGIN
--         SELECT SUM(fee) INTO recent_total FROM rentals WHERE start_date >= DATE '2025-01-01';
--     END first;
--
--     <<second>>
--     BEGIN
--         RAISE NOTICE 'Second subblock sees: %', recent_total;
--     END second;
-- END rental_report $$;
-- ERROR:  column "recent_total" does not exist
-- LINE 1: recent_total
--         ^
-- QUERY:  recent_total
-- CONTEXT:  PL/pgSQL function inline_code_block line 13 at RAISE

-- Declaration moved up into the outer block - both subblocks see it:
DO $$
<<rental_report>>
DECLARE
    recent_total NUMERIC;
BEGIN
    <<first>>
    BEGIN
        SELECT SUM(fee) INTO recent_total FROM rentals WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE 'First subblock sets: %', recent_total;
    END first;

    <<second>>
    BEGIN
        RAISE NOTICE 'Second subblock sees: %', recent_total;
    END second;
END rental_report $$;
-- Output:
--   NOTICE:  First subblock sets: 369.00
--   NOTICE:  Second subblock sees: 369.00

-- Exercise 6.4: From a block to a function
CREATE OR REPLACE FUNCTION fee_split(p_from_date DATE,
                                     OUT before_total NUMERIC,
                                     OUT after_total  NUMERIC)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee) FILTER (WHERE start_date <  p_from_date), 0),
           COALESCE(SUM(fee) FILTER (WHERE start_date >= p_from_date), 0)
    INTO before_total, after_total
    FROM rentals;
END; $$
LANGUAGE plpgsql;

SELECT f.before_total,
       f.after_total,
       f.before_total + f.after_total   AS sum_of_both,
       (SELECT SUM(fee) FROM rentals)   AS table_total
FROM fee_split(DATE '2025-01-01') f;
-- Output:
--    before_total | after_total | sum_of_both | table_total
--   --------------+-------------+-------------+-------------
--          252.50 |      369.00 |      621.50 |      621.50
--   (1 row)


-- =====================================================================
-- Part 7: Practical Scenarios
-- =====================================================================

-- Exercise 7.1: Station occupancy
-- "Currently parked" = bikes of the station that are not on an open rental
-- (bike 101 is out on rental 19).
-- Capacity 0 (Depot): the percentage is undefined, so capacity_pct = NULL.
-- 0 would be misleading ("empty"), an error would break the query for all
-- stations; NULL honestly means "no value".
CREATE OR REPLACE FUNCTION station_load(p_station_id INT,
                                        OUT bikes_parked INT,
                                        OUT capacity_pct NUMERIC)
AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT capacity INTO v_capacity
    FROM stations
    WHERE station_id = p_station_id;

    SELECT COUNT(*) INTO bikes_parked
    FROM bikes b
    WHERE b.station_id = p_station_id
      AND NOT EXISTS (SELECT 1 FROM rentals r
                      WHERE r.bike_id = b.bike_id AND r.end_date IS NULL);

    IF v_capacity = 0 THEN
        capacity_pct := NULL;
    ELSE
        capacity_pct := ROUND(100.0 * bikes_parked / v_capacity, 1);
    END IF;
END; $$
LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l;
-- Output:
--    station_id | station_name | bikes_parked | capacity_pct
--   ------------+--------------+--------------+--------------
--            10 | Central Park |            2 |         50.0
--            20 | Riverside    |            2 |         66.7
--            30 | Expo Gate    |            2 |         40.0
--            40 | Old Town     |            1 |         50.0
--            50 | Depot        |            0 |         NULL
--   (5 rows)

-- Exercise 7.2: Top members, with a default
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (t_name VARCHAR, t_rentals INT, t_spent NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY COALESCE(SUM(r.fee), 0) DESC
    LIMIT p_limit;
END; $$
LANGUAGE plpgsql;

SELECT * FROM top_members();
-- Output:
--        t_name     | t_rentals | t_spent
--   ----------------+-----------+---------
--    Marta Kowalski |         5 |  164.75
--    Chen Wei       |         4 |  139.25
--    Daniyar Serik  |         4 |  138.00
--   (3 rows)
SELECT * FROM top_members(6);
-- Output:
--        t_name      | t_rentals | t_spent
--   -----------------+-----------+---------
--    Marta Kowalski  |         5 |  164.75
--    Chen Wei        |         4 |  139.25
--    Daniyar Serik   |         4 |  138.00
--    Aisha Nurlanova |         5 |   98.50
--    Omar Haddad     |         4 |   81.00
--    Elena Petrova   |         0 |       0
--   (6 rows)
-- Answer: Aisha Nurlanova has 5 rentals but is ranked below Chen Wei and
-- Daniyar Serik (4 rentals each). The ranking is by money spent, not by the
-- number of rentals: her rentals were cheaper, and rental 19 is still open
-- with fee NULL, so it adds a rental but no money. Not a bug.

-- Exercise 7.3: An invoice for an open rental
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (i_member VARCHAR, i_model VARCHAR, i_days INT,
               i_amount NUMERIC, i_status TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           b.model,
           COALESCE(r.end_date, CURRENT_DATE) - r.start_date,
           ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2),
           CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes b   ON b.bike_id   = r.bike_id
    WHERE r.rental_id = p_rental_id;
END; $$
LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
-- Output:
--       i_member    |   i_model   | i_days | i_amount | i_status
--   ----------------+-------------+--------+----------+----------
--    Marta Kowalski | Road Sprint |      8 |    74.00 | CLOSED
--   (1 row)
SELECT * FROM rental_invoice(19);
-- Output:
--       i_member     |   i_model    | i_days | i_amount | i_status
--   -----------------+--------------+--------+----------+----------
--    Aisha Nurlanova | City Cruiser |    410 |  1845.00 | OPEN
--   (1 row)
-- Answer: rental 11: 8 days x 9.25 = 74.00, equal to the stored fee.
-- Rental 19 is open, so it is charged up to CURRENT_DATE: the number of days
-- and the amount grow every day (the output above was run on 2026-11-24).
-- Such a function cannot be IMMUTABLE: IMMUTABLE means "same arguments ->
-- always the same result", but here the result depends on the date
-- (and on table data). It is at most STABLE.

-- Exercise 7.4: A report per city
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (c_members INT, c_rentals INT, c_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (c_members INT, c_rentals INT, c_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
                       AND r.start_date >= p_from_date      -- date condition in ON
    WHERE m.city = p_city;
END; $$
LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
-- Output:
--    c_members | c_rentals | c_revenue
--   -----------+-----------+-----------
--            3 |         9 |    236.50
--   (1 row)
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
-- Output:
--    c_members | c_rentals | c_revenue
--   -----------+-----------+-----------
--            3 |         5 |    135.50
--   (1 row)

-- The same with the date condition in WHERE instead of ON:
SELECT COUNT(DISTINCT m.member_id) AS c_members,
       COUNT(r.rental_id)          AS c_rentals,
       COALESCE(SUM(r.fee), 0)     AS c_revenue
FROM members m
LEFT JOIN rentals r ON r.member_id = m.member_id
WHERE m.city = 'Almaty'
  AND r.start_date >= DATE '2025-01-01';
-- Output:
--    c_members | c_rentals | c_revenue
--   -----------+-----------+-----------
--            2 |         5 |    135.50
--   (1 row)
-- Answer: the date condition belongs in ON. In ON, Elena Petrova (no
-- rentals) is still joined with NULLs and counted: 3 members. In WHERE, her
-- row has start_date NULL, NULL >= date is not TRUE, the row is removed and
-- the LEFT JOIN acts like an INNER JOIN: only 2 members.


-- =====================================================================
-- Lab Questions
-- =====================================================================
-- 1. The name is just total_fees; the signature is the name plus the
--    argument types, e.g. total_fees(integer, date). With overloading,
--    several functions share one name, so DROP FUNCTION needs the argument
--    types to know which one to remove.
--
-- 2. $$ marks the start and end of the body, so quotes inside it need no
--    escaping. Without it every ' must be doubled:
--      ... AS 'BEGIN RETURN ''Rental '' || p_id || '' is '' || ''OPEN''; END;'
--    With dollar quoting: AS $$ BEGIN RETURN 'Rental ' || p_id || ' is OPEN'; END; $$
--
-- 3. Several OUT parameters: when the function returns exactly ONE row with
--    a few values (member_stats, fee_split). RETURNS TABLE: when it returns
--    MANY rows (find_bikes, member_history).
--
-- 4. VARIADIC takes all remaining arguments. If it were not last, e.g.
--    f(VARIADIC a NUMERIC[], b NUMERIC), the call f(1, 2, 3) would be
--    impossible to split: is it a = {1,2}, b = 3, or a = {1}, ... ? Being
--    last, the rule is simple: everything after the fixed parameters goes
--    into the array.
--
-- 5. RETURN returns one value and ends the function. RETURN QUERY adds all
--    rows of a SELECT to the function's result set (for RETURNS TABLE /
--    SETOF) and the function continues; it ends at the final END or RETURN.
--
-- 6. A DEFAULT lets the new function also match calls with fewer arguments.
--    If another function with exactly that shorter argument list already
--    exists, both match and the call becomes ambiguous (Exercise 4.3).
--    Avoid it by not overloading a name with defaults, giving functions
--    different names, or dropping the old version in the same change.
--
-- 7. It disappears: it exists only while the subblock runs. A shadowed
--    variable of the outer block is read through its label:
--    outer_label.variable_name.
--
-- 8. Advantage: one shared rule for every application, executed in one
--    round trip (and execute rights can be granted without table access).
--    Disadvantage: harder to version-control, test and debug, and it ties
--    the system to PostgreSQL's language.
--
-- 9. A trusted language (PL/pgSQL) cannot access anything outside the
--    database - no files, no network - so ordinary users may create
--    functions in it. An untrusted language (PL/Pythonu) can do anything
--    the server's OS user can, so only a superuser may create functions in it.
--
-- 10. CREATE OR REPLACE with different argument types does not replace
--     anything: it creates a NEW function with a new signature, and the old
--     one stays. The database now has two overloaded versions; callers may
--     still reach the old one, and calls can become ambiguous.


-- =====================================================================
-- Additional Challenges (Optional)
-- =====================================================================

-- Challenge 1: busiest station since a date (closed rentals only,
-- because an open rental has no final number of days yet)
CREATE OR REPLACE FUNCTION busiest_station(p_from_date DATE DEFAULT DATE '2024-01-01')
RETURNS TABLE (b_station VARCHAR, b_days INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           SUM(r.end_date - r.start_date)::INT
    FROM rentals r
    JOIN bikes b    ON b.bike_id    = r.bike_id
    JOIN stations s ON s.station_id = b.station_id
    WHERE r.start_date >= p_from_date
      AND r.end_date IS NOT NULL
    GROUP BY s.station_id, s.station_name
    ORDER BY 2 DESC
    LIMIT 1;
END; $$
LANGUAGE plpgsql;

SELECT * FROM busiest_station();
-- Output:
--    b_station | b_days
--   -----------+--------
--    Riverside |     25
--   (1 row)

-- Challenge 2: a loop with one notice per member
CREATE OR REPLACE FUNCTION member_activity_report() RETURNS VOID AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT m.full_name, COUNT(r.rental_id) AS cnt, COALESCE(SUM(r.fee), 0) AS spent
        FROM members m
        LEFT JOIN rentals r ON r.member_id = m.member_id
        GROUP BY m.member_id, m.full_name
        ORDER BY m.member_id
    LOOP
        RAISE NOTICE '%: % rentals, % spent', rec.full_name, rec.cnt, rec.spent;
    END LOOP;
END; $$
LANGUAGE plpgsql;

SELECT member_activity_report();
-- Output:
--   NOTICE:  Aisha Nurlanova: 5 rentals, 98.50 spent
--   NOTICE:  Daniyar Serik: 4 rentals, 138.00 spent
--   NOTICE:  Marta Kowalski: 5 rentals, 164.75 spent
--   NOTICE:  Chen Wei: 4 rentals, 139.25 spent
--   NOTICE:  Omar Haddad: 4 rentals, 81.00 spent
--   NOTICE:  Elena Petrova: 0 rentals, 0 spent
--    member_activity_report
--   ------------------------
--   (1 row)
-- The single SELECT inside the loop already gives the same data as a normal
-- result set that any client can read. I would ship the SELECT (or a view):
-- notices are only text messages, not data; the loop is extra code.

-- Challenge 3: rental_days with a clear error for an unknown id
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Rental % does not exist', p_rental_id;
    END IF;

    RETURN v_days;
END; $$
LANGUAGE plpgsql;

-- SELECT rental_days(999);
-- ERROR:  Rental 999 does not exist
-- CONTEXT:  PL/pgSQL function rental_days(integer) line 11 at RAISE
-- For a single call this is better: a wrong id is reported, not hidden as
-- NULL. Inside a large query it is risky: one bad id stops the whole query.

-- Challenge 4: fee_report(INT), fee_report(VARCHAR), fee_report(TEXT)
CREATE OR REPLACE FUNCTION fee_report(p_member_id INT) RETURNS NUMERIC AS $$
BEGIN
    RETURN (SELECT COALESCE(SUM(fee), 0) FROM rentals WHERE member_id = p_member_id);
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fee_report(p_name VARCHAR) RETURNS NUMERIC AS $$
BEGIN
    RETURN (SELECT COALESCE(SUM(r.fee), 0)
            FROM rentals r JOIN members m ON m.member_id = r.member_id
            WHERE m.full_name = p_name);
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fee_report(p_name TEXT) RETURNS NUMERIC AS $$
BEGIN
    RETURN -1;     -- different body to show which version is called
END; $$ LANGUAGE plpgsql;

SELECT fee_report('Aisha Nurlanova');
-- Output:
--    fee_report
--   ------------
--            -1
--   (1 row)
SELECT fee_report('Aisha Nurlanova'::VARCHAR);
-- Output:
--    fee_report
--   ------------
--         98.50
--   (1 row)
-- VARCHAR and TEXT are different types, so the TEXT version is created
-- without error. A plain string literal has no type yet and PostgreSQL
-- prefers TEXT (the preferred string type), so the call silently goes to
-- the TEXT version; the VARCHAR version is reached only with an explicit
-- cast. Overloading on VARCHAR vs TEXT is confusing and should be avoided.

-- Challenge 5: CREATE PROCEDURE and CALL
CREATE OR REPLACE PROCEDURE close_rental(p_rental_id INT, p_end_date DATE)
AS $$
BEGIN
    UPDATE rentals r
    SET end_date = p_end_date,
        fee      = (p_end_date - r.start_date) * b.daily_rate
    FROM bikes b
    WHERE b.bike_id = r.bike_id
      AND r.rental_id = p_rental_id
      AND r.end_date IS NULL;
END; $$
LANGUAGE plpgsql;

-- run inside a transaction and roll back, so the lab data stays unchanged
BEGIN;
CALL close_rental(19, DATE '2025-10-15');
SELECT rental_id, end_date, fee FROM rentals WHERE rental_id = 19;
-- Output:
--    rental_id |  end_date  |  fee
--   -----------+------------+-------
--           19 | 2025-10-15 | 22.50
--   (1 row)
ROLLBACK;
-- A procedure is run with CALL, returns no value, and - unlike a function -
-- can manage transactions inside its body (COMMIT / ROLLBACK), which is
-- useful for long batch jobs. A function always runs inside the caller's
-- transaction and must return a value, but can be used inside a SELECT.
