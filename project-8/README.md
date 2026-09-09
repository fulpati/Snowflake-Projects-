# Project 8 — Customer Profile History Analysis using Snowflake

## 📌 Project Overview

This project demonstrates the **Slowly Changing Dimension (SCD) problem** in a Snowflake Data Warehouse environment.

An online retail company maintains customer information such as:

* City
* State
* Membership
* Customer Segment

These attributes can change over time. If the existing customer dimension record is simply overwritten when a change occurs, the previous values are lost.

The objective of this project is to demonstrate this problem using Snowflake and show the impact of overwriting customer dimension records.

> **Note:** This project demonstrates the SCD problem. It does **not** implement an SCD Type 2 solution.

---

## 🎯 Objectives

The main objectives of this project are:

1. Create a Snowflake database and schema.
2. Create an initial customer dimension.
3. Load initial customer data using a Snowflake stage and `COPY INTO`.
4. Load customer update data into a separate staging table.
5. Compare existing customer data with incoming updates.
6. Identify changed customer attributes.
7. Generate an attribute-level change report.
8. Demonstrate the overwrite approach.
9. Show the updated customer dimension.
10. Demonstrate the historical information lost after overwriting the dimension.
11. Analyze the business impact of historical data loss.

---

## 🏗️ Project Architecture

```text
customers_initial.csv
        |
        v
 Snowflake Stage
        |
        v
 DIM_CUSTOMER
        |
        | Compare
        |
        v
customer_updates.csv
        |
        v
 Snowflake Stage
        |
        v
CUSTOMER_UPDATES
        |
        v
 Identify Attribute Changes
        |
        v
 Overwrite DIM_CUSTOMER
        |
        v
Historical Data Loss
```

---

## 🛠️ Technologies Used

* Snowflake
* SQL
* CSV
* Snowflake Internal Stage
* `COPY INTO`
* `JOIN`
* `UNION ALL`
* `UPDATE`

---

## 📂 Input Files

### 1. customers_initial.csv

Initial customer data:

```csv
customer_id,customer_name,city,state,membership,segment
101,Amit Sharma,Hyderabad,Telangana,Silver,Regular
102,Priya Reddy,Warangal,Telangana,Gold,Premium
103,Rahul Verma,Vijayawada,Andhra Pradesh,Silver,Regular
104,Neha Patel,Hyderabad,Telangana,Gold,Premium
105,Arjun Gupta,Nagpur,Maharashtra,Bronze,Regular
```

### 2. customer_updates.csv

Customer update data:

```csv
customer_id,customer_name,city,state,membership,segment
101,Amit Sharma,Bengaluru,Karnataka,Gold,Premium
103,Rahul Verma,Chennai,Tamil Nadu,Gold,Premium
104,Neha Patel,Hyderabad,Telangana,Platinum,Premium
```

---

# 🗄️ Database Structure

## Database

```sql
CUSTOMER_SCD_DB
```

## Schema

```sql
CUSTOMER_ANALYTICS
```

## Main Tables

### DIM_CUSTOMER

Stores the initial and subsequently updated customer dimension.

| Column        | Description                  |
| ------------- | ---------------------------- |
| CUSTOMER_KEY  | Surrogate dimension key      |
| CUSTOMER_ID   | Business/customer identifier |
| CUSTOMER_NAME | Customer name                |
| CITY          | Customer city                |
| STATE         | Customer state               |
| MEMBERSHIP    | Membership level             |
| SEGMENT       | Customer segment             |

### CUSTOMER_UPDATES

Staging table containing incoming customer changes.

| Column        | Description              |
| ------------- | ------------------------ |
| CUSTOMER_ID   | Customer identifier      |
| CUSTOMER_NAME | Customer name            |
| CITY          | Updated city             |
| STATE         | Updated state            |
| MEMBERSHIP    | Updated membership       |
| SEGMENT       | Updated customer segment |

---

# 🔄 Project Workflow

## 1. Create Database and Schema

```sql
CREATE OR REPLACE DATABASE CUSTOMER_SCD_DB;

USE DATABASE CUSTOMER_SCD_DB;

CREATE OR REPLACE SCHEMA CUSTOMER_ANALYTICS;

USE SCHEMA CUSTOMER_ANALYTICS;
```

---

## 2. Create DIM_CUSTOMER

