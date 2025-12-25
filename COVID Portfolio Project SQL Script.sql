/* 
Covid 19 Data Exploration

Concepts used -> Joins, CTE's, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


-- Checking if the covid_deaths table is working fine or not
select *
from PortfolioProject..covid_deaths
order by 3,4;

-- Checking if the covid_vaccinations table is working fine or not
select *
select *
from PortfolioProject..covid_vaccinations
order by 3,4;

--Select data that we are going to be starting with
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..covid_deaths
order by 1,2;


-- Looking at Total Cases vs Total Deaths
-- Shows liklihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as death_percentage
from PortfolioProject..covid_deaths
where location like '%states%'
order by 1,2;


-- Looking at Total Cases vs Population
-- Shows what percentage of population infected with Covid
select location, date, population, total_cases, (total_cases/population)*100 as death_percentage
from PortfolioProject..covid_deaths
-- where location like '%states%'
order by 1,2;


-- Looking at Countries with Highest Infection Rate compared to Population
select location, population, max(total_cases) as highest_infection_count , max((total_cases/population))*100 as percent_population_infected
from PortfolioProject..covid_deaths
-- where location like '%states%'
group by population, location
order by percent_population_infected desc;


-- Showing Countries with Highest Death Count per Population
select location, max(total_deaths) as total_death_count
from PortfolioProject..covid_deaths
-- where location like '%states%'
where continent is not null
group by location
order by total_death_count desc;


-- Let's break things down by continent

-- Showing Continents with the Highest Death Count per Population
select continent, max(total_deaths) as total_death_count
from PortfolioProject..covid_deaths
-- where location like '%states%'
where continent is not null
group by continent
order by total_death_count desc;


-- Global Numbers

select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as death_percentage
from PortfolioProject..covid_deaths
--where location like '%states%'
where continent is not null
--group by date
order by 1,2;


-- Looking at Total Population vs Vaccinations 
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- We gonna see 2 ways of approaching this problem


-- 1. Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, sum(cv.new_vaccinations) over (partition by cd.location order by cd.date) as rolling_people_vaccinated
from PortfolioProject..covid_deaths cd
join PortfolioProject..covid_vaccinations cv
   on cd.location = cv.location 
   and cd.date = cv.date
where cd.continent is not null 
   --and cd.location = 'India'
--order by 1, 2, 3 
)
select *, (rolling_people_vaccinated/population)*100 as people_vaccinated 
from PopvsVac;


-- 2. Using TEMP Table to perform Calculation on Partition By in previous query
drop table if exists #PercentPopulationVaccinated   -- Add this if you are planning to update the table
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

insert into #PercentPopulationVaccinated
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, sum(cv.new_vaccinations) over (partition by cd.location order by cd.date) as rolling_people_vaccinated
from PortfolioProject..covid_deaths cd
join PortfolioProject..covid_vaccinations cv
    on cd.location = cv.location 
   and cd.date = cv.date
where cd.continent is not null 
   --and cd.location = 'India'
--order by 1, 2, 3 

select *, (rolling_people_vaccinated/population)*100 as people_vaccinated 
from #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated;
create view PercentPopulationVaccinated as 
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, sum(cv.new_vaccinations) over (partition by cd.location order by cd.date) as rolling_people_vaccinated
from PortfolioProject..covid_deaths cd
join PortfolioProject..covid_vaccinations cv
    on cd.location = cv.location 
    and cd.date = cv.date
where cd.continent is not null 
--order by 2, 3 

select *
from PercentPopulationVaccinated