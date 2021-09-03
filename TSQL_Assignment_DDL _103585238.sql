-- TEST EACH PROCEDURE TO SEE IF THEY WORK. 
-- AS EACH PROCEDURE CHECKS OUT / RUN WHOLE LINE OF SQL CODE TO SEE IF ITS SUCCESSFUL.
-- IF SUCCESSFUL - READY FOR DEMO WITH KAREN.

USE SEM2DB;

IF OBJECT_ID('Sale') IS NOT NULL
DROP TABLE SALE;

IF OBJECT_ID('Product') IS NOT NULL
DROP TABLE PRODUCT;

IF OBJECT_ID('Customer') IS NOT NULL
DROP TABLE CUSTOMER;

IF OBJECT_ID('Location') IS NOT NULL
DROP TABLE LOCATION;

GO

CREATE TABLE CUSTOMER (
CUSTID	INT
, CUSTNAME	NVARCHAR(100)
, SALES_YTD	MONEY
, STATUS	NVARCHAR(7)
, PRIMARY KEY	(CUSTID) 
);


CREATE TABLE PRODUCT (
PRODID	INT
, PRODNAME	NVARCHAR(100)
, SELLING_PRICE	MONEY
, SALES_YTD	MONEY
, PRIMARY KEY	(PRODID)
);

CREATE TABLE SALE (
SALEID	BIGINT
, CUSTID	INT
, PRODID	INT
, QTY	INT
, PRICE	MONEY
, SALEDATE	DATE
, PRIMARY KEY 	(SALEID)
, FOREIGN KEY 	(CUSTID) REFERENCES CUSTOMER
, FOREIGN KEY 	(PRODID) REFERENCES PRODUCT
);

CREATE TABLE LOCATION (
  LOCID	NVARCHAR(5)
, MINQTY	INTEGER
, MAXQTY	INTEGER
, PRIMARY KEY 	(LOCID)
, CONSTRAINT CHECK_LOCID_LENGTH CHECK (LEN(LOCID) = 5)
, CONSTRAINT CHECK_MINQTY_RANGE CHECK (MINQTY BETWEEN 0 AND 999)
, CONSTRAINT CHECK_MAXQTY_RANGE CHECK (MAXQTY BETWEEN 0 AND 999)
, CONSTRAINT CHECK_MAXQTY_GREATER_MIXQTY CHECK (MAXQTY >= MINQTY)
);

IF OBJECT_ID('SALE_SEQ') IS NOT NULL
DROP SEQUENCE SALE_SEQ;
CREATE SEQUENCE SALE_SEQ;

GO

--STORE PROCEDURE #1 ADD_CUSTOMER 
IF OBJECT_ID('ADD_CUSTOMER') IS NOT NULL
DROP PROCEDURE ADD_CUSTOMER;
GO

CREATE PROCEDURE ADD_CUSTOMER @PCUSTID INT, @PCUSTNAME NVARCHAR(100) AS

BEGIN
    BEGIN TRY

        IF @PCUSTID < 1 OR @PCUSTID > 499
            THROW 50020, 'Customer ID out of range', 1

        INSERT INTO CUSTOMER (CUSTID, CUSTNAME, SALES_YTD, STATUS) 
        VALUES (@PCUSTID, @PCUSTNAME, 0, 'OK');

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 2627
            THROW 50010, 'Duplicate customer ID', 1
        ELSE IF ERROR_NUMBER() = 50020
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;

END;
GO
-- TESTING BY ADDING CUSTOMERS INTO CUSTOMER TABLE
-- EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'testdude1';
-- EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'testdude2';
-- EXEC ADD_CUSTOMER @pcustid = 500, @pcustname = 'testdude3';


-- SELECT * FROM CUSTOMER;
-- GO

--STORE PROCEDURE #2 DELETE_ALL_CUSTOMERS
IF OBJECT_ID('DELETE_ALL_CUSTOMERS') IS NOT NULL
DROP PROCEDURE DELETE_ALL_CUSTOMERS;
GO

CREATE PROCEDURE DELETE_ALL_CUSTOMERS AS
BEGIN
    BEGIN TRY
        DELETE FROM CUSTOMER;
        RETURN @@ROWCOUNT;
    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO

-- TESTING BY DELETING CUSTOMERS FROM CUSTOMER TABLE.
-- EXEC DELETE_ALL_CUSTOMERS;
-- SELECT * FROM CUSTOMER;
-- GO


