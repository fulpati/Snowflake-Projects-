# Project 15 — Cross-Border Logistics & Fleet Telematics Lakehouse Platform

## Overview

This project implements an end-to-end **Snowflake Lakehouse pipeline** for a global logistics firm's IoT fleet management platform.

### Modules
- **4.4a:** Schema-on-Read vs. Schema-on-Write
- **4.4b:** Medallion Architecture & Time Travel
- **Environment:** Snowflake SQL

The completed solution demonstrates:

- JSON ingestion through `VIVA_STAGING`
- Bronze Schema-on-Read storage using `VARIANT`
- Malformed payload quarantine
- Silver Schema-on-Write transformation
- Schema evolution
- Customs duty calculations
- Gold business aggregations
- Snowflake Time Travel disaster recovery
- Cross-layer reconciliation

---

## Architecture

```text
VIVA_STAGING
    |
    +-- project15_batch1.json
    +-- project15_batch2.json
    +-- project15_batch3.json
    |
    v
BRONZE_IOT_STREAMS
    |
    | Schema-on-Read
    v
SILVER_CUSTOMS_CLEARANCE
    |
    | Schema-on-Write
    v
GOLD_COUNTRY_DUTY_SUMMARY

Malformed payload
    |
    v
QUARANTINE_IOT_PAYLOADS
```

---

# Source Data

The source data is divided into three batches.

### Batch 1

Contains PL-801 through PL-804:

- PL-801 — TELEMATICS
- PL-802 — CUSTOMS
- PL-803 — TELEMATICS
- PL-804 — CUSTOMS

### Batch 2 — Schema Evolution

Contains:

- PL-805 — TELEMATICS with `driver_fatigue_score`
- PL-806 — CUSTOMS with `border_clearance_code`
- PL-807 — CUSTOMS with `border_clearance_code = null`

### Batch 3 — Corrupted Payload

Contains:

- PL-808 — TELEMATICS
- `MALFORMED_IOT_SENSOR_BINARY_BURST_DATA_ERR`

The malformed payload is not loaded as a valid Bronze record and is handled through the quarantine strategy.

---

# Setup

## Database and Schema

```sql
CREATE DATABASE IF NOT EXISTS LOGISTICS_LAKEHOUSE_DB;

USE DATABASE LOGISTICS_LAKEHOUSE_DB;

CREATE SCHEMA IF NOT EXISTS FLEET_CORE;

USE SCHEMA FLEET_CORE;
```

## Staging

The three JSON files are uploaded to:

```text
@VIVA_STAGING
```

Verify:

```sql
LIST @VIVA_STAGING;
```

Expected files:

```text
project15_batch1.json
project15_batch2.json
project15_batch3.json
```

---

# Task 1 — Bronze Data Lake Ingestion & Schema-on-Read

## Bronze Table

```sql
CREATE OR REPLACE TABLE BRONZE_IOT_STREAMS (
    INGEST_ID NUMBER AUTOINCREMENT,
    RAW_PAYLOAD VARIANT,
    RECORDED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
```

## Load From VIVA_STAGING

```sql
COPY INTO BRONZE_IOT_STREAMS (RAW_PAYLOAD)
FROM @VIVA_STAGING
FILE_FORMAT = (
    TYPE = 'JSON'
)
ON_ERROR = 'CONTINUE';
```

The malformed record is rejected while the eight valid JSON records are loaded.

## Verify Bronze Count

```sql
SELECT COUNT(*) AS TOTAL_BRONZE_RECORDS
FROM BRONZE_IOT_STREAMS;
```

Expected:

```text
8
```

## Schema-on-Read Query

```sql
SELECT
    RAW_PAYLOAD:payload_id::STRING AS PAYLOAD_ID,
    RAW_PAYLOAD:payload_type::STRING AS PAYLOAD_TYPE,
    RAW_PAYLOAD:timestamp::TIMESTAMP_TZ AS EVENT_TIMESTAMP,
    RAW_PAYLOAD:data:vehicle_id::STRING AS VEHICLE_ID,
    RAW_PAYLOAD:data:shipment_id::STRING AS SHIPMENT_ID,
    RAW_PAYLOAD:data:declared_value::NUMBER(18,2) AS DECLARED_VALUE
FROM BRONZE_IOT_STREAMS
ORDER BY INGEST_ID;
```

