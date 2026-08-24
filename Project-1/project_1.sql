create WAREHOUSE SALES_WH 
WITH 
WAREHOUSE_SIZE='X-SMALL'
AUTO_SUSPEND=60
AUTO_RESUME=TRUE;
USE WAREHOUSE SALES_WH;
CREATE DATABASE CUSTOMER_SALES_DB;
USE DATABASE CUSTOMER_SALES_DB;
CREATE SCHEMA SALES_SCHEMA;
USE SCHEMA SALES_SCHEMA;
CREATE FILE FORMAT CSV_FORMAT
TYPE='CSV'
FIELD_DELIMITER=','
SKIP_HEADER=1;
CREATE STAGE SALES_STAGE
FILE_FORMAT=CSV_FORMAT;
CREATE TABLE CUSTOMERS(
customer_id INTEGER,
first_name VARCHAR,
last_name VARCHAR,
email VARCHAR,
phone VARCHAR,
address VARCHAR
);
CREATE TABLE FOODITEMS(
food_id INTEGER,
name VARCHAR,
price NUMBER(10,2),
category VARCHAR,
availability VARCHAR
);
CREATE TABLE ORDERS(
order_id INTEGER,
customer_id INTEGER,
food_id INTEGER,
quantity INTEGER,
order_date TIMESTAMP,
status VARCHAR,
total_amount NUMBER(10,2)
);
COPY INTO CUSTOMERS 
FROM @SALES_STAGE/customers.csv
FILE_FORMAT=CSV_FORMAT;
COPY INTO FOODITEMS 
FROM @SALES_STAGE/fooditems.csv
FILE_FORMAT=CSV_FORMAT;
COPY INTO ORDERS 
FROM @SALES_STAGE/orders.csv
FILE_FORMAT=CSV_FORMAT;
SELECT * FROM CUSTOMERS;
SELECT * FROM FOODITEMS;
SELECT * FROM ORDERS;
SELECT c.customer_id,concat(c.first_name,' ',c.last_name) as customer_name,sum(o.total_amount) as total_spent from CUSTOMERS c 
inner join ORDERS o on c.customer_id=o.customer_id 
group by c.customer_id,c.first_name,c.last_name;

select c.customer_id, concat(c.first_name,' ',c.last_name) as customer_name, sum(o.total_amount) as total_spent from CUSTOMERS c 
inner join ORDERS o on c.customer_id=o.customer_id group by c.customer_id,c.first_name,c.last_name 
order by total_spent desc limit 1;

select sum(total_amount) as total_revenue from ORDERS;

SELECT f.category,sum(o.total_amount) as revenue from FOODITEMS f inner join ORDERS o on f.food_id=o.food_id group by f.category;

select status as order_status,sum(total_amount) as revenue from ORDERS group by status;

select c.first_name || ' ' || c.last_name as customer_name,sum(o.total_amount) as total_spent from CUSTOMERS c
join ORDERS o on c.customer_id=o.customer_id group by customer_name order by total_spent desc limit 3;

select c.customer_id,c.first_name || ' ' || c.last_name as customer_name, count(o.order_id) as order_placed from CUSTOMERS c 
join ORDERS o on c.customer_id=o.customer_id group by c.customer_id,customer_name;

select * from ORDERS where status='Delivered';

select o.order_id, c.first_name || ' ' || c.last_name as customer_name,o.order_date,o.status,o.total_amount from ORDERS o 
join CUSTOMERS c on o.customer_id=c.customer_id where order_date>'2026-07-12';

create view CUSTOMER_SALES_REPORT as 
select c.customer_id,c.first_name || ' ' || c.last_name as customer_name,sum(o.total_amount) as total_spent from CUSTOMERS c 
join ORDERS o on c.customer_id=o.customer_id group by c.customer_id,customer_name;

select * from CUSTOMER_SALES_REPORT;

SELECT *
FROM CUSTOMER_SALES_REPORT
ORDER BY total_spent DESC;


GITHUB LINK:https://github.com/fulpati/Customer-Sales-Analytics-Snowflake-project-1-.git