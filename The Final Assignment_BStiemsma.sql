--**********************************************************************************************--
-- Title: ITFnd130Final
-- Author: BStiemsma
-- Desc: This file demonstrates how to design and create; 
--       tables, views, and stored procedures
-- Change Log: When,Who,What
-- 2024-08-26,BStiemsma,Created File
--***********************************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'ITFnd130FinalDB_BStiemsma')
	 Begin 
	  Alter Database [ITFnd130FinalDB_BStiemsma] set Single_user With Rollback Immediate;
	  Drop Database ITFnd130FinalDB_BStiemsma;
	 End
	Create Database ITFnd130FinalDB_BStiemsma;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use ITFnd130FinalDB_BStiemsma;

-- Create Tables (Review Module 01)-- 

CREATE TABLE Courses (
    CourseID int not null IDENTITY(1,1),
    CourseName nvarchar(100) not null,
    CourseStartDate date null,
    CourseEndDate date null,
    CourseStartTime time null,
    CourseEndTime time null,
    CourseDaysOfWeek nvarchar(100) null,
    CourseCurrentPrice money null
);
GO

CREATE TABLE Students (
    StudentID int not null IDENTITY(1,1),
    StudentNumber nvarchar(100) not null,
    StudentFirstName nvarchar(100) not null,
    StudentLastName nvarchar(100) not null,
    StudentEmail nvarchar(100) not null,
    StudentPhone nvarchar(12) not null,
    StudentAddress1 nvarchar(100) not null,
    StudentAddress2 nvarchar(100) null,
    StudentCity nvarchar(100) not null,
    StudentStateCode nvarchar(2) not null,
    StudentZipCode nvarchar(10) not null
);
GO

CREATE TABLE Enrollments (
    EnrollmentID int not null IDENTITY(1,1),
    StudentID int not null,
    CourseID int not null,
    EnrollmentDate date not null,
    EnrollmentPrice money not null
);
GO

-- Add Constraints (Review Module 02) -- 

ALTER TABLE Courses
    ADD CONSTRAINT pkCourseID PRIMARY KEY (CourseID),
        CONSTRAINT ukCourseName UNIQUE (CourseName),
        CONSTRAINT ckCourseStartDateBeforeEndDate CHECK (CourseStartDate < CourseEndDate), --ensures that the course start date is before the course end date
        CONSTRAINT ckCourseEndDateAfterStartDate CHECK (CourseEndDate > CourseStartDate), --ensures that the course end date is after the course start date
        CONSTRAINT ckCourseStartTimeBeforeEndTime CHECK (CourseStartTime < CourseEndTime), --ensures that the course start time is before the course end time
        CONSTRAINT ckCourseEndTimeAfterStartTime CHECK (CourseEndTime > CourseStartTime) --ensures that the course end time is after the course start time
;
GO

