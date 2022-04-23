-- Write the query to determine the students who have spent more than $3,000 in RegistrationFees for Information School classes after 2010 who also have completed at least 12 credits of Public Health courses before 2016. 
SELECT A.StudentID, A.StudentFname, A.StudentLname, NumCredits, Reg_fees
FROM

(SELECT S.StudentID, S.StudentFname, S.StudentLname, SUM(CL.RegistrationFee) AS Reg_fees
FROM tblSTUDENT S
    JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
    -- CL has registration fees
    JOIN tblCLASS C ON CL.ClassID = C.ClassID
    -- C has year
    JOIN tblCOURSE CR On C.CourseID = CR.CourseID
    -- CR has course ID
    JOIN tblDEPARTMENT D ON CR.DeptID = D.DeptID
    -- has department (public health)
    JOIN tblCOLLEGE CO ON D.CollegeID = CO.CollegeID
    -- has colleges (info school)
WHERE CO.CollegeName LIKE 'Information School%'
    AND C.YEAR > 2010 
GROUP BY S.StudentID, S.StudentFname, S.StudentLname
HAVING SUM(CL.RegistrationFee) >= 3000) A,

(SELECT S.StudentID, S.StudentFname, S.StudentLname, SUM(CR.Credits) AS NumCredits
FROM tblSTUDENT S
    JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
    -- CL has registration fees
    JOIN tblCLASS C ON CL.ClassID = C.ClassID
    -- C has year
    JOIN tblCOURSE CR On C.CourseID = CR.CourseID
    -- CR has course ID
    JOIN tblDEPARTMENT D ON CR.DeptID = D.DeptID
    -- has department (public health)
    JOIN tblCOLLEGE CO ON D.CollegeID = Co.CollegeID
    -- has colleges (info school)
WHERE CO.CollegeName LIKE 'Public Health%'
    AND C.YEAR < 2016
GROUP BY S.StudentID, S.StudentFname, S.StudentLname
HAVING SUM(CR.Credits) >= 12) B

WHERE A.StudentID = B.StudentID
ORDER BY Reg_fees DESC


-- Write the query to list the Top 3 departments in Arts and Sciences ordered by most students completing a class with a grade of less than 3.4 between 2004 and 2013. HINT: look for the number of DISTINCT individuals who meet the condition NOT the number of classes. :-)
SELECT TOP 3 WITH TIES D.DeptName, COUNT(DISTINCT S.StudentID) AS NumStudents
FROM tblDEPARTMENT D
    JOIN tblCOURSE CR ON D.DeptID = CR.DeptID
    JOIN tblCLASS C ON CR.CourseID = C.CourseID
    JOIN tblCLASS_LIST CL ON C.ClassID = CL.ClassID
    JOIN tblSTUDENT S ON CL.StudentID = S.StudentID
    JOIN tblCOLLEGE CO ON D.CollegeID = CO.CollegeID
WHERE CO.CollegeName LIKE 'Arts and Sciences%'
    AND C.[YEAR] BETWEEN '2004' AND '2013'
    AND CL.Grade < 3.4
GROUP BY D.Deptname
ORDER BY NumStudents DESC

-- Write the query to determine the newest building on South campus that has had a Geography class instructed by Greg Hay before winter 2015. 
SELECT TOP 1 WITH TIES B.BuildingName 
FROM tblBUILDING B
    JOIN tblLOCATION L ON B.LocationID = L.LocationID
    JOIN tblCLASSROOM CR ON B.BuildingID = CR.BuildingID
    JOIN tblCLASS C ON CR.ClassroomID = C.ClassroomID
    JOIN tblCOURSE CS ON C.CourseID = CS.CourseID
    JOIN tblDEPARTMENT D ON CS.DeptID = D.DeptID
    JOIN tblINSTRUCTOR_CLASS IC ON C.ClassID = IC.ClassID
    JOIN tblINSTRUCTOR I ON IC.InstructorID = I.InstructorID
