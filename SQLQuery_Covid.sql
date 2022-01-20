/*
Covid 19 Data Exploration 
*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 3,4


-- Select Data -- 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you get covid 
SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as death_perc
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'ger%'
AND continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid, cumulative
SELECT location, date, population, total_cases,  (total_cases/population)*100 as percent_pop_infected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE 'ger%'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as highest_infection_count,  Max((total_cases/population))*100 as perc_population_infected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY perc_population_infected desc


-- Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY total_death_count desc



-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY total_death_count desc



-- GLOBAL NUMBERS
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_perc
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL  
ORDER BY 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations))
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations))
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (rolling_vaccinated/population)*100
FROM PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table IF exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations))
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 

SELECT *, (rolling_vaccinated/population)*100 as vaccinated_perc_pop
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations))
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL