-- SELECT * FROM mCovidDeaths mcd 
-- ORDER BY 3,4;
-- 
-- SELECT * FROM mCovidVaccinations mcv 
-- ORDER BY 3,4;

SELECT location, `date` , total_cases , new_cases , total_deaths , population , continent 
FROM mCovidDeaths mcd  
WHERE continent != ''
ORDER BY 1,2

SELECT continent , SUM(total_vaccinations)  
FROM mCovidVaccinations mcv 
WHERE continent != ''
GROUP BY continent 
ORDER BY 1

-- 1. Total Cases vs Total Deaths
-- Likelihood of Dying if you contract Covid in your Country

SELECT location, `date` , total_cases , total_deaths , (total_deaths/total_cases)*100 AS DeathPercentage
FROM mCovidDeaths mcd 
WHERE location = 'India' and continent NOT IN ('')
ORDER BY 1,2

--  Likelihood of Dying if you contract Covid in UK, USA 

SELECT location, `date` , total_cases , total_deaths , (total_deaths/total_cases)*100 AS DeathPercentage
FROM mCovidDeaths mcd 
WHERE location IN ('United Kingdom', 'United States') and continent NOT IN ('')
ORDER BY 1,2

-- 2. Total cases vs Population
-- Percentage of population who got Covid in your country

SELECT location, `date` , total_cases , population , (total_cases/population)*100 AS CasesPercentage  
FROM mCovidDeaths mcd
WHERE location = 'India' and continent NOT IN ('')
ORDER BY 1,2

-- Percentage of population who got Covid in UK, USA

SELECT location, `date` , total_cases , population , (total_cases/population)*100 AS CasesPercentage  
FROM mCovidDeaths mcd
WHERE location IN ('United Kingdom', 'United States') and continent NOT IN ('')
ORDER BY 1,2

-- 3. Highest Infection Rate in each country

SELECT location, population , MAX(total_cases) AS MaxCases, MAX((total_cases/population))*100 AS MaxInfected  
FROM mCovidDeaths mcd
WHERE continent NOT IN ('')
GROUP BY location, population 
ORDER BY MaxInfected DESC

-- 4. Total cases and Total deaths in each country  
SELECT location, population , SUM(total_cases), SUM(total_deaths), MAX((total_cases/population))*100 AS MaxInfected  
FROM mCovidDeaths mcd
WHERE continent NOT IN ('')
GROUP BY location, population 
ORDER BY MaxInfected DESC

-- 5. Highest Death Count per population in each country 

SELECT location, population , MAX(total_deaths) AS MaxDeath, MAX((total_deaths /population))*100 AS MaxDeathCount  
FROM mCovidDeaths mcd
WHERE continent != ''
GROUP BY location, population 
ORDER BY MaxDeath DESC

-- 6. Highest Death Count in each continent

SELECT continent , MAX(total_deaths) AS MaxDeath 
FROM mCovidDeaths mcd
WHERE continent != ''
GROUP BY continent 
ORDER BY MaxDeath DESC

-- 7. Global Numbers

-- Total cases and Total deaths per day in the world

SELECT `date` , SUM(total_cases) AS TotalCasesGLobally, SUM(total_deaths) AS TotalDeathsGlobally, (SUM(total_deaths)/SUM(total_cases))*100 AS ToatlDeathsGlobally
FROM mCovidDeaths mcd
WHERE continent != ''
GROUP BY `date` 
ORDER BY 1

-- Total cases and Total deaths in the world

SELECT SUM(total_cases) AS TotalCasesGLobally, SUM(total_deaths) AS TotalDeathsGlobally, (SUM(total_deaths)/SUM(total_cases))*100 AS ToatlDeathsGlobally
FROM mCovidDeaths mcd
WHERE continent != ''
ORDER BY 1

-- New cases and new deaths per day in the world

SELECT `date` , SUM(new_cases) AS NewCasesGLobally, SUM(new_deaths) AS NewDeathsGlobally, (SUM(new_deaths)/SUM(new_cases))*100 AS NewDeathsPercentageGlobally
FROM mCovidDeaths mcd
WHERE continent != ''
GROUP BY `date` 
ORDER BY 1


