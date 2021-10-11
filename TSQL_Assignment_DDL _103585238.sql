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
-- EXECUTE ADD_CUSTOMER @pcustid = 1, @pcustname = 'Dummy One';
-- EXECUTE ADD_CUSTOMER @pcustid = 200, @pcustname = 'Dummy Two';
-- EXECUTE ADD_CUSTOMER @pcustid = 499, @pcustname = 'Dummy Three';
-- SELECT * FROM CUSTOMER;

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
-- EXECUTE DELETE_ALL_CUSTOMERS; 
-- SELECT * FROM CUSTOMER; 
-- GO


--STORE PROCEDURE #3 ADD_PRODUCT 
IF OBJECT_ID('ADD_PRODUCT') IS NOT NULL 
DROP PROCEDURE ADD_PRODUCT; 
GO 

CREATE PROCEDURE ADD_PRODUCT @PRODID INT, @PRODNAME NVARCHAR(100), @PPRICE MONEY AS
BEGIN
    BEGIN TRY

        IF @PRODID < 1000 OR @PRODID > 2500
            THROW 50040, 'Product ID out of range', 1
        
        IF @PPRICE < 0 OR @PPRICE > 999.99
            THROW 50050, 'Price out of range', 1

        INSERT INTO PRODUCT (PRODID, PRODNAME, SELLING_PRICE, SALES_YTD) 
        VALUES (@PRODID, @PRODNAME, @PPRICE, 0);

    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 2627 -- cannot insert duplicate key in object 
            THROW 50030, 'Duplicate product ID', 1
        ELSE IF ERROR_NUMBER() = 50040
            THROW
        ELSE IF ERROR_NUMBER() = 50050
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
GO


-- TESTING: Adding Products into the Product Table
-- EXECUTE ADD_PRODUCT @PRODID = 100, @PRODNAME ='Little', @PPRICE = 500 --prod id out of range
-- EXECUTE ADD_PRODUCT @PRODID = 1800, @PRODNAME ='Big', @PPRICE = 10000 --price exceeds range 
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 100 --suits parameters
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Copy', @PPRICE = 100 --duplicate prodid
-- SELECT * FROM PRODUCT
-- GO


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
-- TESTING: Deleting Products from Table 
-- EXECUTE DELETE_ALL_PRODUCTS;

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

    SET @pReturnString = CONCAT('CustId:', @PCUSTID, 'Name: ', @PCUSTNAME, 'Status: ', @STATUS, 'SalesYTD: ', @SALESYTD);

    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50060 
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
-- TESTING: Testing Customer String
-- BEGIN
--     DECLARE @OUTPUTVALUE NVARCHAR(MAX);
--     EXECUTE GET_CUSTOMER_STRING @pcustid= 1, @preturnstring = @OUTPUTVALUE OUTPUT;
--     PRINT (@OUTPUTVALUE);
-- END


--STORE PROCEDURE #6 UPDATE CUSTOMER SALES
IF OBJECT_ID('UPD_CUST_SALESYTD') IS NOT NULL 
DROP PROCEDURE UPD_CUST_SALESYTD;
GO

CREATE PROCEDURE UPD_CUST_SALESYTD @PCUSTID INT, @PAMT MONEY AS 
BEGIN
    BEGIN TRY
        IF @PAMT < -999.99 or @pAMT > 999.99 
        THROW 50080, 'Amount out of range', 1 

        UPDATE CUSTOMER 
        SET SALES_YTD = (SALES_YTD + @pAMT)
        WHERE @pCUSTID = CUSTID;  
    END TRY
    BEGIN CATCH 
        IF ERROR_NUMBER() = 2627
        THROW 50070, 'Customer ID not found', 1 
        ELSE 
            BEGIN 
                DECLARE @ERRORMESSAGE NVARCHAR (100) = ERROR_MESSAGE(); 
                THROW 50000, @ERRORMESSAGE, 1
            END
    END CATCH 
END; 

-- TESTING: Updating sales price in customer table.
-- DELETE FROM CUSTOMER
-- EXECUTE ADD_CUSTOMER @PCUSTID = 1, @PCUSTNAME = 'Dummy Four';
-- SELECT * FROM CUSTOMER

-- EXECUTE UPD_CUST_SALESYTD @pcustid = 1, @pamt = 100; 
-- EXECUTE UPD_CUST_SALESYTD @pcustid = 1, @pamt = 500; 
-- EXECUTE UPD_CUST_SALESYTD @pcustid = 1, @pamt = -1000; 
-- EXECUTE UPD_CUST_SALESYTD @pcustid = 1, @pamt = 1000; 
-- SELECT * FROM CUSTOMER


--STORE PROCEDURE #7 GET PRODUCT STRING
IF OBJECT_ID('GET_PROD_STRING') IS NOT NULL
DROP PROCEDURE GET_PROD_STRING;
GO

CREATE PROCEDURE GET_PROD_STRING @PRODID INT, @pReturnString NVARCHAR(1000) OUTPUT AS
BEGIN
    DECLARE @PRODNAME NVARCHAR(100), @PRICE MONEY, @SALESYTD MONEY;

    BEGIN TRY
    SELECT @PRODNAME = PRODNAME, @PRICE = SELLING_PRICE, @SALESYTD = SALES_YTD
    FROM PRODUCT 
    WHERE PRODID = @PRODID

    IF @@ROWCOUNT = 0
    THROW 50090, 'Product ID not found', 1

    SET @pReturnString = CONCAT('Prodid: ', @PRODID, 'Name: ', @PRODNAME, 'Price: ', @PRICE, 'SalesYTD: ', @SALESYTD);

    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50090
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
GO

--TESTING: Get product string. 
-- SELECT * FROM PRODUCT
-- BEGIN
--     DECLARE @OUTPUTVALUE NVARCHAR(100);
--     EXECUTE GET_PROD_STRING @prodid = 2001, @preturnstring = @OUTPUTVALUE OUTPUT;
--     PRINT (@OUTPUTVALUE);
-- END
-- GO


--STORED PROCEDURE #8
IF OBJECT_ID('UPD_PROD_SALESYTD') IS NOT NULL
DROP PROCEDURE UPD_PROD_SALESYTD
GO

CREATE PROCEDURE UPD_PROD_SALESYTD @PRODID INT, @PAMT MONEY AS 
BEGIN
    BEGIN TRY
    IF @pamt < -999.99 OR @pamt > 999.99
            THROW 50110, 'Amount out of range', 1
        
        UPDATE PRODUCT 
        SET SALES_YTD = SALES_YTD + @PAMT
        WHERE PRODID = @PRODID
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
-- EXECUTE DELETE_ALL_PRODUCTS;
-- EXECUTE ADD_PRODUCT @prodid = 2021, @prodname = 'Dummy Five', @pprice = 100;
-- EXECUTE ADD_PRODUCT @prodid = 2022, @prodname = 'Dummy Six', @pprice = 200;
-- SELECT * FROM PRODUCT

-- EXECUTE UPD_PROD_SALESYTD @prodid = 2021, @pamt = 800;
-- EXECUTE UPD_PROD_SALESYTD @prodid = 2021, @pamt = 200;
-- EXECUTE UPD_PROD_SALESYTD @prodid = 2021, @pamt = -1000; 
-- EXECUTE UPD_PROD_SALESYTD @prodid = 2022, @pamt = 1000;
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
-- EXECUTE DELETE_ALL_CUSTOMERS;
-- EXECUTE ADD_CUSTOMER @PCUSTID = 1, @PCUSTNAME = 'Dummy Seven';
-- EXECUTE ADD_CUSTOMER @PCUSTID = 2, @PCUSTNAME = 'Dummy Eight';
-- SELECT * FROM CUSTOMER;

-- EXECUTE UPD_CUSTOMER_STATUS @PCUSTID = 1, @PSTATUS = 'SUSPEND'; 
-- EXECUTE UPD_CUSTOMER_STATUS @PCUSTID = 2, @PSTATUS = 'SUSPEND';
-- SELECT * FROM CUSTOMER;

-- STORED PROCEDURE #10 
IF OBJECT_ID('ADD_SIMPLE_SALE') IS NOT NULL
DROP PROCEDURE ADD_SIMPLE_SALE;
GO

