import psycopg2
import os
import sys

def run_tests():
    db_url = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/test_db')
    
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}")
        return False

    tests_passed = 0
    total_tests = 0

    def test(name, fn):
        nonlocal tests_passed, total_tests
        total_tests += 1
        try:
            fn(cur)
            print(f"✅ {name}")
            tests_passed += 1
        except Exception as e:
            print(f"❌ {name}: {e}")

    # Test 1: Database exists
    def test_database_exists(cur):
        cur.execute("SELECT 1 FROM pg_database WHERE datname='university'")
        if not cur.fetchone():
            raise Exception("Database 'university' does not exist")
    
    test("Database 'university' exists", test_database_exists)

    # Test 2: Tables exist
    def test_tables_exist(cur):
        cur.execute("""
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name IN ('students', 'courses', 'enrollments')
        """)
        tables = {row[0] for row in cur.fetchall()}
        required = {'students', 'courses', 'enrollments'}
        missing = required - tables
        if missing:
            raise Exception(f"Missing tables: {missing}")
    
    test("Required tables exist", test_tables_exist)

    # Connect to university database for table structure tests
    conn.close()
    conn = psycopg2.connect(db_url.replace('/test_db', '/university'))
    cur = conn.cursor()

    # Test 3: Students table structure
    def test_students_structure(cur):
        cur.execute("""
            SELECT column_name, data_type, is_nullable, column_default 
            FROM information_schema.columns 
            WHERE table_name = 'students' 
            ORDER BY ordinal_position
        """)
        columns = {row[0]: {'type': row[1], 'nullable': row[2] == 'YES', 'default': row[3]} for row in cur.fetchall()}
        
        expected = {
            'id': {'type': 'integer', 'nullable': False, 'default': lambda d: d and 'nextval' in d},
            'name': {'type': 'character varying', 'nullable': False, 'default': None},
            'email': {'type': 'character varying', 'nullable': False, 'default': None},
            'age': {'type': 'integer', 'nullable': True, 'default': None}
        }
        
        for col, exp in expected.items():
            if col not in columns:
                raise Exception(f"Column '{col}' missing in students table")
            if columns[col]['type'] != exp['type']:
                raise Exception(f"Column '{col}' has wrong type: {columns[col]['type']} != {exp['type']}")
            if columns[col]['nullable'] != exp['nullable']:
                raise Exception(f"Column '{col}' nullable mismatch: {columns[col]['nullable']} != {exp['nullable']}")
            if exp['default'] and not exp['default'](columns[col]['default']):
                raise Exception(f"Column '{col}' default mismatch")
    
    test("Students table structure correct", test_students_structure)

    # Test 4: Courses table structure
    def test_courses_structure(cur):
        cur.execute("""
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'courses'
        """)
        columns = {row[0]: {'type': row[1], 'nullable': row[2] == 'YES'} for row in cur.fetchall()}
        
        expected = {
            'id': {'type': 'integer', 'nullable': False},
            'title': {'type': 'character varying', 'nullable': False},
            'credits': {'type': 'integer', 'nullable': True}
        }
        
        for col, exp in expected.items():
            if col not in columns:
                raise Exception(f"Column '{col}' missing in courses table")
            if columns[col]['type'] != exp['type']:
                raise Exception(f"Column '{col}' has wrong type")
            if columns[col]['nullable'] != exp['nullable']:
                raise Exception(f"Column '{col}' nullable mismatch")
    
    test("Courses table structure correct", test_courses_structure)

    # Test 5: Enrollments table structure
    def test_enrollments_structure(cur):
        cur.execute("""
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'enrollments'
        """)
        columns = {row[0]: {'type': row[1], 'nullable': row[2] == 'YES'} for row in cur.fetchall()}
        
        expected = {
            'student_id': {'type': 'integer', 'nullable': False},
            'course_id': {'type': 'integer', 'nullable': False},
            'grade': {'type': 'character', 'nullable': True}
        }
        
        for col, exp in expected.items():
            if col not in columns:
                raise Exception(f"Column '{col}' missing in enrollments table")
            if columns[col]['type'] != exp['type']:
                raise Exception(f"Column '{col}' has wrong type")
            if columns[col]['nullable'] != exp['nullable']:
                raise Exception(f"Column '{col}' nullable mismatch")
    
    test("Enrollments table structure correct", test_enrollments_structure)

    # Test 6: Data exists
    def test_data_exists(cur):
        cur.execute("SELECT COUNT(*) FROM students")
        students_count = cur.fetchone()[0]
        if students_count < 3:
            raise Exception(f"Expected at least 3 students, got {students_count}")
        
        cur.execute("SELECT COUNT(*) FROM courses")
        courses_count = cur.fetchone()[0]
        if courses_count < 2:
            raise Exception(f"Expected at least 2 courses, got {courses_count}")
        
        cur.execute("SELECT COUNT(*) FROM enrollments")
        enrollments_count = cur.fetchone()[0]
        if enrollments_count < 2:
            raise Exception(f"Expected at least 2 enrollments, got {enrollments_count}")
    
    test("Test data exists", test_data_exists)

    # Test 7: Constraints
    def test_constraints(cur):
        # Test unique email constraint
        cur.execute("SELECT email, COUNT(*) FROM students GROUP BY email HAVING COUNT(*) > 1")
        duplicate_emails = cur.fetchall()
        if duplicate_emails:
            raise Exception(f"Duplicate emails found: {duplicate_emails}")
        
        # Test age constraint
        cur.execute("SELECT age FROM students WHERE age < 18")
        underage_students = cur.fetchall()
        if underage_students:
            raise Exception(f"Underage students found: {underage_students}")
        
        # Test credits constraint
        cur.execute("SELECT credits FROM courses WHERE credits <= 0")
        invalid_credits = cur.fetchall()
        if invalid_credits:
            raise Exception(f"Invalid credits found: {invalid_credits}")
        
        # Test grade constraint
        cur.execute("SELECT grade FROM enrollments WHERE grade NOT IN ('A','B','C','D','F') AND grade IS NOT NULL")
        invalid_grades = cur.fetchall()
        if invalid_grades:
            raise Exception(f"Invalid grades found: {invalid_grades}")
    
    test("Constraints work correctly", test_constraints)

    cur.close()
    conn.close()

    print(f"\n📊 Test Results: {tests_passed}/{total_tests} passed")
    return tests_passed == total_tests

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
