create schema assignment;
use assignment;

select * from fact_data;
-- 1. How many records are there in the dataset?

select count(*) as total_records from fact_data;



-- 2. How many unique cities are in the European dataset?

select count(distinct ID) as unique_cities from fact_data;




-- 3. What are the names of the cities in the dataset?

select distinct c.city as cities_name from fact_data as f
join dim_city as c on f.ID = c.CityID;




-- 4. How many bookings are there in each city?

select c.city as CITY, count(c.city) as booking_counts from fact_data as f
join dim_city as c on f.ID = c.CityID
group by CITY
order by booking_counts desc;



-- 5. What is the total booking revenue for each city?
/*
Use SUM() function on the PRICE column.
Group by CITY .
Round the result.
Order by total revenue descending.
*/

select c.city as CITY, round(sum(f.Price), 2) as total_revenue from fact_data as f
join dim_city as c on f.ID = c.CityID
group by CITY
order by total_revenue desc;




-- 6. What is the average guest satisfaction score for each city?
/*
Use AVG() function on GUEST_SATISFACTION column.
Group by CITY .
Round the result.
Order by average score descending.
*/

select c.city as CITY, round(avg(f.`Guest Satisfaction`), 2) as avg_guest_satisfaction from fact_data as f
join dim_city as c on f.ID = c.CityID
group by CITY
order by avg_guest_satisfaction desc;




-- 7. What are the minimum, maximum, average, and median booking prices?
/*
Use MIN() , MAX() , and AVG() functions on PRICE column.
Use ntile() for the median.
Round results.
*/


with cte as (
    select price, ntile(4) over (order by price) as quantile from fact_data
)
select round(min(price), 2) as min_price, 
       round(max(price), 2) as max_price,
       round(avg(price), 2) as avg_price,
       round(max(case when quantile = 2 then price end), 2) as median_price
from cte;




-- 8. How many outliers are there in the price field?
/*
Calculate Q1, Q3, and IQR using ntile() .
Define lower and upper bounds.
Count records outside these bounds.
*/

with cte1 as (
    select price,
           ntile(4) over (order by price) as quartile
    from fact_data
),
cte2 as (
    select 
        max(case when quartile = 1 then price end) as q1,
        max(case when quartile = 3 then price end) as q3
    from cte1
),
cte3 as (
    select 
        q1,
        q3,
        (q3 - q1) as iqr,
        (q1 - 1.5 * (q3 - q1)) as lower_bound,
        (q3 + 1.5 * (q3 - q1)) as upper_bound
    from cte2
)
select count(*) as outlier_count
from fact_data
cross join cte3
where price < lower_bound or price > upper_bound;




-- 9. What are the characteristics of the outliers in terms of room type, number of bookings, and price?
/*
Create a view or CTE for outliers.
Group by ROOM_TYPE .
Use COUNT() , MIN() , MAX() , and AVG() functions.
*/

create view dataset_with_outliers as 
with cte1 as (
    select price,
           ntile(4) over (order by price) as quartile
    from fact_data
),
cte2 as (
    select 
        max(case when quartile = 1 then price end) as q1,
        max(case when quartile = 3 then price end) as q3
    from cte1
),
cte3 as (
    select 
        q1,
        q3,
        (q3 - q1) as iqr,
        (q1 - 1.5 * (q3 - q1)) as lower_bound,
        (q3 + 1.5 * (q3 - q1)) as upper_bound
    from cte2
)
select * 
from fact_data
cross join cte3
where price < lower_bound or price > upper_bound;

select * from dataset_with_outliers;

select r.`Room Type` as ROOM_TYPE, count(dwo.roomtypeID) as room_count, round(min(dwo.Price), 2) as minimum_price,
       round(max(dwo.Price), 2) as maximum_price, round(avg(dwo.Price), 2) average_price
from dataset_with_outliers as dwo
join dim_room_type as r
on dwo.roomtypeID = r.roomtypeID
group by ROOM_TYPE;





-- 10. How does the average price differ between the main dataset and the dataset with outliers removed?
/*
Create a view for cleaned data (without outliers).
Calculate the average price for both datasets.
Compare results.
*/

-- Removing the Outliered Data
create view cleaned_data as 
with cte1 as (
    select price,
           ntile(4) over (order by price) as quartile
    from fact_data
),
cte2 as (
    select 
        max(case when quartile = 1 then price end) as q1,
        max(case when quartile = 3 then price end) as q3
    from cte1
),
cte3 as (
    select 
        q1,
        q3,
        (q3 - q1) as iqr,
        (q1 - 1.5 * (q3 - q1)) as lower_bound,
        (q3 + 1.5 * (q3 - q1)) as upper_bound
    from cte2
),
cte4 as (
    select fact_data.*
    from fact_data
    cross join cte3
    where price >= lower_bound and price <= upper_bound
)
select * 
from cte4;
select * from cleaned_data;

