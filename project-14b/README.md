# Project 14B — Financial Gateway: Medallion Lakehouse & Snapshot Auditing

## 📌 Project Overview

This project implements a **Medallion Lakehouse Architecture** for a fintech payment gateway using **Snowflake SQL**.

The pipeline follows the:

**Bronze → Silver → Gold**

architecture to process raw payment gateway JSON data into cleaned transaction data and merchant-level financial settlement metrics.

The project also demonstrates **Snowflake Time Travel** for snapshot auditing and recovery after accidental data corruption.

---

## 🏗️ Architecture

```text
                Raw JSON Payment Data
                         │
                         ▼
                 ┌───────────────┐
                 │     STAGE     │
                 │ JSON File     │
                 └───────┬───────┘
                         │
                    COPY INTO
                         │
                         ▼
                 ┌───────────────┐
                 │    BRONZE     │
                 │ Raw VARIANT   │
                 │ JSON Payloads │
                 └───────┬───────┘
                         │
                    ETL / Clean
                         │
                         ▼
                 ┌───────────────┐
                 │    SILVER     │
                 │ Cleaned Data  │
                 │ Masked Cards  │
                 │ Fee Calculated│
                 └───────┬───────┘
                         │
                    Aggregation
                         │
                         ▼
                 ┌───────────────┐
                 │     GOLD      │
                 │ Merchant      │
                 │ Settlements   │
                 └───────────────┘

                         ▲
                         │
                 Snowflake Time Travel
                 Snapshot Auditing
                 & Recovery
```

---

## 🎯 Business Scenario

The system represents a fintech payment gateway processing transactions from multiple merchants.

The pipeline must:

- Ingest raw JSON payment transactions.
- Extract and clean transaction attributes.
- Mask sensitive card information.
- Calculate gateway processing fees.
- Calculate net settlement amounts.
- Aggregate approved transactions by merchant.
- Detect and recover from accidental status corruption.
- Reconcile financial totals across the Bronze, Silver, and Gold layers.

---

## 🛠️ Technologies Used

- **Snowflake**
- **Snowflake SQL**
- **VARIANT / JSON**
- **Snowflake Stages**
- **COPY INTO**
- **Medallion Architecture**
- **Time Travel**
- **CTEs**
- **Aggregation Functions**
- **CASE Expressions**

---

## 🗄️ Snowflake Environment

Database:

```sql
PROJECT_14A_DB
```

Schema:

```sql
ECOMMERCE_ANALYTICS
```

Project objects:

```text
BRONZE_PAYMENT_PAYLOADS
SILVER_CLEANED_TRANSACTIONS
GOLD_MERCHANT_SETTLEMENTS
PAYMENT_BRONZE_STAGE
PAYMENT_JSON_FORMAT
```

---

# 🥉 Task 1 — Bronze Layer

## Objective

Ingest the raw payment gateway JSON payloads into Snowflake.

The dataset contains **8 payment transactions**.

### Raw Data Attributes

```text
txn_id
txn_time
merchant_id
merchant_name
card_number
amount
fee_pct
status
```

### Bronze Table

```sql
CREATE OR REPLACE TABLE BRONZE_PAYMENT_PAYLOADS (
    RAW_PAYLOAD VARIANT
);
```

### JSON File Format

```sql
CREATE OR REPLACE FILE FORMAT PAYMENT_JSON_FORMAT
TYPE = 'JSON';
```

### Snowflake Stage

```sql
CREATE OR REPLACE STAGE PAYMENT_BRONZE_STAGE
FILE_FORMAT = PAYMENT_JSON_FORMAT;
```

The JSON file was uploaded to the Snowflake stage and loaded using `COPY INTO`.

```sql
COPY INTO BRONZE_PAYMENT_PAYLOADS
FROM @PAYMENT_BRONZE_STAGE;
```

### Validation

```sql
SELECT COUNT(*) AS TOTAL_BRONZE_RECORDS_CT
FROM BRONZE_PAYMENT_PAYLOADS;
```

### Result

```text
TOTAL_BRONZE_RECORDS_CT
-----------------------
8
```

---

# 🥈 Task 2 — Silver Layer

## Objective

Transform the raw Bronze JSON data into structured transaction records.

The Silver layer performs:

- JSON field extraction
- Credit card masking
- Processing fee calculation
- Net settlement calculation
- Status preservation

### Silver Table

```sql
CREATE OR REPLACE TABLE SILVER_CLEANED_TRANSACTIONS (
    TXN_ID VARCHAR,
    TXN_TIME TIMESTAMP_TZ,
    MERCHANT_ID NUMBER,
    MERCHANT_NAME VARCHAR,
    MASKED_CARD VARCHAR,
    GROSS_AMOUNT NUMBER(18,2),
    FEE_PCT NUMBER(5,2),
    PROCESSING_FEE NUMBER(18,2),
    NET_SETTLEMENT_AMOUNT NUMBER(18,2),
    STATUS VARCHAR
);
```

### Processing Fee Formula

```text
PROCESSING_FEE =
GROSS_AMOUNT × (FEE_PCT / 100)
```

### Net Settlement Formula

```text
NET_SETTLEMENT_AMOUNT =
GROSS_AMOUNT - PROCESSING_FEE
```

### Card Masking

Raw card numbers are transformed into:

```text
XXXX-XXXX-XXXX-4444
```

Only the final four digits remain visible.

### Silver Results

| Transaction | Gross Amount | Processing Fee | Net Settlement | Status |
|---|---:|---:|---:|---|
| TXN-901 | 50,000.00 | 1,250.00 | 48,750.00 | APPROVED |
| TXN-902 | 12,000.00 | 360.00 | 11,640.00 | APPROVED |
| TXN-903 | 25,000.00 | 625.00 | 24,375.00 | PENDING |
| TXN-904 | 8,500.00 | 153.00 | 8,347.00 | APPROVED |
| TXN-905 | 45,000.00 | 1,350.00 | 43,650.00 | DECLINED |
| TXN-906 | 150,000.00 | 3,750.00 | 146,250.00 | APPROVED |
| TXN-907 | 3,200.00 | 57.60 | 3,142.40 | APPROVED |
| TXN-908 | 67,000.00 | 2,010.00 | 64,990.00 | PENDING |

---

# 🥇 Task 3 — Gold Layer

## Objective

Create a business-level settlement mart containing financial metrics for **APPROVED transactions only**.

### Gold Table

```sql
CREATE OR REPLACE TABLE GOLD_MERCHANT_SETTLEMENTS (
    MERCHANT_ID NUMBER,
    MERCHANT_NAME VARCHAR,
    TOTAL_APPROVED_GROSS NUMBER(18,2),
    TOTAL_GATEWAY_FEES NUMBER(18,2),
    TOTAL_NET_PAYOUT NUMBER(18,2),
    APPROVED_COUNT NUMBER
);
```

### Aggregations

The Gold layer calculates:

```text
TOTAL_APPROVED_GROSS
TOTAL_GATEWAY_FEES
TOTAL_NET_PAYOUT
APPROVED_COUNT
```

Only:

```sql
STATUS = 'APPROVED'
```

transactions are included.

### Gold Results

| Merchant ID | Merchant | Approved Gross | Gateway Fees | Net Payout | Approved Count |
|---:|---|---:|---:|---:|---:|
| 301 | TechZone | 200,000.00 | 5,000.00 | 195,000.00 | 2 |
| 302 | StyleHub | 12,000.00 | 360.00 | 11,640.00 | 1 |
| 303 | FreshMart | 11,700.00 | 210.60 | 11,489.40 | 2 |

---

# ⏪ Task 4 — Data Corruption & Time Travel

## Objective

Simulate an accidental data corruption event in the Silver layer and inspect the previous state using Snowflake Time Travel.

### Simulated Corruption

The approved TechZone transactions were intentionally changed:

```sql
UPDATE SILVER_CLEANED_TRANSACTIONS
SET STATUS = 'REFUNDED'
WHERE MERCHANT_NAME = 'TechZone'
  AND STATUS = 'APPROVED';
```

The two affected transactions were:

```text
TXN-901 → REFUNDED
TXN-906 → REFUNDED
```

`TXN-903` remained `PENDING` because it was never part of the update condition.

### Time Travel Inspection

Snowflake Time Travel was used to query the historical state of the table before the corruption.

The historical snapshot showed:

```text
TXN-901 → APPROVED
TXN-906 → APPROVED
```