--STORE PROCEDURE #3 ADD_PRODUCT 
IF OBJECT_ID('ADD_PRODUCT') IS NOT NULL 
DROP PROCEDURE ADD_PRODUCT; 
GO 

CREATE PROCEDURE ADD_PRODUCT @pprodid INT, @prodname NVARCHAR, @pprice MONEY AS 
BEGIN 
    BEGIN TRY 
        IF @pprodid > 2500 or @pprodid <1000
            THROW 500400, 'Product ID out of range', 1
        IF @pprice > 999.99 or @pprice < 0
            THROW 500500, 'Price out of range', 1
        INSERT INTO PRODUCT (PRODID, PRODNAME, SELLING_PRICE)
        VALUES (@pprodid, @prodname, @pprice)
    END TRY 

    BEGIN CATCH 
        IF ERROR_NUMBER() = 50040 THROW
        IF ERROR_NUMBER() = 50050 THROW
        IF ERROR_NUMBER() = 2501 THROW 50030, 'Duplicate Product ID', 1
        ELSE
    BEGIN 
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE(); 
        THROW 50000, @ERRORMESSAGE, 1 
    END; 
END CATCH 
END; 


-- -- TESTING: Adding Products into the Product Table
-- EXEC ADD_PRODUCT @prodid = 1111, @prodname = 'Coke Can', @price = 3;
-- EXEC ADD_PRODUCT @prodid = 2222, @prodname = 'Birthday Cake', @price = 5;
-- EXEC ADD_PRODUCT @prodid = 2600, @prodname = 'Bottle of Water', @price = 3; 
-- SELECT * FROM PRODUCT;



-- STORE PROCEDURE #4 DELETE_ALL_PRODUCTS 
IF OBJECT_ID('DELETE_ALL_PRODUCTS') IS NOT NULL
DROP PROCEDURE DELETE_ALL_PRODUCTS;
GO

CREATE PROCEDURE DELETE_ALL_PRODUCTS AS
BEGIN
    BEGIN TRY
        DELETE FROM PRODUCT;
        RETURN @@ROWCOUNT;
    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO
--TESTING: Delete all the products added from the add product procedure. 
-- Succesfully deleted products from product table.
-- SELECT * FROM PRODUCT 
-- EXEC DELETE_ALL_PRODUCTS;

--STORE PROCEDURE #5 
IF OBJECT_ID('GET_CUSTOMER_STRING') IS NOT NULL 
DROP PROCEDURE GET_CUSTOMER_STRING 
GO 

CREATE PROCEDURE GET_CUSTOMER_STRING @PCUSTID INT, @pReturnString NVARCHAR(100) OUTPUT AS
BEGIN
    DECLARE @PCUSTNAME NVARCHAR(100), @STATUS NVARCHAR(7), @SALESYTD MONEY;

    BEGIN TRY
    SELECT @PCUSTNAME = CUSTNAME, @STATUS = [STATUS], @SALESYTD = SALES_YTD
    FROM CUSTOMER 
    WHERE CUSTID = @PCUSTID

    SET @pReturnString = CONCAT('Custid: ', @PCUSTID, 'Name: ', @PCUSTNAME, 'Status: ', @STATUS, 'SalesYTD: ', @SALESYTD);

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 2627
            THROW 50060, 'Customer ID Not Found', 1
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
--TESTING: Testing Customer String
-- BEGIN
--     DECLARE @OUTPUTVALUE NVARCHAR(MAX);
--     EXEC GET_CUSTOMER_STRING @pcustid=1, @preturnstring = @OUTPUTVALUE OUTPUT;
--     PRINT (@OUTPUTVALUE);
-- END;


--STORE PROCEDURE #6 UPDATE CUSTOMER SALES
IF OBJECT_ID('UPD-CUST-SALESYTD') IS NOT NULL 
DROP PROCEDURE UPD_CUST_SALESYTD;
GO

CREATE PROCEDURE UPD_CUST_SALESYTD @pCUSTID INT, @pAMT MONEY AS 
BEGIN
    BEGIN TRY
        if @pAMT < -999.99 or @pAMT > 999.99 
        THROW 50080, 'Amount out of range', 1 

        UPDATE CUSTOMER 
        SET SALES_YTD = (SALES_YTD + @pAMT)
        WHERE @pCUSTID = CUSTID;  
    END TRY
    BEGIN CATCH 
        if ERROR_NUMBER() = 2627
        THROW 50070, 'Customer ID not found', 1 
        ELSE 
            BEGIN 
                DECLARE @ERRORMESSAGE NVARCHAR (100) = ERROR_MESSAGE(); 
                THROW 50000, @ERRORMESSAGE, 1
            END
    END CATCH 
