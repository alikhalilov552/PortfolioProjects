/*

Cleaning Data in SQL Queries

*/

SELECT 
    saledate, saledate_converted
FROM
    portfolio_project_2.nashville_housing;
    
---------------------------------------------------------------------------------
    
-- Standardize Date Format
-- Issue resolution: There were 3 values in different format in SaleDate column. Specifically '20160628-0065980', '20150407-0030110'. 

SELECT 
    saledate,
    STR_TO_DATE(saledate, '%M %e, %Y') AS converted_date
FROM
    portfolio_project_2.nashville_housing
WHERE
    saledate LIKE '%-%'; 

-- Firstly, I had used UPDATE statement together with SUBSTRING to delete the right side of hyphen together with hyphen.
    
UPDATE portfolio_project_2.nashville_housing 
SET 
    saledate = SUBSTRING(saledate,
        1,
        INSTR(saledate, '-') - 1)
WHERE
    saledate LIKE '%-%';  

-- Update VARCHAR value in the SaleDate column to Date format
    
UPDATE portfolio_project_2.nashville_housing 
SET 
    saledate = STR_TO_DATE(saledate, '%Y%m%d')
WHERE
    saledate in ('20150407', '20160628');


SELECT 
    saledate_converted
FROM
    portfolio_project_2.nashville_housing;

-- Add a new column to the table for converted saledate in date format
   
Alter table portfolio_project_2.nashville_housing
add saledate_converted date;

-- UPDATE converted saledate with the converted date values of saledate column excluding '2016-06-28', '2015-04-07' because their format is different

UPDATE portfolio_project_2.nashville_housing 
SET 
    saledate_converted = CASE
        WHEN saledate NOT IN ('2016-06-28' , '2015-04-07') THEN STR_TO_DATE(saledate, '%M %e, %Y')
        ELSE saledate_converted
    END;
    
-- UPDATE last 2 values add them to the converted saledate column
-- UPDATE 3 empty cells set them NULL
  
UPDATE portfolio_project_2.nashville_housing 
SET 
    saledate_converted = CASE
	    WHEN saledate = '' THEN NULL 
        WHEN saledate IN ('2016-06-28' , '2015-04-07') THEN saledate
        ELSE saledate_converted
    END;

---------------------------------------------------------------------------------------------    
-- POPULATE PROPERTY ADDRESS DATA
-- Check how many empty cells exist in propertyaddress column (32 exists)

SELECT 
    propertyaddress
FROM
    portfolio_project_2.nashville_housing
WHERE
    propertyaddress = '';

-- Update 32 existing empty cells set them as null

UPDATE portfolio_project_2.nashville_housing 
SET 
    propertyaddress = NULL
WHERE
    propertyaddress = '';

-- Check if update succeeded

SELECT 
   propertyaddress
FROM
    portfolio_project_2.nashville_housing
WHERE
    propertyaddress IS NULL;

-- There are 3 rows which does not contain any data. Use Delete statement to delete 3 rows from the database

DELETE FROM portfolio_project_2.nashville_housing 
WHERE
    propertyaddress IS NULL;
    
-- There are the same parcelIDs in the dataset which include propertyaddresses of the clients which can help us to fill these null values
-- Join the same table with itself on parcelID and <> uniqueID to pull property addresses
-- Used ifnull function to see what will be replaced with null values

SELECT 
    a_nh.ParcelID,
    a_nh.PropertyAddress,
    b_nh.ParcelID,
    b_nh.PropertyAddress,
    IFNULL(a_nh.propertyaddress,
            b_nh.propertyaddress)
FROM
    portfolio_project_2.nashville_housing a_nh
        JOIN
    portfolio_project_2.nashville_housing b_nh ON a_nh.ParcelID = b_nh.ParcelID
        AND a_nh.UniqueID_ <> b_nh.UniqueID_
WHERE
    a_nh.propertyaddress IS NULL;

-- Update null values with corressponding addresses by the help of parcelID
    
UPDATE portfolio_project_2.nashville_housing a_nh
        JOIN
    portfolio_project_2.nashville_housing b_nh ON a_nh.ParcelID = b_nh.ParcelID
        AND a_nh.UniqueID_ <> b_nh.UniqueID_ 
SET 
    a_nh.propertyaddress = IFNULL(a_nh.propertyaddress,
            b_nh.propertyaddress)
WHERE
    a_nh.propertyaddress IS NULL;

-----------------------------------------------------------------------------------------
-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

SELECT PROPERTYADDRESS
FROM portfolio_project_2.nashville_housing;

-- Used SUBSTRING and INSTR functions together to split propertyaddress 2 parts. First part before comma is the address, second part after comma is the name of the city.

