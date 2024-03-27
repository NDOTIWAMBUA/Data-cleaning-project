SELECT * FROM project2.housings;
----- STANDARDIZE THE DATE FORMAT
DROP temporary TABLE IF exists tempo;
create temporary table tempo as
select *,str_to_date(SaleDate, '%M %d,%Y') as newsaledateupdated
FROM project2.housings;
select *
from tempo;
update project2.housings as t
join tempo as tem on t.UniqueID = tem.UniqueID 
set t.SaleDate = tem.newsaledateupdated;
------------------------------------------------------------------------------------------------------
----- POPULATE THE PROPERTY ADRESS
select *
FROM project2.housings
where PropertyAddress like ''
-- where PropertyAddress is NULL
order by ParcelID;

select ifnull(PropertyAddress,'')as newpropertyadress
FROM project2.housings;
 
update a
set PropertyAddress= ifnull(a.PropertyAddress, b.PropertyAddress);
select *
from project2.housings as a
join project2.housings as b
on a.ParcelID=b. ParcelID
and a.UniqueID <> b.UniqueID
where a.PropertyAddress IS NULL;

----- BREAKING UP INDIVIDUAL COLUMNS
---- i.e ADRESS INTO ADRESS,CITY, STATE
select UniqueID ,PropertyAddress
from project2.housings;
         
select PropertyAddress,
Replace(substring_index(PropertyAddress,' ',1),',', '') as Address,
replace(substring_index(substring_index(PropertyAddress,',',1),' ',-2),' ',' ') as City,
Replace(substring_index(PropertyAddress,' ',-1),',', '') as State
from project2.housings;

-- COLUMNS TO HOLD THE SPLIT VALUES
alter table project2.housings
add column PropertySplitAdress varchar(255);
alter table project2.housings
add column PropertySplitCity varchar(255);
alter table project2.housings
add column PropertySplitState varchar(255);

-- TEMPORARY TABLE TO STORE THE SPLIT VALUES
DROP temporary TABLE IF exists ad;
create temporary table ad as
select *,
Replace(substring_index(PropertyAddress,' ',1),',', '') as Address,
replace(substring_index(substring_index(PropertyAddress,',',1),' ',-2),' ',' ') as City,
Replace(substring_index(PropertyAddress,' ',-1),',', '') as State
FROM project2.housings;
select *
from ad;

-- UPDATING ORIGINAL TABLE USING THE TEMPORARY TABLE
update project2.housings as t
join ad as b on t.UniqueID = b.UniqueID 
set t.PropertySplitAdress = b.Address;
update project2.housings as t
join ad as b on t.UniqueID = b.UniqueID 
set t.PropertySplitCity = b.City;
update project2.housings as t
join ad as b on t.UniqueID = b.UniqueID 
set t.PropertySplitState = b.State;

-- VIEW THE UPDATES
select *
FROM project2.housings;

--- i.e OWNER ADDRESS
select OwnerAddress
FROM project2.housings;

select 
parsename(replace(PropertyAddress,',' ,'.'),3),
parsename(replace(PropertyAddress,',' ,'.'),2),
parsename(replace(PropertyAddress,',' ,'.'),1)
from project2.housings;
 
----- CHANGE Y AND N TO YES AND NO IN 'SOLD AS VACANT' FIELD
SELECT distinct(SoldAsVacant), count(SoldAsVacant)
from project2.housings
group by SoldAsVacant
order by 2;

select SoldAsVacant,
  case 
   when SoldAsVacant = 'Y' then 'Yes'
   when SoldAsVacant = 'N' then 'No'
   else SoldAsVacant
   end
from project2.housings;

DROP temporary TABLE IF exists sale;
create temporary table sale as
select *,
case 
   when SoldAsVacant = 'Y' then 'Yes'
   when SoldAsVacant = 'N' then 'No'
   else SoldAsVacant
   end as newsoldas
FROM project2.housings;
update project2.housings as t
join sale as s on t.UniqueID = s.UniqueID 
set t.SoldAsVacant = s.newsoldas
;
select *
from project2.housings;

----- REMOVE DUPLICATES
with rowcte as (
 select*,
  row_number ()over (partition by  ParcelID,
                                 PropertyAddress,
                                 SalePrice,
                                 SaleDate,
                                 LegalReference order by UniqueID) as row_num
from project2.housings
order by UniqueID
)
delete 
from rowcte
where row_num >1;
select *
from rowcte 
where row_num >1;

----- DELETING UNUSED COLUMNS
alter table project2.housings
drop column newdate;

alter table project2.housings
drop column PropertyAddress;

select *
FROM project2.housings