CREATE PROCEDURE ADD_SIMPLE_SALE @PCUSTID INT, @PPRODID INT, @PQTY INT AS
BEGIN
    BEGIN TRY

    DECLARE @CUSTSTATUS NVARCHAR(7);

    SELECT @CUSTSTATUS = STATUS
    FROM CUSTOMER
    WHERE CUSTID = @PCUSTID
    IF @@ROWCOUNT = 0
        THROW 50160, 'Customer ID not found', 1

    IF (@CUSTSTATUS NOT IN ('OK'))
        THROW 50150, 'Customer status is not OK', 1

    IF @PQTY<1 OR @PQTY>999
        THROW 50140, 'Sale Quantity outside valid range', 1

    DECLARE @PRODSELLPRICE MONEY;
    SELECT @PRODSELLPRICE = SELLING_PRICE
    FROM PRODUCT
    WHERE PRODID = @PPRODID
    IF @@ROWCOUNT = 0
        THROW 50170, 'Product ID not found', 1

    DECLARE @UPDATEAMT MONEY
    SET @UPDATEAMT = @PRODSELLPRICE*@PQTY;

    EXEC UPD_CUST_SALESYTD @PCUSTID = @PCUSTID, @PAMT = @UPDATEAMT
    EXEC UPD_PROD_SALESYTD @PRODID = @PPRODID, @PAMT = @UPDATEAMT

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() in (50150, 50160, 50140, 50170)
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
GO

---- testing ----
-- DELETE FROM SALE
-- DELETE FROM PRODUCT
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10
-- SELECT * FROM PRODUCT

-- DELETE FROM CUSTOMER
-- EXECUTE ADD_CUSTOMER @pcustid = 1, @pcustname = 'Dummy Nine';
-- EXECUTE ADD_CUSTOMER @pcustid = 2, @pcustname = 'Dummy Ten';
-- EXECUTE UPD_CUSTOMER_STATUS @pcustid = 2, @pstatus = 'SUSPEND';
-- SELECT * FROM CUSTOMER

-- EXECUTE ADD_SIMPLE_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10;
-- SELECT * FROM PRODUCT
-- SELECT * FROM CUSTOMER
-- SELECT * FROM SALE


--STORED PROCEDURE #11
IF OBJECT_ID('SUM_CUSTOMER_SALESYTD') IS NOT NULL
DROP PROCEDURE SUM_CUSTOMER_SALESYTD;
GO

CREATE PROCEDURE SUM_CUSTOMER_SALESYTD AS
BEGIN
    BEGIN TRY

    SELECT SUM(SALES_YTD)
    FROM CUSTOMER

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;

GO
-- TESTING:
-- DELETE FROM SALE
-- DELETE FROM PRODUCT
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10
-- SELECT * FROM PRODUCT

-- EXECUTE ADD_CUSTOMER @pcustid = 1, @pcustname = 'Dummy Eleven';
-- EXECUTE ADD_CUSTOMER @pcustid = 2, @pcustname = 'Dummy Twelve';
-- EXECUTE ADD_CUSTOMER @pcustid = 3, @pcustname = 'Dummy Thirteen';
-- SELECT * FROM CUSTOMER

-- EXECUTE SUM_CUSTOMER_SALESYTD

--STORED PROCEDURE #12
IF OBJECT_ID('SUM_PRODUCT_SALESYTD') IS NOT NULL
DROP PROCEDURE SUM_PRODUCT_SALESYTD;
GO

CREATE PROCEDURE SUM_PRODUCT_SALESYTD AS
BEGIN
    BEGIN TRY

    SELECT SUM(SALES_YTD)
    FROM PRODUCT

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO
-- TESTING:
-- SELECT * FROM PRODUCT
-- EXECUTE DELETE_ALL_PRODUCTS
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME = 'Perfect', @PPRICE = 10
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME = 'Perfect', @PPRICE = 10

-- EXECUTE SUM_PRODUCT_SALESYTD

--STORED PROCEDURE #13
IF OBJECT_ID('GET_ALL_CUSTOMERS') IS NOT NULL
DROP PROCEDURE GET_ALL_CUSTOMERS;
GO

CREATE PROCEDURE GET_ALL_CUSTOMERS @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY

        SET @POUTCUR = CURSOR FOR
            SELECT *
            FROM CUSTOMER

        OPEN @POUTCUR;

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO
-- TESTING:
-- DELETE FROM CUSTOMER 
-- EXECUTE ADD_CUSTOMER @pcustid = 1, @pcustname = "Dummy One"
-- EXECUTE ADD_CUSTOMER @pcustid = 2, @pcustname = "Dummy Two"
-- EXECUTE ADD_CUSTOMER @pcustid = 3, @pcustname = "Dummy Three"
-- SELECT * FROM CUSTOMER 