SELECT 
    SUBSTRING(PROPERTYADDRESS, 1, INSTR(PROPERTYADDRESS, ',') - 1) AS ADDRESS,
    SUBSTRING(PROPERTYADDRESS, INSTR(PROPERTYADDRESS, ',')+1, length(PropertyAddress)) AS CITY
FROM
    portfolio_project_2.nashville_housing;
    
-- Altering table adding 2 more columns for the splitted property address

alter table portfolio_project_2.nashville_housing
add property_split_address varchar(250),
add property_split_city varchar(250);

-- Update add property split data into corresponding columns

UPDATE portfolio_project_2.nashville_housing
SET PROPERTY_SPLIT_ADDRESS = SUBSTRING(PROPERTYADDRESS, 1, INSTR(PROPERTYADDRESS, ',') - 1);

UPDATE portfolio_project_2.nashville_housing
SET PROPERTY_SPLIT_CITY = SUBSTRING(PROPERTYADDRESS, INSTR(PROPERTYADDRESS, ',')+1, length(PropertyAddress));

-- Check if succeeded

SELECT 
    property_split_address, property_split_city
FROM
    portfolio_project_2.nashville_housing;
    
-- Update Owner Address    

SELECT 
    owneraddress,
    owneraddress_split,
    owneraddress_city,
    owneraddress_state,
    SUBSTRING_INDEX(owneraddress, ',', 1),
    SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', - 1),
    SUBSTRING_INDEX(owneraddress, ',', - 1)
FROM
    portfolio_project_2.nashville_housing;
    
-- Alter table to add 3 new columns for splitted owner addresses    

alter table portfolio_project_2.nashville_housing
add owneraddress_split varchar(250),
add owneraddress_city varchar (250),
add owneraddress_state varchar (250);

-- Update columns with new data

UPDATE portfolio_project_2.nashville_housing 
SET 
    owneraddress_split = SUBSTRING_INDEX(owneraddress, ',', 1);

UPDATE portfolio_project_2.nashville_housing 
SET 
    owneraddress_city = SUBSTRING_INDEX(SUBSTRING_INDEX(owneraddress, ',', 2), ',', - 1);

UPDATE portfolio_project_2.nashville_housing 
SET 
    owneraddress_state = SUBSTRING_INDEX(owneraddress, ',', - 1);
    
-- Update owner address and new columns with NULL where the cell is empty

UPDATE portfolio_project_2.nashville_housing 
SET 
    OWNERADDRESS = NULL,
    owneraddress_split = NULL,
    owneraddress_city = NULL,
    owneraddress_state = NULL
WHERE
    OWNERADDRESS = ''
        AND owneraddress_split = ''
        AND owneraddress_city = ''
        AND owneraddress_state = '';

-------------------------------------------------------------------------------------

-- CHANGE Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD
-- Checking the count of 'N' and 'Y' values

SELECT DISTINCT
    (soldasvacant), COUNT(soldasvacant)
FROM
    portfolio_project_2.nashville_housing
GROUP BY soldasvacant
ORDER BY 2;

-- Checking the UPDATE statement how will it perform before updating

SELECT 
    soldasvacant,
    CASE
        WHEN soldasvacant = 'Y' THEN 'Yes'
        WHEN soldasvacant = 'N' THEN 'No'
        ELSE soldasvacant
    END
FROM
    portfolio_project_2.nashville_housing;
    
UPDATE portfolio_project_2.nashville_housing 
SET 
    soldasvacant = CASE
        WHEN soldasvacant = 'Y' THEN 'Yes'
        WHEN soldasvacant = 'N' THEN 'No'
        ELSE soldasvacant
    END;



------------------------------------------------------------------------------------------

-- REMOVE THE DUPLICATES

WITH RowNumCTE AS( 
SELECT *,
row_number() over (
partition by parcelid, propertyaddress, saleprice, saledate, legalreference
order by uniqueid_ 
) row_num
 FROM portfolio_project_2.nashville_housing
 )
 DELETE FROM ROWNUMCTE
 WHERE ROW_NUM > 1
 ORDER BY PROPERTYADDRESS; 
 
------------------------------------------------------------------------------------------

-- DELETE UNUSED COLUMNS

SELECT * FROM portfolio_project_2.nashville_housing;

ALTER TABLE portfolio_project_2.nashville_housing
DROP COLUMN OWNERADDRESS, 
DROP COLUMN TAXDISTRICT,  
DROP COLUMN PROPERTYADDRESS,
DROP COLUMN SALEDATE;

------------------------------------------------------------------------------------------
