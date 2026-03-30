-- PostgreSQL Task 1: Test Script
-- This script validates the database schema and data

\set ON_ERROR_STOP off

DROP TABLE IF EXISTS test_results;
CREATE TEMP TABLE test_results(line text);

DO $$
DECLARE
    failures integer := 0;
    c integer;
BEGIN
    SELECT count(*) INTO c
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name IN ('students', 'courses', 'enrollments');
    IF c = 3 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Tables exist: PASS - 3/3');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Tables exist: FAIL - ' || c || '/3');
    END IF;

    SELECT count(*) INTO c
    FROM information_schema.columns
    WHERE table_name = 'students' AND column_name IN ('id', 'name', 'email', 'age');
    IF c = 4 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Students columns: PASS - 4/4');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Students columns: FAIL - ' || c || '/4');
    END IF;

    SELECT count(*) INTO c
    FROM information_schema.columns
    WHERE table_name = 'courses' AND column_name IN ('id', 'title', 'credits');
    IF c = 3 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Courses columns: PASS - 3/3');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Courses columns: FAIL - ' || c || '/3');
    END IF;

    SELECT count(*) INTO c
    FROM information_schema.columns
    WHERE table_name = 'enrollments' AND column_name IN ('student_id', 'course_id', 'grade');
    IF c = 3 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Enrollments columns: PASS - 3/3');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Enrollments columns: FAIL - ' || c || '/3');
    END IF;

    SELECT count(*) INTO c FROM students;
    IF c >= 3 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Students data: PASS - ' || c || ' records');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Students data: FAIL - ' || c || '/3 minimum');
    END IF;

    SELECT count(*) INTO c FROM courses;
    IF c >= 2 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Courses data: PASS - ' || c || ' records');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Courses data: FAIL - ' || c || '/2 minimum');
    END IF;

    SELECT count(*) INTO c FROM enrollments;
    IF c >= 2 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Enrollments data: PASS - ' || c || ' records');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Enrollments data: FAIL - ' || c || '/2 minimum');
    END IF;

    SELECT count(*) INTO c
    FROM (
        SELECT email
        FROM students
        GROUP BY email
        HAVING count(*) > 1
    ) dup_emails;
    IF c = 0 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Email uniqueness: PASS');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Email uniqueness: FAIL - duplicates=' || c);
    END IF;

    SELECT count(*) INTO c FROM students WHERE age < 18;
    IF c = 0 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Age constraint: PASS');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Age constraint: FAIL - underage=' || c);
    END IF;

    SELECT count(*) INTO c FROM courses WHERE credits <= 0;
    IF c = 0 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Credits constraint: PASS');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Credits constraint: FAIL - invalid=' || c);
    END IF;

    SELECT count(*) INTO c
    FROM enrollments
    WHERE grade NOT IN ('A','B','C','D','F') AND grade IS NOT NULL;
    IF c = 0 THEN
        INSERT INTO test_results(line) VALUES ('TEST: Grade constraint: PASS');
    ELSE
        failures := failures + 1;
        INSERT INTO test_results(line) VALUES ('TEST: Grade constraint: FAIL - invalid=' || c);
    END IF;

    IF failures = 0 THEN
        INSERT INTO test_results(line) VALUES ('RESULT: PASS');
    ELSE
        INSERT INTO test_results(line) VALUES ('RESULT: FAIL - failures=' || failures);
        INSERT INTO test_results(line) VALUES ('ERROR: Tests failed. failures=' || failures);
    END IF;
END $$;

SELECT line FROM test_results;
