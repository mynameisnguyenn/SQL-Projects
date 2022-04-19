-- Overview of Data
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

---Reproduction Rate
SELECT location, YEAR(date) as 'Year', AVG(CONVERT(float, reproduction_rate)) as 'Reproduction Rate'
FROM PortfolioProject..CovidDeaths
WHERE reproduction_rate IS NOT NULL
GROUP BY location, YEAR(date)
ORDER BY 1, 2

--- Positive Rate vs Total Test using another table
SELECT location, date, (CONVERT(float, positive_rate)/ CONVERT(float, total_tests)) as positveRate
FROM PortfolioProject..CovidVaccinations

-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, CAST((total_deaths/total_cases)*100 as NUMERIC(10,4)) as 'Death Percentage'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Total Case vs Population
SELECT location, date, total_cases, population, CAST((total_cases/population)*100 as NUMERIC(10,4)) as 'Percentage of Total Infected'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- The highest infection case and the proportion during that perid of time
SELECT location, population, MAX(total_cases) as 'Highest Total Case', CAST(MAX(total_cases/population)*100 as NUMERIC(10,4)) as 'Percentage Population Infected'
FROM PortfolioProject..CovidDeaths
GROUP BY location, population 
ORDER BY 'Percentage Population Infected' DESC

-- Showing Countries with Highest Death Count Per Population
SELECT location, MAX(CAST(total_deaths as INT)) as 'Total Deaths', CAST(MAX(CAST(total_deaths as INT)/population)*100 as NUMERIC(10,4)) as 'Percentage Population Deaths'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY 'Percentage Population Deaths' DESC

-- CONTINENT
-- Filter by Continent but using location column because the continent is incorrect (i.e: NA only takes into account the United States)
SELECT location, MAX(CAST(total_deaths as INT)) as 'Total Deaths', CAST(MAX(CAST(total_deaths as INT)/population)*100 as NUMERIC(10,4)) as 'Percentage Population Deaths'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
AND location <> 'European Union' 
AND location <> 'High Income' 
AND location <> 'Upper middle income' 
AND location <> 'World' 
AND location <> 'Lower middle income' 
AND location <> 'European Union'
AND location <> 'Low income' 
AND location <> 'International'
GROUP BY location 
ORDER BY 'Percentage Population Deaths' DESC, 'Total Deaths' DESC

-- Global Infected Numbers:
SELECT date, SUM(new_cases) AS total_cases, 
SUM(CAST(new_deaths as INT)) as total_deaths, 
SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as 'Death Percentage'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Join Covid Vaccinations Table with Covid Deaths 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND
	dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- Use the Rolling People Vaccinatedcolumn to calculate the total vaccination amount
WITH PopvsVac
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND
	dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (Rolling_People_Vaccinated/Population)*100 FROM PopvsVac

-- Create View to store data for Tableau
CREATE View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
