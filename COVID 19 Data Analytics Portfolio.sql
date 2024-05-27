USE PortfolioProject

SELECT *
FROM CovidDeaths
ORDER BY 3,4

SELECT * FROM CovidVacinations
ORDER BY location, datecol

--TO ALTER THE TABLE, BECAUSE THE DATE IS VARCHAR NOT DATE
begin tran

alter table covidVacinations
add datecol datetime

update covidVacinations
set datecol = date

ALTER TABLE covidDeaths
DROP [date]

rollback

COMMIT

--TOTAL CASE VS TOTAL DEATH
--Death percentage (showing the death percentage each day)
SELECT location, datecol, total_cases, total_deaths, (CAST(total_deaths as float)/CAST(total_cases as float))*100 as DeathPercentage
FROM CovidDeaths
WHERE total_cases <> 0
order by 1,2 

-- More detailed version (showing how many cases and deaths per day)
SELECT location, datecol, new_cases, SUM(CONVERT(float, new_cases)) OVER (PARTITION BY location order by location, datecol) as rollingPeopleInfected,
new_deaths, SUM(CONVERT(float, new_deaths)) OVER (PARTITION BY location order by location, datecol) as rollingDeathCounter,
(CONVERT(float, total_deaths)/CONVERT(float, total_cases)) * 100 as deathPercentage
FROM CovidDeaths
WHERE total_cases <> 0
ORDER BY 1, 2


--TOTAL CASE VS POPULATION
--POPULATION INFECTED (showing the population infected percentage at every country)
SELECT location, population, MAX(total_cases) as totalCases, MAX(CAST(total_cases as float)/population )*100 as PercentagePopulationInfected
FROM CovidDeaths
WHERE location not like '%Lower%'
AND location not like '%Upper%'
AND location not like '%High%'
AND location not like '%World%'
AND location not like '%Low%'
AND location not like '%union%'
GROUP BY location, population
ORDER BY 4 desc

--Hospitalized infected per day
SELECT cd.location, cd.datecol, new_cases, SUM(CONVERT(float, new_cases)) OVER (PARTITION BY cd.location order by cd.location, cd.datecol) as rollingPeopleInfected,
hosp_patients, r.rollingHospitalizedPatients,
icu_patients, r.rollingPatientsInICU,
CONVERT(float, r.rollingPatientsInICU)/CONVERT(float, r.rollingHospitalizedPatients) * 100 as ICUPatientsPercentage
FROM CovidDeaths cd JOIN
	(SELECT location, datecol,
	SUM(CONVERT(float, hosp_patients)) OVER (PARTITION BY location order by location, datecol) as rollingHospitalizedPatients,
	SUM(CONVERT(float, icu_patients)) OVER (PARTITION BY location order by location, datecol) as rollingPatientsInICU
	FROM CovidDeaths) AS r
	ON cd.location = r.location
	AND cd.datecol = r.datecol
WHERE cd.location not like '%Lower%'
AND cd.location not like '%Upper%'
AND cd.location not like '%High%'
AND cd.location not like '%World%'
AND cd.location not like '%Low%'
AND cd.location not like '%union%'
AND r.rollingHospitalizedPatients <> 0
ORDER BY 1, 2



--DEATH COUNT
--showing the total death count at every country
SELECT location, MAX(CAST(total_deaths AS int)) as totalDeathCount
FROM CovidDeaths
WHERE continent not like ''
GROUP BY location
ORDER BY 2 desc
	-- Using '' in order to eliminate countries that are not a country (from the dataset there are world, upper mid class, oceania, etc)
	-- This used '' not "is not null" because the data set doesn't register the columns as null


--Showing death count at every continent
SELECT continent, SUM(CAST(total_deaths AS float)) as TotalDeathCount
FROM CovidDeaths
WHERE continent not like ''
GROUP BY continent
ORDER BY 2 desc


-- This can be used too (SAME AS ABOVE)
SELECT location, SUM(CAST(total_deaths AS float)) as TotalDeathCount
FROM CovidDeaths
WHERE continent like ''
AND location not like '%Lower%'
AND location not like '%Upper%'
AND location not like '%High%'
AND location not like '%World%'
AND location not like '%Low%'
AND location not like '%union%'
GROUP BY location
ORDER BY 2 desc

--showing highest death count in a day at each country
SELECT d.location, d.datecol, new_deaths
FROM CovidDeaths d
	JOIN	(SELECT location, MAX(CAST(new_deaths AS int)) as highestDeathCount
			FROM CovidDeaths
			WHERE continent not like ''
			GROUP BY location) as hdc
			ON d.location = hdc.location
WHERE continent not like ''
AND new_deaths = highestDeathCount
AND new_deaths <> 0
ORDER BY 1, 2

-- GLOBAL NUMBER
SELECT SUM(CAST(new_cases AS float)) AS total_case, SUM(CAST(new_deaths AS float)) AS Deaths_per_day, (SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))) * 100 as DeathPercentage
FROM CovidDeaths
WHERE continent not like ''
AND new_cases <> 0

-- showing death percentage every day
SELECT datecol, SUM(CAST(new_cases AS float)) AS total_case, SUM(CAST(new_deaths AS float)) AS Deaths_per_day, 
(SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))) * 100 as DeathPercentage
FROM CovidDeaths
WHERE continent not like ''
AND new_cases <> 0
GROUP BY datecol
order by 1

-- a more detailed version
SELECT datecol, SUM(CAST(new_cases AS float)) AS total_case, SUM(CAST(new_deaths AS float)) AS Deaths_per_day, 
	CASE
		WHEN CONVERT(float, new_cases) = 0 THEN 0
		WHEN CONVERT(float, new_cases) <> 0 THEN (SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))) * 100 
	END as DeathPercentage
FROM CovidDeaths
WHERE continent not like ''
GROUP BY datecol, new_cases
order by 1


--Total population vs vaccination
SELECT d.location, d.datecol, d.population, v.new_vaccinations, 
SUM(CONVERT(float, v.new_vaccinations)) OVER (PARTITION BY d.location order by d.location, d.datecol) as rollingPeopleVacinated
FROM CovidDeaths d
JOIN CovidVacinations v
	ON d.location = v.location
	AND d.datecol = v.datecol
WHERE d.continent not like ''
order by 1,2

--same as the above but with percentage
SELECT d.location, d.datecol, d.population, CONVERT(float, vac.new_vaccinations) as newVaccination, vac.rollingPeopleVacinated,
	CASE
		WHEN vac.rollingPeopleVacinated = 0 THEN 0
		WHEN vac.rollingPeopleVacinated <> 0 THEN rollingPeopleVacinated / CONVERT(float, d.population) * 100 
	END as peopleVaccinatedPercentage
FROM CovidDeaths d
JOIN	(SELECT location, datecol, new_vaccinations,
		SUM(CONVERT(float, new_vaccinations)) OVER (PARTITION BY location order by location, datecol) as rollingPeopleVacinated
		FROM CovidVacinations) as vac
		ON d.location = vac.location
		AND d.datecol = vac.datecol
WHERE d.continent not like ''
ORDER BY 1, 2



	
