-- questions for greg: 
-- go over computed columns, is #1 correct syntax
-- for #2, do we need to input toolDescr too bc that is a column in the tool table but not one of our parameters

-- Write the code to create a computed column to measure the total number of tasks each employee has completed in the past 4.5 years that involved any tool with condition of 'damaged'.
CREATE FUNCTION fn_NumTasks(@PK INT)
RETURNS INTEGER
AS
BEGIN
    DECLARE @RET INTEGER = (SELECT COUNT(JTTE.TaskID)
                            FROM tblJOB_TASK_TOOL_EQUIP JTTE
                                JOIN tblTOOL_CONDITION TC ON JTTE.ToolID = TC.ToolID
                                JOIN tblCONDITION C ON TC.ConditionID = C.ConditionID
                                JOIN tblEMPLOYEE_SKIL_LEVEL ESL ON JTTE.EmpSkillID = ESL.EmpSkillID
                                JOIN tblEMPLOYEE_POSITION EP ON ESL.EmpPositionID = EP.EmpPositionID
                                JOIN tblEMPLOYEE E ON EP.EmpID = E.EmpID
                            WHERE JTTE.EndDateTime > DATEADD(month, -4.5 * 12, GETDATE())
                            AND C.ConditionName = 'damaged'
                            AND E.EmpID = @PK
    )

RETURN @RET
END
GO

ALTER TABLE tblEMPLOYEE
ADD Calc_NumTasks_Damaged AS (dbo.fn_NumTasks(EmpID))

GO

-- Write the code to CREATE a stored procedure to insert a new row into TOOL_CONDITION of a tool NOT yet in the database (yes...two INSERT statements in a single transaction using scope_identity function! 
-- Assume IDENTITY function enabled on both TOOL and TOOL_CONDITION tables): 
-- Takes in four parameters: ToolName, ToolTypeName, ConditionName, and BeginDate 
-- Uses variables to look-up required FK values
-- Inserts a new row in a single explicit transaction
CREATE PROCEDURE egInsert_Tool
@ToolName varchar (50),
@ToolTypeName varchar(50), 
@ConditionName varchar(50), 
@BeginDate date,
@ToolDescr varchar (500)

AS
DECLARE @C_ID INT, @TT_ID INT, @T_ID INT


SET @C_ID = (SELECT ConditionID
                FROM tblCONDITION
                WHERE ConditionName = @ConditionName)

SET @TT_ID = (SELECT ToolTypeID
                FROM tblTool_Type
                WHERE ToolTypeName = @ToolTypeName)

BEGIN TRANSACTION H1
INSERT INTO tblTOOl (ToolName, ToolTypeID)
VALUES (@ToolName, @TT_ID)

SET @T_ID = (SELECT scope_identity())

INSERT INTO tblTOOL_CONDITION (ToolID, ConditionID, BeginDate, ToolDesc)
VALUES (@T_ID, @C_ID, @BeginDate, @ToolDescr)
COMMIT TRANSACTION H1

GO

EXEC egInsert_Tool
@ToolName = 'Wrench',
@ToolTypeName = 'Garden', 
@ConditionName = 'New', 
@BeginDate = '01-03-2022',
@ToolDescr = 'A tool!'

-- Write the code to determine which customers have placed more than 11 orders for any kind of product type of 'lighting' in the past 5 years 
-- who have also had a task of 'sliding-glass door replaced' in the past 4 years with employee ‘Mikki Bailey’ having participated.
SELECT C.CustID, COUNT(O.OrderID) AS NumOrders
FROM tblCUSTOMER C
    JOIN tblJOB J ON C.CustID = J.CustID
    JOIN tblJOB_TASK_TOOL_EQUIP JTTE ON J.JobID = JTTE.JobID
    JOIN tblTASK T ON JTTE.TaskID = T.TaskID
    JOIN tblORDER O ON J.JobID = O.JobID
    JOIN tblLINE_ITEM LI ON O.OrderID = LI.OrderID
    JOIN tblPRODUCT P ON LI.ProductID = P.ProductID
    JOIN tblPRODUCT_TYPE PT ON P.ProductTypeID = Pt.ProductTypeID