WHERE L.LocationName LIKE 'South campus%'
    AND D.DeptName LIKE 'Geography%'
    AND C.[YEAR] < '2015'
    AND I.InstructorFName = 'Greg' 
    AND I.InstructorLName = 'Hay'
ORDER BY B.YearOpened DESC

-- Write the query to determine the staff person currently-employed who has been in their position the longest for each college.
-- how do i find who has been employed the longest? does it need to be someone who is still employed
SELECT C.CollegeID, C.CollegeName, S.StaffID, S.StaffFName, S.StaffLName, MAX(DATEDIFF(DAY, SP.BeginDate, GETDATE())) AS DayEmployed
FROM tblCOLLEGE C
	JOIN tblDEPARTMENT D ON C.CollegeID = D.CollegeID
	JOIN tblSTAFF_POSITION SP ON D.DeptID = SP.DeptID
	JOIN tblSTAFF S ON SP.StaffID = S.StaffID
	JOIN (SELECT C.CollegeID, MAX(DATEDIFF(DAY, SP.BeginDate, GETDATE())) AS DayEmployed
		FROM tblCOLLEGE C
			JOIN tblDEPARTMENT D ON C.CollegeID = D.CollegeID
			JOIN tblSTAFF_POSITION SP ON D.DeptID = SP.DeptID
			JOIN tblSTAFF S ON SP.StaffID = S.StaffID
		WHERE SP.EndDate IS NULL
		GROUP BY C.CollegeID) AS SubQ1 ON C.CollegeID = SubQ1.CollegeID 
			AND (DATEDIFF(DAY, SP.BeginDate, GETDATE())) = SubQ1.DayEmployed
WHERE SP.EndDate IS NULL
GROUP BY C.CollegeID, C.CollegeName, S.StaffID, S.StaffFName, S.StaffLName
ORDER BY C.CollegeID

-- Write the query to determine the TOP 3 classroom types (and their COUNT) that have been most-frequently assigned for 300-level Anthropology courses since 1983.
SELECT TOP 3 WITH TIES CT.ClassroomTypeName, COUNT(CT.ClassroomTypeID) AS CountType
FROM tblCLASSROOM_TYPE CT
    JOIN tblCLASSROOM CR ON CT.ClassroomTypeID = CR.ClassroomTypeID
    JOIN tblCLASS C ON CR.ClassroomID = C.ClassroomID
    JOIN tblCOURSE CS ON C.CourseID = CS.CourseID
    JOIN tblDEPARTMENT D ON CS.DeptID = D.DeptID 
WHERE D.DeptName LIKE 'Anthropology%'
    AND C.[YEAR] > 1983
    AND CS.CourseNumber LIKE '3%'
GROUP BY CT.ClassroomTypeName
ORDER BY CountType DESC

-- Write the code to create a stored procedure to hire an existing person to an existing staff position. 
USE [UNIVERSITY]
GO
--
CREATE PROCEDURE HIRE_STAFF
-- dont input PK
@FirstN varchar(60),
@LastN varchar(60),
@BirthDate date,
@PosName varchar (60),
@BeginDate date,
@EndDate date,
@DeptName varchar (60)
AS

DECLARE @S_ID INT, @D_ID INT, @P_ID INT

SET @S_ID = (SELECT StaffID 
    FROM tblSTAFF
    WHERE StaffFName = @FirstN
    AND StaffLName = @LastN
    AND StaffBirth = @BirthDate
)

SET @D_ID = (SELECT DeptID 
    FROM tblDEPARTMENT
    WHERE DeptName = @DeptName
)

SET @P_ID = (SELECT PositionID 
    FROM tblPOSITION
    WHERE PositionName = @PosName
)

BEGIN TRANSACTION H1    
INSERT INTO tblSTAFF_POSITION (StaffID, DeptID, PositionID, BeginDate, EndDate)
VALUES (@S_ID, @D_ID, @P_ID, @BeginDate, @EndDate)

COMMIT TRANSACTION H1
--
GO

