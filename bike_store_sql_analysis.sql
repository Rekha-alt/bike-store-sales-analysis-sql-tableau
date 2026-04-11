-- ============================================
-- Bike Store Sales Analysis
-- Tools Used: BigQuery SQL
-- Description: Analysis of sales, customers, average order value, monthly trends, and store performance.
-- ============================================

-- ============================
-- 1. Total Revenue
-- ============================
select round(sum(quantity*list_price*(1-discount)),2) as total_revenue
 from bike_store.order_items

-- ============================
--2. Total Orders
-- ============================
select count(*) as total_orders
from bike_store.orders

-- ============================
--3. Total Customers
-- ============================
select count(*) as total_customers
 from bike_store.customers

-- ============================
--4. Monthly revenue trend
-- ============================
select
format_date("%Y-%m",o.order_date) as month,
sum(oi.quantity*oi.list_price*(1-oi.discount)) as total_revenue
from bike_store.orders as o
join bike_store.order_items as oi
on o.order_id = oi.order_id
group by month
order by month

-- ============================
--5. Revenue by Category
-- ============================
select c.category_name,
round(sum(oi.quantity*oi.list_price*(1-oi.discount)),2) as revenue
from bike_store.order_items as oi
join bike_store.products as p
on oi.product_id = p.product_id
join bike_store.categories as c
on c.category_id = p.category_id
group by c.category_name
order by revenue desc

====================================
--6. Customers who spent more than 3000
====================================

select 
    c.customer_id,
    c.first_name,
    c.last_name,
    round(sum(oi.quantity * oi.list_price * (1 - oi.discount)),2) as total_spent
from bike_store.customers c
join bike_store.orders o 
    on c.customer_id = o.customer_id
join bike_store.order_items oi 
    on o.order_id = oi.order_id
group by c.customer_id, c.first_name, c.last_name
having total_spent > 3000
order by total_spent desc

-- ====================================
--7. Top 5 Customers by Total Spending
-- ====================================
with customer_sales as
(select c.customer_id,c.first_name,c.last_name,
round(sum(oi.quantity*oi.list_price*(1-oi.discount)),2) as total_spent
from bike_store.customers as c
join bike_store.orders as o
on c.customer_id = o.customer_id
join bike_store.order_items as oi
on o.order_id = oi.order_id
group by c.customer_id,c.first_name,c.last_name),

ranked_customer as (select *,dense_rank()over(order by total_spent desc) as rn
from customer_sales)

select * from ranked_customer
where rn <= 5
order by total_spent desc

-- ============================
--8. Average Order Value
-- ============================
with order_total as
(select order_id, sum(quantity * list_price * (1 - discount)) as total
from bike_store.order_items
group by order_id)
select round(avg(total),2) as avg_order_value
from order_total

===================================================
--9. Store Performance Ranking based on Total Sales
===================================================
with store_sales as (select s.store_name,
round(sum(oi.quantity * oi.list_price * (1 - oi.discount)),2)as total_sales
 from bike_store.stores as s
                       join bike_store.orders as o
                       on s.store_id = o.store_id
                       join bike_store.order_items as oi
                       on oi.order_id = o.order_id
                       group by s.store_name)

select *,rank() over(order by total_sales desc) as store_rank
 from store_sales

===================================================
--10. Customer Segmentation (High/ Medium/Low Value)
===================================================
with customer_value as
(select c.customer_id, sum(oi.quantity*oi.list_price*(1-oi.discount)) as total_spent
from bike_store.customers as c
join bike_store.orders as o
on c.customer_id = o.customer_id
join bike_store.order_items as oi
on oi.order_id =o.order_id
group by c.customer_id)

select *, case when total_spent > 5000 then "high_value_customers"
               when total_spent between 2000 and 5000 then "medium_value_customers"
               else "low_value_customers"
               end as segmented_customers
from customer_value

============================
--11. Running Sales Total
============================
with daily_sales as(
    select
        o.order_date,
        round(sum(oi.quantity * oi.list_price * (1 - oi.discount)),2) as sales
    from bike_store.orders o
    join bike_store.order_items oi
        on o.order_id = oi.order_id
    group by o.order_date
)
select
    order_date,
    sales,
    sum(sales) over(order by order_date) AS running_total
from daily_sales
order by order_date

===========================
--12. Repeat Customers
===========================
with customer_orders AS (
    select
        customer_id,
        count(order_id) AS total_orders
    from bike_store.orders
    group by customer_id
)
select
    c.customer_id,
    c.first_name,
    c.last_name,
    co.total_orders
from customer_orders co
join bike_store.customers c
    on co.customer_id = c.customer_id
where co.total_orders > 1
order by co.total_orders desc

========================
--13. Staff Performance
========================
select 
    s.staff_id,
    concat(s.first_name," ",s.last_name) as full_name,
    round(sum(oi.quantity * oi.list_price * (1 - oi.discount)),2) as total_sales
from bike_store.staffs s
join bike_store.orders o
    on s.staff_id = o.staff_id
join bike_store.order_items oi
    on o.order_id = oi.order_id
group by s.staff_id, s.first_name, s.last_name
order by total_sales desc

===========================
--14. Brand-wise Revenue
===========================
select 
    b.brand_name,
    round(sum(oi.quantity * oi.list_price * (1 - oi.discount)),2) as revenue
from bike_store.order_items oi
join bike_store.products p
    on oi.product_id = p.product_id
join bike_store.brands b
    on p.brand_id = b.brand_id
group by b.brand_name
order by revenue desc

===========================
--15. Stock Analysis
===========================
select 
    p.product_name,
    sum(s.quantity) as total_stock
from bike_store.stocks s
join bike_store.products p
    on s.product_id = p.product_id
group by p.product_name
order by total_stock asc

===============================
--16. Store-wise Orders
===============================
select 
    s.store_name,
    count(o.order_id) as total_orders
from bike_store.stores s
join bike_store.orders o
    on s.store_id = o.store_id
group by s.store_name
order by total_orders desc