WHERE O.OrderDate > DATEADD(year, -5, GETDATE())
    AND PT.ProductTypeName = 'lighting'
    AND NumOrders >= 11

    AND C.CustID IN (
    SELECT C.CustID
    FROM tblCUSTOMER C
        JOIN tblJOB J ON C.CustID = J.CustID
        JOIN tblJOB_TASK_TOOL_EQUIP JTTE ON J.JobID = JTTE.JobID
        JOIN tblTASK T ON JTTE.TaskID = T.TaskID
        JOIN tblEMPLOYEE_SKIL_LEVEL ESL ON JTTE.EmpSkillID = ESL.EmpSkillID
        JOIN tblEMPLOYEE_POSITION EP ON ESL.EmpPositionID = EP.EmpPositionID
        JOIN tblEMPLOYEE E ON EP.EmpID = E.EmpID
    WHERE T.TaskName = 'sliding-glass door replaced'
    AND JTTE.EndDateTime > DATEADD(year, -4, GETDATE())
    AND E.EmpFname = 'Mikki'
    AND E.EmpLname = 'Bailey'
    )


-- Write the code to enforce the business rule that Employees between ages of 18 and 21 cannot participate in tasks with any equipment type ‘Nuclear’.
CREATE FUNCTION fn_NoKids_Nuclear ()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
        IF EXISTS (SELECT *
                    FROM tblEMPLOYEE E
                        JOIN tblEMPLOYEE_POSITION EP ON E.EmpID = EP.EmpID
                        JOIN tblEMPLOYEE_SKIL_LEVEL ESL ON EP.EmpPositionID = ESL.EmpPositionID
                        JOIN tblJOB_TASK_TOOL_EUIP JTTE ON ESL.EmpSkillID = JTTE.EmpSkillID
                        JOIN tblEQUIPMENT EQ ON JTTE.EquipID = EQ.EquipID
                        JOIN tblEQUIPMENT_TYPE ET ON EQ.EquipTypeID = ET.EquipTypeID
                    WHERE ET.EquipTypeName = 'Nuclear'
                    AND E.EmpBirthDate BETWEEN DateAdd(Year, -21, GetDate()) AND DateAdd(Year, -18, GetDate())                  
                    )
    BEGIN
        SET @RET = 1
    END

RETURN @RET
END

GO

ALTER TABLE tblTASK
ADD CONSTRAINT CK_NoKids_Nuclear
CHECK (dbo.fn_NoKids_Nuclear () = 0)


-- Write the code to enforce the business rule that only Senior-Level employees of skill type 'Heavy Machinery' can work on 
-- any job type 'high-rise commercial' with equipment type 'hydraulic lift' for any job beginning after November 13, 2020.
CREATE FUNCTION fn_Senior_Priviledges()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
        IF EXISTS (SELECT * 
                    FROM tblJOB_TASK_TOOL_EQUIP JTTE
                        JOIN tblEMPLOYEE_SKIL_LEVEL ESL ON JTTE.EmpSkillID = ESL.EmpSkillID
                        JOIN tblSKILL S ON ESL.SkillID = S.SkillID
                        JOIN tblSKILL_TYPE ST ON S.SkillTypeID = ST.SkillTypeID
                        JOIN tblEMPLOYEE_POSITION EP ON ESL.EmpPositionID = EP.EmpPositionID
                        JOIN tblEMPLOYEE E ON EP.EmpID = E.EmpID
                        JOIN tblPOSITION P ON EP.PositionID = P.PositionID
                        JOIN tblEQUIPMENT EQ ON JTTE.EquipID = EQ.EquipID
                        JOIN tblEQUIPMENT_TYPE ET ON EQ.EquipTypeID = ET.EquipTypeID
                        JOIN tblJOB J ON JTTE.JobID = J.JobID
                        JOIN tblJOB_TYPE JT ON J.JobTypeID = JT.JobTypeID
                    WHERE P.PositionName = 'senior'
                    AND ST.SkillTypeName = 'Heavy Machinery'
                    AND JT.JobTypeName = 'high-rise commercial'
                    AND ET.EquipTypeName = 'hydraulic lift'
                    AND J.JobBeginDate > 11-13-2020
                    )
    BEGIN
        SET @RET = 1
    END

RETURN @RET
END

GO

-- alter tbl job?
ALTER TABLE tblJOB_TASK_TOOL_EQUIP
ADD CONSTRAINT CK_Senior_Priviledges
CHECK (dbo.fn_Senior_Priviledges() = 0)

