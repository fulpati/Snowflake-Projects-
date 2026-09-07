# Enterprise Retail Data Warehouse Design using Snowflake Schema

## 📌 Project Overview

This project demonstrates the design and implementation of an **Enterprise Retail Data Warehouse using Snowflake Schema architecture in Snowflake**.

The project starts with a retail sales data model containing customer, product, branch, calendar, and sales information. The dimension data is normalized into multiple related lookup tables to reduce redundancy, improve data consistency, and support hierarchical analysis.

The final warehouse supports analytical reporting across customers, products, brands, categories, cities, states, regions, branches, and time.

---

## 🎯 Business Objective

A multinational retail company receives daily sales transactions from retail branches across India.

As the business grows across multiple regions and product categories, dimension tables can contain repeated information such as:

- City
- State
- Region
- Brand
- Category
- Month
- Quarter
- Year

The objective of this project is to convert the existing **Star Schema into a Snowflake Schema** by normalizing dimension tables while preserving the central `FACT_SALES` table.

The Snowflake Schema reduces redundancy and provides standardized hierarchical master data for enterprise-level reporting.

---

## 🏢 Business Process

**Retail Sales Analytics**

### Business Event

A customer purchases one or more products from a retail branch on a specific date.

---

## 🗂️ Source Datasets

The project uses five CSV datasets:

```text
customers.csv
products.csv
branches.csv
calendar.csv
sales.csv
