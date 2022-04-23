-- Write the SQL query to determine which students were born after November 5, 1996.
SELECT *
FROM tblSTUDENT
WHERE StudentBirth > 'Nov 5, 1996'

-- Write the SQL query to determine which buildings are on West Campus.
SELECT BuildingName, LocationName
FROM tblBUILDING B
    JOIN tblLOCATION L ON B.LocationID = L.LocationID
WHERE LocationName = 'West Campus'

-- Write the SQL query to determine how many libraries are at UW.
SELECT BuildingTypeName, COUNT(B.BuildingID) AS NumLocations
FROM tblBUILDING_TYPE BT
    JOIN tblBUILDING B ON BT.BuildingTypeID = B.BuildingTypeID
WHERE BuildingTypeName = 'Library'
GROUP BY BT.BuildingTypeName

-- Write the code to return the 10 youngest students enrolled a course from Information School during winter quarter 2009.
SELECT TOP 10 WITH TIES StudentFname, StudentLname, CR.CourseName, Q.QuarterName, CS.Year
FROM tblSTUDENT S
    JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
    JOIN tblCLASS CS ON CL.ClassID = CS.ClassID
    JOIN tblCOURSE CR ON CS.CourseID = CR.CourseID
    JOIN tblDEPARTMENT D ON CR.DeptID = D.DeptID
    JOIN tblCOLLEGE C ON D.CollegeID = C.CollegeID
    JOIN tblQUARTER Q ON CS.QuarterID = Q.QuarterID
WHERE C.CollegeName = 'Information School'
    AND CS.Year = '2009'
    AND QuarterName = 'Winter'
ORDER BY StudentBirth DESC

-- Write the code that exhibits the 5 oldest buildings on UW campus by the year that they were opened.
SELECT TOP 5 WITH TIES YearOpened, BuildingName
FROM tblBUILDING
ORDER BY YearOpened ASC

-- Write the code to determine the 5 most-common states listed as permanent addresses for students who registered for at least one course in the 1930's.
SELECT TOP 5 S.StudentPermState, COUNT(S.StudentID) AS NumStudents
FROM tblStudent S
    JOIN tblCLASS_LIST CL ON S.StudentID = CL.StudentID
    JOIN tblCLASS CS ON CL.ClassID = CS.ClassID
    JOIN tblCOURSE CR ON CS.CourseID = CR.CourseID
WHERE (CS.[YEAR] >= 1930 AND CS.[YEAR] < 1940)
GROUP BY S.StudentPermState
HAVING COUNT(CR.CourseID) >= 1
ORDER BY NumStudents DESC

-- Write the SQL query to list the Department that hired the most people to the position type 'Executive' between June 8, 1968 and March 6, 1989.
SELECT TOP 1 WITH TIES (DeptName), COUNT(P.PositionID) AS NumPosition
FROM tblDEPARTMENT D
    JOIN tblSTAFF_POSITION SP ON D.DeptID = SP.DeptID
    JOIN tblPOSITION P ON SP.PositionID = P.PositionID
    JOIN tblPOSITION_TYPE PT ON P.PositionTypeID = PT.PositionTypeID
WHERE (SP.BeginDate >= '1968-06-08' AND SP.BeginDate <= '1989-03-06')
    AND PT.PositionTypeName = 'Executive'
GROUP BY D.DeptName
ORDER BY NumPosition DESC

-- Write the SQL query to determine which current instructor has been a Senior Lecturer the longest. 
SELECT TOP 1 I.InstructorFName, I.InstructorLName, DATEDIFF(Day, IIt.BeginDate, GETDATE()) AS WorkDuration
FROM tblINSTRUCTOR I
    JOIN tblINSTRUCTOR_INSTRUCTOR_TYPE IIT ON I.InstructorID = IIT.InstructorID
    JOIN tblINSTRUCTOR_TYPE IT ON IIT.InstructorTypeID = IT.InstructorTypeID
WHERE IT.InstructorTypeName = 'Senior Lecturer'
    AND(IIT.EndDate is null OR IIT.EndDate >= GETDATE())
    AND IIT.BeginDate < GETDATE()
ORDER BY WorkDuration DESC

-- Write the SQL query to determine which College offer the most courses Spring quarter 2014.
SELECT TOP 1 WITH TIES C.CollegeName, COUNT(CL.CourseID) AS NumCourse
FROM tblCOLLEGE C
    JOIN tblDEPARTMENT D ON C.CollegeID = D.CollegeID
    JOIN tblCOURSE CS ON D.DeptID = CS.DeptID
    JOIN tblCLASS CL ON CS.CourseID = CL.CourseID
    JOIN tblQUARTER Q ON CL.QuarterID = Q.QuarterID
WHERE (CL.[YEAR] = 2014)
    AND QuarterName = 'Spring'
GROUP BY C.CollegeName
HAVING COUNT(CL.CourseID) >= 1
ORDER BY NumCourse DESC

-- Write the SQL query to determine which courses were held in large lecture halls or auditorium type classrooms summer 2016. 
-- 632
SELECT CourseName, ClassroomTypeName
FROM tblCOURSE C
    JOIN tblCLASS CL ON C.CourseID = CL.CourseID
    JOIN tblQUARTER Q ON CL.QuarterID=Q.QuarterID
    JOIN tblCLASSROOM CR ON CL.ClassroomID = CR.ClassroomID
    JOIN tblCLASSROOM_TYPE CT ON CR.ClassroomTypeID = CT.ClassroomTypeID
WHERE CL.[YEAR] = '2016'
    AND Q.QuarterName = 'Summer'
    AND CT.ClassroomTypeName = 'Large lecture hall' OR CT.ClassroomTypeName = 'Auditorium'