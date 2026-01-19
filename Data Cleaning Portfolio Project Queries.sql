/*

Cleaning Data in SQL Queries
Before cleaning data, remember to keep a copy of the same table you are working on in order to avoid any errors or the need to reimport the dataset
*/

select * 
from PortfolioProject.dbo.NashvilleHousing;

-- A copy of the NashvilleHousing table 
select * into 
NashvilleHousing_Backup
from PortfolioProject.dbo.NashvilleHousing;


----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1. Standardize Date Format


select SaleDate, CONVERT(Date,SaleDate)
from PortfolioProject.dbo.NashvilleHousing;

Update PortfolioProject.dbo.NashvilleHousing
Set SaleDate = CONVERT(Date,SaleDate);

-- If the above one doesn't work properly

select SaleDate, SaleDateConverted
from PortfolioProject.dbo.NashvilleHousing;

Alter Table PortfolioProject.dbo.NashvilleHousing
Add SaleDateConverted Date;

Update PortfolioProject.dbo.NashvilleHousing
Set SaleDateConverted = CONVERT(Date,SaleDate);


-- Checking with the copy of the table
-- Method 1 (Working fine)
/*

Alter Table PortfolioProject.dbo.NashvilleHousing_Backup
Add SaleDateConverted Date;

Update PortfolioProject.dbo.NashvilleHousing_Backup
Set SaleDateConverted = Convert(Date, SaleDate);

select *
from PortfolioProject.dbo.NashvilleHousing_Backup;

*/

-- Method 2 (Not working)
-- Have to check once later
/*

Alter Table PortfolioProject.dbo.NashvilleHousing_Backup
Alter Column SaleDate Date;

*/


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Populate Property Address data (Filling the NULL values)

select *
from PortfolioProject.dbo.NashvilleHousing
--where PropertyAddress is null
order by ParcelID;

-- Using SELF JOIN and ISNULL method
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
    on a.ParcelID = b.ParcelID
    and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
    on a.ParcelID = b.ParcelID
    and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. Breaking out Address into Individual Columns (Address, City, State)

select PropertyAddress, PropertySplitAddress, PropertySplitCity
from PortfolioProject.dbo.NashvilleHousing;

--Method 1 (Using SUBSTRING with CHARINDEX method)
select 
substring(PropertyAddress,1,charindex(',', PropertyAddress) - 1) as Address,
substring(PropertyAddress,charindex(',', PropertyAddress) + 1,LEN(PropertyAddress)) as City
from PortfolioProject.dbo.NashvilleHousing;


Alter Table PortfolioProject.dbo.NashvilleHousing
Add PropertySplitAddress nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set PropertySplitAddress = substring(PropertyAddress,1,charindex(',', PropertyAddress) - 1);

Alter Table PortfolioProject.dbo.NashvilleHousing
Add PropertySplitCity nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set PropertySplitCity = substring(PropertyAddress,charindex(',', PropertyAddress) + 1,LEN(PropertyAddress));


-- Method 2 (Using PARSENAME method) (A bit easier than previous method)
select OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
from PortfolioProject.dbo.NashvilleHousing;


select
PARSENAME(replace(OwnerAddress, ',', '.'), 3) as OwnerSplitAddress,
PARSENAME(replace(OwnerAddress, ',', '.'), 2) as OwnerSplitCity,
PARSENAME(replace(OwnerAddress, ',', '.'), 1) as OwnerSplitState 
from PortfolioProject.dbo.NashvilleHousing;


Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitAddress = PARSENAME(replace(OwnerAddress, ',', '.'), 3);


Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitCity = PARSENAME(replace(OwnerAddress, ',', '.'), 2);


Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitState = PARSENAME(replace(OwnerAddress, ',', '.'), 1);


---------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. Change Y and N to Yes and No in 'Sold as Vacant' field

select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing
group by SoldAsVacant
order by 2;


select SoldAsVacant
, CASE when SoldAsVacant = 'Y' THEN 'Yes'
       when SoldAsVacant = 'N' THEN 'No'
       else SoldAsVacant
  END as SoldAsVacantUpdated
from PortfolioProject.dbo.NashvilleHousing
-- where SoldAsVacant = 'N';  

Update PortfolioProject.dbo.NashvilleHousing
Set SoldAsVacant = CASE when SoldAsVacant = 'Y' THEN 'Yes'
       when SoldAsVacant = 'N' THEN 'No'
       else SoldAsVacant
       END


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5. Remove Duplicates

WITH RowNumCTE AS(
select *, 
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER by UniqueID
                 ) as row_num
from PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
-- We deleted those rows which had a row number greater than 1. 
select *
from RowNumCTE
where row_num > 1
order by PropertyAddress;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. Delete Unused Columns (Not recommended when dealing with raw data)

select *
from PortfolioProject.dbo.NashvilleHousing;


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate 


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------









-- ETL (Extract, Transform and Load)
-- Try this out if you want to explore more


-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO


