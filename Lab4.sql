-- 1. Write the SQL to determine which customers have booked more than 5 flights between March 3, 2015 and November 12, 2018 
-- arriving in airports in the region of South America who have also booked fewer than 10 total flights on planes 
-- from Boeing Airplane manufacturer before January 15, 2019.
 
SELECT A.CustomerID, A.NumSAFLights, B.NumBoeingFLights
FROM
 
(SELECT C.CustomerID, COUNT(F.FlightID) AS NumSAFLights
FROM CUSTOMER C
    JOIN BOOKING B ON C.CustomerID = B.BookingID
    JOIN ROUTE_FLIGHT RF ON B.RouteFlightID = RF.RouteFlightID
    JOIN FLIGHT F ON RF.FlightID = F.FlightID
    JOIN AIRPORT A ON F.ArrivalAirportID = A.AirportID
    JOIN CITY C ON A.CityID = C.CityID
    JOIN COUNTRY CO ON C.CountryID = CO.CountryID
    JOIN REGION R ON CO.RegionID = R.RegionID
WHERE B.BookDateTime BETWEEN '03-03-2015' AND '11-12-2018'
AND R.RegionName = 'South America'
GROUP BY C.CustomerID
HAVING COUNT(F.FlightID) > 5) A,
 
(SELECT C.CustomerID, COUNT(F.FlightID) AS NumBoeingFLights
FROM CUSTOMER C
    JOIN BOOKING B ON C.CustomerID = B.BookingID
    JOIN SEAT_PLANE SP ON B.SeatPlaneClassID = Sp.SeatPlaneClassID
    JOIN PLANE P ON Sp.PlaneID = P.PlaneID
    JOIN MANUFACTURER M ON P.MfgID = M.MfgID
WHERE B.BookDateTime < '01-15-2019'
AND M.MfgName = 'Boeing Airplane'
GROUP BY C.CustomerID
HAVING COUNT(F.FlightID) < 10) B

 
WHERE A.CustomerID = B.CustomerID
ORDER BY A.CustomerID DESC

-- 2. Write the SQL to determine which employees served in the role of ‘captain’ on greater than 11 flights 
-- departing from airport type of ‘military’ from the region of North America who 
-- also served in the role of ‘Chief Navigator’ no more than 5 flights arriving to airports in Japan.
SELECT A.EmployeeID, A.NumCaptainFlights, B.NumChiefFlights
FROM

(SELECT E.EmployeeID, COUNT(F.FlightID) AS NumCaptainFlights
FROM EMPLOYEE E
    JOIN FLIGHT_EMPLOYEE FE ON E.EmployeeID = FE.EmployeeID
    JOIN ROLE R On FE.RoleID = R.RoleID
    JOIN FLIGHT F ON FE.FLightID = F.FlightID
    JOIN AIRPORT A ON F.ArrivalAirportID = A.AirportID
    JOIN AIRPORT_TYPE AT ON A.AirportTypeID = AT.AirportTypeID
    JOIN CITY C ON A.CityID = C.CityID
    JOIN COUNTRY CO ON C.CountryID = CO.CountryID
    JOIN REGION R ON CO.RegionID = R.RegionID
WHERE R.RoleName = 'captain'
AND AT.AirportTypeName = 'military'
AND R.RegionName = 'North America'
GROUP BY E.EmployeeID
HAVING COUNT(F.FlightID) > 11) A,
 
(SELECT E.EmployeeID, COUNT(F.FlightID) AS NumChiefFlights
FROM EMPLOYEE E 
    JOIN FLIGHT_EMPLOYEE FE ON E.EmployeeID = FE.EmployeeID
    JOIN ROLE R On FE.RoleID = R.RoleID
    JOIN FLIGHT F ON FE.FLightID = F.FlightID
    JOIN AIRPORT A ON F.ArrivalAirportID = A.AirportID
    JOIN AIRPORT_TYPE AT ON A.AirportTypeID = AT.AirportTypeID
    JOIN CITY C ON A.CityID = C.CityID
    JOIN COUNTRY CO ON C.CountryID = CO.CountryID
WHERE R.RoleName = 'Chief Navigator'
AND CO.CountryName = 'Japan'
GROUP BY E.EmployeeID
HAVING COUNT(F.FlightID) <= 5 ) B 

