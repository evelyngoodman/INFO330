-- CREATE DATABASE G3_COFFEE_SHOP
-- GO

-- populating tables:
-- 3-5 rows per table

-- tblPOSITION: created, populated DONE
-- tblSTAFF_POSITION: created, FKs connected, populated DONE
-- tblSTAFF: created, FKs connected, populated DONE
-- tblSHOP: created, populated DONE

USE G3_COFFEE_SHOP
GO
select * from tblSTAFF_POSITION
select * from tblSTAFF

ALTER TABLE tblSTAFF_POSITION
DROP CONSTRAINT FK_tblSTAFF_POSITION_StaffID

ALTER TABLE tblSTAFF_POSITION
ADD CONSTRAINT FK_tblSTAFF_POSITION_StaffID
FOREIGN KEY (StaffID)
REFERENCES tblSTAFF (StaffID)
GO

UPDATE tblSTAFF_POSITION
SET StaffID = (SELECT StaffID FROM tblSTAFF WHERE FName = 'Sarah')
WHERE BeginDate = '2015-11-23'
GO 
-- stored procedure #1 (populate transactional table)
CREATE PROCEDURE egNEW_EVENT
@EventDescr varchar (100),
@ProductName varchar (100),
@Quantity int,
@Date date,
@Time time
AS
 
DECLARE @P_ID INT
 
SET @P_ID = (SELECT ProductID
           FROM tblPRODUCT
           WHERE ProductName = @ProductName)
 
BEGIN TRANSACTION H1
INSERT INTO tblEVENT (EventDescr, Quantity, Date, TIME, ProductID)
VALUES (@EventDescr, @Quantity, @Date, @Time, @P_ID)
COMMIT TRANSACTION H1
 
GO
-- stored procedure #2 (insert new line item) CHANGE
CREATE PROCEDURE egUPDATE_EVENT
@EventDescr varchar (100),
@ProductName varchar (100),
@Quantity int,
@Date date,
@Time time
AS

DECLARE @P_ID INT

SET @P_ID = (SELECT ProductID
            FROM tblPRODUCT
            WHERE ProductName = @ProductName)

BEGIN TRANSACTION G1
UPDATE tblEVENT
SET EventDescr = @EventDescr, Quantity = @Quantity, Date = @Date, Time = @Time)
WHERE ProductID = @P_ID
COMMIT TRANSACTION G1
GO

-- Business rule #1
-- staff in position 'manager' who began after 2018 cannot work at shop 3rd & madison
CREATE FUNCTION fn_2018_Staff_Only ()
RETURNS INTEGER
AS
BEGIN
 
DECLARE @RET INT = 0
   IF EXISTS (SELECT *
               FROM tblSTAFF S
                   JOIN tblSTAFF_POSITION SP ON S.StaffID = SP.StaffID
                   JOIN tblPOSITION P ON SP.PositionID = P.PositionID
                   JOIN tblSHOP SH ON SP.ShopID = SH.ShopID
               WHERE P.PositionName = 'manager'
               AND YEAR(SP.BeginDate) = 2018
               AND SH.ShopName = '3rd & Madison'
                   )
 
BEGIN
   SET @RET = 1
END
 
RETURN @RET
END
GO
 
ALTER TABLE tblSTAFF_POSITION
ADD CONSTRAINT CK_2018_Staff_Only
CHECK(dbo.fn_2018_Staff_Only () = 0)
 
GO
-- Business rule #2
-- orders over 100 before year 2023 cannot receive rewards member discount
CREATE FUNCTION fn_No_Expensive_Discounts ()
RETURNS INTEGER
AS
BEGIN
 
DECLARE @RET INT = 0
   IF EXISTS (SELECT *
               FROM tblORDER O
                   JOIN tblDISCOUNT D ON O.DiscountID = D.DiscountID
               WHERE D.DiscountType = 'Rewards Member'
               AND YEAR(O.OrderDate) >= 2023
               AND O.Subtotal >= 100
                   )
 
BEGIN
   SET @RET = 1
END
 
RETURN @RET
END
GO
 
ALTER TABLE tblORDER
ADD CONSTRAINT CK_No_Expensive_Discounts
CHECK(dbo.fn_No_Expensive_Discounts () = 0)
 
GO

