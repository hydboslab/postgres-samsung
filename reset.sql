-- dbms_class 데이터베이스에 접속한 상태로 실행시켜주시면 됩니다.

-- Drop existing tables
DROP TABLE IF EXISTS course CASCADE;
DROP TABLE IF EXISTS enrolled;
DROP TABLE IF EXISTS students CASCADE;

-- Create schemas
CREATE TABLE course (
	cid INT NOT NULL PRIMARY KEY,
	code CHAR(5), 
	name VARCHAR(20), 
	credit INT
);

CREATE TABLE students ( 
	sid SERIAL,name VARCHAR(10) NOT NULL DEFAULT '', 
	age INT, 
	gpa DOUBLE PRECISION NOT NULL DEFAULT '0.0',
	department VARCHAR(20) NOT NULL DEFAULT '',
	PRIMARY KEY (sid)
); 

CREATE TABLE enrolled (
	sid INT NOT NULL,
	cid INT NOT NULL,
	PRIMARY KEY (sid, cid),
	FOREIGN KEY (sid) REFERENCES students (sid),
	FOREIGN KEY (cid) REFERENCES course (cid)
);

-- Insert data
INSERT INTO course VALUES
(10, 'ITE01', 'Database Systems', 3),
(11, 'ITE02', 'Operating Systems', 3),
(12, 'ITE03', 'Algorithms', 3);

Insert INTO students VALUES
(100, 'Fred', 23, 3.5, 'Computer Science'),
(101, 'David', 23, 3.7, 'Electronics'),
(102, 'John', 21, 3.3, 'Electronics'),
(103, 'Jake', 24, 4.0, 'Computer Science'), 
(104, 'George', 22, 2.8, 'Computer Science'),
(105, 'Kim', 25, 3.7, 'Electronics'),
(106, 'Louise', 21, 3.5, 'Electronics');

INSERT INTO enrolled VALUES
(100, 10),
(100, 11),
(100, 12),
(101, 10),
(101, 11),
(102, 10),
(103, 11),
(104, 12);