```sql
CREATE OR REPLACE TABLE DIM_CUSTOMER (
    CUSTOMER_KEY NUMBER AUTOINCREMENT,
    CUSTOMER_ID NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    MEMBERSHIP VARCHAR(50),
    SEGMENT VARCHAR(50)
);
```

---

## 3. Create Snowflake Stage

```sql
CREATE OR REPLACE STAGE CUSTOMER_STAGE;
```

---

## 4. Create CSV File Format

```sql
CREATE OR REPLACE FILE FORMAT CUSTOMER_CSV_FORMAT
TYPE = CSV
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"';
```

---

## 5. Load Initial Customer Data

The initial customer CSV is uploaded to the Snowflake stage and loaded using `COPY INTO`.

```sql
COPY INTO DIM_CUSTOMER
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    MEMBERSHIP,
    SEGMENT
)
FROM @CUSTOMER_STAGE
FILE_FORMAT = CUSTOMER_CSV_FORMAT;
```

### Initial Records

```text
101 → Hyderabad → Telangana → Silver
102 → Warangal  → Telangana → Gold
103 → Vijayawada → Andhra Pradesh → Silver
104 → Hyderabad → Telangana → Gold
105 → Nagpur → Maharashtra → Bronze
```

Total initial customers:

```text
5
```

---

# 6. Create CUSTOMER_UPDATES

```sql
CREATE OR REPLACE TABLE CUSTOMER_UPDATES (
    CUSTOMER_ID NUMBER,
    CUSTOMER_NAME VARCHAR(100),
    CITY VARCHAR(100),
    STATE VARCHAR(100),
    MEMBERSHIP VARCHAR(50),
    SEGMENT VARCHAR(50)
);
```

---

# 7. Load Customer Updates

```sql
COPY INTO CUSTOMER_UPDATES
FROM @CUSTOMER_STAGE/customer_updates.csv
FILE_FORMAT = CUSTOMER_CSV_FORMAT;
```

Records received:

```text
3
```

---

# 8. Identify Changed Customers

The existing dimension is compared with the incoming update table.

```sql
SELECT
    d.CUSTOMER_ID,
    d.CITY AS OLD_CITY,
    u.CITY AS NEW_CITY,
    d.MEMBERSHIP AS OLD_MEMBERSHIP,
    u.MEMBERSHIP AS NEW_MEMBERSHIP
FROM DIM_CUSTOMER d
JOIN CUSTOMER_UPDATES u
    ON d.CUSTOMER_ID = u.CUSTOMER_ID
WHERE d.CITY <> u.CITY
   OR d.STATE <> u.STATE
   OR d.MEMBERSHIP <> u.MEMBERSHIP
   OR d.SEGMENT <> u.SEGMENT
ORDER BY d.CUSTOMER_ID;
```

### Changed Customers

| CUSTOMER_ID | OLD_CITY   | NEW_CITY  | OLD_MEMBERSHIP | NEW_MEMBERSHIP |
| ----------: | ---------- | --------- | -------------- | -------------- |
|         101 | Hyderabad  | Bengaluru | Silver         | Gold           |
|         103 | Vijayawada | Chennai   | Silver         | Gold           |
|         104 | Hyderabad  | Hyderabad | Gold           | Platinum       |

---

# 9. Attribute-Level Change Report

The project identifies the following attribute changes:

| CUSTOMER_ID | ATTRIBUTE  | OLD_VALUE      | NEW_VALUE  |
| ----------: | ---------- | -------------- | ---------- |
|         101 | CITY       | Hyderabad      | Bengaluru  |
|         101 | STATE      | Telangana      | Karnataka  |
|         101 | MEMBERSHIP | Silver         | Gold       |
|         103 | CITY       | Vijayawada     | Chennai    |
|         103 | STATE      | Andhra Pradesh | Tamil Nadu |
|         103 | MEMBERSHIP | Silver         | Gold       |
|         104 | MEMBERSHIP | Gold           | Platinum   |

This demonstrates the core concept of a Slowly Changing Dimension: **dimension attributes can change over time.**

---

# 10. Demonstrate the SCD Problem

The existing dimension records are overwritten with the incoming values.

```sql
UPDATE DIM_CUSTOMER d
SET
    CITY = u.CITY,
    STATE = u.STATE,
    MEMBERSHIP = u.MEMBERSHIP,
    SEGMENT = u.SEGMENT
FROM CUSTOMER_UPDATES u
WHERE d.CUSTOMER_ID = u.CUSTOMER_ID;
```