This demonstrated the ability to inspect previous versions of Snowflake table data.

---

# 🔄 Task 5 — Time Travel Recovery

The corrupted TechZone statuses were restored using the historical Time Travel snapshot.

The recovery restored:

```text
TXN-901 → APPROVED
TXN-906 → APPROVED
```

### Recovery Validation

```text
MERCHANT_NAME   APPROVED_COUNT   REFUNDED_COUNT
--------------  ---------------  --------------
TechZone        2                0
```

This confirms that the corrupted statuses were successfully recovered.

---

# 🔍 Task 6 — End-to-End Reconciliation

The final task validates financial consistency across all three layers.

### Reconciliation Metrics

| Metric | Amount |
|---|---:|
| Bronze Gross Sum | 360,700.00 |
| Silver Gross Sum | 360,700.00 |
| Gold Approved Gross | 223,700.00 |

### Reconciliation Logic

Bronze and Silver contain all 8 transactions:

```text
360,700.00
```

Gold contains only approved transactions:

```text
200,000.00
+ 12,000.00
+ 11,700.00
----------------
223,700.00
```

### Final Validation

```text
BRONZE_GROSS_SUM   = 360700.00
SILVER_GROSS_SUM   = 360700.00
GOLD_GROSS_SUM     = 223700.00
DATA_MATCH_FLAG    = TRUE
```

---

# 📊 Final Pipeline Summary

```text
8 Raw JSON Records
        │
        ▼
      STAGE
        │
        │ COPY INTO
        ▼
     BRONZE
   8 records
   ₹360,700 gross
        │
        ▼
     SILVER
   8 records
   ₹360,700 gross
        │
        ▼
      GOLD
 Approved only
   ₹223,700 gross
        │
        ▼
 RECONCILIATION
     TRUE
```

---

# 🔐 Data Security

The project demonstrates basic sensitive-data protection by masking payment card numbers in the Silver layer.

Example:

```text
Raw:
4111222233334444

Masked:
XXXX-XXXX-XXXX-4444
```

This prevents the complete card number from being exposed in downstream analytical tables.

---

# ⏱️ Time Travel & Data Recovery

Snowflake Time Travel was used to:

1. Inspect the table before corruption.
2. Identify the correct historical transaction statuses.
3. Restore the corrupted records.
4. Validate the recovered state.

This demonstrates how historical table versions can support auditing and recovery workflows.

---

# 📁 Project Files

```text
Project-14B/
│
├── payment_payloads.json
├── Project-14b.txt
└── README.md
```

---

# ✅ Project Completion Checklist

- [x] Created Bronze table
- [x] Created JSON file format
- [x] Created Snowflake stage
- [x] Uploaded JSON dataset
- [x] Loaded 8 records using `COPY INTO`
- [x] Created Silver table
- [x] Extracted JSON fields
- [x] Masked card numbers
- [x] Calculated processing fees
- [x] Calculated net settlement amounts
- [x] Created Gold merchant settlement table
- [x] Aggregated approved transactions
- [x] Simulated status corruption
- [x] Used Snowflake Time Travel
- [x] Recovered corrupted statuses
- [x] Reconciled Bronze, Silver, and Gold totals
- [x] Confirmed `DATA_MATCH_FLAG = TRUE`

---

## 🎓 Key Concepts Demonstrated

- Medallion Architecture
- Bronze / Silver / Gold data layers
- JSON ingestion in Snowflake
- `VARIANT` data type
- Snowflake Internal Stages
- JSON File Formats
- `COPY INTO`
- Semi-structured data extraction
- Data masking
- Financial calculations
- Aggregations
- Snowflake Time Travel
- Snapshot auditing
- Data recovery
- Data reconciliation
- ETL / ELT pipeline design

---

## 🏁 Conclusion

Project 14B demonstrates an end-to-end **Financial Gateway Lakehouse pipeline in Snowflake**, beginning with raw JSON payment payloads and progressing through Bronze, Silver, and Gold layers.

The project also demonstrates how Snowflake **Time Travel** can be used for historical inspection and recovery after accidental data corruption.

The final reconciliation confirms that the Bronze and Silver layers contain the same total gross transaction value of **360,700.00**, while the Gold layer correctly represents only approved transactions with a gross value of **223,700.00**.
