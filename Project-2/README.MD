# Retail Sales Analytics Data Warehouse using Snowflake

## 📌 Project Overview

This project focuses on building a **Retail Sales Analytics Data Warehouse using Snowflake**.

A nationwide retail chain receives daily sales data from multiple branches in the form of CSV files. The objective of this project is to load the data into Snowflake, organize it into relational tables, and perform analytical queries to generate business intelligence reports.

The project demonstrates data loading, multi-table joins, aggregation, window functions, Common Table Expressions (CTEs), Views, and Materialized Views.

## 🎯 Objectives

* Create and configure a Snowflake data warehouse environment
* Load multiple CSV datasets into Snowflake
* Create relational tables for customers, products, branches, and sales
* Use `COPY INTO` for bulk data loading
* Perform multi-table joins
* Apply aggregate functions for business analysis
* Use Window Functions for ranking and cumulative analysis
* Use Common Table Expressions (CTEs)
* Create and query Views
* Create and query a Materialized View
* Generate business intelligence reports for sales analysis

## 🛠️ Technologies Used

* **Snowflake**
* **SQL**
* **CSV**
* **GitHub**

## 📂 Dataset

The project uses four CSV files:

### 1. customers.csv

Contains customer information.

| Column        | Description                |
| ------------- | -------------------------- |
| customer_id   | Unique customer identifier |
| customer_name | Customer name              |
| city          | Customer city              |
| membership    | Customer membership level  |

### 2. products.csv

Contains product information.

| Column       | Description               |
| ------------ | ------------------------- |
| product_id   | Unique product identifier |
| product_name | Product name              |
| category     | Product category          |
| price        | Product price             |

### 3. branches.csv

Contains branch information.

| Column      | Description              |
| ----------- | ------------------------ |
| branch_id   | Unique branch identifier |
| branch_name | Branch name              |
| city        | Branch city              |

### 4. sales.csv

Contains sales transaction information.

| Column       | Description                    |
| ------------ | ------------------------------ |
| sale_id      | Unique sale identifier         |
| customer_id  | Customer who made the purchase |
| product_id   | Product purchased              |
| branch_id    | Branch where the sale occurred |
| quantity     | Quantity purchased             |
| sale_date    | Date of transaction            |
| total_amount | Total transaction amount       |

## 🏗️ Snowflake Architecture

The Snowflake environment created for this project consists of:

```text
RETAIL_WH
    │
    └── RETAIL_DB
          │
          └── SALES_SCHEMA
                │
                ├── CUSTOMERS
                ├── PRODUCTS
                ├── BRANCHES
                ├── SALES
                │
                ├── SALES_REPORT (View)
                └── TOP_CUSTOMERS (Materialized View)
```

An internal stage and CSV file format were also created for loading the datasets.

## 🔄 Data Loading Process

The data loading process followed these steps:

1. Created the `RETAIL_WH` warehouse.
2. Created the `RETAIL_DB` database.
3. Created the `SALES_SCHEMA` schema.
4. Created a CSV file format.
5. Created an internal Snowflake stage.
6. Uploaded all four CSV files to the stage.
7. Created the required tables.
8. Loaded the CSV files using `COPY INTO`.
9. Verified the imported records.

## 📊 SQL Analysis

The project includes the following analytical reports:

### Basic Reports

* Display all customers
* Display all products
* Display all branches
* Display all sales transactions
* Calculate total business revenue
* Generate customer-wise sales
* Generate branch-wise sales
* Generate product-wise sales
* Generate category-wise sales
* Identify the highest revenue branch
* Identify the highest spending customer
* Find the top three products by revenue
* Find the top three customers by spending

### Window Function Analysis

Window functions were used to perform:

* Customer ranking based on total spending
* Branch ranking based on total sales
* Top-selling product in each category using `ROW_NUMBER()`
* Cumulative sales using `SUM() OVER()`
* Average sale amount using `AVG() OVER()`

### Common Table Expressions

CTEs were used to:

* Generate customer-wise revenue
* Identify customers whose spending is greater than the average customer spending

## 👁️ Views

### SALES_REPORT

A View named `SALES_REPORT` was created to provide a combined sales report by joining sales with customer, product, and branch information.

The report includes information such as:

* Sale details
* Customer details
* Membership
* Product
* Category
* Branch
* Branch city
* Quantity
* Total amount

### TOP_CUSTOMERS

A Materialized View named `TOP_CUSTOMERS` was created using the `SALES` table to store customer-wise spending totals.

The customer name can then be retrieved by joining the Materialized View with the `CUSTOMERS` table when generating the final report.

## 📁 Project Structure

```text
Project-2-Kimball/
│
├── customers.csv
├── products.csv
├── branches.csv
├── sales.csv
├── project_2.sql
└── README.md
```

## 🚀 How to Run the Project

### Step 1 — Open Snowflake

Log in to your Snowflake account and open a SQL Worksheet.

### Step 2 — Create the Environment

Create the warehouse, database, and schema:

```sql
CREATE WAREHOUSE RETAIL_WH;
CREATE DATABASE RETAIL_DB;
CREATE SCHEMA RETAIL_DB.SALES_SCHEMA;
```

### Step 3 — Create File Format and Stage

Create the CSV file format and internal stage required for data loading.

### Step 4 — Upload CSV Files

Upload:

```text
customers.csv
products.csv
branches.csv
sales.csv
```

to the Snowflake internal stage.

### Step 5 — Create Tables

Create:

```text
CUSTOMERS
PRODUCTS
BRANCHES
SALES
```

### Step 6 — Load Data

Use Snowflake's `COPY INTO` command to load the CSV data into the respective tables.

### Step 7 — Run Analytical Queries

Execute the SQL queries in `project_2.sql` to generate the required business intelligence reports.

## 📈 Key Concepts Demonstrated

This project demonstrates practical usage of:

* Data Warehousing
* Snowflake Cloud Data Warehouse
* SQL
* Relational Data Modeling
* Multi-table Joins
* Aggregate Functions
* `GROUP BY`
* `ORDER BY`
* `LIMIT`
* Window Functions
* `RANK()`
* `ROW_NUMBER()`
* `SUM() OVER()`
* `AVG() OVER()`
* Common Table Expressions
* Views
* Materialized Views
* Data Loading using `COPY INTO`

## 🎓 Learning Outcome

Through this project, I gained practical experience in loading structured datasets into Snowflake and performing analytical SQL operations on top of a cloud data warehouse.

The project helped demonstrate how raw transactional data can be transformed into meaningful business reports for analyzing customers, products, branches, revenue, and purchasing behavior.

## 👩‍💻 Author

**Shravani**

BE – Computer Science and Engineering (AIML)