ALTER TABLE Students
    ADD CONSTRAINT pkStudentID PRIMARY KEY (StudentID),
        CONSTRAINT ukStudentNumber UNIQUE (StudentNumber), --ensures a unique student ID
        CONSTRAINT ukStudentEmail UNIQUE (StudentEmail), --ensures a unique student email
        CONSTRAINT ckStudentPhone CHECK (StudentPhone LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'), --ensures numerical phone number in xxx-xxx-xxxx form
        CONSTRAINT ckStudentEmail CHECK (StudentEmail LIKE '%_@%_.%_'), --ensures email address in xxxx@xxx.xxx format
        CONSTRAINT ckStudentZipCode CHECK (StudentZipCode LIKE '[0-9][0-9][0-9][0-9][0-9]' OR StudentZipCode LIKE '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]') --ensures zip code is numerical and in xxxxx or xxxxx-xxxx format
;
GO

ALTER TABLE Enrollments
    ADD CONSTRAINT pkEnrollmentID PRIMARY KEY (EnrollmentID),
        CONSTRAINT fkStudentID FOREIGN KEY (StudentID) REFERENCES Students(StudentID), --foreign key that references StudentID in Students table
        CONSTRAINT fkCourseID FOREIGN KEY (CourseID) REFERENCES Courses(CourseID), --foreign key that references CourseID in Courses table
        CONSTRAINT ckEnrollmentPriceNonNegative CHECK (EnrollmentPrice >=0), --ensures the enrollment price of the course is non-netagive
        CONSTRAINT dfEnrollmentDate DEFAULT GETDATE() FOR EnrollmentDate --defaults the enrollment date to the current date if none provided
;
GO        


-- Add Views (Review Module 03 and 06) -- 

CREATE OR ALTER VIEW vCourses WITH SCHEMABINDING AS
SELECT CourseID, CourseName, CourseStartDate, CourseEndDate, CourseStartTime, CourseEndTime, CourseDaysOfWeek, CourseCurrentPrice
FROM dbo.Courses;
GO

CREATE OR ALTER VIEW vStudents WITH SCHEMABINDING AS
SELECT StudentID, StudentNumber, StudentFirstName, StudentLastName, StudentEmail, StudentPhone, StudentAddress1, StudentAddress2, StudentCity, StudentStateCode, StudentZipCode
FROM dbo.Students;
GO

CREATE OR ALTER VIEW vEnrollments WITH SCHEMABINDING AS
SELECT EnrollmentID, StudentID, CourseID, EnrollmentDate, EnrollmentPrice
FROM dbo.Enrollments;
GO

CREATE OR ALTER VIEW vSpreadsheet WITH SCHEMABINDING AS
SELECT TOP 999999
    C.CourseName AS [Course], 
    CAST(C.CourseStartDate AS nvarchar)+ ' to ' + CAST(C.CourseEndDate AS nvarchar) AS [Dates], 
    C.CourseDaysOfWeek AS Days, 
    C.CourseStartTime AS [Start], 
    C.CourseEndTime AS [End], 
    C.CourseCurrentPrice AS [Price],
    S.StudentFirstName + ' ' + S.StudentLastName AS [Student],
    S.StudentNumber AS [Number],
    S.StudentEmail AS [Email],
    S.StudentPhone AS [Phone],
    S.StudentAddress1 + ' ' + S.StudentStateCode + ', ' + S.StudentZipCode AS [Address],
    E.EnrollmentDate AS [Signup Date],
    E.EnrollmentPrice AS [Paid]
    FROM dbo.vEnrollments AS E
    JOIN dbo.vStudents AS S ON E.StudentID = S.StudentID
    JOIN dbo.vCourses AS C ON E.CourseID = C.CourseID
    ORDER BY CourseName, Student;
GO

--SELECT * FROM vSpreadsheet

--< Test Tables by adding Sample Data >--  

INSERT INTO Courses (CourseName, CourseStartDate, CourseEndDate, CourseStartTime, CourseEndTime, CourseDaysOfWeek, CourseCurrentPrice)
VALUES
        ('SQL1 - Winter 2017', '1/10/2017', '1/27/2017', '18:00','20:50', 'T', '399.00'),
        ('SQL2 - Winter 2017', '1/31/2017', '2/14/2017', '18:00','20:50', 'T', '399.00')
;
GO        

INSERT INTO Students (StudentNumber, StudentFirstName, StudentLastName, StudentEmail, StudentPhone, StudentAddress1, StudentAddress2, StudentCity, StudentStateCode, StudentZipCode)
VALUES
        ('B-Smith-071', 'Bob', 'Smith', 'Bsmith@HipMail.com', '206-111-2222', '123 Main St.', null, 'Seattle', 'WA', '98001'),
        ('S-Jones-003', 'Sue', 'Jones', 'SueJones@YaYou.com', '206-231-4321', '333 1st Ave.', null, 'Seattle', 'WA', '98001')
;
GO   

INSERT INTO Enrollments (StudentID, CourseID, EnrollmentDate, EnrollmentPrice)
VALUES
        (2, 1, '12/14/2016', 349.00),
        (2, 2, '12/14/2016', 349.00),
        (1, 1, '1/12/2017', 399.00),
        (1, 2, '1/12/2017', 399.00)
;
GO        

-- Add Stored Procedures (Review Module 04 and 08) --

--<Stored Procedures for the Courses table>--
--Insert Stored Procedure--
CREATE OR ALTER PROCEDURE pInsertCourses (
    @CourseName nvarchar(100),
    @CourseStartDate date,
    @CourseEndDate date,
    @CourseStartTime time,
    @CourseEndTime time,
    @CourseDaysOfWeek nvarchar(100),
    @CourseCurrentPrice money
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            INSERT INTO Courses (
                CourseName, 
                CourseStartDate, 
                CourseEndDate, 
                CourseStartTime, 
                CourseEndTime, 
                CourseDaysOfWeek, 
                CourseCurrentPrice
                )
            VALUES (
                @CourseName, 
                @CourseStartDate, 
                @CourseEndDate, 
                @CourseStartTime, 
                @CourseEndTime, 
                @CourseDaysOfWeek, 
                @CourseCurrentPrice
                )
        COMMIT TRANSACTION
        ;
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO        

--Update Stored Procedure--
CREATE OR ALTER PROCEDURE pUpdateCourses (
    @CourseID int,
    @CourseName nvarchar(100),
    @CourseStartDate date,
    @CourseEndDate date,
    @CourseStartTime time,
    @CourseEndTime time,
    @CourseDaysOfWeek nvarchar(100),
    @CourseCurrentPrice money
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            UPDATE Courses 
            SET CourseName = @CourseName,
                CourseStartDate = @CourseStartDate,
                CourseEndDate = @CourseEndDate,
                CourseStartTime = @CourseStartTime,
                CourseEndTime = @CourseEndTime,
                CourseDaysOfWeek = @CourseDaysOfWeek,
                CourseCurrentPrice = @CourseCurrentPrice
            WHERE CourseID = @CourseID    
        COMMIT TRANSACTION
        ;
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO 

--Delete Stored Procedure--
CREATE OR ALTER PROCEDURE pDeleteCourses (
    @CourseID int
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            DELETE FROM Enrollments 
            WHERE CourseID = @CourseID 
        COMMIT TRANSACTION
        ;
        BEGIN TRANSACTION
            DELETE FROM Courses
            WHERE CourseID = @CourseID
        COMMIT TRANSACTION
        ;    
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO

--<Stored Procedures for the Students table>--
--Insert Stored Procedure--
CREATE OR ALTER PROCEDURE pInsertStudents (
    @StudentNumber nvarchar(100),
    @StudentFirstName nvarchar(100),
    @StudentLastName nvarchar(100),
    @StudentEmail nvarchar(100),
    @StudentPhone nvarchar(12),
    @StudentAddress1 nvarchar(100),
    @StudentAddress2 nvarchar(100),
    @StudentCity nvarchar(100),
    @StudentStateCode nvarchar(2),
    @StudentZipCode nvarchar(10)  
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            INSERT INTO Students (
                StudentNumber, 
                StudentFirstName, 
                StudentLastName, 
                StudentEmail, 
                StudentPhone, 
                StudentAddress1, 
                StudentAddress2, 
                StudentCity, 
                StudentStateCode, 
                StudentZipCode
                )
            VALUES (
                @StudentNumber, 
                @StudentFirstName, 
                @StudentLastName, 
                @StudentEmail, 
                @StudentPhone, 
                @StudentAddress1, 
                @StudentAddress2, 
                @StudentCity, 
                @StudentStateCode, 
                @StudentZipCode
                )
        COMMIT TRANSACTION
        ;
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO   

--Update Stored Procedure--
CREATE OR ALTER PROCEDURE pUpdateStudents (
    @StudentID int,
    @StudentNumber nvarchar(100),
    @StudentFirstName nvarchar(100),
    @StudentLastName nvarchar(100),
    @StudentEmail nvarchar(100),
    @StudentPhone nvarchar(12),
    @StudentAddress1 nvarchar(100),
    @StudentAddress2 nvarchar(100),
    @StudentCity nvarchar(100),
    @StudentStateCode nvarchar(2),
    @StudentZipCode nvarchar(10)
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            UPDATE Students 
            SET StudentNumber = @StudentNumber,
                StudentFirstName = @StudentFirstName,
                StudentLastName = @StudentLastName,
                StudentEmail = @StudentEmail,
                StudentPhone = @StudentPhone,
                StudentAddress1 = @StudentAddress1,
                StudentAddress2 = @StudentAddress2,
                StudentCity = @StudentCity,
                StudentStateCode = @StudentStateCode,
                StudentZipCode = @StudentZipCode
            WHERE StudentID = @StudentID    
        COMMIT TRANSACTION
        ;
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO

--Delete Stored Procedure--
CREATE OR ALTER PROCEDURE pDeleteStudents (
    @StudentID int
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            DELETE FROM Enrollments 
            WHERE StudentID = @StudentID 
        COMMIT TRANSACTION
        ;
        BEGIN TRANSACTION
            DELETE FROM Students
            WHERE StudentID = @StudentID
        COMMIT TRANSACTION
        ;    
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO

--<Stored Procedures for the Enrollments table>--
--Insert Stored Procedure--
CREATE OR ALTER PROCEDURE pInsertEnrollments (
    @StudentID int,
    @CourseID int,
    @EnrollmentDate date,
    @EnrollmentPrice money
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            INSERT INTO Enrollments (
                StudentID,
                CourseID,
                EnrollmentDate,
                EnrollmentPrice
                )
            VALUES (
                @StudentID,
                @CourseID,
                @EnrollmentDate,
                @EnrollmentPrice
                )
        COMMIT TRANSACTION
        ;
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO

--Update Stored Procedure--
CREATE OR ALTER PROCEDURE pUpdateEnrollments (
    @EnrollmentID int,
    @StudentID int,
    @CourseID int,
    @EnrollmentDate date,
    @EnrollmentPrice money
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            UPDATE Enrollments
            SET StudentID = @StudentID,
                CourseID = @CourseID,
                EnrollmentDate = @EnrollmentDate,
                EnrollmentPrice = @EnrollmentPrice
            WHERE EnrollmentID = @EnrollmentID   
        COMMIT TRANSACTION
        ;
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO

--Delete Stored Procedure--
CREATE OR ALTER PROCEDURE pDeleteEnrollments (
    @EnrollmentID int
)
AS 
    BEGIN TRY
        BEGIN TRANSACTION
            DELETE FROM Enrollments 
            WHERE EnrollmentID = @EnrollmentID
        COMMIT TRANSACTION
        ; 
    END TRY  
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT ERROR_MESSAGE();
    END CATCH
GO

-- Set Permissions --

DENY SELECT ON Courses TO PUBLIC;
DENY SELECT ON Students TO PUBLIC;
DENY SELECT ON Enrollments TO PUBLIC;

GRANT SELECT ON vCourses TO PUBLIC;
GRANT SELECT ON vStudents TO PUBLIC;
GRANT SELECT ON vEnrollments TO PUBLIC;
GRANT SELECT ON vSpreadsheet TO PUBLIC;
GO

GRANT EXECUTE ON pUpdateCourses TO PUBLIC;
GRANT EXECUTE ON pUpdateStudents TO PUBLIC;
GRANT EXECUTE ON pUpdateEnrollments TO PUBLIC;
GRANT EXECUTE ON pInsertCourses TO PUBLIC;
GRANT EXECUTE ON pInsertStudents TO PUBLIC;
GRANT EXECUTE ON pInsertEnrollments TO PUBLIC;
GRANT EXECUTE ON pDeleteCourses TO PUBLIC;
GRANT EXECUTE ON pDeleteStudents TO PUBLIC;
GRANT EXECUTE ON pDeleteEnrollments TO PUBLIC;
GO

--< Test Sprocs >-- 

--EXECUTE dbo.pInsertCourses "SQL3", "1/25/2024", "3/1/2024", "6:00", "8:00", "W", "250";
--EXECUTE dbo.pUpdateCourses "3", "SQL3", "1/25/2024", "3/1/2024", "18:00", "20:00", "W", "250";
--EXECUTE dbo.pDeleteCourses 3;
--SELECT * FROM vCourses
--GO

--EXECUTE dbo.pInsertStudents "abcd","Ben", "Smith", "aaaa@bbb.com", "555-555-5555", "133 Pine St", null,"Seattle", "WA", "98103";
--EXECUTE dbo.pUpdateStudents "4", "abcd","Benjamin", "Smith", "aaaa@bbb.com", "555-555-5555", "133 Pine St", null,"Seattle", "WA", "98103";
--EXECUTE dbo.pDeleteStudents 4;
--SELECT * FROM vStudents;
--GO

--EXECUTE dbo.pInsertEnrollments "4", "2", "1/23/2024", "0";
--EXECUTE dbo.pUpdateEnrollments "4", "2", "1/23/2024", "250";
--EXECUTE dbo.pDeleteEnrollments 5;
--SELECT * FROM vEnrollments;
--GO


--{ IMPORTANT!!! }--
-- To get full credit, your script must run without having to highlight individual statements!!!  
/**************************************************************************************************/