-- BEGIN 
--     DECLARE @CUSTID INT, @CUSTNAME NVARCHAR(MAX), @SALES_YTD MONEY, @STATUS NVARCHAR(10);
--     DECLARE @OUTCUR AS CURSOR 

--     EXECUTE GET_ALL_CUSTOMERS @POUTCUR = @OUTCUR OUTPUT; 
--     FETCH NEXT FROM @OUTCUR INTO @CUSTID, @CUSTNAME, @SALES_YTD, @STATUS
--     WHILE @@FETCH_STATUS = 0
-- BEGIN 
--     PRINT CONCAT(@CUSTID, ' ', @CUSTNAME, ' ', @SALES_YTD, @STATUS)
--     FETCH NEXT FROM @OUTCUR INTO @CUSTID, @CUSTNAME, @SALES_YTD, @STATUS
-- END 

--     CLOSE @OUTCUR; 
--     DEALLOCATE @OUTCUR; 
-- END 

-- STORED PROCEDURE #14 
IF OBJECT_ID('GET_ALL_PRODUCTS') IS NOT NULL
DROP PROCEDURE GET_ALL_PRODUCTS;
GO

CREATE PROCEDURE GET_ALL_PRODUCTS @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY

        SET @POUTCUR = CURSOR FOR
            SELECT *
            FROM PRODUCT

        OPEN @POUTCUR;

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO

-- TESTING: 
-- DELETE FROM PRODUCT
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect One', @PPRICE = 10
-- EXECUTE ADD_PRODUCT @PRODID = 2002, @PRODNAME ='Perfect Two', @PPRICE = 1
-- SELECT * FROM PRODUCT


-- BEGIN
--     DECLARE @PRODID INT, @PRODNAME NVARCHAR(100), @SELLING_PRICE MONEY, @SALES_YTD MONEY;
--     DECLARE @OUTCUR AS CURSOR
--     EXEC GET_ALL_PRODUCTS @POUTCUR = @OUTCUR OUTPUT;
--     FETCH NEXT FROM @OUTCUR INTO @PRODID, @PRODNAME, @SELLING_PRICE, @SALES_YTD
--     WHILE @@FETCH_STATUS=0
--     BEGIN
--         PRINT CONCAT(@PRODID, ' ', @PRODNAME, ' ', @SELLING_PRICE, ' ', @SALES_YTD)
--         FETCH NEXT FROM @OUTCUR INTO @PRODID, @PRODNAME, @SELLING_PRICE, @SALES_YTD
--     END
    
--     CLOSE @OUTCUR;
--     DEALLOCATE @OUTCUR;
-- END

--STORED PROCEDURE #15 
IF OBJECT_ID('ADD_LOCATION') IS NOT NULL
DROP PROCEDURE ADD_LOCATION;
GO

CREATE PROCEDURE ADD_LOCATION @PLOCCODE NVARCHAR(5), @PMINQTY INT, @PMAXQTY INT AS
BEGIN
    BEGIN TRY

        IF LEN(@PLOCCODE)!=5
            THROW 50190, 'Location Code length invalid', 1
        
        IF @PMINQTY < 0 OR @PMAXQTY > 999
            THROW 50200, 'Minimum Qty out of range', 1

        IF @pmaxqty < 0 OR @PMAXQTY > 999
            THROW 50210, 'Maximum Qty out of range', 1

        IF @pmaxqty < @pminqty
            THROW 50220, 'Minimum Qty larger than Maximum Qty', 1

        INSERT INTO LOCATION (LOCID, MINQTY, MAXQTY) 
        VALUES (@PLOCCODE, @PMINQTY, @PMAXQTY);

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 2627
                THROW 50180, 'Duplicate location ID', 1
        if ERROR_NUMBER() in (50190, 50200, 50210, 50220)
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
GO
-- TESTING:
-- DELETE FROM LOCATION
-- EXECUTE ADD_LOCATION @ploccode = 'Loc01', @pminqty = 0, @pmaxqty = 999;
-- EXECUTE ADD_LOCATION @ploccode = 'Loc01', @pminqty = 0, @pmaxqty = 999; -- duplicate location code
-- EXECUTE ADD_LOCATION @ploccode = 'Loc02', @pminqty = -500, @pmaxqty = 999; --min out of range
-- EXECUTE ADD_LOCATION @ploccode = 'Loc02', @pminqty = 0, @pmaxqty = 1000; --max out of range
-- EXECUTE ADD_LOCATION @ploccode = 'Loc02', @pminqty = 500, @pmaxqty = 200; -- min bigger than max 
-- SELECT * FROM LOCATION

