# Customer History Management using SCD Type 1 and Type 2

## 📌 Project Overview

This project demonstrates **Slowly Changing Dimensions (SCD)** in Snowflake using **SCD Type 1** and **SCD Type 2**.

An online retail company maintains customer information such as city, state, membership, and customer segment. Since these attributes can change over time, the project implements two different approaches:

* **SCD Type 1** — Overwrites the existing customer information without preserving the old value.
* **SCD Type 2** — Preserves historical customer information by creating a new record whenever a tracked attribute changes.

The project demonstrates the differences between the two approaches using a customer dataset and update records.

---

## 🎯 Objectives

* Create a Snowflake database and schema.
* Load customer data from CSV files.
* Implement an SCD Type 1 dimension.
* Apply Type 1 updates by overwriting existing records.
* Demonstrate Type 1 history loss.
* Implement an SCD Type 2 dimension.
* Maintain effective and expiry dates for customer versions.
* Maintain the `IS_CURRENT` indicator.
* Preserve historical customer records.
* Perform historical customer analysis.
* Compare SCD Type 1 and Type 2.
* Validate the final record counts.

---

## 🏗️ Architecture

```text
customers_initial.csv
        |
        v
  CUSTOMER_STAGE
        |
        v
CUSTOMER_INITIAL_RAW
        |
        +----------------------+
        |                      |
        v                      v
CUSTOMER_SCD_TYPE1     CUSTOMER_SCD_TYPE2
        |                      |
        |                      |
        v                      v
Overwrite Updates       Preserve History
        ^                      ^
        |                      |
        +----------+-----------+
                   |
        customer_updates.csv
```

---

## 📂 Input Files

### `customers_initial.csv`

Contains the initial customer records.

| Customer ID | Customer Name | City       | State          | Membership | Segment |
| ----------- | ------------- | ---------- | -------------- | ---------- | ------- |
| 101         | Amit Sharma   | Hyderabad  | Telangana      | Silver     | Regular |
| 102         | Priya Reddy   | Warangal   | Telangana      | Gold       | Premium |
| 103         | Rahul Verma   | Vijayawada | Andhra Pradesh | Silver     | Regular |
| 104         | Neha Patel    | Hyderabad  | Telangana      | Gold       | Premium |
| 105         | Arjun Gupta   | Nagpur     | Maharashtra    | Bronze     | Regular |

### `customer_updates.csv`

Contains the customer changes received later.

| Customer ID | Customer Name | City      | State      | Membership | Segment | Effective Date |
| ----------- | ------------- | --------- | ---------- | ---------- | ------- | -------------- |
| 101         | Amit Sharma   | Bengaluru | Karnataka  | Gold       | Premium | 2026-04-01     |
| 103         | Rahul Verma   | Chennai   | Tamil Nadu | Gold       | Premium | 2026-04-05     |
| 104         | Neha Patel    | Hyderabad | Telangana  | Platinum   | Premium | 2026-04-10     |

---

# 🗄️ Snowflake Database Structure

```text
CUSTOMER_HISTORY_DB
│
└── CUSTOMER_SCD
    │
    ├── CUSTOMER_SCD_TYPE1
    ├── CUSTOMER_SCD_TYPE2
    ├── CUSTOMER_INITIAL_RAW
    ├── CUSTOMER_INITIAL_RAW_TYPE2
    └── CUSTOMER_UPDATES_RAW
```

---

# 🔹 SCD Type 1

## Concept

SCD Type 1 directly updates the existing customer record.

When a customer's information changes:

```text
Old Value
   ↓
Overwritten
   ↓
New Value
```

The old value is not preserved.

### Example

Customer 101 initially:

```text
Hyderabad
Telangana
Silver
```

After the update:

```text
Bengaluru
Karnataka
Gold
```

The original Hyderabad/Telangana/Silver information is no longer available in the Type 1 table.

---

## Type 1 Table

`CUSTOMER_SCD_TYPE1` contains:

| Column        | Description          |
| ------------- | -------------------- |
| CUSTOMER_KEY  | Surrogate key        |
| CUSTOMER_ID   | Natural/business key |
| CUSTOMER_NAME | Customer name        |
| CITY          | Current city         |
| STATE         | Current state        |
| MEMBERSHIP    | Current membership   |
| SEGMENT       | Current segment      |

---

## Type 1 Result

After applying the updates:

| Customer ID | Customer Name | City      | State       | Membership | Segment |
| ----------- | ------------- | --------- | ----------- | ---------- | ------- |
| 101         | Amit Sharma   | Bengaluru | Karnataka   | Gold       | Premium |
| 102         | Priya Reddy   | Warangal  | Telangana   | Gold       | Premium |
| 103         | Rahul Verma   | Chennai   | Tamil Nadu  | Gold       | Premium |
| 104         | Neha Patel    | Hyderabad | Telangana   | Platinum   | Premium |
| 105         | Arjun Gupta   | Nagpur    | Maharashtra | Bronze     | Regular |

### Type 1 Record Count

```text
5
```

The number of records remains unchanged because updates overwrite existing rows.

---

# 🔹 SCD Type 2

## Concept

SCD Type 2 preserves the complete history of customer changes.

When a customer's information changes:

```text
Existing Record
      |
      v
Expire Old Record
      |
      v
Insert New Version
```

The old record is retained and a new record is created.

The Type 2 table uses:

* `EFFECTIVE_DATE`
* `EXPIRY_DATE`
* `IS_CURRENT`

to manage different versions of a customer.

---

## Type 2 Table

`CUSTOMER_SCD_TYPE2` contains:

| Column         | Description                     |
| -------------- | ------------------------------- |
| CUSTOMER_KEY   | Surrogate key                   |
| CUSTOMER_ID    | Natural/business key            |
| CUSTOMER_NAME  | Customer name                   |
| CITY           | Customer city                   |
| STATE          | Customer state                  |
| MEMBERSHIP     | Customer membership             |
| SEGMENT        | Customer segment                |
| EFFECTIVE_DATE | Beginning of the record version |
| EXPIRY_DATE    | End of the record version       |
| IS_CURRENT     | Identifies the latest version   |

`CUSTOMER_KEY` is implemented using **AUTOINCREMENT** so that each new customer version receives a new surrogate key.

---

## Initial Type 2 Load

The five initial customers are loaded with:

```text
EFFECTIVE_DATE = 2026-01-01
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

Initial state:

```text
Total Records   = 5
Current Records = 5
```

---

# 🔄 Type 2 Changes

## Customer 101

Original:

```text
Hyderabad
Telangana
Silver
```

Effective from:

```text
2026-04-01
```

New:

```text
Bengaluru
Karnataka
Gold
```

The old record becomes:

```text
EFFECTIVE_DATE = 2026-01-01
EXPIRY_DATE    = 2026-03-31
IS_CURRENT     = FALSE
```

The new record becomes:

```text
EFFECTIVE_DATE = 2026-04-01
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

---

## Customer 103

Original:

```text
Vijayawada
Andhra Pradesh
Silver
```

Effective from:

```text
2026-04-05
```

New:

```text
Chennai
Tamil Nadu
Gold
```

The old record expires on:

```text
2026-04-04
```

The new record has:

```text
EFFECTIVE_DATE = 2026-04-05
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

---

## Customer 104

Original:

```text
Hyderabad
Telangana
Gold
```

Effective from:

```text
2026-04-10
```

New:

```text
Hyderabad
Telangana
Platinum
```

The old record expires on:

```text
2026-04-09
```

The new record has:

```text
EFFECTIVE_DATE = 2026-04-10
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

---

# 📊 Complete Type 2 History

After all changes are applied, the Type 2 dimension contains **8 records**.