WHERE A.EmployeeID = B.EmployeeID
ORDER BY NumCaptainFlights DESC

-- 3. Write the SQL to create a stored procedure to UPDATE the EMPLOYEE table with new values for City, State and Zip. 
-- Use the following parameters:
-- @Fname, @Lname, @Birthdate, @NewCity, @NewState, @NewZip
CREATE PROCEDURE egUPDATE_EMPLOYEE
@Fname varchar(60),
@Lname varchar(60),
@DOB date,
@City varchar(60),
@State varchar(60),
@Zip int
AS

DECLARE @E_ID INT

SET @E_ID = (SELECT EmployeeID 
            FROM EMPLOYEE 
            WHERE EmployeeFname = @Fname, 
            AND EmployeeLname= @Lname 
            AND EMployeeDOB = @DOB)

BEGIN TRANSACTION G1
UPDATE tblEMPLOYEE
SET City = @City, State = @State, Zip = @Zip)
WHERE EmployeeID = @E_ID
COMMIT TRANSACTION G1
GO

-- 4. Write the SQL to create enforce the following business rule:
-- “No employee younger than 28 years old may serve the role of ‘Principal Engineer’ 
-- for routes named ‘Around the world over the Arctic’ scheduled to depart in the month of December”  
CREATE FUNCTION fn_no_young_principals ()
RETURNS INTEGER
AS
BEGIN
 
DECLARE @RET INT = 0
   IF EXISTS (SELECT *
              FROM EMPLOYEE E 
                  JOIN FLIGHT_EMPLOYEE FE ON E.EmployeeID = FE.EmployeeID
                  JOIN ROLE R On FE.RoleID = R.RoleID
                  JOIN FLIGHT F ON FE.FLightID = F.FlightID
                  JOIN ROUTE_FLIGHT RF ON F.FlightID = RF.FlightID 
                  JOIN ROUTE RO ON RF.RouteID = R.RouteID
              WHERE E.EmployeeDOB > DATEADD(YEAR, -28, GETDATE())
              AND R.RoleName = 'Principal Engineer'
              AND RO.RouteName = 'Around the world over the Arctic'
              AND MONTH(F.ScheduleDepart) = 12
   )
 
BEGIN
   SET @RET = 1
END
 
RETURN @RET
END
GO
 
ALTER TABLE FLIGHT_EMPLOYEE 
ADD CONSTRAINT CK_No_Young_Principals
CHECK(dbo.fn_no_young_principals () = 0)
 
GO

-- 5. Write the SQL to create enforce the following business rule:
-- “No more than 12,500 pounds of baggage may be booked on planes of type ‘Puddle Jumper’” 
CREATE FUNCTION fn_no_heavy_puddle ()
RETURNS INTEGER
AS
BEGIN
 
DECLARE @RET INT = 0
   IF EXISTS (SELECT *
              FROM BOOKING B 
                JOIN BAG BA ON B.BookingID = BA.BookingID 
                JOIN SEAT_PLANE SP ON B.SeatPlaneClassID = Sp.SeatPlaneClassID
                JOIN PLANE P ON Sp.PlaneID = P.PlaneID
                JOIN PLANE_TYPE ON P.PlaneTypeID = PT.PlaneTypeID
              WHERE BA.Weight <= 12500
              AND PT.PlaneTypeName = 'Puddle Jumper'
    )
 
BEGIN
   SET @RET = 1
END
 
RETURN @RET
END
GO
 
ALTER TABLE BAG
ADD CONSTRAINT CK_No_Heavy_PuddleJumpers
CHECK(dbo.fn_no_heavy_puddle () = 0)
 
GO