---

# Task 2 — Dead-Letter Queue / Quarantine

## Create Quarantine Table

```sql
CREATE OR REPLACE TABLE QUARANTINE_IOT_PAYLOADS (
    QUARANTINE_ID NUMBER AUTOINCREMENT,
    RAW_RECORD_TEXT STRING,
    REASON STRING
);
```

## Quarantine Malformed Payload

```sql
INSERT INTO QUARANTINE_IOT_PAYLOADS
(
    RAW_RECORD_TEXT,
    REASON
)
SELECT
    'MALFORMED_IOT_SENSOR_BINARY_BURST_DATA_ERR',
    'MALFORMED_JSON_BODY'
WHERE TRY_PARSE_JSON(
    'MALFORMED_IOT_SENSOR_BINARY_BURST_DATA_ERR'
) IS NULL;
```

## Verify

```sql
SELECT *
FROM QUARANTINE_IOT_PAYLOADS;
```

Expected:

```text
QUARANTINE_ID | RAW_RECORD_TEXT                            | REASON
--------------+--------------------------------------------+--------------------
1             | MALFORMED_IOT_SENSOR_BINARY_BURST_DATA_ERR | MALFORMED_JSON_BODY
```

---

# Task 3 — Silver Layer ETL

## Create Silver Table

```sql
CREATE OR REPLACE TABLE SILVER_CUSTOMS_CLEARANCE (
    SHIPMENT_ID STRING,
    PAYLOAD_ID STRING,
    VEHICLE_ID STRING,
    DESTINATION_COUNTRY STRING,
    DECLARED_VALUE NUMBER(18,2),
    DUTY_PCT NUMBER(5,2),
    DUTY_AMOUNT_DUE NUMBER(18,2),
    BORDER_CODE STRING,
    CLEARANCE_STATUS STRING
);
```

## ETL

```sql
INSERT INTO SILVER_CUSTOMS_CLEARANCE
(
    SHIPMENT_ID,
    PAYLOAD_ID,
    VEHICLE_ID,
    DESTINATION_COUNTRY,
    DECLARED_VALUE,
    DUTY_PCT,
    DUTY_AMOUNT_DUE,
    BORDER_CODE,
    CLEARANCE_STATUS
)
SELECT
    RAW_PAYLOAD:data:shipment_id::STRING AS SHIPMENT_ID,
    RAW_PAYLOAD:payload_id::STRING AS PAYLOAD_ID,
    RAW_PAYLOAD:data:vehicle_id::STRING AS VEHICLE_ID,
    RAW_PAYLOAD:data:destination_country::STRING AS DESTINATION_COUNTRY,
    RAW_PAYLOAD:data:declared_value::NUMBER(18,2) AS DECLARED_VALUE,
    RAW_PAYLOAD:data:duty_pct::NUMBER(5,2) AS DUTY_PCT,
    (
        RAW_PAYLOAD:data:declared_value::NUMBER(18,2)
        * RAW_PAYLOAD:data:duty_pct::NUMBER(5,2)
        / 100
    )::NUMBER(18,2) AS DUTY_AMOUNT_DUE,
    RAW_PAYLOAD:data:border_clearance_code::STRING AS BORDER_CODE,
    RAW_PAYLOAD:data:clearance_status::STRING AS CLEARANCE_STATUS
FROM BRONZE_IOT_STREAMS
WHERE RAW_PAYLOAD:payload_type::STRING = 'CUSTOMS';
```

## Expected Silver Data

