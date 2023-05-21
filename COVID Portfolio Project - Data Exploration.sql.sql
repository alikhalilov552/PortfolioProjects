/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, Converting Date/time

*/

-- Select everything from the Covid Vaccinations table and order it by location and date

SELECT 
    *
FROM
    portfolio_project_1.covidvaccinations
ORDER BY 3 , 4;

-- Update empty continent cells in Covid Deaths table and set them as NULL for future queries (cells were empty instead of NULL)

UPDATE portfolio_project_1.coviddeaths 
SET 
    continent = NULL
WHERE
    continent = '';
    
-- Checking update statement if it succeeded
    
SELECT 
    *
FROM
    portfolio_project_1.coviddeaths
WHERE
    continent IS NULL;
    

-- Select everything from Covid Deaths table where continent value is not null so that we will not see Continents as locations (ex. Europe, World and etc.)
-- Order by Location and the Date
SELECT 
    *
FROM
    portfolio_project_1.coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY 3 , 4;

-- Select data that we are going to be using for data exploration
-- Used "date_format" function to format a date value into a specified string representation. Date format was not implemented correctly during import.
-- Used "str_to_date" function in "date_format" function to convert string representation of dates into an actual date or datetime value.

SELECT 
    location,
    DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%y'),
            '%Y-%m-%d') AS formatted_date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    portfolio_project_1.coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY 1 , 2;

-- Looking at Total Cases vs Total Deaths
-- Likelihood of dying if you contract Covid in Azerbaijan

SELECT 
    location,
    DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%y'),
            '%Y-%m-%d') AS formatted_date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS death_percentage
FROM
    portfolio_project_1.coviddeaths
WHERE
    location LIKE '%Azer%'
        AND continent IS NOT NULL
ORDER BY 1 , 2;
    
-- Looking at to the Total Cases vs Population
-- Shows what percentage of population got Covid
    
  SELECT 
    location,
    DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%y'),
            '%Y-%m-%d') AS formatted_date,
    total_cases,
    population,
    (total_cases / population) * 100 AS percent_population_infected
FROM
    portfolio_project_1.coviddeaths
WHERE
    location LIKE '%Azerbaijan%'
        AND continent IS NOT NULL
ORDER BY 1 , 2; 
    
-- Looking at countries with highest infection rate compared to the population

  SELECT 
    location,
    population,
    DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%y'),
            '%Y-%m-%d') AS formatted_date,
    MAX(total_cases) AS highest_infection_count,
    MAX((total_cases / population)) * 100 AS percent_population_infected
FROM
    portfolio_project_1.coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY location , population
ORDER BY percent_population_infected DESC;


    
-- Showing countries with highest death count per population
-- Used "cast" statement to convert total_deaths numbers to integer
    
    SELECT 
    location,
    DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%y'),
            '%Y-%m-%d') AS formatted_date,
    MAX(CAST(total_deaths AS SIGNED)) AS total_death_count
FROM
    portfolio_project_1.coviddeaths
WHERE
    continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

    
-- Let's break things down by continent
    
SELECT 
    location,
    MAX(CAST(total_deaths AS SIGNED)) AS total_death_count
FROM
    portfolio_project_1.coviddeaths
WHERE
    continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;



-- Checking total deaths in USA

SELECT 
    location,
    date,
    CAST(total_deaths AS SIGNED) AS total_death_count
FROM
    portfolio_project_1.coviddeaths
WHERE
    location LIKE '%states%'
ORDER BY total_death_count DESC;


-- Continue to break things down :)
-- Continents with the highest death counts

SELECT 
    continent,
    MAX(CAST(total_deaths AS SIGNED)) AS total_death_count
FROM
    portfolio_project_1.coviddeaths
WHERE
    continent IS not NULL
GROUP BY continent
ORDER BY total_death_count DESC;

-- Global Numbers

SELECT 
    SUM(new_cases) AS sum_new_cases,
    SUM(CAST(new_deaths AS SIGNED)) AS sum_new_deaths,
    SUM(new_deaths) / SUM(new_cases) * 100 AS death_percentage
FROM
    portfolio_project_1.coviddeaths
WHERE
    continent IS NOT NULL
ORDER BY 1 , 2;
    
