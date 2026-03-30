-- PostgreSQL Task 1: University Database Schema
-- This is an example solution that students should create

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS university;

-- Connect to the university database
\c university

-- Drop tables if they exist (for clean re-runs)
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

-- Create students table
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INTEGER CHECK (age >= 18)
);

-- Create courses table
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    credits INTEGER CHECK (credits > 0)
);

-- Create enrollments table with foreign keys and constraints
CREATE TABLE enrollments (
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    course_id INTEGER REFERENCES courses(id) ON DELETE CASCADE,
    grade CHAR(1) CHECK (grade IN ('A','B','C','D','F')),
    PRIMARY KEY (student_id, course_id)
);

-- Insert sample data into students
INSERT INTO students (name, email, age) VALUES
    ('Alice Johnson', 'alice.johnson@university.edu', 20),
    ('Bob Smith', 'bob.smith@university.edu', 22),
    ('Charlie Brown', 'charlie.brown@university.edu', 19),
    ('Diana Prince', 'diana.prince@university.edu', 21);

-- Insert sample data into courses
INSERT INTO courses (title, credits) VALUES
    ('Introduction to Computer Science', 3),
    ('Database Systems', 4),
    ('Web Development', 3);

-- Insert sample data into enrollments
INSERT INTO enrollments (student_id, course_id, grade) VALUES
    (1, 1, 'A'),  -- Alice - Intro to CS
    (1, 2, 'B'),  -- Alice - Database Systems
    (2, 1, 'B'),  -- Bob - Intro to CS
    (2, 3, 'A'),  -- Bob - Web Development
    (3, 1, 'C'),  -- Charlie - Intro to CS
    (4, 2, 'A'),  -- Diana - Database Systems
    (4, 3, 'B');  -- Diana - Web Development

-- Create some useful views for demonstration
CREATE VIEW student_summary AS
SELECT 
    s.id,
    s.name,
    s.email,
    s.age,
    COUNT(e.course_id) as enrolled_courses,
    AVG(CASE 
        WHEN e.grade = 'A' THEN 4
        WHEN e.grade = 'B' THEN 3
        WHEN e.grade = 'C' THEN 2
        WHEN e.grade = 'D' THEN 1
        WHEN e.grade = 'F' THEN 0
    END) as gpa
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
GROUP BY s.id, s.name, s.email, s.age;

CREATE VIEW course_summary AS
SELECT 
    c.id,
    c.title,
    c.credits,
    COUNT(e.student_id) as enrolled_students,
    AVG(CASE 
        WHEN e.grade = 'A' THEN 4
        WHEN e.grade = 'B' THEN 3
        WHEN e.grade = 'C' THEN 2
        WHEN e.grade = 'D' THEN 1
        WHEN e.grade = 'F' THEN 0
    END) as average_grade
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
GROUP BY c.id, c.title, c.credits;

-- Sample queries to demonstrate the database
SELECT '=== Students ===' as info;
SELECT * FROM students ORDER BY id;

SELECT '=== Courses ===' as info;
SELECT * FROM courses ORDER BY id;

SELECT '=== Enrollments ===' as info;
SELECT 
    s.name as student_name,
    c.title as course_title,
    e.grade
FROM enrollments e
JOIN students s ON e.student_id = s.id
JOIN courses c ON e.course_id = c.id
ORDER BY s.name, c.title;

SELECT '=== Student Summary ===' as info;
SELECT * FROM student_summary ORDER BY name;

SELECT '=== Course Summary ===' as info;
SELECT * FROM course_summary ORDER BY title;
