select location,date,total_cases,new_cases,total_deaths,population
from Portfolio..CovidDeaths
where location is not null
order by 1,2

-- Examine the total cases versus the total deaths

select location,date,total_deaths,total_cases,CAST(total_deaths as decimal(10,2))/ NULLIF(total_cases,0)*100 as DeathPercentage
from CovidDeaths
where location like '%Kenya%' 
order by location,date

-- Examine the Total Cases vs Population

select location,date,population,total_cases,CAST(total_cases as decimal(10,2))/ NULLIF(population,0)*100 as COVID_Cases_vs_Population
from CovidDeaths
where location like '%kenya%' 
order by location,date

-- Which Country has the highest infection rate copmared to population?
select location as Country,
		date as LatestDate,
		population as Population,
		MAX(total_cases) as HighestCases,
		MAX(CAST(total_cases as decimal(38,2)) / population)*100 as COVID_Cases_vs_Population
from CovidDeaths
where location like '%Kenya%'
group by 
		location,
		date,
		population 
order by 
		COVID_Cases_vs_Population desc,
		location,
		date;


-- Showing Countries with highest death count per population
select location as Location, MAX(cast(total_deaths as int)) as Total_Death_Count
from CovidDeaths
where location is not null
Group by location
order by Total_Death_Count desc;

-- Showing the conitents with highest death count
select location as Location, MAX(cast(total_deaths as int)) as Total_Death_Count
from Portfolio.dbo.CovidDeaths
where location in ('North America', 'South America','Europe','Asia','Africa','World','Oceania','International') 
Group by location
order by Total_Death_Count desc;

-- Create queries with the intent to visualize

-- Global numbers
-- Use aggregate functions
select date,Avg(total_deaths) as Total_Deaths,avg(total_cases) as Total_Cases
from Portfolio..CovidDeaths
where location in ('North America', 'South America','Europe','Asia','Africa','World','Oceania','International') 
group by date
order by 1,2

-- Global Death Perecentage
SELECT 
    date,
    NULLIF(SUM(CAST(new_deaths AS DECIMAL(38,2))), 0) AS New_Deaths,
    NULLIF(SUM(CAST(new_cases AS DECIMAL(38,2))), 0) AS New_Cases,
    NULLIF(SUM(CAST(new_deaths AS DECIMAL(38,2))), 0) / NULLIF(SUM(CAST(new_cases AS DECIMAL(38,2))), 0) * 100 AS DeathRate
FROM 
    Portfolio.dbo.CovidDeaths
WHERE 
    location IN ('World') 
GROUP BY 
    date
ORDER BY
    date, New_Deaths;


-- Total Deaths Overall 
SELECT 
    
    NULLIF(SUM(CAST(total_deaths AS DECIMAL(38,2))), 0) AS Total_Deaths_Worldwide,
    NULLIF(SUM(CAST(total_cases AS DECIMAL(38,2))), 0) AS Total_Cases_Worldwide,
    NULLIF(SUM(CAST(total_deaths AS DECIMAL(38,2))), 0) / NULLIF(SUM(CAST(total_cases AS DECIMAL(38,2))), 0) * 100 AS DeathRate_Worldwide
FROM 
    Portfolio.dbo.CovidDeaths
WHERE 
    location IN ('World') 
--GROUP BY 
--    date
ORDER BY
    Total_Deaths_Worldwide;

-- Explore the vaccinations table

select *
from Portfolio.dbo.CovidVaccinations

-- Join the two tables on location and date

select *
from Portfolio.dbo.CovidDeaths dea
join Portfolio.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Examine total vaccinations vs population
select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations
from Portfolio.dbo.CovidDeaths dea
join Portfolio.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent like '%America%'
order by 1,2,3

-- Learn to use Partition as rolling count
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, sum(cast(vac.new_vaccinations as decimal(38,2))) OVER (Partition by dea.location order by dea.location,dea.date) as Rolling_People_Vaccinated
from Portfolio.dbo.CovidDeaths dea
join Portfolio.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Important Concept: Using CTE 
-- Remeber the number of columns in CTE must match columns in the query


with PopsVac(contient,location,date,population,new_vaccinations,Rolling_People_Vaccinated) as
(
select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as decimal(38,2))) OVER (Partition by dea.location order by dea.location,dea.date) as Rolling_People_Vaccinated
from 
	Portfolio.dbo.CovidDeaths dea
join 
	Portfolio.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
)
 select *, (Rolling_People_Vaccinated/population)*100 
 from PopsVac

 -- Temp Table
 -- This is a good skill to showcase
 -- In the case you want to alter the table use Drop table command
 DROP TABLE IF EXISTS #PercentPopulationVaccinated

 create table #PercentPopulationVaccinated
 (
 continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population bigint,
 new_vaccinations numeric,
 Rolling_People_Vaccinated numeric
 )
 
 insert into #PercentPopulationVaccinated
 select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as decimal(38,2))) OVER (Partition by dea.location order by dea.location,dea.date) as Rolling_People_Vaccinated
from 
	Portfolio.dbo.CovidDeaths dea
join 
	Portfolio.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null

 select *,(Rolling_People_Vaccinated/ population) * 100
 from #PercentPopulationVaccinated

 -- Creating Data for viewing on Tableau
 Create View PercentPopulationVaccinated as 
  select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as decimal(38,2))) OVER (Partition by dea.location order by dea.location,dea.date) as Rolling_People_Vaccinated
from 
	Portfolio.dbo.CovidDeaths dea
join 
	Portfolio.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select * 
from PercentPopulationVaccinated

