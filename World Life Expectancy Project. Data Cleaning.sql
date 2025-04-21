# World Life Expectancy (Data Cleaning)

SELECT * 
FROM world_life_expectancy;

-- Identify if there are duplicates utilising Country and Year column

SELECT country, year, CONCAT(country, year), COUNT(CONCAT(country, year))
FROM world_life_expectancy
GROUP BY country, year, CONCAT(country, year)
HAVING COUNT(CONCAT(country, year)) > 1
;

-- 3 countries are duplicated: Ireland, Senegal and Zimbabwe. 
-- Next step is remove them from our dataset. For this, we'll look at their Row ID


SELECT *
FROM (
	SELECT Row_ID,
	CONCAT(country, year),
	ROW_NUMBER() OVER(PARTITION BY CONCAT(country, year) ORDER BY CONCAT(country, year)) AS Row_Num
	FROM world_life_expectancy
	) AS Row_table
WHERE Row_Num > 1
;

-- Now that we know the row number for these 3 countries, we are going to delete them from our table

DELETE FROM world_life_expectancy
WHERE 
	Row_ID IN (
		SELECT Row_ID
		FROM (
			SELECT Row_ID,
			CONCAT(country, year),
			ROW_NUMBER() OVER(PARTITION BY CONCAT(country, year) ORDER BY CONCAT(country, year)) AS Row_Num
			FROM world_life_expectancy
			) AS Row_table
		WHERE Row_Num > 1)
;

-- Next step is to identify how many blank or null there are

SELECT * 
FROM world_life_expectancy
WHERE status = ''
;

-- The query above threw 8 rows where Status is blank. I will use the status information those countries have in different year to populated in the missing fields
-- Firstly, I am making sure those countries have a Status 

SELECT DISTINCT(Status)
FROM world_life_expectancy
WHERE status <> ''
;

-- I have checked that all countries have either 'Developing' or 'Develop' as status. Now, let's see which ones have a 'Developing' status so it can be populated in those 8 that were missing

SELECT DISTINCT(Country)
FROM world_life_expectancy
WHERE Status = 'Developing'
;

UPDATE world_life_expectancy
SET Status = 'Developing'
WHERE Country IN (SELECT DISTINCT(Country)
				FROM world_life_expectancy
				WHERE Status = 'Developing')
;

-- The above query is not allowing me to do that change as expected so will try a work around (joining the table to itself)

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing'
;

-- This query has worked and 7 countries Status were populated in the missing fields. Now, I need to do the same for the Developed countries

SELECT * 
FROM world_life_expectancy
WHERE Country = 'United States of America';

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed'
;


-- Next step is to identify further blank or null fields

SELECT *
FROM world_life_expectancy
WHERE `Life expectancy` = ''
;

-- There are some blank field in Life Expectancy column (Afganistan 2018 and Albania 2018) and can see the average is increasing over the years. I will populate this fie1d (2018) with the avg between the previous and next year (2017 - 2019)

SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
;

-- We are going to follow the same step we have done previously, join the table to itself twice

SELECT t1.Country, t1.Year, t1.`Life expectancy`, 
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
	AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
	AND t1.Year = t3.Year + 1
;

-- Now that we have pulled the figures in year 2017 and 2019, the average needs to be done to fill the year 2018

 SELECT t1.Country, t1.Year, t1.`Life expectancy`, 
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
	AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
	AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = ''
;

-- Updating table 1 with the average calculated above


UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
	AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
	AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = ''
;


-- Checking the results after the update

SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
;


