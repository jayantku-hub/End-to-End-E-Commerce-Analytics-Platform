CREATE DATABASE olist_project;

-- customers → orders → order_items ← products
--                     ↓
--                  payments
--                     ↓
--                  sellers


-- 8 Tables
-- 100K+ Orders
-- Relational Database Design

USE olist_project;

CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

select count(*) from geolocation;
SET GLOBAL max_allowed_packet = 1073741824;
CREATE TABLE orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);

CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);




CREATE TABLE payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

select count(*) from reviews;


CREATE TABLE sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);


CREATE TABLE product_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                         Assigning primary key
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

Alter table customers
add primary key(customer_id);

Alter table orders
add primary key(order_id);

Alter table products
add primary key(product_id);

Alter table sellers
add primary key(seller_id);

-- Do not ass pk to rest of the table due to duplicates rows exist there  

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Add FOREIGN KEYS
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

Alter table orders
add constraint fk_orders_customers
foreign key(customer_id)
references customers(customer_id);

Alter table order_items
add constraint fk_orderitems_orders
foreign key (order_id)
references orders(order_id);

alter table order_items
add constraint fk_orderitems_products
foreign key (product_id)
references products(product_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_sellers
FOREIGN KEY (seller_id)
REFERENCES sellers(seller_id);

ALTER TABLE payments
ADD CONSTRAINT fk_payments_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- Verify Relationships

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'olist_project'
AND REFERENCED_TABLE_NAME IS NOT NULL;

--                            DATA VALIDATION & EXPLORATION

SELECT COUNT(*) AS total_customers
FROM customers;

SELECT COUNT(*) AS total_orders
FROM orders;

SELECT COUNT(*) AS total_order_items
FROM order_items;

SELECT COUNT(*) AS total_products
FROM products;

SELECT COUNT(*) AS total_payments
FROM payments;

SELECT COUNT(*) AS total_sellers
FROM sellers;

SELECT COUNT(*) AS total_location
FROM geolocation;

-- --------------------------- Check NULL Values ---------------------------------------------------------------------------

-- orders table NULL check
SELECT 
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivery_date
FROM orders;
	
-- products NULL check
SELECT 
	SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category
from products;


-- --------------------------- Check Duplicate Orders ---------------------------------------------------------------------------

SELECT order_id, 
	   count(*) as duplicate_count
FROM orders
GROUP BY order_id
HAVING count(*) > 1;	


-- ----------------------------- Explore Order Status ---------------------------------------------------------------------------


SELECT order_status, 
		COUNT(*) AS total_orders
FROM ORDERS
group by order_status
order by total_orders desc;

-- ------------------------------- Explore Payment Types ---------------------------------------------------------------------------

SELECT payment_type,
		COUNT(*) AS total_payment
FROM payments
group by payment_type
order by total_payment desc;


-- ------------------------------ Explore Product Categories ---------------------------------------------------------------------------

SELECT product_category_name,
	   COUNT(*) AS total_product
from products
group by product_category_name
order by total_product desc;        
       
       

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------- BUSINESS KPI ANALYSIS ---------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- KPI 1 — Total Revenue
SELECT 
	round(SUM(price),2) as total_revenue 
FROM order_items;

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KPI 2 — Total Freight Cost
select 
	round(sum(freight_value),2) AS total_freight_cost
from order_items;

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KPI 3 — Average Order Value

SELECT 
    ROUND(
        SUM(price) / COUNT(DISTINCT order_id),
        2
    ) AS avg_order_value
FROM order_items;

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KPI 4 — Total Unique Customers

select 
	count(distinct customer_id) as unique_customer 
from customers;


-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KPI 5 — Top 10 Revenue States

select c.customer_state,
	   sum(oi.price) as total_sales
from customers c
join orders o
on
c.customer_id = o.customer_id
join  order_items oi
on o.order_id = oi.order_id
group by c.customer_state
order by total_sales Desc
limit 10;
       
   
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------   
-- KPI 6 — Top Product Categories	

select 	p.product_category_name,
        pt.product_category_name_english,
		sum(oi.price) as top_product_sale
from products p
join order_items oi
on
p.product_id = oi.product_id
join product_translation pt
on
p.product_category_name = pt.product_category_name
group by p.product_category_name,
pt.product_category_name_english

order by top_product_sale desc
limit 10;


-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KPI 7 — Monthly Sales Trend

select 
	year(o.order_purchase_timestamp) as year_no,
    month(o.order_purchase_timestamp) as month_no,
    sum(oi.price) as total_sales
from orders o 
join order_items oi
on
o.order_id = oi.order_id
group by year_no, month_no
order by year_no, month_no;


-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KPI 8 — Top Sellers

select s.seller_id, 
round(sum(oi.price),2) as total_sale
from sellers s
join order_items oi
on
s.seller_id = oi.seller_id
group by s.seller_id
order by total_sale desc
limit 10;



-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KPI 9 — Most Used Payment Types

select payment_type,
	   count(payment_type) as payment_count
 from payments
 group by payment_type
 order by payment_count desc;


-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- KPI 10 — Average Delivery Time

SELECT 
    ROUND(
        AVG(
            DATEDIFF(
                order_delivered_customer_date,
                order_purchase_timestamp
            )
        ),
        2
    ) AS avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 							PHASE 3 — ADVANCED BUSINESS ANALYSIS
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

use olist_project; 

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Question 1: Top 10 Customers by Revenue

select o.customer_id,
	   sum(oi.price) as total_revenue
from orders o
join order_items oi 
on
o.order_id = oi.order_id
group by o.customer_id
order by total_revenue desc
limit 10;    


-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Question 2: Monthly Sales Trend

select date_format(o.order_purchase_timestamp, '%Y-%m') as months,
		sum(oi.price) as total_revenue
from orders o
join order_items oi
on o.order_id = oi.order_id
group by months
order by months  desc;      


--  Repeat Customers
-- Which customers purchased more than once?

select 
	c.customer_unique_id,
    count(o.order_id) as total_orders
from customers c
join orders o
on
c.customer_id = o.customer_id
group by customer_unique_id
having count(o.order_id) > 1
order by total_orders desc;
    
    
--  Not-Repeated Customers
-- Which customers does not purchased more than once

select 
	c.customer_unique_id,
    count(o.order_id) as total_orders
from customers c
join orders o
on
c.customer_id = o.customer_id
group by customer_unique_id
having count(o.order_id) = 1
order by total_orders desc;
    

-- Category Contribution %

select pt.product_category_name_english,
	   sum(oi.price) as total_revenue,
       round(sum(oi.price)*100 /
	   sum(sum(oi.price)) over() ,2)
       as contributions
       
from products p
JOIN order_items oi 
on
p.product_id = oi.product_id
join product_translation pt
on
pt.product_category_name = p.product_category_name
group by pt.product_category_name_english
order by total_revenue desc;


-- Rank Categories

select pt.product_category_name_english,
	   sum(oi.price) as total_revenue,
       round(sum(oi.price)*100 /
	   sum(sum(oi.price)) over() ,2)
       as contributions,
       rank() over(order by  sum(oi.price) desc ) as r_n
       
from products p
JOIN order_items oi 
on
p.product_id = oi.product_id
join product_translation pt
on
pt.product_category_name = p.product_category_name
group by pt.product_category_name_english
order by total_revenue desc;       
        


-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 						     	Customer Retention Analysis
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



with retention_contribution as (

SELECT
    c.customer_unique_id as customer_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id)

select     customer_id,
    total_orders,
        ROUND(
        total_orders * 100.0 /
        SUM(total_orders) OVER(),
        2) AS contribution_pct
     from retention_contribution
     WHERE total_orders > 1
     ORDER BY contribution_pct DESC;



-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 					          Cohort Analysis
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Find First Purchase Month

with first_order as (select customer_id, 
	   min(order_purchase_timestamp) as first_order_date
       from orders
       group by customer_id)
       
       select * from first_order;       
       
-- Create Cohort Month       
       
WITH first_purchase AS
(
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    c.customer_unique_id,
    DATE_FORMAT(fp.first_order_date,'%Y-%m') AS cohort_month,
    DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS order_month
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN first_purchase fp
    ON c.customer_unique_id = fp.customer_unique_id
WHERE c.customer_unique_id IN
(
    SELECT c.customer_unique_id
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
    HAVING COUNT(*) > 1
)
ORDER BY c.customer_unique_id;       
       
       
       
       
       
       
       
       
       
       
       