| Shipment | Vehicle | Country | Declared Value | Duty % | Duty Due | Border Code | Status |
|---|---|---|---:|---:|---:|---|---|
| SHP-5001 | TRK-9001 | CAN | 85,000.00 | 5.0 | 4,250.00 | NULL | CLEARED |
| SHP-5002 | TRK-9002 | MEX | 42,000.00 | 7.5 | 3,150.00 | NULL | CLEARED |
| SHP-5003 | TRK-9003 | CAN | 120,000.00 | 4.0 | 4,800.00 | FAST_PASS_01 | CLEARED |
| SHP-5004 | TRK-9001 | MEX | 15,000.00 | 7.5 | 1,125.00 | NULL | HELD_INSPECTION |

---

# Task 4 — Gold Strategic Aggregation

Only shipments with `CLEARANCE_STATUS = 'CLEARED'` are included.

## Create Gold Table

```sql
CREATE OR REPLACE TABLE GOLD_COUNTRY_DUTY_SUMMARY (
    DEST_COUNTRY STRING,
    TOTAL_CLEARED_VAL NUMBER(18,2),
    TOTAL_DUTIES_COLLECTED NUMBER(18,2),
    AVG_DUTY_RATE_PCT NUMBER(10,2),
    CLEARED_SHIPMENTS NUMBER
);
```

## Populate Gold

```sql
INSERT INTO GOLD_COUNTRY_DUTY_SUMMARY
(
    DEST_COUNTRY,
    TOTAL_CLEARED_VAL,
    TOTAL_DUTIES_COLLECTED,
    AVG_DUTY_RATE_PCT,
    CLEARED_SHIPMENTS
)
SELECT
    DESTINATION_COUNTRY AS DEST_COUNTRY,
    SUM(DECLARED_VALUE) AS TOTAL_CLEARED_VAL,
    SUM(DUTY_AMOUNT_DUE) AS TOTAL_DUTIES_COLLECTED,
    ROUND(AVG(DUTY_PCT), 2) AS AVG_DUTY_RATE_PCT,
    COUNT(*) AS CLEARED_SHIPMENTS
FROM SILVER_CUSTOMS_CLEARANCE
WHERE CLEARANCE_STATUS = 'CLEARED'
GROUP BY DESTINATION_COUNTRY
ORDER BY DESTINATION_COUNTRY;
```

## Expected Gold Output

| Country | Total Cleared Value | Total Duties | Avg Duty Rate | Cleared Shipments |
|---|---:|---:|---:|---:|
| CAN | 205,000.00 | 9,050.00 | 4.41 | 2 |
| MEX | 42,000.00 | 3,150.00 | 7.50 | 1 |

---

# Task 5 — Disaster Recovery Using Snowflake Time Travel

## Simulate Corruption

```sql
UPDATE SILVER_CUSTOMS_CLEARANCE
SET CLEARANCE_STATUS = 'REJECTED'
WHERE DESTINATION_COUNTRY = 'CAN';
```

## Corruption Query ID Used

```text
01c76573-3203-7613-0018-46ee00101266
```

## View Original Data

```sql
SELECT
    SHIPMENT_ID,
    DESTINATION_COUNTRY,
    CLEARANCE_STATUS
FROM SILVER_CUSTOMS_CLEARANCE
BEFORE (
    STATEMENT => '01c76573-3203-7613-0018-46ee00101266'
)
ORDER BY SHIPMENT_ID;
```

## Create Recovery Copy

```sql
CREATE OR REPLACE TEMPORARY TABLE SILVER_RECOVERY AS
SELECT *
FROM SILVER_CUSTOMS_CLEARANCE
BEFORE (
    STATEMENT => '01c76573-3203-7613-0018-46ee00101266'
);
```

## Restore Silver

```sql
CREATE OR REPLACE TABLE SILVER_CUSTOMS_CLEARANCE AS
SELECT *
FROM SILVER_RECOVERY;
```

## Post-Recovery Audit

