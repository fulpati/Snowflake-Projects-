# Customer Membership History using SCD Type 3 and Type 6

## 📌 Project Overview

This project demonstrates how to manage changing customer membership information in a **Snowflake Data Warehouse** using two Slowly Changing Dimension (SCD) techniques:

* **SCD Type 3**
* **SCD Type 6**

The project uses an online retail customer membership scenario where customers can change their city, state, membership level, and segment over time.

The implementation demonstrates the differences between retaining only the previous value and maintaining complete historical versions of customer records.

---

## 🛠️ Technologies Used

* Snowflake
* Snowflake SQL
* CSV Files
* Slowly Changing Dimensions (SCD)

---

## 🎯 Objectives

The main objectives of this project are:

1. Create a Snowflake database and schema.
2. Implement an SCD Type 3 customer dimension.
3. Load initial customer data from CSV using a Snowflake Stage.
4. Track current and previous membership values.
5. Implement an SCD Type 6 customer dimension.
6. Maintain complete membership history.
7. Track effective and expiry dates.
8. Identify current and historical records.
9. Perform point-in-time historical queries.
10. Compare SCD Type 3 and SCD Type 6 approaches.
11. Validate record counts.

---

## 📂 Input Files

### customers_initial.csv

Contains the initial customer information.

```text
customer_id,customer_name,city,state,membership,segment
101,Amit Sharma,Hyderabad,Telangana,Silver,Regular
102,Priya Reddy,Warangal,Telangana,Gold,Premium
103,Rahul Verma,Vijayawada,Andhra Pradesh,Silver,Regular
104,Neha Patel,Hyderabad,Telangana,Gold,Premium
105,Arjun Gupta,Nagpur,Maharashtra,Bronze,Regular
```

### customer_updates.csv

Contains subsequent customer changes.

```text
customer_id,customer_name,city,state,membership,segment,effective_date
101,Amit Sharma,Bengaluru,Karnataka,Gold,Premium,2026-04-01
103,Rahul Verma,Chennai,Tamil Nadu,Gold,Premium,2026-04-05
104,Neha Patel,Hyderabad,Telangana,Platinum,Premium,2026-04-10
```

---

# 🏗️ Database Structure

```text
CUSTOMER_MEMBERSHIP_DW
│
└── MEMBERSHIP_ANALYTICS
    │
    ├── CUSTOMER_MEMBERSHIP_TYPE3
    │
    └── CUSTOMER_MEMBERSHIP_TYPE6
```

---

# 📊 SCD Type 3

## Purpose

SCD Type 3 maintains:

* Current membership
* Previous membership

Only the previous value is retained. No new row is created when a customer's membership changes.

### Type 3 Table

`CUSTOMER_MEMBERSHIP_TYPE3`

| Column              | Description         |
| ------------------- | ------------------- |
| CUSTOMER_KEY        | Surrogate key       |
| CUSTOMER_ID         | Business key        |
| CUSTOMER_NAME       | Customer name       |
| CITY                | Current city        |
| STATE               | Current state       |
| CURRENT_MEMBERSHIP  | Current membership  |
| PREVIOUS_MEMBERSHIP | Previous membership |
| SEGMENT             | Customer segment    |

---

## Type 3 Logic

When a membership changes:

```text
OLD CURRENT_MEMBERSHIP
          ↓
PREVIOUS_MEMBERSHIP

NEW MEMBERSHIP
          ↓
CURRENT_MEMBERSHIP
```

For example:

```text
Before:

CURRENT_MEMBERSHIP  = Silver
PREVIOUS_MEMBERSHIP = NULL


After:

CURRENT_MEMBERSHIP  = Gold
PREVIOUS_MEMBERSHIP = Silver
```

No additional row is created.

---

## Type 3 Final Result

| CUSTOMER_ID | CUSTOMER_NAME | CITY      | CURRENT_MEMBERSHIP | PREVIOUS_MEMBERSHIP |
| ----------: | ------------- | --------- | ------------------ | ------------------- |
|         101 | Amit Sharma   | Bengaluru | Gold               | Silver              |
|         102 | Priya Reddy   | Warangal  | Gold               | NULL                |
|         103 | Rahul Verma   | Chennai   | Gold               | Silver              |
|         104 | Neha Patel    | Hyderabad | Platinum           | Gold                |
|         105 | Arjun Gupta   | Nagpur    | Bronze             | NULL                |

### Type 3 Record Count

```text
5 rows
```

---

# 📚 SCD Type 6

## Purpose

SCD Type 6 provides a more complete historical solution by maintaining:

* Current value
* Previous value
* Historical records
* Effective date
* Expiry date
* Current-record indicator

### Type 6 Table

`CUSTOMER_MEMBERSHIP_TYPE6`

| Column                | Description                         |
| --------------------- | ----------------------------------- |
| CUSTOMER_KEY          | Surrogate key                       |
| CUSTOMER_ID           | Business key                        |
| CUSTOMER_NAME         | Customer name                       |
| CITY                  | Customer city                       |
| STATE                 | Customer state                      |
| CURRENT_MEMBERSHIP    | Current membership                  |
| PREVIOUS_MEMBERSHIP   | Previous membership                 |
| HISTORICAL_MEMBERSHIP | Historical membership               |
| SEGMENT               | Customer segment                    |
| EFFECTIVE_DATE        | Date from which record is effective |
| EXPIRY_DATE           | Date until which record is valid    |
| IS_CURRENT            | Indicates the current record        |

---

## Initial Type 6 Records

Initial records use:

```text
EFFECTIVE_DATE = 2026-01-01
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

For the initial records:

```text
CURRENT_MEMBERSHIP  = membership
PREVIOUS_MEMBERSHIP = NULL
HISTORICAL_MEMBERSHIP = membership
```

---

## Type 6 Change Process

When a customer membership changes:

### Step 1 — Close the existing record

```text
IS_CURRENT = FALSE
EXPIRY_DATE = day before new effective date
```

### Step 2 — Create a new version

```text
EFFECTIVE_DATE = new effective date
EXPIRY_DATE    = 9999-12-31
IS_CURRENT     = TRUE
```

---

## Example — Customer 101

Customer 101 changed:

```text
Silver → Gold
```

Effective date:

```text
2026-04-01
```

### Historical Record

```text
CUSTOMER_ID       = 101
MEMBERSHIP        = Silver
EFFECTIVE_DATE    = 2026-01-01
EXPIRY_DATE       = 2026-03-31
IS_CURRENT        = FALSE
```

### Current Record

```text
CUSTOMER_ID       = 101
MEMBERSHIP        = Gold
PREVIOUS          = Silver
EFFECTIVE_DATE    = 2026-04-01
EXPIRY_DATE       = 9999-12-31
IS_CURRENT        = TRUE
```

---

# 📜 Complete Type 6 History

The final Type 6 table contains historical and current versions:

| CUSTOMER_ID | CUSTOMER_NAME | CURRENT_MEMBERSHIP | PREVIOUS_MEMBERSHIP | EFFECTIVE_DATE | EXPIRY_DATE | IS_CURRENT |
| ----------: | ------------- | ------------------ | ------------------- | -------------- | ----------- | ---------- |
|         101 | Amit Sharma   | Silver             | NULL                | 2026-01-01     | 2026-03-31  | FALSE      |
|         101 | Amit Sharma   | Gold               | Silver              | 2026-04-01     | 9999-12-31  | TRUE       |
|         102 | Priya Reddy   | Gold               | NULL                | 2026-01-01     | 9999-12-31  | TRUE       |
|         103 | Rahul Verma   | Silver             | NULL                | 2026-01-01     | 2026-04-04  | FALSE      |
|         103 | Rahul Verma   | Gold               | Silver              | 2026-04-05     | 9999-12-31  | TRUE       |
|         104 | Neha Patel    | Gold               | NULL                | 2026-01-01     | 2026-04-09  | FALSE      |
|         104 | Neha Patel    | Platinum           | Gold                | 2026-04-10     | 9999-12-31  | TRUE       |
|         105 | Arjun Gupta   | Bronze             | NULL                | 2026-01-01     | 9999-12-31  | TRUE       |

The project specifies this final 8-row historical output.

---

# 🔎 Point-in-Time Query

A point-in-time query can determine which membership was valid on a particular date.

For Customer 101 on **2026-03-15**:

```sql
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CURRENT_MEMBERSHIP,
    EFFECTIVE_DATE,
    EXPIRY_DATE
FROM CUSTOMER_MEMBERSHIP_TYPE6
WHERE CUSTOMER_ID = 101
  AND '2026-03-15'::DATE
      BETWEEN EFFECTIVE_DATE AND EXPIRY_DATE;
```

### Result

```text
CUSTOMER_ID       101
CUSTOMER_NAME     Amit Sharma
MEMBERSHIP        Silver
EFFECTIVE_DATE    2026-01-01
EXPIRY_DATE       2026-03-31
```

Therefore, Customer 101 was a **Silver member on March 15, 2026**.

---

# ⚖️ SCD Type 3 vs SCD Type 6

| Feature         | SCD Type 3 | SCD Type 6 |
| --------------- | ---------- | ---------- |
| Current Value   | YES        | YES        |
| Previous Value  | YES        | YES        |
| Historical Rows | NO         | YES        |
| Effective Date  | NO         | YES        |
| Expiry Date     | NO         | YES        |
| IS_CURRENT      | NO         | YES        |

### Type 3

```text
One customer
     ↓
One row
     ↓
Current + Previous value
```

### Type 6

```text
One customer
     ↓
Multiple versions
     ↓
Current + Previous + Historical values
     ↓
Effective / Expiry dates
     ↓
Current-record indicator
```

---

# ✅ Record Count Validation

The final record counts are:

| Validation                         | Expected Result |
| ---------------------------------- | --------------: |
| SCD Type 3 Record Count            |               5 |
| SCD Type 6 Record Count            |               8 |
| SCD Type 6 Current Record Count    |               5 |
| SCD Type 6 Historical Record Count |               3 |

The Type 6 count is:

```text
Initial records             = 5
Additional historical rows  = 3
--------------------------------
Total Type 6 records        = 8
```

The project specifies these final validation results.

---

# 🧠 Key Learnings

Through this project, the following concepts were implemented:

* Slowly Changing Dimensions
* SCD Type 3
* SCD Type 6
* Current vs previous values
* Historical record management
* Effective and expiry dates
* Current-record flags
* Surrogate keys
* Snowflake tables
* Snowflake file formats
* Snowflake stages
* `COPY INTO`
* Point-in-time historical queries
* SCD implementation comparison
* Data validation using record counts

---

# 🎯 Conclusion

This project demonstrates two different approaches to managing changing customer membership information.

**SCD Type 3** is suitable when only the current and immediately previous value need to be retained. It maintains one row per customer.

**SCD Type 6** provides a more complete historical solution by maintaining multiple versions of customer records along with effective dates, expiry dates, previous values, and current-record indicators.

The final implementation successfully produced:

```text
SCD TYPE 3 RECORD COUNT              = 5
SCD TYPE 6 RECORD COUNT              = 8
SCD TYPE 6 CURRENT RECORD COUNT      = 5
SCD TYPE 6 HISTORICAL RECORD COUNT   = 3
```

This completes the **Customer Membership History using SCD Type 3 and Type 6** project.
