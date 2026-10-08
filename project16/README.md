# Project 16: Healthcare Claims & Billing — Real-Time CDC & Dynamic Table Pipelines

## Overview

This project implements a continuous declarative data pipeline for a healthcare claims network using Snowflake SQL.

The pipeline demonstrates:

- Bronze staging for raw JSON healthcare claims
- Schema-on-read JSON processing with `VARIANT`
- Error handling and dead-letter/quarantine isolation
- Snowflake Streams for Change Data Capture (CDC)
- Silver-layer transformation and claim deduplication
- Dynamic Tables for declarative Gold-layer aggregation
- Dynamic Table refresh and dependency/DAG monitoring
- End-to-end Bronze → Silver → Gold reconciliation

**Target Module:** 4.5 — Declarative Data Pipelines: Dynamic Tables vs. Streams & Tasks  
**Platform:** Snowflake SQL  
**Database:** `HEALTHCARE_PIPELINE_DB`  
**Schema:** `CLAIMS_CORE`

---

## Architecture

```text
JSON Payload Files
       |
       v
+-------------------+
| Snowflake Stage   |
| CLAIMS_RAW_STAGE |
+---------+---------+
          |
          v
+----------------------+
| Bronze               |
| BRONZE_RAW_CLAIMS   |
| PAYLOAD VARIANT      |
+----------+-----------+
           |
           +--------------------+
           |                    |
           v                    v
      Snowflake Stream     Quarantine
      STRM_BRONZE_CLAIMS   QUARANTINE_CLAIMS_PAYLOADS
           |
           v
+-------------------------------+
| Silver                        |
| SILVER_CLAIMS_TRANSACTIONS   |
| Deduplicated latest claim     |
+---------------+---------------+
                |
                v
+----------------------------------+
| Gold / Dynamic Table             |
| DT_PROVIDER_FINANCIAL_SUMMARY   |
| Approved claims by provider     |
+----------------------------------+
```

---

# Tasks Completed

## Task 1 — Bronze Streaming Staging

Created:

```sql
HEALTHCARE_PIPELINE_DB.CLAIMS_CORE.BRONZE_RAW_CLAIMS
```

Columns:

| Column | Type | Purpose |
|---|---|---|
| `INGEST_ID` | `NUMBER` | Auto-generated ingestion identifier |
| `PAYLOAD` | `VARIANT` | Raw JSON payload |
| `LOADED_AT` | `TIMESTAMP_NTZ` | Ingestion timestamp |

Valid JSON payloads from Batch 1, Batch 2, and Batch 3 were loaded through a Snowflake stage.

### Bronze validation

```sql
SELECT COUNT(*) AS TOTAL_BRONZE_RECORDS
FROM BRONZE_RAW_CLAIMS;
```

Result:

```text
TOTAL_BRONZE_RECORDS
--------------------
8
```

The malformed Batch 3 record was not loaded as a valid Bronze JSON payload.

---

## Task 2 — Error Handling & Dead-Letter Isolation

Created:

```sql
QUARANTINE_CLAIMS_PAYLOADS
```

Columns:

| Column | Type |
|---|---|
| `QUARANTINE_ID` | `NUMBER` |
| `RAW_RECORD_TEXT` | `VARCHAR` |
| `REASON` | `VARCHAR` |

Malformed payload:

```text
INVALID_PAYLOAD_UNPARSEABLE_STRING
```

was identified using:

```sql
TRY_PARSE_JSON()
```

and isolated with:

```text
REASON = MALFORMED_JSON_BODY
```

Expected quarantine result:

| QUARANTINE_ID | RAW_RECORD_TEXT | REASON |
|---:|---|---|
| 1 | `INVALID_PAYLOAD_UNPARSEABLE_STRING` | `MALFORMED_JSON_BODY` |

---

## Task 3 — Silver Layer & CDC

Created Stream:

```sql
STRM_BRONZE_CLAIMS
```

on:

```sql
BRONZE_RAW_CLAIMS
```

Created Silver table:

```sql
SILVER_CLAIMS_TRANSACTIONS
```

Columns:

```text
CLAIM_ID
SUBMITTED_AT
PATIENT_ID
PROVIDER_ID
DIAGNOSIS_CODE
BILLED_AMOUNT
COPAY_AMOUNT
NET_PAYABLE_AMOUNT
STATUS
```

### Transformation

```text
NET_PAYABLE_AMOUNT = BILLED_AMOUNT - COPAY_AMOUNT
```

### Deduplication

Claims were deduplicated by `CLAIM_ID`, keeping the latest ingestion state.

Important status changes:

```text
CLM-301
PENDING  → APPROVED

CLM-303
PENDING  → DENIED
```

### Final Silver state

| CLAIM_ID | PATIENT_ID | PROVIDER_ID | DIAGNOSIS_CODE | BILLED_AMOUNT | COPAY_AMOUNT | NET_PAYABLE_AMOUNT | STATUS |
|---|---:|---|---|---:|---:|---:|---|
| CLM-301 | 5001 | PRV-10 | ICD-10-A | 15000.00 | 500.00 | 14500.00 | APPROVED |
| CLM-302 | 5002 | PRV-11 | ICD-10-B | 8500.00 | 300.00 | 8200.00 | APPROVED |
| CLM-303 | 5003 | PRV-10 | ICD-10-C | 45000.00 | 1500.00 | 43500.00 | DENIED |
| CLM-304 | 5004 | PRV-12 | ICD-10-A | 3200.00 | 100.00 | 3100.00 | APPROVED |
| CLM-305 | 5005 | PRV-11 | ICD-10-B | 120000.00 | 2500.00 | 117500.00 | APPROVED |
| CLM-306 | 5002 | PRV-12 | ICD-10-A | 6000.00 | 200.00 | 5800.00 | APPROVED |