EXEC HIRE_STAFF
@FirstN = 'Alvaro',
@LastN = 'Peeling',
@BirthDate = '1954-06-27',
@PosName = 'Administrative-Assistant',
@BeginDate = '02-23-2022',
@EndDate = NULL,
@DeptName = 'Classics'


-- Write the code to create a stored procedure to create a new class of an existing course.
USE [UNIVERSITY]
GO
--
CREATE PROCEDURE NEW_CLASS_EG
-- dont input PK
@CourseN varchar(60),
@DeptName varchar(60),
@QuarterName varchar(60),
@ScheduleName varchar(60),
@ClassroomName varchar(60),
@Credits int,
@CourseNum int,
@Section varchar (50)
AS

DECLARE @CS_ID INT, @Q_ID INT, @SCH_ID INT, @CR_ID INT, @C_ID INT

SET @CS_ID = (SELECT CourseID 
    FROM tblCOURSE
    WHERE CourseName = @CourseN
    AND Credits = @Credits
    AND CourseNumber = @CourseNum
)

SET @Q_ID = (SELECT QuarterID 
    FROM tblQuarter
    WHERE QuarterName = @QuarterName
)
SET @SCH_ID = (SELECT ScheduleID 
    FROM tblSCHEDULE
    WHERE ScheduleName = @ScheduleName
)

SET @CR_ID = (SELECT ClassroomID 
    FROM tblCLASSROOM
    WHERE ClassroomName = @ClassroomName
)

SET @C_ID = (SELECT ClassID 
    FROM tblCLASS
    WHERE CourseID = @CS_ID
    AND QuarterID = @Q_ID
    AND ClassroomID = @CR_ID
    AND ScheduleID = @SCH_ID
)


BEGIN TRANSACTION H1    
INSERT INTO tblCLASS(ClassID, CourseID, QuarterID, ClassroomID, ScheduleID, Section)
VALUES (@C_ID, @CS_ID, @Q_ID, @CR_ID, @SCH_ID, @Section)

COMMIT TRANSACTION H1
--
GO

EXEC NEW_CLASS_EG
@CourseN = 'ECON278',
@DeptName = 'Economics',
@QuarterName = 'Spring',
@ScheduleName = 'TueThur4',
@ClassroomName = 'GWN688',
@Credits = '4.0',
@CourseNum = '278',
@Section = 'A'

-- Write the code to create a stored procedure to register an existing student to an existing class.
USE [UNIVERSITY]
GO
--
CREATE PROCEDURE REGISTER_STUDENT_eg
-- dont input PK
@FirstN varchar(60),
@LastN varchar(60),
@BirthDate date,
@CourseName varchar (60),
@CourseNumber int,
@Year date,
@RegDate date,
@Grade int,
@RegFee int
AS

DECLARE @S_ID INT, @CS_ID INT, @C_ID INT

SET @S_ID = (SELECT StudentID 
    FROM tblSTUDENT
    WHERE StudentFName = @FirstN
    AND StudentLName = @LastN
    AND StudentBirth = @BirthDate
)

SET @CS_ID = (SELECT CourseID 
    FROM tblCOURSE
    WHERE CourseName = @CourseName
    AND CourseNumber = @CourseNumber
)

SET @C_ID = (SELECT ClassID 
    FROM tblCLASS
    WHERE CourseID = @CS_ID
    AND YEAR = @Year
)

BEGIN TRANSACTION H1    
INSERT INTO tblCLASS_LIST (ClassID, StudentID, Grade, RegistrationDate, RegistrationFee)
VALUES (@C_ID, @S_ID, @Grade, @RegDate, @RegFee)

COMMIT TRANSACTION H1
--
GO

EXEC REGISTER_STUDENT_eg
@FirstN = 'Claudie',
@LastN = 'Brandolino',
@BirthDate = '1880-12-19',
@CourseName = 'CSE171',
@CourseNumber = '171',
@Year = '2016',
@RegDate = '2016-02-28',
@Grade = '3.49',
@RegFee = '2262.72'