END; 

--TESTING: Updating sales price in customer table.
-- delete customers that are already in customer table. 
-- EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'testdude1';

-- EXEC UPD_CUST_SALESYTD @pcustid = 1, @pamt = 100; 
-- EXEC UPD_CUST_SALESYTD @pcustid = 1, @pamt = 500; 
-- EXEC UPD_CUST_SALESYTD @pcustid = 1, @pamt = -1000; 
-- EXEC UPD_CUST_SALESYTD @pcustid = 1, @pamt = 1000; 

-- SELECT * FROM CUSTOMER


--STORE PROCEDURE #7 GET PRODUCT STRING
IF OBJECT_ID('GET_PROD_STRING') IS NOT NULL 
DROP PROCEDURE GET_PROD_STRING; 
GO 

CREATE PROCEDURE GET_PROD_STRING @prodid INT, @pReturnString NVARCHAR(100) OUT AS 
BEGIN 
    BEGIN TRY 
        DECLARE @PRODNAME INT, @SELLING_PRICE MONEY, @PSYTD MONEY;

        SELECT @PRODNAME = PRODNAME, @SELLING_PRICE = SELLING_Price, @PSYTD = SALES_YTD
        FROM PRODUCT WHERE PRODID = @prodid;

        IF @@ROWCOUNT = 0 
        THROW 50060, 'Customer ID not Found', 1 
        ELSE 
        SET @preturnString = CONCAT('ProdID:', @PRODID, 'Name:', @prodname, 'Price:', @SELLING_PRICE, 'SalesYTD:', @PSYTD); 
    END TRY 
    BEGIN CATCH 
        if ERROR_NUMBER() = 2627 
            THROW 50090, 'Product ID Not Found', 1
        ELSE 
            BEGIN  
                DECLARE @ERRORMESSAGE NVARCHAR(100) = ERROR_MESSAGE(); 
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END; 

--TESTING: Get product string. GOTTA COME BACK TO THIS AND FIX IT LATER. 
-- BEGIN
--     DECLARE @OUTPUTVALUE NVARCHAR(100);
--     EXEC GET_PROD_STRING @prodid = 1111, @preturnstring = @OUTPUTVALUE OUTPUT;
--     PRINT (@OUTPUTVALUE);
-- END
-- GO


--STORED PROCEDURE #8
IF OBJECT_ID('UPD_PROD_SALESYTD') IS NOT NULL
DROP PROCEDURE UPD_PROD_SALESYTD; 
GO

CREATE PROCEDURE UPD_PROD_SALESYTD @PPRODID INT, @PAMT MONEY AS 
BEGIN
    BEGIN TRY
    IF @pamt < -999.99 OR @pamt > 999.99
            THROW 50110, 'Amount out of range', 1
        
        UPDATE PRODUCT SET SALES_YTD = SALES_YTD + @pamt  WHERE PRODID = @pprodid;
    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 50110
            THROW 
        if ERROR_NUMBER() = 50100
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END;
    END CATCH
END;
GO

--TESTING: Updating product sales price. 
-- EXEC DELETE_ALL_PRODUCTS;
-- SELECT * FROM PRODUCT
-- EXEC ADD_PRODUCT @pprodid = 2000, @prodname = 'testdude3', @pprice = 100;
-- EXEC ADD_PRODUCT @pprodid = 2010, @prodname = 'testdude4', @pprice = 200;

-- EXEC UPD_PROD_SALESYTD @pprodid = 2007, @pamt = 800;
-- EXEC UPD_PROD_SALESYTD @pprodid = 2007, @pamt = 200;
-- EXEC UPD_PROD_SALESYTD @pprodid = 2010, @pamt = -1000; 
-- EXEC UPD_PROD_SALESYTD @pprodid = 2010, @pamt = 1000;
-- SELECT * FROM PRODUCT



-- STORED PROCEDURE #9 UPDATING CUSTOMER STATUS 
IF OBJECT_ID('UPD_CUSTOMER_STATUS') IS NOT NULL 
DROP PROCEDURE UPD_CUSTOMER_STATUS;  
GO 