This approach updates the existing customer records instead of preserving previous versions.

---

# 11. Updated Dimension

After the overwrite, the dimension contains:

| CUSTOMER_ID | CUSTOMER_NAME | CITY      | STATE       | MEMBERSHIP | SEGMENT |
| ----------: | ------------- | --------- | ----------- | ---------- | ------- |
|         101 | Amit Sharma   | Bengaluru | Karnataka   | Gold       | Premium |
|         102 | Priya Reddy   | Warangal  | Telangana   | Gold       | Premium |
|         103 | Rahul Verma   | Chennai   | Tamil Nadu  | Gold       | Premium |
|         104 | Neha Patel    | Hyderabad | Telangana   | Platinum   | Premium |
|         105 | Arjun Gupta   | Nagpur    | Maharashtra | Bronze     | Regular |

---

# ⚠️ Historical Data Loss

Consider Customer 101.

### Before Update

```text
Customer ID : 101
Name        : Amit Sharma
City        : Hyderabad
State       : Telangana
Membership  : Silver
```

### After Update

```text
Customer ID : 101
Name        : Amit Sharma
City        : Bengaluru
State       : Karnataka
Membership  : Gold
```

The current `DIM_CUSTOMER` table can only show:

```text
101 | Amit Sharma | Bengaluru | Karnataka | Gold
```

It can no longer determine that Customer 101 previously had:

```text
City       → Hyderabad
State      → Telangana
Membership → Silver
```

---

# 💼 Business Impact

Overwriting dimension records results in the loss of historical information.

For Customer 101:

| Attribute  | Historical Value | Current Value | Historical Value Available? |
| ---------- | ---------------- | ------------- | --------------------------- |
| City       | Hyderabad        | Bengaluru     | ❌ No                        |
| State      | Telangana        | Karnataka     | ❌ No                        |
| Membership | Silver           | Gold          | ❌ No                        |

Therefore, the company cannot use the current dimension to determine the customer's previous state.

---

# 🧠 Key SCD Concept

A **Slowly Changing Dimension** deals with changes to dimension attributes over time.

In this project, the problem is:

```text
Old Record
    ↓
Customer attribute changes
    ↓
Existing row overwritten
    ↓
Current value retained
    ↓
Historical value lost
```

For example:

```text
Hyderabad → Bengaluru
Silver    → Gold
```

After the overwrite, only the new values remain.

---

# 📌 Project Conclusion

This project successfully demonstrates the **Slowly Changing Dimension problem** using Snowflake.

The analysis shows that simply overwriting existing dimension records preserves current customer information but destroys historical information.

For example, after Customer 101's record is overwritten, the warehouse can identify the customer's current city as Bengaluru but cannot determine from the dimension that the customer previously lived in Hyderabad.

The project therefore demonstrates why historical tracking is important when designing customer dimensions in a data warehouse.

---

## 🚀 Future Enhancement

A future implementation could introduce an SCD strategy that preserves historical versions of customer records.

Possible approaches include:

* SCD Type 1 — overwrite old values
* SCD Type 2 — preserve historical versions
* SCD Type 3 — maintain selected previous values

However, this project focuses specifically on **demonstrating the SCD problem and historical data loss**, rather than implementing one of these historical-tracking solutions.

---

## 📁 Project Structure

```text
Project_8/
│
├── customers_initial.csv
├── customer_updates.csv
├── README.md
└── Project_8_SCD.sql
```

---

## ✅ Project Status

**Status: Completed**

### Tasks Completed

* [x] Create Snowflake database
* [x] Create schema
* [x] Create `DIM_CUSTOMER`
* [x] Create Snowflake stage
* [x] Load initial customer data
* [x] Display initial dimension
* [x] Create `CUSTOMER_UPDATES`
* [x] Load customer updates
* [x] Identify changed customers
* [x] Generate attribute-level change report
* [x] Overwrite dimension records
* [x] Display updated dimension
* [x] Demonstrate historical data loss
* [x] Perform business impact analysis

---

## 👩‍💻 Project Type

**Data Warehousing / Snowflake / Slowly Changing Dimensions**

**Platform:** Snowflake
**Language:** SQL
**Concept:** Slowly Changing Dimension (SCD) Problem