-- Calculating the difference of Average Price
with cte1 as (
     select round(avg(Price), 2) as avg_price_main_dataset
	 from fact_data
),
cte2 as (
     select round(avg(Price), 2) as avg_price_cleaned_dataset
     from cleaned_data
)
select c1.avg_price_main_dataset, c2.avg_price_cleaned_dataset, 
       round(c1.avg_price_main_dataset - c2.avg_price_cleaned_dataset, 2) as difference
from cte1 as c1
cross join cte2 as c2;





select * from cleaned_data;

-- 11. What is the average price for each room type?

select r.`Room Type` as ROOM_TYPE, round(avg(c.Price), 2) as average_price from cleaned_data as c
join dim_room_type as r on c.roomtypeID = r.roomtypeID
group by ROOM_TYPE;





-- 12. How do weekend and weekday bookings compare in terms of average price and number of bookings?
/*
Group by DAY column.
Use AVG() for price and COUNT() for bookings.
*/

select d.DayType as DAY, round(avg(c.Price), 2) as average_price, count(c.DayTypeID) as booking_count from cleaned_data as c
join dim_day_type as d on c.DayTypeID = d.DayTypeID
group by DAY;





-- 13. What is the average distance from metro and city center for each city?
/*
Use AVG() on METRO_DISTANCE_KM and CITY_CENTER_KM columns.
Group by CITY 
*/

select c.City as CITY, round(avg(cd.`Metro Distance (km)`), 2) as METRO_DISTANCE_KM,
       round(avg(cd.`City Center (km)`), 2) as CITY_CENTER_KM
from cleaned_data as cd
join dim_city as c on cd.ID = c.CityID
group by CITY;





-- 14. How many bookings are there for each room type on weekdays vs weekends?
/*
Use CASE statements to categorize room types.
Group by DAY and ROOM_TYPE 
*/

select case 
         when r.`Room Type` = 'Private room' then 'Private'
         when r.`Room Type` = 'Entire home/apt' then 'Entire'
         when r.`Room Type` = 'Shared room' then 'Shared'
	   end as ROOM_TYPE,
       d.DayType as DAY,
       count(*) as booking_count
from cleaned_data as c
join dim_day_type as d on c.DayTypeID = d.DayTypeID
join dim_room_type as r on c.roomtypeID = r.roomtypeID
group by DAY, ROOM_TYPE;





-- 15. What is the booking revenue for each room type on weekdays vs weekends?
select round(sum(Price), 2) from cleaned_data;

select case 
         when r.`Room Type` = 'Private room' then 'Private'
         when r.`Room Type` = 'Entire home/apt' then 'Entire'
         when r.`Room Type` = 'Shared room' then 'Shared'
	   end as ROOM_TYPE,
       d.DayType as DAY,
       round(sum(c.Price), 2) as total_revenue
from cleaned_data as c
join dim_day_type as d on c.DayTypeID = d.DayTypeID
join dim_room_type as r on c.roomtypeID = r.roomtypeID
group by DAY, ROOM_TYPE;





-- 16. What is the overall average, minimum, and maximum guest satisfaction score?

select round(avg(`Guest Satisfaction`), 2) as average_guest_satisfaction, 
       round(min(`Guest Satisfaction`), 2) as minimum_guest_satisfacton,
       round(max(`Guest Satisfaction`), 2) as maximum_guest_satisfaction
from cleaned_data;





-- 17. How does guest satisfaction score vary by city?

select c.city as CITY,
       round(avg(cd.`Guest Satisfaction`), 2) as average_guest_satisfaction, 
       round(min(cd.`Guest Satisfaction`), 2) as minimum_guest_satisfacton,
       round(max(cd.`Guest Satisfaction`), 2) as maximum_guest_satisfaction
from cleaned_data as cd
join dim_city as c on cd.ID = c.CityID
group by CITY;






-- 18. What is the average booking value across all cleaned data?

select round(avg(Price), 2) as average_booking_value from cleaned_data;




-- 19. What is the average cleanliness score across all cleaned data?

select round(avg(`Cleanliness Rating`), 2) as average_cleanliness_score from cleaned_data;





-- 20. How do cities rank in terms of total revenue?
/*
Use SUM() on PRICE column.
Group by CITY .
Use window function ROW_NUMBER() to assign ranks.
*/

with cte as (
	 select c.City as CITY, round(sum(cd.Price), 2) as total_revenue
     from cleaned_data as cd
     join dim_city as c on cd.ID = c.CityID
     group by CITY
)
select *, 
       row_number() over(order by total_revenue desc) as ranking
from cte;