-- STORED PROCEDURE ##16 
IF OBJECT_ID('ADD_COMPLEX_SALE') IS NOT NULL
DROP PROCEDURE ADD_COMPLEX_SALE;
GO

CREATE PROCEDURE ADD_COMPLEX_SALE @pcustid INT, @pprodid INT, @pqty INT, @pdate NVARCHAR(8) AS
BEGIN
    BEGIN TRY

        DECLARE @CUSTSTATUS NVARCHAR(7);

        SELECT @CUSTSTATUS = STATUS
        FROM CUSTOMER
        WHERE CUSTID = @PCUSTID
        IF @@ROWCOUNT = 0
            THROW 50260, 'Customer ID not found', 1

        IF (@CUSTSTATUS NOT IN ('OK'))
            THROW 50240, 'Customer status is not OK', 1

        IF @PQTY<1 OR @PQTY>999
            THROW 50230, 'Sale Quantity outside valid range', 1

        DECLARE @PRODSELLPRICE MONEY;
        SELECT @PRODSELLPRICE = SELLING_PRICE
        FROM PRODUCT
        WHERE PRODID = @PPRODID
        IF @@ROWCOUNT = 0
            THROW 50270, 'Product ID not found', 1
        
        IF (ISDATE(@pdate) = 0)
            THROW 50250, 'Date not valid', 1

        DECLARE @SALEIDFROMSEQ BIGINT;
        SELECT @SALEIDFROMSEQ = NEXT VALUE FOR SALE_SEQ;

        INSERT INTO SALE(SALEID, CUSTID, PRODID, QTY, PRICE, SALEDATE) 
        VALUES (@SALEIDFROMSEQ, @PCUSTID, @PPRODID, @PQTY, @PRODSELLPRICE, CONVERT(DATE, @pdate, 112));

        DECLARE @UPDATEAMT MONEY
        SET @UPDATEAMT = @PRODSELLPRICE * @PQTY;

        EXEC UPD_CUST_SALESYTD @pcustid = @pcustid, @PAMT = @UPDATEAMT
        EXEC UPD_PROD_SALESYTD @prodid = @pprodid, @PAMT = @UPDATEAMT

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() in (50240, 50260, 50230, 50270, 50250)
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
GO

---- testing ----
-- DELETE FROM SALE
-- DELETE FROM PRODUCT
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10
-- SELECT * FROM PRODUCT

-- DELETE FROM CUSTOMER
-- EXECUTE ADD_CUSTOMER @pcustid = 1, @pcustname = 'Dummy Nine';
-- EXECUTE ADD_CUSTOMER @pcustid = 2, @pcustname = 'Dummy Ten';
-- EXECUTE UPD_CUSTOMER_STATUS @pcustid = 2, @pstatus = 'SUSPEND';
-- SELECT * FROM CUSTOMER

-- DELETE FROM SALE 
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211004';
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 100, @pdate = '2021082'; -- date not valid
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 100, @pdate = '2021-08-21';-- date not valid
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 3, @pprodid = 2001, @pqty = 100, @pdate = '20210821'; --cust id not found
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 0, @pdate = '20210821'; -- sale quant out of range
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2002, @pqty = 100, @pdate = '20210821'; --prodid not found
-- SELECT * FROM PRODUCT
-- SELECT * FROM CUSTOMER
-- SELECT * FROM SALE

-- STORED PROCEDURE #17 
IF OBJECT_ID('GET_ALLSALES') IS NOT NULL
DROP PROCEDURE GET_ALLSALES;
GO

CREATE PROCEDURE GET_ALLSALES @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY

        SET @POUTCUR = CURSOR FOR
            SELECT *
            FROM SALE

        OPEN @POUTCUR;

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO

-- TESTING:
-- DELETE FROM SALE
-- DELETE FROM PRODUCT
-- EXEC ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10

-- DELETE FROM CUSTOMER
-- EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'Dummy One';

-- EXEC ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211004';
-- EXEC ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211004';
-- EXEC ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20201004';
-- SELECT * FROM PRODUCT
-- SELECT * FROM CUSTOMER
-- SELECT * FROM SALE