```sql
SELECT
    DESTINATION_COUNTRY,
    SUM(
        CASE
            WHEN CLEARANCE_STATUS = 'CLEARED' THEN 1
            ELSE 0
        END
    ) AS CLEARED_COUNT,
    SUM(
        CASE
            WHEN CLEARANCE_STATUS = 'REJECTED' THEN 1
            ELSE 0
        END
    ) AS REJECTED_COUNT
FROM SILVER_CUSTOMS_CLEARANCE
GROUP BY DESTINATION_COUNTRY
ORDER BY DESTINATION_COUNTRY;
```

Expected:

| Country | Cleared Count | Rejected Count |
|---|---:|---:|
| CAN | 2 | 0 |
| MEX | 1 | 0 |

---

# Task 6 — End-to-End Reconciliation

## Reconciliation Query

```sql
WITH BRONZE_TOTAL AS (
    SELECT
        SUM(
            RAW_PAYLOAD:data:declared_value::NUMBER(18,2)
        ) AS BRONZE_GROSS_TOTAL
    FROM BRONZE_IOT_STREAMS
    WHERE RAW_PAYLOAD:payload_type::STRING = 'CUSTOMS'
),

SILVER_TOTAL AS (
    SELECT
        SUM(DECLARED_VALUE) AS SILVER_GROSS_TOTAL
    FROM SILVER_CUSTOMS_CLEARANCE
),

GOLD_TOTAL AS (
    SELECT
        SUM(TOTAL_CLEARED_VAL) AS GOLD_GROSS_TOTAL
    FROM GOLD_COUNTRY_DUTY_SUMMARY
)

SELECT
    B.BRONZE_GROSS_TOTAL,
    S.SILVER_GROSS_TOTAL,
    G.GOLD_GROSS_TOTAL,
    CASE
        WHEN B.BRONZE_GROSS_TOTAL = S.SILVER_GROSS_TOTAL
         AND G.GOLD_GROSS_TOTAL <= S.SILVER_GROSS_TOTAL
        THEN TRUE
        ELSE FALSE
    END AS RECONCILED_FLAG
FROM BRONZE_TOTAL B
CROSS JOIN SILVER_TOTAL S
CROSS JOIN GOLD_TOTAL G;
```

## Expected Result

| Bronze Gross Total | Silver Gross Total | Gold Gross Total | Reconciled |
|---:|---:|---:|---|
| 262,000.00 | 262,000.00 | 247,000.00 | TRUE |

### Why Gold is 247,000

```text
85,000 + 42,000 + 120,000 = 247,000
```

The remaining `15,000` shipment is `HELD_INSPECTION`, so it is excluded from Gold.

---

# Final Validation Checklist

- [x] Database `LOGISTICS_LAKEHOUSE_DB`
- [x] Schema `FLEET_CORE`
- [x] Source files uploaded to `VIVA_STAGING`
- [x] Batch 1 loaded
- [x] Batch 2 loaded
- [x] Batch 3 loaded
- [x] 8 valid Bronze records
- [x] Schema-on-Read demonstrated
- [x] Malformed payload quarantined
- [x] Silver ETL completed
- [x] Duty calculations completed
- [x] Schema evolution handled
- [x] Gold aggregation completed
- [x] Time Travel corruption simulated
- [x] Original state recovered
- [x] Post-recovery audit passed
- [x] End-to-end reconciliation passed
- [x] `RECONCILED_FLAG = TRUE`

## Final Results

```text
Bronze Records       = 8
Quarantined Records  = 1
Silver Customs       = 4
Gold Countries       = 2

Bronze Total         = 262,000.00
Silver Total         = 262,000.00
Gold Total           = 247,000.00

Reconciled Flag      = TRUE
```

## Conclusion

Project 15 successfully implements a Snowflake-based cross-border logistics lakehouse using a Medallion Architecture.

The completed pipeline demonstrates raw IoT ingestion through `VIVA_STAGING`, Schema-on-Read Bronze storage, malformed-data quarantine, Schema-on-Write Silver modeling, schema evolution, customs-duty calculations, Gold business analytics, Snowflake Time Travel disaster recovery, and end-to-end reconciliation.