CREATE PROCEDURE UPD_CUSTOMER_STATUS @PCUSTID INT, @PSTATUS NVARCHAR(100) AS  
    BEGIN 
        BEGIN TRY 
            if @@ROWCOUNT = 0 
                THROW 50120, 'Customer ID Not Found', 1 

            if @PSTATUS = 'OK' or @PSTATUS = 'SUSPEND' 
            UPDATE CUSTOMER SET STATUS = @PSTATUS 
            WHERE CUSTID = @PCUSTID 
            UPDATE CUSTOMER SET STATUS = @PSTATUS 
            WHERE CUSTID = @PCUSTID;
        END TRY 
    BEGIN CATCH 
        DECLARE @ERRORMESSAGE NVARCHAR(100) = ERROR_MESSAGE(); 
        THROW 50000, @ERRORMESSAGE, 1 
    END CATCH 
END; 
GO
-- TESTING: Updating Customer Status
-- EXEC DELETE_ALL_CUSTOMERS;
-- EXEC ADD_CUSTOMER @PCUSTID = 1, @PCUSTNAME = 'TESTDUDE1';
-- EXEC ADD_CUSTOMER @PCUSTID = 2, @PCUSTNAME = 'TESTDUDE2';
-- EXEC UPD_CUSTOMER_STATUS @PCUSTID = 1, @PSTATUS = 'SUSPEND'; 
-- EXEC UPD_CUSTOMER_STATUS @PCUSTID = 2, @PSTATUS = 'SUSPEND';
-- SELECT * FROM CUSTOMER;

-- STORED PROCEDURE #10 
IF OBJECT_ID('ADD_SIMPLE_SALE') IS NOT NULL
DROP PROCEDURE ADD_SIMPLE_SALE; 

GO

CREATE PROCEDURE ADD_SIMPLE_SALE @PCUSTID INT, @PPRODID INT, @PQTY MONEY AS
BEGIN
BEGIN TRY 
    DECLARE @STATUS AS NVARCHAR(7)
    SELECT @STATUS = Status FROM CUSTOMER WHERE CUSTID = @pcustid
    IF @STATUS != 'OK'
        THROW 50150, 'Customer Status is not OK',1;
    IF @PQTY  > 999 or @PQTY  < 1
        THROW 50140, 'Sale Quantity outside valid range',1;
        
    IF EXISTS (SELECT * FROM CUSTOMER WHERE CUSTID = @pcustid) 
    
    IF EXISTS (SELECT * FROM PRODUCT WHERE PRODID = @pPRODID)
        BEGIN
        DECLARE @PRICE AS MONEY
        SELECT @PRICE =  SELLING_PRICE FROM PRODUCT WHERE PRODID = @PPRODID
        DECLARE @TOTAL MONEY = @PQTY * @PRICE;
        UPDATE CUSTOMER SET SALES_YTD += @total WHERE CUSTID = @PCUSTID;
        UPDATE PRODUCT SET SALES_YTD += @total WHERE PRODID = @PPRODID;
        END;
         ELSE 
            THROW 50170, 'Product ID not found', 1;
         ELSE  
            THROW 50160, 'Customer ID not found', 1;
         END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 50150 OR ERROR_NUMBER() = 50160 OR  ERROR_NUMBER() = 50140 or ERROR_NUMBER() = 50170
        THROW;
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END;
    END CATCH
END;

--TESTING: Adding Simple Sale. 
SELECT * FROM SALE







--STORED PROCEDURE #11
IF OBJECT_ID('SUM_CUSTOMER_SALESYTD') IS NOT NULL
DROP PROCEDURE SUM_CUSTOMER_SALESYTD;
GO
CREATE PROCEDURE SUM_CUSTOMER_SALESYTD AS
BEGIN
    BEGIN TRY 
    DECLARE @total as INT;
    SELECT @total = SUM(SALES_YTD) 
    FROM CUSTOMER;
    RETURN @total;
    END TRY
    BEGIN CATCH
    DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
    THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END;
GO


--STORED PROCEDURE #12
IF OBJECT_ID('SUM_PRODUCT_SALESYTD') IS NOT NULL
DROP PROCEDURE SUM_PRODUCT_SALESYTD;
GO
CREATE PROCEDURE SUM_PRODUCT_SALESYTD AS
BEGIN
    BEGIN TRY 
    DECLARE @total as INT;
    SELECT @total = SUM(SALES_YTD) 
    FROM PRODUCT;
    RETURN @total;
    END TRY
    BEGIN CATCH
    DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
    THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END;
GO