-- Inner Joining coviddeaths and covidvaccinations tables on location and date
-- Looking at total population vs vaccinations
-- Finding sum of new vaccinations for each location

SELECT 
    dea.continent,
    dea.location,
    DATE_FORMAT(STR_TO_DATE(dea.date, '%m/%d/%y'),
            '%Y - %m - %d') AS formatted_date,
    dea.population,
    CAST(vac.new_vaccinations AS SIGNED) FORMATTED_NEW_VACCINATIONS,
    SUM(CAST(vac.new_vaccinations AS SIGNED))
OVER (PARTITION BY dea.location ORDER BY dea.location, date_format(str_to_date(dea.date, '%m/%d/%y'),'%Y - %m - %d')) 
AS rolling_people_vaccinated
FROM portfolio_project_1.coviddeaths dea
JOIN portfolio_project_1.covidvaccinations vac
ON dea.location = vac.location and dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- USED CTE (COMMON TABLE EXPRESSION) TO STORE TEMPORARY NAMED (POPVSVAC) RESULT SET THAT I CAN REFERENCE IN A FUTURE STATEMENT 

with popvsvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as 
(
select dea.continent, dea.location, date_format(str_to_date(dea.date, '%m/%d/%y'),'%Y - %m - %d') as formatted_date,
dea.population, cast(vac.new_vaccinations as signed), 
sum(cast(vac.new_vaccinations as signed)) 
over (partition by dea.location order by dea.location, date_format(str_to_date(dea.date, '%m/%d/%y'),'%Y - %m - %d')) 
as rolling_people_vaccinated
-- ,(rolling_people_vaccinated/population)*100
from portfolio_project_1.coviddeaths dea
join portfolio_project_1.covidvaccinations vac
on dea.location = vac.location and dea.date=vac.date
where dea.continent is not null 
-- group by dea.continent
order by 2,3 
)
select *, (rolling_people_vaccinated/population)*100 as percentage_rolling_people_vaccinated from popvsvac;

-- CREATED A TEMPORARY TABLE INSTEAD OF CTE TO QUERY DATA EASILY
-- NULLIF USED IN THE CAST STATEMENT BECAUSE OF A TRUNCATE INTEGER ERROR DURING THE TEMP TABLE CREATION
-- In the given expression, NULLIF(vac.new_vaccinations, '') is used to check if the value of vac.new_vaccinations is an empty string. If it is, NULL will be returned. If it is not empty, the original value of vac.new_vaccinations will be returned
-- Then, the result of NULLIF() is passed to the CAST() function as CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED). This converts the value to a signed integer data type (SIGNED). 

drop table if exists percentpopulationvaccinated;

create temporary table percentpopulationvaccinated 
(
continent varchar (255),
location varchar (255),
date varchar(100),
population double,
new_vaccinations varchar(100),
rolling_people_vaccinated varchar(100)
);
insert into percentpopulationvaccinated (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
select dea.continent, dea.location, date_format(str_to_date(dea.date, '%m/%d/%y'),'%Y-%m-%d') as formatted_date,
dea.population, CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED),
    SUM(CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
    DATE_FORMAT(STR_TO_DATE(dea.date, '%m/%d/%y'), '%Y-%m-%d')) AS rolling_people_vaccinated
from portfolio_project_1.coviddeaths dea
join portfolio_project_1.covidvaccinations vac
on dea.location = vac.location and dea.date=vac.date
where dea.continent is not null;

SELECT 
    *,
    (rolling_people_vaccinated / population) * 100 AS percentage_rolling_people_vaccinated
FROM
    percentpopulationvaccinated;
    
-- Create view to store data for later visualisations

drop view percentpopulationvaccinated;
create view portfolio_project_1.percentpopulationvaccinated as 
select dea.continent, dea.location, date_format(str_to_date(dea.date, '%m/%d/%y'),'%Y-%m-%d') as formatted_date,
dea.population, CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED) as formatted_new_vaccinations,
    SUM(CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
    DATE_FORMAT(STR_TO_DATE(dea.date, '%m/%d/%y'), '%Y-%m-%d')) AS rolling_people_vaccinated
from portfolio_project_1.coviddeaths dea
join portfolio_project_1.covidvaccinations vac
on dea.location = vac.location and dea.date=vac.date
where dea.continent is not null;


