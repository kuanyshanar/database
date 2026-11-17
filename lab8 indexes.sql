-- Laboratory Work 8: SQL Indexes (PostgreSQL)
-- Part 1: Setup
CREATE TABLE departments (dept_id INT PRIMARY KEY, dept_name VARCHAR(50), location VARCHAR(50));
CREATE TABLE employees (
    emp_id INT PRIMARY KEY, emp_name VARCHAR(100), dept_id INT, salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id));
CREATE TABLE projects (
    proj_id INT PRIMARY KEY, proj_name VARCHAR(100), budget DECIMAL(12,2), dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id));

INSERT INTO departments VALUES (101,'IT','Building A'),(102,'HR','Building B'),(103,'Operations','Building C');
INSERT INTO employees VALUES
(1,'John Smith',101,50000),(2,'Jane Doe',101,55000),(3,'Mike Johnson',102,48000),
(4,'Sarah Williams',102,52000),(5,'Tom Brown',103,60000);
INSERT INTO projects VALUES
(201,'Website Redesign',75000,101),(202,'Database Migration',120000,101),(203,'HR System Upgrade',50000,102);

-- Part 2
CREATE INDEX emp_salary_idx ON employees(salary);
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees';
-- Q2.1: 2 indexes: employees_pkey (automatic, PRIMARY KEY) and emp_salary_idx.

CREATE INDEX emp_dept_idx ON employees(dept_id);
SELECT * FROM employees WHERE dept_id = 101;
-- Q2.2: Foreign keys are used in JOINs and lookups of child rows; an index speeds these up,
-- and also speeds checks when a parent row is deleted/updated (PostgreSQL does NOT index FKs automatically).

SELECT tablename, indexname, indexdef FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;
-- Q2.3: departments_pkey, employees_pkey, projects_pkey were created automatically (PRIMARY KEY).
-- Manual: emp_salary_idx, emp_dept_idx.

-- Part 3
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);
SELECT emp_name, salary FROM employees WHERE dept_id = 101 AND salary > 52000;
-- Q3.1: Generally no. A B-tree multicolumn index is efficient when the leading column (dept_id) is
-- constrained; filtering only on salary can't use it efficiently (full index scan at best).

CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
-- Q3.2: Column order in the index matters; the order in the WHERE clause does not (planner reorders).
-- (dept_id, salary) is best for equality on dept_id + range on salary; (salary, dept_id) is best when
-- salary is the leading/only filter.

-- Part 4
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com'   WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com'      WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com'  WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com'     WHERE emp_id = 5;
CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- Expected to FAIL:
INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
-- Q4.1: ERROR: duplicate key value violates unique constraint "emp_email_unique_idx"
--       DETAIL: Key (email)=(john.smith@company.com) already exists.

ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees' AND indexname LIKE '%phone%';
-- Q4.2: Yes. PostgreSQL automatically created a unique B-tree index named employees_phone_key.

-- Part 5
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);
SELECT emp_name, salary FROM employees ORDER BY salary DESC;
-- Q5.1: Index is already stored in sorted order, so the planner can read rows in order
-- and skip an explicit sort step. (A plain ASC B-tree can also be scanned backwards; DESC matters most
-- for multicolumn indexes with mixed ordering.)

CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);
SELECT proj_name, budget FROM projects ORDER BY budget NULLS FIRST;

-- Part 6
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));
SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- Q6.1: Without it, PostgreSQL does a sequential scan and applies LOWER() to every row.

ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;
CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));
SELECT emp_name, hire_date FROM employees WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- Part 7
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';
DROP INDEX emp_salary_dept_idx;
-- Q7.2: Unused/redundant indexes waste disk space and slow INSERT/UPDATE/DELETE.
REINDEX INDEX employees_salary_index;

-- Part 8
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- (JOIN: emp_dept_idx; ORDER BY: emp_salary_desc_idx already exist)
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;
SELECT proj_name, budget FROM projects WHERE budget > 80000;
-- Q8.2: Partial index is smaller, cheaper to maintain (only matching rows are indexed), and faster to scan.
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
-- Q8.3: With only 5 rows you will most likely see "Seq Scan": the planner decides reading the
-- single page is cheaper than using an index. Indexes pay off on large tables. To see an index scan
-- anyway: SET enable_seqscan = off; then rerun EXPLAIN (for demonstration only).

-- Part 9
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);
SELECT * FROM departments WHERE dept_name = 'IT';
-- Q9.1: Use HASH only for pure equality lookups (=); B-tree supports =, <, >, BETWEEN, ORDER BY.
-- B-tree is almost always the better default.

CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx  ON projects USING HASH (proj_name);
SELECT * FROM projects WHERE proj_name = 'Website Redesign';  -- both can be used
SELECT * FROM projects WHERE proj_name > 'Database';          -- only B-tree

-- Part 10
SELECT schemaname, tablename, indexname,
       pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;
-- Q10.1: Likely the hash indexes (a hash index preallocates metapage, bitmap and bucket pages, so it is
-- bigger than a B-tree on tiny tables). Check your own output.

DROP INDEX IF EXISTS proj_name_hash_idx;

CREATE VIEW index_documentation AS
SELECT tablename, indexname, indexdef, 'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public' AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;

-- Summary Questions
-- 1. B-tree.
-- 2. Create an index on: columns frequently in WHERE; foreign keys / JOIN columns; ORDER BY columns on large tables.
-- 3. Don't index: very small tables; columns rarely queried; tables with heavy writes; low-selectivity columns (e.g. boolean).
-- 4. Indexes are updated on every INSERT/UPDATE/DELETE, so writes get slower (and use extra disk space).
-- 5. EXPLAIN / EXPLAIN ANALYZE: look for Index Scan / Index Only Scan / Bitmap Index Scan vs Seq Scan.

-- Additional Challenges
-- 1. Hired in a specific month:
CREATE INDEX emp_hire_month_idx ON employees(EXTRACT(MONTH FROM hire_date));
-- 2. Composite unique index:
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);
-- 3. Compare performance:
EXPLAIN ANALYZE SELECT * FROM employees WHERE dept_id = 101;
SET enable_indexscan = off; SET enable_bitmapscan = off;
EXPLAIN ANALYZE SELECT * FROM employees WHERE dept_id = 101;
RESET enable_indexscan; RESET enable_bitmapscan;
-- 4. Covering index (index-only scan):
CREATE INDEX emp_dept_cover_idx ON employees(dept_id) INCLUDE (emp_name, salary);
EXPLAIN SELECT emp_name, salary FROM employees WHERE dept_id = 101;

-- Reflection: use indexes on large, read-heavy tables for columns used in WHERE/JOIN/ORDER BY;
-- avoid over-indexing because each index costs disk space and write speed; verify with EXPLAIN.
