CREATE DATABASE Census_2011
USE Census_2011
SELECT * FROM [dbo].[Data1$]

--As there were duplicates, removing duplicates here:
SELECT District,State,Growth,Sex_ratio,Literacy,COUNT(*) as count1 into New_data_1 from [dbo].[Data1$]
Group BY District,State,Growth,Sex_ratio,Literacy

-- Now, two databases tables created as Data1 and Data2 
SELECT * FROM Data1;
SELECT * FROM Data2;

-- Number of rows in the dataset
SELECT COUNT(*) as count_of_data1 FROM Data1;
SELECT COUNT(*) as count_of_data2 FROM Data2;

--Data from Jharkhand and Bihar
SELECT * FROM Data1 
WHERE State = 'Jharkhand' or State ='Bihar';

--Population of India
SELECT SUM(population) as Population FROM Data2 

--Average Growth Rate
SELECT AVG(Growth)*100 as Avg_gwt_rate FROM Data1

--Average Growth percentage - statewise
SELECT State,AVG(Growth)*100 as Avg_gwt_rate FROM Data1
GROUP BY State

-- Average Sex ratio
SELECT State,Round(AVG(Sex_ratio),0) as Avg_sex_rate FROM Data1
GROUP BY State
Order By Avg_sex_rate desc;

--Average Literacy rate
SELECT State,Round(AVG(Literacy),0) as Avg_literacy_rate FROM Data1
GROUP BY State
Having Round(AVG(Literacy),0) > 90
Order By Avg_literacy_rate desc;

--Top 3 states with highest average growth state
SELECT TOP 3 State,AVG(Growth)*100 as Avg_gwt_rate FROM Data1
GROUP BY State
Order BY Avg_gwt_rate desc;

--Bottom 3 states with highest average growth state
SELECT TOP 3 State,Round(AVG(Sex_ratio),0) as Avg_sex_rate FROM Data1
GROUP BY State
Order BY Avg_sex_rate asc;

--Top and bottom 3 states in literacy rate

create table #topstates
( state nvarchar(225),
topstates float,
)

insert into #topstates
SELECT TOP 3 State,Round(AVG(Literacy),0) as Avg_literacy_rate FROM Data1
GROUP BY State
Order BY Avg_literacy_rate desc 

SELECT * FROM #topstates

create table #bottomstates
( state nvarchar(225),
bottomstates float,
)

insert into #bottomstates
SELECT TOP 3 State,Round(AVG(Literacy),0) as Avg_literacy_rate FROM Data1
GROUP BY State
Order BY Avg_literacy_rate asc 

SELECT * FROM #bottomstates

-- Using union operator to combine both tables of top and bottom

SELECT * FROM #topstates
UNION ALL
SELECT * FROM #bottomstates

--States starting with letter "a"
SELECT distinct State FROM Data1
WHERE lower(State) like 'a%'

--States starting with both 'a' or 'b'
SELECT distinct State FROM Data1
WHERE lower(State) like 'a%' or lower(State) like 'b%'

--States starting with both 'a' or ending with 'd'
SELECT distinct State FROM Data1
WHERE lower(State) like 'a%' or lower(State) like '%d'

--States starting with both 'a' and ending with 'm'
SELECT distinct State FROM Data1
WHERE lower(State) like 'a%' and lower(State) like '%m'

-- Joining both the Data tables 1 and 2 to find number of Males and females
SELECT a.District,a.State,a.Sex_ratio,b.Population FROM Data1 as a
LEFT JOIN Data2 as b on a.District = b.District

--Formulae:

--Sex_ratio = number of females / numbers of males *100 ... eq.1
--females + males = population
--therefore, females = population - males
--and males = population - females
--now, using eq.1 - (population - males) = sex_ratio * males
--population = males(sex_ratio + 1)
--so, males = population / (sex_ratio + 1)
--females = population - (population/(sex_ratio + 1))

--Deriving the males and females using sub-query

--Districtwise data
SELECT district,state,Round((a.Population/(a.sex_ratio+1)),0) as no_of_males,Round((a.Population - (a.Population/(a.sex_ratio + 1))),0)as no_of_females from
(SELECT a.District,a.State,a.Sex_ratio/1000 as sex_ratio,b.Population FROM Data1 as a
LEFT JOIN Data2 as b on a.District = b.District)a

--Statewise data
SELECT State,sum(no_of_males) as males,sum(no_of_females) as females from
(SELECT district,state,Round((a.Population/(a.sex_ratio+1)),0) as no_of_males,Round((a.Population - (a.Population/(a.sex_ratio + 1))),0)as no_of_females from
(SELECT a.District,a.State,a.Sex_ratio/1000 as sex_ratio,b.Population FROM Data1 as a
INNER JOIN Data2 as b on a.District = b.District)a)c
Group By State;

--total literacy rate 
SELECT a.District,a.State,a.Literacy as literacy_ratio,b.Population FROM Data1 as a
INNER JOIN Data2 as b on a.District = b.District

--Formulae:
--total literate people/population = literacy_ratio

--District-wise literate and illiterate people
SELECT District,State,literacy_ratio,Population,total_literate_people,(Population - total_literate_people) as total_illiterate_people FROM
(SELECT District,State,literacy_ratio,Population,Round((Population*literacy_ratio/100),0) as total_literate_people FROM
(SELECT a.District,a.State,a.Literacy as literacy_ratio,b.Population FROM Data1 as a
INNER JOIN Data2 as b on a.District = b.District)a)c
 
--State-wise literate and illiterate people
SELECT State,sum(total_literate_people) as total_literate_people,sum(total_illiterate_people) as total_illiterate_people FROM
(SELECT District,State,literacy_ratio,Population,total_literate_people,(Population - total_literate_people) as total_illiterate_people FROM
(SELECT District,State,literacy_ratio,Population,Round((Population*literacy_ratio/100),0) as total_literate_people FROM
(SELECT a.District,a.State,a.Literacy as literacy_ratio,b.Population FROM Data1 as a
INNER JOIN Data2 as b on a.District = b.District)a)c)d
GROUP BY State;

-- Finding the population in the previous Census 
SELECT a.District,a.State,a.Growth as Growth_rate,b.Population FROM Data1 as a
INNER JOIN Data2 as b on a.District = b.District

--Formulae:

--previous_census + growth*previous_census = population
--previous_census = population / (1+growth)

--District-wise
SELECT District,State,Round((Population/(1+Growth_rate)),0) as previous_census,Population FROM
(SELECT a.District,a.State,a.Growth as Growth_rate,b.Population FROM Data1 as a
INNER JOIN Data2 as b on a.District = b.District)a
 
--State-wise
SELECT State, sum(previous_census) as previous_census,sum(population) as current_census FROM
(SELECT District,State,Round((Population/(1+Growth_rate)),0) as previous_census,Population FROM
(SELECT a.District,a.State,a.Growth as Growth_rate,b.Population FROM Data1 as a
INNER JOIN Data2 as b on a.District = b.District)a)b
GROUP BY STATE

--Total previous census population and current census population
SELECT SUM(previous_census) as previous_census_population , SUM(current_census) as current_census_population FROM
(SELECT State, sum(previous_census) as previous_census,sum(population) as current_census FROM
(SELECT District,State,Round((Population/(1+Growth_rate)),0) as previous_census,Population FROM
(SELECT a.District,a.State,a.Growth as Growth_rate,b.Population FROM Data1 as a
INNER JOIN Data2 as b on a.District = b.District)a)b
GROUP BY STATE)f

--TOP 3 districts with each state with highest literacy rate
SELECT * FROM
(SELECT District,State,Literacy,rank() over(partition by State Order by literacy desc) as rank1 FROM Data1)a	
WHERE rank1 in (1,2,3)
ORDER BY State









