--STORED PROCEDURE #13
IF OBJECT_ID('GET_ALL_CUSTOMERS') IS NOT NULL
DROP PROCEDURE GET_ALL_CUSTOMERS;
GO
CREATE PROCEDURE GET_ALL_CUSTOMERS @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY 
    SET NOCOUNT ON;
    SET @POUTCUR = CURSOR FOR 
    SELECT * FROM CUSTOMER;
    OPEN @POUTCUR
    END TRY
    BEGIN CATCH
    DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
    THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END;
GO

-- STORED PROCEDURE #14
IF OBJECT_ID('GET_ALL_PRODUCTS') IS NOT NULL
DROP PROCEDURE GET_ALL_PRODUCTS;
GO
CREATE PROCEDURE GET_ALL_PRODUCTS @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY 
    SET NOCOUNT ON;
    SET @POUTCUR = CURSOR FOR 
    SELECT * FROM PRODUCT;
    OPEN @POUTCUR
    END TRY
    BEGIN CATCH
    DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
    THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END;

GO

--STORED PROCEDURE #15
IF OBJECT_ID('ADD_LOCATION') IS NOT NULL
DROP PROCEDURE ADD_LOCATION;
GO
CREATE PROCEDURE ADD_LOCATION @ploccode NVARCHAR(5), @pminqty INT, @pMaxQty INT AS
BEGIN
BEGIN TRY
    IF @pLocCode != 5
        THROW 50190, 'Location Code length invalid', 1
    IF @pMinQty > 999 OR @pMinQty < 0 
        THROW 50200, 'Minimum Qty out of range', 1
    IF @pMaxQty > 999 OR @pMaxQty < 0 
        THROW 50210, 'Maximum Qty out of range', 1
    IF @pMaxQty < @pMinQty 
        THROW 50220, 'Minimum Qty larger than Maximum Qty', 1
        
    INSERT INTO LOCATION (LOCID, MINQTY, MAXQTY)
    VALUES(@pLocCode, @pMinQty, @);
    END TRY

BEGIN CATCH
        IF ERROR_NUMBER() = 50190 OR ERROR_NUMBER() = 50200 OR ERROR_NUMBER() = 50210 OR ERROR_NUMBER() = 50220
        THROW
        IF ERROR_NUMBER() = 2627
        THROW 50180, 'Duplicate location ID',1
        ELSE
        BEGIN
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1
            END;
    END CATCH
END;
GO

-- STORED PROCEDURE #16
IF OBJECT_ID('ADD_COMPLEX_SALE') IS NOT NULL
DROP PROCEDURE ADD_COMPLEX_SALE;
GO
CREATE PROCEDURE ADD_COMPLEX_SALE @pcustid INT, @pprodid INT, @pQty INT, @pdate DATE AS
BEGIN
    BEGIN TRY 
    DECLARE @Status AS NVARCHAR(7)
    SELECT @Status = Status FROM CUSTOMER WHERE CUSTID = @pcustid
    IF @Status != 'OK'
        THROW 50240, 'Customer Status is not OK',1;
    IF @pQty > 999 or @pQty < 1
        THROW 50230, 'Sale Quantity Outside Valid Range',1;
        
    IF EXISTS (SELECT * FROM CUSTOMER WHERE CUSTID = @pcustid)
    IF EXISTS (SELECT * FROM PRODUCT WHERE PRODID = @pprodid)
        BEGIN
        DECLARE @Price AS MONEY
        SELECT @Price =  SELLING_Price FROM PRODUCT WHERE PRODID = @pprodid;
        DECLARE @total money = @pQty * @Price;
        UPDATE CUSTOMER SET SALES_YTD += @total WHERE CUSTID = @pcustid;
        UPDATE PRODUCT SET SALES_YTD += @total WHERE PRODID = @pprodid;
        DECLARE @saleid BIGINT;
        SELECT @Price = SELLING_Price FROM PRODUCT WHERE PRODID = @pprodid;
        INSERT INTO SALE (SALEID, CUSTID, PRODID, QTY, Price, SALEDATE)
        VALUES(NEXT VALUE FOR SALE_SEQ,@pcustid, @pprodid,@pQty, @Price, @pdate )
        END;
        ELSE 
            THROW 50270, 'Product ID not found',1;
        ELSE 
            THROW 50260, 'Customer ID not found',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50230 OR ERROR_NUMBER() = 50240 OR ERROR_NUMBER() = 50250 OR ERROR_NUMBER() = 50260 OR ERROR_NUMBER() = 50270
        Throw
        ELSE
            BEGIN
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1
            END;
    END CATCH
END;
GO

--STORED PROCEDURE #17
IF OBJECT_ID('GET_ALL_SALES') IS NOT NULL
    DROP PROCEDURE GET_ALL_SALES
