--select each driver's personal record of points in a single season and the year they achieved that
select d.forename, d.surname, ds.points, r.year
from drivers d
join driver_standings ds on ds.driverid = d.driverid
join races r on r.raceid = ds.raceid
where ds.points = (
    select max(ds2.points)
    from driver_standings ds2
    join races r2 on r2.raceid = ds2.raceid
    where ds2.driverid = d.driverid
)
and r.year between 2017 and 2024
order by ds.points desc;


--driver standings in 2024
select distinct rank() over (order by max(ds.points) desc) as rank, d.forename, d.surname, max(ds.points) as points
from drivers d
join driver_standings ds on ds.driverId = d.driverId
join races r on r.raceId = ds.raceId
where r.year = '2024'
group by d.driverId, d.forename, d.surname
order by points desc;


--constructor standings in 2024
select distinct rank() over (order by max(cs.points) desc) as rank, c.name, max(cs.points) AS points
from constructors c
join constructor_standings cs on cs.constructorid = c.constructorid
join races r on r.raceId = cs.raceId
where r.year = 2024
group by c.constructorid, c.name
order by points desc;


--points for leclerc for each year
select d.forename, d.surname, r.year, max(ds.points)as total_points, c.name
from drivers d
join results res on res.driverId = d.driverId
join races r on r.raceId = res.raceId
join constructors c on c.constructorId = res.constructorId
join driver_standings ds on ds.driverId = d.driverId and ds.raceId = r.raceId
where d.forename = 'Charles' and d.surname = 'Leclerc' and r.year between '2017' and '2024'
group by d.forename, d.surname, r.year, c.name
order by r.year desc;


--points for mclaren for each year
select c.name, max(cs.points)as total_points, r.year
from constructors c
join results res on c.constructorId = res.constructorId
join races r on r.raceId = res.raceId
join constructor_standings cs on cs.constructorId = c.constructorId and cs.raceId = r.raceId
where c.name like 'McLaren' and r.year between '2017' and '2024'
group by c.name, r.year
order by r.year desc;


--results for all teams 2017-2024
select c.name, max(cs.points)as total_points, r.year
from constructors c
join results res on c.constructorId = res.constructorId
join races r on r.raceId = res.raceId
join constructor_standings cs on cs.constructorId = c.constructorId and cs.raceId = r.raceId
where r.year between '2017' and '2024'
group by c.name, r.year
order by r.year desc, total_points desc;


--results for all drivers 2017-2024
select d.forename, d.surname, max(ds.points)as total_points, r.year, c.name
from drivers d
join results res on res.driverId = d.driverId
join races r on r.raceId = res.raceId
join constructors c on c.constructorId = res.constructorId
join driver_standings ds on ds.driverId = d.driverId and ds.raceId = r.raceId
where r.year between '2017' and '2024'
group by d.forename, d.surname, c.name, r.year
order by r.year desc, total_points desc;


--results for a specific race
select rank() over(order by r.points desc, r.time desc) as rank, ra.year, ra.name, d.forename, d.surname, c.name, r.points, r.time,s.status
from results r
join races ra on ra.raceId = r.raceId
join drivers d on d.driverId = r.driverId
join constructors c on c.constructorId = r.constructorId
join status s on s.statusId=r.statusId
where ra.raceId = 1140;


--results for a specific race (constructors)
select  ra.year, ra.name, c.name, sum(r.points) as sum
from results r
join races ra on ra.raceId = r.raceId
join drivers d on d.driverId = r.driverId
join constructors c on c.constructorId = r.constructorId
join status s on s.statusId=r.statusId
where ra.raceId = 1144
group by c.name, ra.year,ra.name
order by sum desc;


--constructor winning in the specific race
select ra.year, ra.name, c.name
from results r
join races ra on ra.raceId = r.raceId
join drivers d on d.driverId = r.driverId
join constructors c on c.constructorId = r.constructorId
where ra.raceId = 1134 and r.points>=25;


--wins in the specific year for each constructor
select c.name, ra.name, ra.year
from results r
join races ra on ra.raceId = r.raceId
join drivers d on d.driverId = r.driverId
join constructors c on c.constructorId = r.constructorId
where ra.year=2024 and r.points>=25
group by ra.raceId, c.name, ra.name, ra.year
order by ra.raceId;


--sum of points per team for a set period
select distinct c.name, sum(cr.points)/2 as total_points
from constructors c
join results res on c.constructorId = res.constructorId
join races r on r.raceId = res.raceId
join constructor_results cr on cr.constructorId = c.constructorId and cr.raceId = r.raceId
where r.year in(2017,2018,2019,2020)
group by c.name
order by total_points desc;


--wins in the specific year for each constructor grouped
select c.name, count(*) as number_wins
from results r
join races ra on ra.raceId = r.raceId
join drivers d on d.driverId = r.driverId
join constructors c on c.constructorId = r.constructorId
where ra.year=2024 and r.points>=25
group by c.name
order by number_wins desc;


--average points, variance and standard deviation for the top 4 constructors
with constructor_points_per_year as (
    select
        c.name as constructor_name,
        r.year,
        max(cs.points) as total_points
    from constructors c
    join constructor_standings cs on cs.constructorid = c.constructorid
    join races r on r.raceid = cs.raceid
    where r.year between 2016 and 2024
    group by c.name, r.year
),
top_4_per_year as (
    select
        constructor_name,
        year,
        total_points,
        rank() over (partition by year order by total_points desc) as rank
    from constructor_points_per_year
)
select
    year,
    round(avg(total_points), 2) as avg_points_top4,
    round(var_samp(total_points), 2) as variance_top4,
    round(stddev_samp(total_points), 2) as stddev_top4
from top_4_per_year
where rank <= 4
group by year
order by year desc;


--same but fot all teams overall
with constructor_points_per_year as (
    select
        c.name as constructor_name,
        r.year,
        max(cs.points) as total_points
    from constructors c
    join constructor_standings cs on cs.constructorid = c.constructorid
    join races r on r.raceid = cs.raceid
    where r.year between 2016 and 2024
    group by c.name, r.year
),
top_4_per_year as (
    select
        constructor_name,
        year,
        total_points,
        rank() over (partition by year order by total_points desc) as rank
    from constructor_points_per_year
)
select
    year,
    round(avg(total_points), 2) as avg_points_top4,
    round(var_samp(total_points), 2) as variance_top4,
    round(stddev_samp(total_points), 2) as stddev_top4
from top_4_per_year
where rank <=10
group by year
order by year desc;