-- Computed column #1
-- subtotal
-- can multiply columns together
-- line total = price * quantity
-- subtotal = SUM(line total = price * quantity)
-- where order id = order id = calc order total
-- order total = total - (100 *discount) + tip
GO 
select * from tblORDER
select * from tblPRODUCT

ALTER FUNCTION fn_lineTotal(@PK INT)
RETURNS DECIMAL(7, 2)
AS
BEGIN

DECLARE @RET DECIMAL(7, 2) = (SELECT LI.Quantity * P.ProductPrice
                    FROM tblLINE_ITEM LI
                     JOIN tblPRODUCT P ON LI.ProductID = P.ProductID
                    WHERE LI.LineItemID = @PK)

RETURN @RET
END
GO

ALTER TABLE tblLINE_ITEM 
ADD LineTotal AS (dbo.fn_lineTotal(LineItemID))

GO

-- Computed column #2
-- Subtotal
CREATE FUNCTION fn_subtotal(@PK INT)
RETURNS DECIMAL(7, 2) 
AS
BEGIN

DECLARE @RET DECIMAL(7, 2) = (SELECT SUM(LI.LineTotal)
                    FROM tblORDER O
                     JOIN tblLINE_ITEM LI ON O.OrderID = LI.OrderID
                    WHERE O.OrderID = @PK)

RETURN @RET
END
GO

ALTER TABLE tblORDER
ADD Calc_total AS (dbo.fn_subtotal(OrderID))

GO

-- Computed column #3
-- Total
CREATE FUNCTION fn_total(@PK INT)
RETURNS DECIMAL(7, 2)
AS
BEGIN

DECLARE @RET DECIMAL(7, 2) = (SELECT ((O.Calc_total * Amount) / 100) + O.Tip
                    FROM tblORDER O
                    JOIN tblDISCOUNT D ON O.DiscountID = D.DiscountID
                    WHERE O.OrderID = @PK)

RETURN @RET
END
GO

ALTER TABLE tblORDER
ADD Abs_Total AS (dbo.fn_total(OrderID))

GO
select * from tblDISCOUNT
-- Two (2) views generating a 'complex' query (includes multiple JOINs, GROUP BY/HAVING statements, TOP, and aggregate function)

-- Write the query to determine the customer who has spent more than 100$ on orders for the shop on 3rd ave after 2010 
-- who has also ordered more than 2 of product type 'coffee' 

SELECT A.CustomerID, A.Fname, A.Lname, B.NumCoffeeProducts, A.OrderTotal
FROM
 
(SELECT C.CustomerID, C.Fname, C.Lname, SUM(O.Total) AS OrderTotal
FROM tblCUSTOMER C
   JOIN tblORDER O ON C.CustomerID = O.CustomerID
   JOIN tblSHOP S ON O.ShopID = S.ShopID
WHERE S.SHopName = '3rd & Madison'
   AND year(O.OrderDate) > 2010
GROUP BY C.CustomerID, C.Fname, C.Lname
HAVING SUM(O.Total) >= 100) A,
 
(SELECT C.CustomerID, C.Fname, C.Lname, SUM(LI.Quantity) AS NumCoffeeProducts
FROM tblCUSTOMER C
   JOIN tblORDER O ON C.CustomerID = O.CustomerID
   JOIN tblLINE_ITEM LI ON O.OrderID = LI.OrderID
   JOIN tblPRODUCT P ON LI.ProductID = P.ProductID
   JOIN tblPRODUCT_TYPE PT ON P.ProductTypeID = PT.ProductTypeID
WHERE PT.ProductTypeName LIKE 'coffee'
GROUP BY C.CustomerID, C.Fname, C.Lname
HAVING SUM(LI.Quantity) >= 2) B
 
WHERE A.CustomerID = B.CustomerID
ORDER BY OrderTotal DESC

-- Write the query to determine the TOP 3 shop locations (and their COUNT) that have the highest count
-- of employees with 5 letter or higher names.
SELECT TOP 3 WITH TIES SH.SHopID, SH.ShopName, COUNT(DISTINCT ST.StaffID) AS CountStaff
FROM tblSHOP SH
   JOIN tblSTAFF_POSITION SP ON SH.ShopID = SP.ShopID
   JOIN tblSTAFF ST ON SP.StaffID = ST.StaffID
WHERE LEN (ST.FName) >= 5
GROUP BY SH.ShopID, SH.ShopName
ORDER BY CountStaff DESC
