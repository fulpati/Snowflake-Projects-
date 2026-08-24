# Customer Sales Analytics using Snowflake

## Project Overview

This project implements a Customer Sales Analytics solution using Snowflake Cloud Data Warehouse.

The project uses customer information, food item details, and order transaction data to generate analytical reports for business decision-making.

## Technologies Used

- Snowflake Cloud Data Warehouse
- SQL
- CSV
- GitHub

## Snowflake Objects

- Virtual Warehouse: `SALES_WH`
- Database: `CUSTOMER_SALES_DB`
- Schema: `SALES_SCHEMA`
- Internal Stage: `SALES_STAGE`
- File Format: `CSV_FORMAT`

## Tables

### CUSTOMERS
Contains customer information such as customer ID, name, email, phone, and city.

### FOODITEMS
Contains food item details including price, category, and availability.

### ORDERS
Contains order transactions including customer, food item, quantity, order date, status, and total amount.

## Analysis Performed

- Customer-wise Sales Report
- Highest Spending Customer
- Total Business Revenue
- Category-wise Revenue
- Order Status-wise Revenue
- Top Three Customers
- Customer Purchase Frequency
- Delivered Orders
- Orders Placed After 12 July 2026
- Customer Sales Reporting View

## Project Structure

```text
Customer-Sales-Analytics-Snowflake/
│
├── project_1.sql
├── customers.csv
├── fooditems.csv
├── orders.csv
└── README.md
