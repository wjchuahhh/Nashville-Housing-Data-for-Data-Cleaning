-- Selecting all columns for quick visual inspection

select * from [Nashville Housing]..NashvilleHousing


-- Standardize SaleDate by removing the time (2014-06-10 00:00:00.000 --> 2014-06-10)

select SaleDate, convert(date, SaleDate)
from [Nashville Housing]..NashvilleHousing

alter table NashvilleHousing -- adding new column for converting date format
add SaleDateConverted date;

Update NashvilleHousing
SET SaleDateConverted = convert(date, SaleDate)


-- Populate PropertyAddress column to fill in NULL fields using ParcelID as a reference

select *
from [Nashville Housing]..NashvilleHousing
order by ParcelID

select t1.ParcelID, t1.PropertyAddress,t2.ParcelID, t2.PropertyAddress -- to inspect if join is working as expected
from [Nashville Housing]..NashvilleHousing as t1
join [Nashville Housing]..NashvilleHousing as t2
on t1.ParcelID = t2.ParcelID and t1.[UniqueID ] <> t2.[UniqueID ]
where t1.PropertyAddress is null

update t1 -- updating t1 using ISNULL function 
set PropertyAddress = isnull(t1.PropertyAddress,t2.PropertyAddress)
from [Nashville Housing]..NashvilleHousing as t1
join [Nashville Housing]..NashvilleHousing as t2
on t1.ParcelID = t2.ParcelID and t1.[UniqueID ] <> t2.[UniqueID ]
where t1.PropertyAddress is null


-- Breaking Out PropertyAddress into different columns (Address, City)

select -- using subtring and charindex to manipulate address string. Query allows us to see if we are getting intended results
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as City 
from [Nashville Housing]..NashvilleHousing

alter table NashvilleHousing -- adding new column for Property Address
add PropertySplitAddress nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

alter table NashvilleHousing -- adding new column for Property City
add PropertySplitCity nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))


-- Breaking OwnerAddress to different columns (Address, City, State)

select -- using PARSENAME. PARSENAME only recognises '.' so we have to replace ',' in string to '.' and it starts reading the string backwards.
	PARSENAME(replace(OwnerAddress, ',','.'),1),
	PARSENAME(replace(OwnerAddress, ',','.'),2),
	PARSENAME(replace(OwnerAddress, ',','.'),3)
from [Nashville Housing]..NashvilleHousing

alter table NashvilleHousing -- adding new column for Owner Address
add OwnerSplitAddress nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(replace(OwnerAddress, ',','.'),3)

alter table NashvilleHousing -- adding new column for Owner City
add OwnerSplitCity nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(replace(OwnerAddress, ',','.'),2)

alter table NashvilleHousing -- adding new column for Owner State
add OwnerSplitState nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(replace(OwnerAddress, ',','.'),1)


-- Update SoldAsVacant column to only contain Yes and No

select distinct SoldAsVacant,COUNT(SoldAsVacant) -- to check what are the different entries for the column initially
from [Nashville Housing]..NashvilleHousing
group by SoldAsVacant
order by 2

select SoldAsVacant, -- using CASE to change entries to make them uniform (this step doesn't update the table, it just assist in checking if result is as expected)
	case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end as newSoldAsVacant
from [Nashville Housing]..NashvilleHousing

Update NashvilleHousing -- this step will update the table based on case statement
SET SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
						else SoldAsVacant
						end


-- Remove duplicate rows using CTE (removing of records usually not done on raw data. Usually done on Views)
with RemoveDuplicates as(
select *,
	ROW_NUMBER() over (
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by
					UniqueID
				 ) as row_num
from [Nashville Housing]..NashvilleHousing
)
DELETE
from RemoveDuplicates
where row_num > 1 -- if row_num > 1 then it is a duplicate row.


-- Delete unused columns (once again, this is not usually done on raw data itself. Usually done on Views)

alter table [Nashville Housing]..NashvilleHousing
drop column PropertyAddress, OwnerAddress, SaleDate -- these are columns which were cleaned previously