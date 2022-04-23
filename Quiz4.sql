-- Create the SQL queries based on the following questions and ERD: 

-- 1. Write the SQL code to create a stored procedure to INSERT one row into SCHEDULE_TRIP. 
    -- a. Takes in 9 parameters of non-ID values 
    -- b. Uses variables to look-up required FK values 

-- CHANGE INTO one query
CREATE PROCEDURE new_schedule_trip
@DateTime date,
@DOB date,
@RouteName varchar (50),
@VehicleNum int,
@EmpFName varchar (50),
@EmpLName varchar (50),
@PositionName varchar (50),
@TripDate date,
@SchedDateTime date

AS

DECLARE @S_ID INT, @T_ID INT


SET @S_ID = (SELECT ScheduleID
             FROM SCHEDULE SH
                JOIN ROUTE R ON SH.RouteID = R.RouteID
                JOIN STOP S ON SH.StopID = S.StopID
             WHERE RouteName = @RouteName
             AND StopName = @StopName 
             AND ScheduleDateTime = @SchedDateTime
             )

SET @T_ID = (SELECT TripID
             FROM TRIP T
                JOIN EMPLOYEE_POISTION EP ON T.EmpPoisitionID = EP.EmpPoisitionID
                JOIN EMPLOYEE E ON EP.EmpID = E.EmpID
                JOIN VEHICLE V ON T.VehicleID = V.VehicleID
             WHERE VehicleSerialNum = @VehicleNum
             AND PositionName = @PositionName
             AND EmpFname = @EmpFName
             AND EmpLname = @EmpLName
             AND E.EmpDOB = @DOB
             AND TripDate = @TripDate)

BEGIN TRANSACTION H1
INSERT INTO SCHEDULE_TRIP (ScheduleID, TripID, ActualDateTime)
VALUES (@S_ID, @T_ID, @DateTime)
COMMIT TRANSACTION H1
GO

-- 2. Write the single query to determine which customers meet all the following conditions: 
    -- a. Boarded more than 44 trips on ‘Route 305’ from stops in the neighborhood of ‘U-
        -- District’ between March 17, 2016 and July 8, 2019 
    -- b. Spent more than $235 with a payment type ‘ORCA’ for trips on vehicles that had Jimi 
        -- Hendrix assigned as ‘Coach Operator’ during October 2019  
    -- c. Boarded fewer than 12 trips with destination ‘Northgate’ in the past 3 years.  

SELECT A.CustID, A.NumTrips, B.SumFares, C.NumNorthgateTrips
FROM 

(SELECT C.CustID, COUNT(TripID) AS NumTrips
FROM CUSTOMER C
    JOIN BOARDING B ON C.CustID = B.CustID
    JOIN SCHEDULE_TRIP ST ON B.ScheduleTripID = ST.ScheduleTripID
    JOIN TRIP T ON ST.TripID = T.TripID
    JOIN SCHEDULE S ON ST.ScheduleID = S.ScheduleID
    JOIN ROUTE R ON S.RouteID = R.RouteID
    JOIN STOP SP ON S.StopID = SP.StopID
    JOIN NEIGHBORHOOD N ON ST.NeighborhoodID = N.NeighborhoodID
WHERE R.RouteName = 'Route 305'
    AND N.NeighborhoodName = 'U-District'
    AND T.TripDate BETWEEN '03-17-2016' AND '07-08-2019'
GROUP BY C.CustID
HAVING COUNT(NumTrips) > 44) A,

(SELECT C.CustID, SUM(F.FareAmount) AS SumFares
FROM CUSTOMER C
    JOIN BOARDING B ON C.CustID = B.CustID
    JOIN FARE F ON B.FareID = F.FareID
    JOIN PAYMENT PA ON B.PaymentID = PA.PaymentID
    JOIN SCHEDULE_TRIP ST ON B.ScheduleTripID = ST.ScheduleTripID
    JOIN TRIP T ON ST.TripID = T.TripID
    JOIN EMPLOYEE_POSITION EP ON T.EmpPositionID = EP.EmpPositionID
    JOIN POSITION P ON EP.PositionID = P.PositionID
    JOIN EMPLOYEE E ON EP.EmpID = E.EmpID
WHERE PA.PaymentName = 'ORCA'
    AND P.PositionName = 'Coach Operator'
    AND E.EmpFname = 'Jimi'
    AND E.EmpLname = 'Hendrix'
    AND T.TripDate BETWEEN '01-10-2019' AND '31-10-2019'
GROUP BY C.CustID
HAVING SUM(F.FareAmount) >= 235) B,

(SELECT C.CustID, COUNT(TripID) AS NumNorthgateTrips
FROM CUSTOMER C
    JOIN BOARDING B ON C.CustID = B.CustID
    JOIN SCHEDULE_TRIP ST ON B.ScheduleTripID = ST.ScheduleTripID
    JOIN TRIP T ON ST.TripID = T.TripID
    JOIN SCHEDULE S ON ST.ScheduleID = S.ScheduleID
    JOIN ROUTE R ON S.RouteID = R.RouteID
    JOIN ROUTE_DESTINATION RD ON R.RouteID = RD.RouteID
    JOIN DESTINATION D ON RD.DestID = D.DestID
WHERE D.DestName = 'Northgate'
    AND T.TripDate > DATEADD(YEAR, -3, GETDATE())
GROUP BY C.CustID
HAVING COUNT(NumNorthgateTrips) < 12) C

WHERE A.CustID = B.CustID
    AND B.CustID = C.CustID
ORDER BY NumTrips DESC

-- 3. Write the SQL code to enforce the following business rule: 
    -- “No vehicle of type ‘articulated double-length’ older than than 12 years old may be assigned a 
        -- trip through the neighborhood of ‘Capitol Hill’ in the months of December, January, or 
        -- February” 

CREATE FUNCTION fn_no_Winter_Vehicles ()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
    IF EXISTS (SELECT *
               FROM TRIP T
                JOIN VEHICLE V ON T.VehicleID = V.VehicleID
                JOIN VEHICLETYPE VT ON V.VehicleTypeID = VT.VehicleID
                JOIN SCHEDULE_TRIP ST ON T.TripID = ST.TripID
                JOIN SCHEDULE S ON ST.ScheduleID = S.ScheduleID
                JOIN STOP SP ON S.StopID = SP.StopID
                JOIN NEIGHBORHOOD N ON ST.NeighborhoodID = N.NeighborhoodID
               WHERE VT.VehicleTypeName = 'articulated double-length'
               AND V.DatePurchased > DATEADD(YEAR, -12, GETDATE())
               AND N.NeighborhoodName = 'Capitol Hill'
               AND MONTH(T.TripDate) BETWEEN 12 AND 2
               )

    BEGIN
        SET @RET = 1
    END

RETURN @RET
END
GO

ALTER TABLE TRIP
ADD CONSTRAINT CK_no_Winter_Vehicles
CHECK (dbo.fn_no_Winter_Vehicles () = 0)