```text
101 | Hyderabad   | Silver   | 2026-01-01 | 2026-03-31 | FALSE
101 | Bengaluru   | Gold     | 2026-04-01 | 9999-12-31 | TRUE

102 | Warangal    | Gold     | 2026-01-01 | 9999-12-31 | TRUE

103 | Vijayawada  | Silver   | 2026-01-01 | 2026-04-04 | FALSE
103 | Chennai     | Gold     | 2026-04-05 | 9999-12-31 | TRUE

104 | Hyderabad   | Gold     | 2026-01-01 | 2026-04-09 | FALSE
104 | Hyderabad   | Platinum | 2026-04-10 | 9999-12-31 | TRUE

105 | Nagpur      | Bronze   | 2026-01-01 | 9999-12-31 | TRUE
```

---

# 🔎 Current Customer Analysis

To retrieve only the latest version of every customer:

```sql
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    MEMBERSHIP,
    SEGMENT
FROM CUSTOMER_SCD_TYPE2
WHERE IS_CURRENT = TRUE
ORDER BY CUSTOMER_ID;
```

This returns the current state of all five customers.

---

# 🕒 Historical Analysis

SCD Type 2 allows the warehouse to answer historical questions.

### Example

Question:

> What was Customer 101's membership on March 15, 2026?

Query:

```sql
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    MEMBERSHIP,
    CITY,
    EFFECTIVE_DATE,
    EXPIRY_DATE
FROM CUSTOMER_SCD_TYPE2
WHERE CUSTOMER_ID = 101
  AND '2026-03-15'::DATE
      BETWEEN EFFECTIVE_DATE AND EXPIRY_DATE;
```

Result:

```text
Customer ID : 101
Customer    : Amit Sharma
Membership  : Silver
City        : Hyderabad
Effective   : 2026-01-01
Expiry      : 2026-03-31
```

This demonstrates the main advantage of SCD Type 2: **historical customer information remains available.**

---

# ⚖️ SCD Type 1 vs SCD Type 2

| Feature              | Type 1 | Type 2 |
| -------------------- | ------ | ------ |
| Old value preserved? | No     | Yes    |
| New row created?     | No     | Yes    |
| Historical analysis? | No     | Yes    |
| Effective Date       | No     | Yes    |
| Expiry Date          | No     | Yes    |
| IS_CURRENT           | No     | Yes    |
| Storage required     | Lower  | Higher |

---

# ✅ Final Validation

The final expected results are:

```text
SCD TYPE 1 RECORD COUNT
5

SCD TYPE 2 RECORD COUNT
8

SCD TYPE 2 CURRENT RECORD COUNT
5

SCD TYPE 2 HISTORICAL RECORD COUNT
3
```

### Why Type 2 has 8 records

```text
Initial customers       = 5
Changed customers       = 3
                            ─
Total Type 2 records    = 8
```

The three customers with historical changes are:

```text
101
103
104
```

---

# 🛠️ Technologies Used

* **Snowflake**
* **SQL**
* **CSV**
* **Snowflake Internal Stage**
* **COPY INTO**
* **SCD Type 1**
* **SCD Type 2**
* **AUTOINCREMENT Surrogate Keys**

---

# 📚 Key Concepts Demonstrated

* Data Warehousing
* Slowly Changing Dimensions
* Natural Keys
* Surrogate Keys
* SCD Type 1
* SCD Type 2
* Historical Data Preservation
* Effective Dating
* Expiry Dating
* Current Record Tracking
* CSV Data Loading
* Snowflake Stages
* `COPY INTO`
* `UPDATE`
* `INSERT`
* Historical Point-in-Time Analysis

---

# 🏁 Conclusion

This project demonstrates how customer history can be managed using two different Slowly Changing Dimension strategies.

**SCD Type 1** is suitable when historical values are not required because it overwrites the existing record.

**SCD Type 2** is suitable when historical information is important because it preserves the previous version and creates a new record for every change.

The final implementation successfully demonstrates:

```text
SCD Type 1
5 records
History overwritten

SCD Type 2
8 records
5 current records
3 historical records
History preserved
```
