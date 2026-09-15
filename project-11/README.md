# Project 11 — Enterprise Customer Master Data Management using Hybrid SCD Strategies

## 📌 Project Overview

This project implements an **Enterprise Customer Master Data Management system** using **Snowflake SQL**.

The objective is to maintain customer information while applying different Slowly Changing Dimension (SCD) strategies to different customer attributes.

A unified **Hybrid Customer Dimension** is implemented to simultaneously support:

- Operational attributes that are overwritten
- Historical tracking of customer segments
- Previous-value tracking for cities
- Current, previous, and historical tracking of memberships

The final implementation maintains both the **current customer state** and the required **historical versions**.

---

## 🛠️ Technologies Used

- Snowflake
- Snowflake SQL
- CSV
- SCD / Slowly Changing Dimensions
- Hybrid SCD Strategy

---

## 🏗️ Project Architecture

```text
customers_initial.csv
        |
        v
CUSTOMER_INITIAL_STAGE
        |
        | COPY INTO
        v
CUSTOMER_INITIAL_RAW
        |
        | INSERT ... SELECT
        v
CUSTOMER_HYBRID_DIM
        ^
        |
CUSTOMER_UPDATES_RAW
        ^
        |
CUSTOMER_UPDATES_STAGE
        ^
        |
customer_updates.csv
