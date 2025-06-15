/*
1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.
*/ 
select * from dim_customer;

-- market, customer, region

select distinct market from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";





/*
2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg
*/

select * from fact_sales_monthly;

with up_2020_2021 as (
select (select count(distinct product_code) from fact_sales_monthly where fiscal_year = 2020) as unique_products_2020, 
	   (select count(distinct product_code) from fact_sales_monthly where fiscal_year = 2021) as unique_products_2021
from fact_sales_monthly limit 1)

select unique_products_2020, unique_products_2021, 
       round(((unique_products_2021 - unique_products_2020)/unique_products_2020) * 100, 2) as percentage_chg
from up_2020_2021;

-- Second Method (Cross Join)

with up_2020 as (
select count(distinct product_code) as unique_products_2020
from fact_sales_monthly 
where fiscal_year = 2020),

up_2021 as (
select count(distinct product_code) as unique_products_2021
from fact_sales_monthly 
where fiscal_year = 2021),

up2020_21 as (
select unique_products_2020, unique_products_2021 from up_2020
cross join up_2021)

select *, round(((unique_products_2021 - unique_products_2020)/unique_products_2020) * 100, 2) as percentage_chg
from up2020_21;





/*
3. Provide a report with all the unique product counts for each segment and sort them in descending order of 
product counts. The final output contains 2 fields,
segment
product_count
*/

select * from dim_product;

select segment, count(product_code) as product_count
from dim_product
group by segment
order by product_count desc;





/*
4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output 
contains these fields,
segment
product_count_2020
product_count_2021
difference
*/


select p.segment,
       count(distinct case when s.fiscal_year = 2020 then s.product_code end) as unique_products_2020, 
	   count(distinct case when s.fiscal_year = 2021 then s.product_code end) as unique_products_2021,
       count(distinct case when s.fiscal_year = 2021 then s.product_code end) - 
       count(distinct case when s.fiscal_year = 2020 then s.product_code end) as difference
from dim_product as p
join fact_sales_monthly as s
on p.product_code = s.product_code
where s.fiscal_year in (2020, 2021)
group by p.segment
order by difference desc
limit 1;




/*
5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
product_code
product
manufacturing_cost
*/

select * from fact_manufacturing_cost;

with cte1 as (
select p.product_code, p.product, manufacturing_cost from dim_product as p
left join fact_manufacturing_cost as fm
on p.product_code = fm.product_code),

cte2 as (
select * from cte1
where manufacturing_cost = (select max(manufacturing_cost) from cte1)),

cte3 as (
select * from cte1
where manufacturing_cost = (select min(manufacturing_cost) from cte1))

select * from cte2
union
select * from cte3;





/*
6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the 
fiscal year 2021 and in the Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/
select * from fact_pre_invoice_deductions;
select * from dim_customer;


select c.customer_code, c.customer, round(avg(p.pre_invoice_discount_pct)*100, 2) as average_discount_percentage
from dim_customer as c
left join fact_pre_invoice_deductions as p
on c.customer_code = p.customer_code
where c.market = 'India' and p.fiscal_year = 2021
group by c.customer_code, c.customer
order by average_discount_percentage desc
limit 5;





/*
7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
This analysis helps to get an idea of low and high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/
select * from fact_gross_price;
select * from dim_product;
select * from fact_sales_monthly;

with atliq_sales as (
select c.customer_code, s.date, s.product_code, s.sold_quantity from dim_customer as c
join fact_sales_monthly as s
on c.customer_code = s.customer_code
where c.customer = 'Atliq Exclusive'),

all_month_sales as (
select year(a.date) as Year, monthname(a.date) as Month, (a.sold_quantity*gp.gross_price) as gross_sales_amount
from atliq_sales as a
join fact_gross_price as gp
on a.product_code = gp.product_code)

select Month, Year, round(sum(gross_sales_amount)/1000000, 2) as gross_sales_amount, 'Millions' as unit from all_month_sales
group by Month, Year;







/*
8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the 
total_sold_quantity,
Quarter
total_sold_quantity
*/
select * from fact_sales_monthly;

-- 2020, quarter, sum

-- Fiscal year starts from September
-- Sep, Oct, Nov -1
-- Dec, Jan, Feb -2
-- Mar, Apr, May -3
-- Jun, Jul, Aug -4

select 
       case when date between '2019-09=01' and '2019-11-01' then 'Qtr-1'
            when date between '2019-12=01' and '2020-02-01' then 'Qtr-2'
            when date between '2020-03=01' and '2020-05-01' then 'Qtr-3'
            when date between '2020-06=01' and '2020-08-01' then 'Qtr-4'
	   end as Quarters,
       
       format(sum(sold_quantity), 0) as total_sold_quantity

from fact_sales_monthly 
where fiscal_year = 2020
group by Quarters
order by total_sold_quantity desc;





/*
9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields,
channel
gross_sales_mln
percentage
*/
select * from dim_customer;
select * from fact_sales_monthly;
select * from fact_gross_price;

with cte1 as (
select c.channel, s.sold_quantity, s.product_code from dim_customer as c
join fact_sales_monthly as s
on c.customer_code = s.customer_code
where s.fiscal_year = 2021),

cte2 as (
select ct.channel, round(sum(ct.sold_quantity*gp.gross_price)/1000000, 2) as gross_sales_mln from cte1 as ct
join fact_gross_price as gp
on ct.product_code = gp.product_code
group by ct.channel),

cte3 as (
select *, 
sum(gross_sales_mln) over() as total_sales_mln
from cte2)

select channel, gross_sales_mln, round((gross_sales_mln/total_sales_mln)*100, 2) as percentage
from cte3
order by percentage desc;





/*
10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order
*/
select * from dim_product;

with cte1 as (
select p.division, p.product_code, p.product, s.sold_quantity from dim_product as p
join fact_sales_monthly as s
on p.product_code = s.product_code
where s.fiscal_year = 2021),

cte2 as (
select division, product_code, product, sum(sold_quantity) as total_sold_quantity from cte1
group by division, product_code, product),

cte3 as (
select division, product_code, product, total_sold_quantity,
       dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order
from cte2)

select * from cte3
having rank_order <= 3;



