---

# Task 4 — Dynamic Table / Gold Layer

Created:

```sql
DT_PROVIDER_FINANCIAL_SUMMARY
```

Configuration:

```text
TARGET_LAG = '1 minute'
WAREHOUSE   = COMPUTE_WH
```

The Dynamic Table summarizes only:

```text
STATUS = 'APPROVED'
```

claims, grouped by `PROVIDER_ID`.

### Gold result

| PROVIDER_ID | TOTAL_BILLED_AMOUNT | TOTAL_COPAY_COLLECT | TOTAL_NET_PAYABLE | APPROVED_CLAIMS |
|---|---:|---:|---:|---:|
| PRV-10 | 15000.00 | 500.00 | 14500.00 | 1 |
| PRV-11 | 128500.00 | 2800.00 | 125700.00 | 2 |
| PRV-12 | 9200.00 | 300.00 | 8900.00 | 2 |

---

# Task 5 — Dynamic Table Refresh & DAG Monitoring

Dynamic Table refresh history was queried to verify successful refresh execution.

The Dynamic Table graph history confirmed:

```text
TARGET_LAG_TYPE  = USER_DEFINED
TARGET_LAG_SEC   = 60
SCHEDULING_STATE = ACTIVE
```

The dependency graph establishes the upstream relationship:

```text
SILVER_CLAIMS_TRANSACTIONS
            |
            v
DT_PROVIDER_FINANCIAL_SUMMARY
```

This verifies that the Dynamic Table is configured with a one-minute target lag and is actively scheduled.

---

# Task 6 — End-to-End Reconciliation

The three pipeline layers were reconciled:

```text
Bronze → Silver → Gold
```

Actual totals from the supplied payloads:

| Layer | Gross Billed Total |
|---|---:|
| Bronze | 257700.00 |
| Silver | 197700.00 |
| Gold | 152700.00 |

### Reconciliation logic

**Bronze**

Contains all 8 valid raw claim events, including earlier versions of claims whose status was subsequently changed.

**Silver**

Contains the latest deduplicated state of each claim:

```text
15000 + 8500 + 45000 + 3200 + 120000 + 6000
= 197700
```

**Gold**

Contains only approved claims:

```text
15000 + 8500 + 3200 + 120000 + 6000
= 152700
```

---

## Important Data Reconciliation Note

The project brief states an expected Bronze total of:

```text
250700.00
```

However, the 8 supplied valid payloads mathematically total:

```text
257700.00
```

The supplied Silver and Gold expected totals do match the data:

```text
Silver = 197700.00
Gold   = 152700.00
```

Therefore, the implementation preserves the source payloads rather than deleting or altering a legitimate Bronze record merely to force the Bronze total to `250700.00`.

The source-data-accurate reconciliation is:

```text
BRONZE = 257700.00
SILVER = 197700.00
GOLD   = 152700.00
```

---

# Key Snowflake Objects

```text
DATABASE
└── HEALTHCARE_PIPELINE_DB

SCHEMA
└── CLAIMS_CORE

STAGE
└── CLAIMS_RAW_STAGE

TABLES
├── BRONZE_RAW_CLAIMS
├── QUARANTINE_CLAIMS_PAYLOADS
└── SILVER_CLAIMS_TRANSACTIONS

STREAM
└── STRM_BRONZE_CLAIMS

DYNAMIC TABLE
└── DT_PROVIDER_FINANCIAL_SUMMARY
```

---

# Key SQL Concepts Demonstrated

### Semi-structured data

```sql
PAYLOAD:claim_id::VARCHAR
PAYLOAD:billed_amount::NUMBER(18,2)
PAYLOAD:status::VARCHAR
```

### JSON error handling

```sql
TRY_PARSE_JSON(...)
```

### CDC

```sql
CREATE STREAM STRM_BRONZE_CLAIMS
ON TABLE BRONZE_RAW_CLAIMS;
```

### Incremental Silver processing

```sql
MERGE INTO SILVER_CLAIMS_TRANSACTIONS
```

### Deduplication

```sql
ROW_NUMBER() OVER (
    PARTITION BY CLAIM_ID
    ORDER BY INGEST_ID DESC
)
```

### Declarative transformation

```sql
CREATE DYNAMIC TABLE DT_PROVIDER_FINANCIAL_SUMMARY
TARGET_LAG = '1 minute'
WAREHOUSE = COMPUTE_WH
AS
...
```

---

# Final Project Status

| Task | Status |
|---|---|
| Bronze staging | ✅ Completed |
| JSON ingestion | ✅ Completed |
| Error quarantine | ✅ Completed |
| Stream / CDC | ✅ Completed |
| Silver transformation | ✅ Completed |
| Claim deduplication | ✅ Completed |
| Dynamic Table | ✅ Completed |
| Provider financial aggregation | ✅ Completed |
| Refresh history monitoring | ✅ Completed |
| DAG/dependency monitoring | ✅ Completed |
| End-to-end reconciliation | ✅ Completed |

## Conclusion

This project demonstrates a continuous healthcare claims pipeline in Snowflake using a combination of staged JSON ingestion, Bronze storage, Streams for CDC, Silver-layer transformations, and Dynamic Tables for declarative Gold-layer processing.

The final architecture replaces traditional batch-oriented processing with incremental and continuously refreshed data transformations while maintaining quarantine handling for malformed input and reconciliation across pipeline layers.
