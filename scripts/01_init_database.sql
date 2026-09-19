/*
===============================================================================
Script Name   : 01_init_database.sql
Description   : Creates the 'DataWarehouse' database and its primary schemas 
                (bronze, silver, gold) for the Medallion Architecture.
Author        : Omar
Date          : 2026-09-14
===============================================================================

This script safely initializes the DataWarehouse database and creates three 
core schemas (bronze, silver, gold) based on the Medallion Architecture. 
It uses IF NOT EXISTS logic to allow safe, repeated execution without 
overwriting data or throwing errors.

*/

USE master;
GO

-- 1. Create DataWarehouse
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'DataWarehouse')
BEGIN
    CREATE DATABASE DataWarehouse;
    PRINT 'Database "DataWarehouse" created successfully.';
END
ELSE
BEGIN
    PRINT 'Database "DataWarehouse" already exists.';
END
GO

-- 2. Create bronze
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze;');
    PRINT 'Schema "bronze" created successfully.';
END
GO

-- 3. Create silver
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'silver')
BEGIN
    EXEC('CREATE SCHEMA silver;');
    PRINT 'Schema "silver" created successfully.';
END
GO

-- 4. Create gold
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'gold')
BEGIN
    EXEC('CREATE SCHEMA gold;');
    PRINT 'Schema "gold" created successfully.';
END
GO