GO
CREATE PROCEDURE GET_ALL_SALES @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY
        SET @POUTCUR = CURSOR
        FORWARD_ONLY STATIC FOR
        SELECT * FROM SALE
        OPEN @POUTCUR
    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END

--STORED PROCEDURE #18
IF OBJECT_ID('COUNT_PRODUCT_SALES') IS NOT NULL
    DROP PROCEDURE COUNT_PRODUCT_SALES
GO
CREATE PROCEDURE COUNT_PRODUCT_SALES @pdays INT AS
BEGIN
    DECLARE @numSales INT
    BEGIN TRY
        SELECT @numSales = COUNT(*)
        FROM SALE
        WHERE DATEDIFF(day, SALEDATE, GETDATE()) BETWEEN 0 AND @pdays
    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH
    RETURN @numSales
END

--STORED PROCEDURE #19
IF OBJECT_ID('DELETE_SALE') IS NOT NULL
    DROP PROCEDURE DELETE_SALE
GO
CREATE PROCEDURE DELETE_SALE @saleid BIGINT OUTPUT AS
BEGIN
DECLARE @custid INT, @prodid INT, @price INT, @qty INT, @amt INT
BEGIN TRY
    SELECT @saleid = SALEID, @custid = CUSTID, @prodid = PRODID, @price = PRICE, @qty = QTY
    FROM SALE
    WHERE SALEID = (SELECT MIN(SALEID) FROM SALE)
    IF @@ROWCOUNT = 0
        THROW 50280, 'No Sale Rows Found', 1;
    SET @amt = -1 * (@price * @qty)
    EXEC UPD_CUST_SALESYTD @pcustid = @custid, @pamt = @amt
    EXEC UPD_PROD_SALESYTD @pprodid = @prodid, @pamt = @amt
    DELETE FROM SALE
    WHERE SALEID = (SELECT MIN(SALEID) FROM SALE)
    IF @@ROWCOUNT = 0
        THROW 50280, 'No Sale Rows Found', 1;
    END TRY
    BEGIN CATCH
    IF ERROR_NUMBER() = 50280
        THROW
    ELSE
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
    THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END
GO

--STORED PROCEDURE #20
IF OBJECT_ID('DELETE_ALL_SALES') IS NOT NULL
    DROP PROCEDURE DELETE_ALL_SALES
GO
CREATE PROCEDURE DELETE_ALL_SALES  AS
BEGIN
BEGIN TRY
    DELETE FROM SALE
    UPDATE CUSTOMER
    SET SALES_YTD = 0;
    UPDATE PRODUCT
    SET SALES_YTD = 0;
    END TRY
   
    BEGIN CATCH
    
    DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
    THROW 50000, @ERRORMESSAGE, 1
    
    END CATCH
END

--STORED PROCEDURE #21
IF OBJECT_ID('DELETE_CUSTOMER') IS NOT NULL
    DROP PROCEDURE DELETE_CUSTOMER
GO
CREATE PROCEDURE DELETE_CUSTOMER @pcustid INT AS
BEGIN
    
BEGIN TRY
    IF NOT EXISTS(SELECT * FROM CUSTOMER WHERE CUSTID = @pcustid)
        THROW 50290, 'Customer ID not found', 1
    IF EXISTS(SELECT * FROM SALE WHERE CUSTID = @pcustid)
        THROW 50300, 'Customer cannot be deleted as sales exist', 1
    DELETE FROM CUSTOMER WHERE CUSTID = @pcustid
    
    END TRY
    
    BEGIN CATCH
    IF ERROR_NUMBER() IN (50290, 50300)
        THROW
    ELSE
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END
GO

--STORED PROCEDURE #22
IF OBJECT_ID('DELETE_PRODUCT') IS NOT NULL
DROP PROCEDURE DELETE_PRODUCT
GO
CREATE PROCEDURE DELETE_PRODUCT @pprodid INT AS
BEGIN
    BEGIN TRY
    IF NOT EXISTS(SELECT * FROM PRODUCT WHERE PRODID = @pprodid)
        THROW 50310, 'Product ID not found', 1
    IF EXISTS(SELECT * FROM SALE WHERE PRODID = @pprodid)
        THROW 50320, 'Product cannot be deleted as sales exist', 1
    DELETE FROM PRODUCT WHERE PRODID = @pprodid
    END TRY
   
    BEGIN CATCH
        IF ERROR_NUMBER() IN (50290, 50300)
            THROW
        ELSE
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END