-- BEGIN
--     DECLARE @SALEID BIGINT, @CUSTID INT, @PRODID INT, @QTY INT, @PRICE MONEY, @SALEDATE DATE;
--     DECLARE @OUTCUR AS CURSOR
--     EXEC GET_ALLSALES @POUTCUR = @OUTCUR OUTPUT;
--     FETCH NEXT FROM @OUTCUR INTO @SALEID, @CUSTID, @PRODID, @QTY, @PRICE, @SALEDATE
--     WHILE @@FETCH_STATUS=0
--     BEGIN
--         PRINT CONCAT(@SALEID, ' ', @CUSTID, ' ', @PRODID, ' ', @QTY, ' ', @PRICE, ' ', @SALEDATE)
--         FETCH NEXT FROM @OUTCUR INTO @SALEID, @CUSTID, @PRODID, @QTY, @PRICE, @SALEDATE
--     END
    
--     CLOSE @OUTCUR;
--     DEALLOCATE @OUTCUR;
-- END

-- STORED PROCEDURE #18
IF OBJECT_ID('COUNT_PRODUCT_SALES') IS NOT NULL
DROP PROCEDURE COUNT_PRODUCT_SALES;
GO

CREATE PROCEDURE COUNT_PRODUCT_SALES @PDAYS INT, @PCOUNT INT OUTPUT AS
BEGIN
    BEGIN TRY

    SELECT COUNT(SALEID) FROM SALE
    WHERE SALEDATE>=(GETDATE()-@PDAYS)

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO

-- TESTING:
-- DELETE FROM SALE
-- DELETE FROM PRODUCT
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10

-- DELETE FROM CUSTOMER
-- EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'Dummy One';

-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211004';
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211004';
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20201004';
-- SELECT * FROM PRODUCT
-- SELECT * FROM CUSTOMER
-- SELECT * FROM SALE

-- BEGIN
--     DECLARE @OUTPUTVALUE INT;
    
--     EXECUTE COUNT_PRODUCT_SALES @PDAYS = 0, @PCOUNT = @OUTPUTVALUE OUTPUT
--     PRINT (@OUTPUTVALUE);

--     EXECUTE COUNT_PRODUCT_SALES @PDAYS = 1, @PCOUNT = @OUTPUTVALUE OUTPUT
--     PRINT (@OUTPUTVALUE);

--     EXECUTE COUNT_PRODUCT_SALES @PDAYS = 11, @PCOUNT = @OUTPUTVALUE OUTPUT
--     PRINT (@OUTPUTVALUE);

--     EXECUTE COUNT_PRODUCT_SALES @PDAYS = 1000, @PCOUNT = @OUTPUTVALUE OUTPUT
--     PRINT (@OUTPUTVALUE);
-- END
-- GO

-- STORED PROCEDURE #19
IF OBJECT_ID('DELETE_SALE') IS NOT NULL
DROP PROCEDURE DELETE_SALE;
GO

CREATE PROCEDURE DELETE_SALE @saleid BIGINT OUTPUT AS
BEGIN
    BEGIN TRY
        DECLARE @SALEPCUSTID INT, @SALEPPRODID INT, @UPDATEAMT INT;

        SELECT @SALEID = MIN(SALEID) FROM SALE
        IF @SALEID IS NULL
            THROW 50280, 'No Sale Rows Found', 1
        
        SELECT @SALEPCUSTID = CUSTID FROM SALE
        WHERE SALEID = @SALEID;
        SELECT @SALEPPRODID = PRODID FROM SALE
        WHERE SALEID = @SALEID;
        SELECT @UPDATEAMT = QTY*PRICE FROM SALE
        WHERE SALEID = @SALEID;
        
        EXEC UPD_CUST_SALESYTD @pcustid = @salepcustid, @PAMT = @UPDATEAMT
        EXEC UPD_PROD_SALESYTD @prodid = @salepprodid, @PAMT = @UPDATEAMT

        DELETE FROM SALE
        WHERE SALEID = @SALEID;

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() in (50280)
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
GO

-- TESTING: 
DELETE FROM SALE
DELETE FROM PRODUCT
EXEC ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10

DELETE FROM CUSTOMER
EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'Dummy One';

EXEC ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211011';
EXEC ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211011';
SELECT * FROM PRODUCT
SELECT * FROM CUSTOMER
SELECT * FROM SALE

BEGIN
    DECLARE @OUTPUTVALUE BIGINT;
    EXEC DELETE_SALE @SALEID = @OUTPUTVALUE OUTPUT;
    PRINT (@OUTPUTVALUE);
END
GO

BEGIN
    DECLARE @OUTPUTVALUE BIGINT;
    EXEC DELETE_SALE @SALEID = @OUTPUTVALUE OUTPUT;
    PRINT (@OUTPUTVALUE);
END
GO

SELECT * FROM SALE

BEGIN
    DECLARE @OUTPUTVALUE BIGINT;
    EXEC DELETE_SALE @SALEID = @OUTPUTVALUE OUTPUT;
    PRINT (@OUTPUTVALUE);
END
GO

-- STORED PROCEDURE #20
IF OBJECT_ID('DELETE_ALL_SALES') IS NOT NULL
DROP PROCEDURE DELETE_ALL_SALES;
GO

CREATE PROCEDURE DELETE_ALL_SALES AS
BEGIN
    BEGIN TRY

        DELETE FROM SALE

        UPDATE CUSTOMER
        SET SALES_YTD=0;
        UPDATE PRODUCT
        SET SALES_YTD=0;        

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO

-- TESTING: 
-- DELETE FROM SALE 
-- DELETE FROM PRODUCT
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10

-- DELETE FROM CUSTOMER
-- EXECUTE ADD_CUSTOMER @PCUSTID = 1, @PCUSTNAME = 'Dummy One';

-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211004';
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211014';

-- SELECT * FROM PRODUCT
-- SELECT * FROM CUSTOMER
-- SELECT * FROM SALE

-- EXECUTE DELETE_ALL_SALES;


-- STORED PROCEDURE #21
IF OBJECT_ID('DELETE_CUSTOMER') IS NOT NULL
DROP PROCEDURE DELETE_CUSTOMER;
GO

CREATE PROCEDURE DELETE_CUSTOMER @pCustid INT AS
BEGIN
    BEGIN TRY

        DELETE FROM CUSTOMER
        WHERE CUSTID = @pCustid
        IF @@ROWCOUNT = 0
            THROW 50290, 'Customer ID not found', 1

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 547
            THROW 50300, 'Customer cannot be deleted as sales exist', 1
        ELSE if ERROR_NUMBER() in (50290)
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
GO

-- TESTING: 
-- DELETE FROM SALE 
-- DELETE FROM PRODUCT
-- EXECUTE ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10

-- DELETE FROM CUSTOMER
-- EXECUTE ADD_CUSTOMER @PCUSTID = 1, @PCUSTNAME = 'Dummy One';

-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211004';
-- EXECUTE ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20211014';

-- SELECT * FROM PRODUCT
-- SELECT * FROM CUSTOMER
-- SELECT * FROM SALE

-- DELETE FROM CUSTOMER 
-- WHERE CUSTID = 1

-- EXECUTE DELETE_CUSTOMER @PCUSTID = 1;
-- EXECUTE DELETE_ALL_SALES;
-- SELECT * FROM CUSTOMER 

-- STORED PROCEDURE #22
IF OBJECT_ID('DELETE_PRODUCT') IS NOT NULL
DROP PROCEDURE DELETE_PRODUCT;
GO

CREATE PROCEDURE DELETE_PRODUCT @pProdid INT AS
BEGIN
    BEGIN TRY

        DELETE FROM PRODUCT
        WHERE PRODID = @pProdid
        IF @@ROWCOUNT = 0
            THROW 50310, 'Product ID not found', 1

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 547
            THROW 50320, 'Product cannot be deleted as sales exist', 1
        ELSE if ERROR_NUMBER() in (50310)
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;
END;
GO
-- TESTING: 
-- DELETE FROM SALE
-- DELETE FROM PRODUCT
-- EXEC ADD_PRODUCT @PRODID = 2001, @PRODNAME ='Perfect', @PPRICE = 10

-- DELETE FROM CUSTOMER
-- EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'Dummy One';

-- EXEC ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20210821';
-- EXEC ADD_COMPLEX_SALE @pcustid = 1, @pprodid = 2001, @pqty = 10, @pdate = '20210811';
-- SELECT * FROM PRODUCT
-- SELECT * FROM CUSTOMER
-- SELECT * FROM SALE

-- EXECUTE DELETE_PRODUCT @pProdid = 2001;
-- EXECUTE DELETE_ALL_SALES;
-- EXECUTE DELETE_PRODUCT @pProdid = 2001;
-- SELECT * FROM PRODUCT
-- EXECUTE DELETE_PRODUCT @pProdid = 2001;


