--- Cleaning Data in SQL Queries
SELECT * FROM PortfolioProject..NashvilleHousing

-- Standardize Date Format
SELECT SaleDate, CONVERT(DATE, SaleDate) FROM PortfolioProject..NashvilleHousing

--UPDATE function is not working
UPDATE NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate)

--Use ALTER as an solution
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)

SELECT SaleDateConverted FROM PortfolioProject..NashvilleHousing

-- Populate Property Address Data by joining the same tables twice where it has the same parcel id but different unique id.
-- Many of these columns have null property address, however there are other properties (with unique uniqueid) that have the same parcel id so we assume they also have the same property address
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM PortfolioProject..NashvilleHousing A
JOIN PortfolioProject..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID] <> B.[UniqueID]
WHERE A.PropertyAddress IS NULL 

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM PortfolioProject..NashvilleHousing A
JOIN PortfolioProject..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL 

-- Breaking Out Address Into Individual Columns (Address, City, State)
SELECT PropertyAddress, 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as 'Address',
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as 'State'
FROM PortfolioProject..NashvilleHousing;

-- Add 2 New Columns:
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress VARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity VARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Seperate Owner Address Using PARSENAME (only useful with commas)
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress VARCHAR(255);

--Update 3 New Columns:
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity VARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState VARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y and N to Yes and No in "Sold As Vacant" Column:
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC;

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'N' THEN 'No'
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant
END AS Test
FROM PortfolioProject..NashvilleHousing

-- Update Column
UPDATE NashvilleHousing
SET SoldAsVacant = 
CASE
	WHEN SoldAsVacant = 'N' THEN 'No'
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant
END

-- Remove Duplicates (Not Standard)
-- First Delete: Assume that if the row has the same ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference then it is a duplicate
-- Then because they are partitioned into row_num, we will delete the row which has row_num > 1
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)
DELETE
From RowNumCTE
WHERE row_num > 1

-- Then Check!
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)
SELECT *
From RowNumCTE
Where row_num > 1

-- Delete Unused Columns
Select *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
