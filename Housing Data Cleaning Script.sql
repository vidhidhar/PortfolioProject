/* 
 
CLEANING DATA USING SQL
 
*/

SELECT *
FROM NashvilleHousing nh 

-- 1. Standardising Date Format

SELECT SaleDate, DATE_FORMAT(STR_TO_DATE( SaleDate , '%M %e, %Y'), '%Y-%m-%d') AS ConverstedDate
FROM NashvilleHousing nh ;

UPDATE NashvilleHousing 
SET SaleDate = DATE_FORMAT(STR_TO_DATE( SaleDate , '%M %e, %Y'), '%Y-%m-%d') ;

-- 2. Populate Property Address Data

SELECT nh.ParcelID, nh.PropertyAddress , nh2.ParcelID , nh2.PropertyAddress 
FROM NashvilleHousing nh 
JOIN NashvilleHousing nh2 
	ON nh.ParcelID = nh2.ParcelID 
	AND nh.Uniqueid <> nh2.Uniqueid 
WHERE nh.PropertyAddress = ""

UPDATE NashvilleHousing nh
JOIN NashvilleHousing nh2 
	ON nh.ParcelID = nh2.ParcelID 
	AND nh.Uniqueid <> nh2.Uniqueid 
SET nh.PropertyAddress = CASE WHEN nh.PropertyAddress = '' THEN nh2.PropertyAddress ELSE nh.PropertyAddress END 
WHERE nh.PropertyAddress = ""	

-- 3. Breaking Out Address into Individual Columns (Address, City, State)

	-- 3(a) Property Address

SELECT PropertyAddress,
SUBSTRING_INDEX(PropertyAddress, ',',1 ) AS Address,
SUBSTRING_INDEX(PropertyAddress, ',',-1 ) AS City
FROM NashvilleHousing nh 

ALTER TABLE NashvilleHousing 
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing 
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1 );

ALTER TABLE NashvilleHousing 
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing 
SET PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1 );

	-- 3(b) Owner Address

SELECT OwnerAddress
FROM NashvilleHousing nh 

SELECT OwnerAddress,
SUBSTRING_INDEX(OwnerAddress, ',', 1 ) AS Address,
SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress, ',', 2)), ',', -1) AS City,
SUBSTRING_INDEX(OwnerAddress, ',', -1 ) AS State
FROM NashvilleHousing nh 

ALTER TABLE NashvilleHousing 
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing 
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1 );

ALTER TABLE NashvilleHousing 
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing 
SET OwnerSplitCity = SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress, ',', 2)), ',', -1);

ALTER TABLE NashvilleHousing 
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing 
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1 );

-- 4. Change Y and N to Yes and No in SoldAsVacant Field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing nh 
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN "Yes"
	 WHEN SoldAsVacant = 'N' THEN "No"
	 ELSE SoldAsVacant 
	 END
FROM NashvilleHousing nh 

UPDATE NashvilleHousing 
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN "Yes"
	 WHEN SoldAsVacant = 'N' THEN "No"
	 ELSE SoldAsVacant 
	 END

-- 5. Remove Duplicates

	 -- 5a. Selecting
WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER () OVER (PARTITION BY ParcelID, 
								 PropertyAddress, 
								 SaleDate, 
								 SalePrice, 
								 LegalReference 
								 ORDER BY Uniqueid) RowNum
FROM NashvilleHousing nh )
SELECT *
FROM RowNumCTE
WHERE RowNum > 1

	-- 5b. Deleting 
DELETE nh
FROM NashvilleHousing nh
JOIN (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ParcelID, 
                                         PropertyAddress, 
                                         SaleDate, 
                                         SalePrice, 
                                         LegalReference 
                            ORDER BY Uniqueid) AS RowNum
    FROM NashvilleHousing
) AS RowNumCTE
ON nh.Uniqueid = RowNumCTE.Uniqueid
WHERE RowNum != 1;

-- 6. Delete unused columns

ALTER TABLE NashvilleHousing 
DROP COLUMN PropertyAddress, 
DROP COLUMN OwnerAddress;