-- New cases and new deaths in the world

SELECT SUM(new_cases) AS NewCasesGLobally, SUM(new_deaths) AS NewDeathsGlobally, (SUM(new_deaths)/SUM(new_cases))*100 AS NewDeathsPercentageGlobally
FROM mCovidDeaths mcd
WHERE continent != ''
ORDER BY 1

-- 8. Both tables

-- Total population VS Total Vaccinations

SELECT mcd.continent, mcd.location, mcd.`date` , mcd.population , mcv.total_vaccinations 
FROM mCovidDeaths mcd 
JOIN mCovidVaccinations mcv 
	ON mcd.location = mcv.location AND mcd.date = mcv.date
WHERE mcd.continent != ''
ORDER BY 2,3

-- Total population VS New Vaccinations

SELECT mcd.continent, mcd.location, mcd.`date` , mcd.population , mcv.new_vaccinations
FROM mCovidDeaths mcd 
JOIN mCovidVaccinations mcv 
	ON mcd.location = mcv.location AND mcd.date = mcv.date
WHERE mcd.continent != ''
ORDER BY 2,3

-- Rolling count of vaccination 

SELECT mcd.continent, mcd.location, mcd.`date` , mcd.population , mcv.new_vaccinations,
SUM(mcv.new_vaccinations) OVER (PARTITION BY mcv.location ORDER BY location, `date`) AS RollingPeopleVac
FROM mCovidDeaths mcd 
JOIN mCovidVaccinations mcv 
	ON mcd.location = mcv.location AND mcd.date = mcv.date
WHERE mcd.continent != ''
ORDER BY 2,3

-- 9. USING CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations , RollingPeopleVac) AS
(SELECT mcd.continent, mcd.location, mcd.`date` , mcd.population , mcv.new_vaccinations,
SUM(mcv.new_vaccinations) OVER (PARTITION BY mcv.location ORDER BY location, `date`) AS RollingPeopleVac
FROM mCovidDeaths mcd 
JOIN mCovidVaccinations mcv 
	ON mcd.location = mcv.location AND mcd.date = mcv.date
WHERE mcd.continent != ''
ORDER BY 2,3)

-- 9.1

-- SELECT *, (RollingPeopleVac/Population)*100 AS PopvsVacPercent
-- FROM PopvsVac

-- 9.2

SELECT continent, location, population, (MAX(RollingPeopleVac/Population))*100 AS PopvsVacPercent
FROM PopvsVac
GROUP BY 1,2,3
ORDER BY PopvsVacPercent DESC

-- 10. USING TEMP TABLE

DROP TEMPORARY TABLE IF EXISTS PopVacPercent;

CREATE TEMPORARY TABLE PopVacPercent
SELECT mcd.continent, 
	   mcd.location, 
	   mcd.`date`, 
	   mcd.population, 
	   mcv.new_vaccinations,
	   SUM(mcv.new_vaccinations) OVER (PARTITION BY mcv.location ORDER BY location, `date`) AS RollingPeopleVac
FROM mCovidDeaths mcd 
JOIN mCovidVaccinations mcv 
	ON mcd.location = mcv.location AND mcd.date = mcv.date
WHERE mcd.continent != ''
ORDER BY 2,3;

SELECT *, (RollingPeopleVac/Population)*100 AS PopvsVacPercent
FROM PopVacPercent;

-- 11. Creating VIEW to store data for Visualisation

CREATE VIEW PopVacPercent AS
SELECT mcd.continent, 
	   mcd.location, 
	   mcd.`date`, 
	   mcd.population, 
	   mcv.new_vaccinations,
	   SUM(mcv.new_vaccinations) OVER (PARTITION BY mcv.location ORDER BY location, `date`) AS RollingPeopleVac
FROM mCovidDeaths mcd 
JOIN mCovidVaccinations mcv 
	ON mcd.location = mcv.location AND mcd.date = mcv.date
WHERE mcd.continent != ''
ORDER BY 2,3;

SELECT * 
FROM PopVacPercent





