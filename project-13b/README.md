# Healthcare Analytics Warehouse — Star Schema vs. Snowflake Schema

## 📌 Project Overview

This project demonstrates the design and implementation of a **Healthcare Analytics Data Warehouse** using **Snowflake SQL**.

The project implements the same healthcare business data using two dimensional modeling approaches:

* ⭐ **Star Schema**
* ❄️ **Snowflake Schema**

The objective is to compare how both approaches handle:

* Dimension modeling
* Fact table design
* Hierarchical data
* Analytical queries
* Master-data updates
* Data redundancy and normalization

---

## 🏥 Business Scenario

The warehouse models healthcare information for hospital networks, hospitals, treatments, patients, and insurance claims.

The source data contains:

* Hospital hierarchy
* Treatment hierarchy
* Patient information
* Insurance claims

The project uses a staging-based ETL workflow:

```text
CSV Files
    ↓
Snowflake Stage
    ↓
Staging Tables
    ↓
Dimension Tables
    ↓
Fact Tables
    ↓
Analytical Queries
```

---

## 🛠️ Technology Used

* **Snowflake**
* **Snowflake SQL**
* CSV
* Data Warehousing
* Dimensional Modeling
* Star Schema
* Snowflake Schema
* SQL Joins
* Aggregations
* Foreign Keys
* Staging / ETL

---

# 📂 Source Data

Four CSV files were used:

```text
hospital_hierarchy.csv
treatment_hierarchy.csv
patients.csv
insurance_claims.csv
```

### Hospital Hierarchy

Contains:

* Hospital ID
* Hospital Name
* City
* State
* Network ID
* Network Name
* Network Director

### Treatment Hierarchy

Contains:

* Treatment ID
* Treatment Name
* Diagnosis Group ID
* Diagnosis Group Name
* Standard Cost

### Patients

Contains:

* Patient ID
* Patient Name
* Gender
* Age
* City

### Insurance Claims

Contains:

* Claim ID
* Claim Date
* Patient ID
* Hospital ID
* Treatment ID
* Claimed Amount
* Approved Amount

---

# 🏗️ Database Structure

Database:

```text
HEALTHCARE_DW
```

Schema:

```text
SCHEMA_COMPARE_LAB
```

---

# ⭐ Star Schema

The Star Schema stores hierarchy information directly inside the dimension tables.

## Star Schema Tables

### `STAR_DIM_HOSPITAL`

Stores hospital and network information together.

```text
HOSPITAL_KEY
HOSPITAL_ID
HOSPITAL_NAME
CITY
STATE
NETWORK_NAME
NETWORK_DIRECTOR
```

### `STAR_DIM_TREATMENT`

Stores treatment and diagnosis-group information together.

```text
TREATMENT_KEY
TREATMENT_ID
TREATMENT_NAME
DIAGNOSIS_GROUP_NAME
STANDARD_COST
```

### `STAR_FACT_CLAIMS`

Stores insurance claim transactions.

```text
CLAIM_KEY
CLAIM_ID
CLAIM_DATE
PATIENT_ID
HOSPITAL_KEY
TREATMENT_KEY
CLAIMED_AMOUNT
APPROVED_AMOUNT
```

### Star Schema Relationship

```text
                STAR_DIM_HOSPITAL
                       |
                       |
                       ↓
                STAR_FACT_CLAIMS
                       ↑
                       |
                       |
                STAR_DIM_TREATMENT
```

---

# ❄️ Snowflake Schema

The Snowflake Schema normalizes the hierarchical dimensions into separate tables.

## Hospital Hierarchy

```text
SNOW_DIM_NETWORK
        |
        ↓
SNOW_DIM_HOSPITAL
        |
        ↓
SNOW_FACT_CLAIMS
```

### `SNOW_DIM_NETWORK`

```text
NETWORK_KEY
NETWORK_ID
NETWORK_NAME
NETWORK_DIRECTOR
```

### `SNOW_DIM_HOSPITAL`

```text
HOSPITAL_KEY
HOSPITAL_ID
HOSPITAL_NAME
CITY
STATE
NETWORK_KEY
```

---

## Treatment Hierarchy

```text
SNOW_DIM_DIAGNOSIS_GROUP
            |
            ↓
SNOW_DIM_TREATMENT
            |
            ↓
SNOW_FACT_CLAIMS
```

### `SNOW_DIM_DIAGNOSIS_GROUP`

```text
DIAGNOSIS_GROUP_KEY
DIAGNOSIS_GROUP_ID
DIAGNOSIS_GROUP_NAME
```

### `SNOW_DIM_TREATMENT`

```text
TREATMENT_KEY
TREATMENT_ID
TREATMENT_NAME
STANDARD_COST
DIAGNOSIS_GROUP_KEY
```

### `SNOW_FACT_CLAIMS`

```text
CLAIM_KEY
CLAIM_ID
CLAIM_DATE
PATIENT_ID
HOSPITAL_KEY
TREATMENT_KEY
CLAIMED_AMOUNT
APPROVED_AMOUNT
```

---

# 🔄 ETL / Loading Process

A single Snowflake stage was used for all source CSV files.

```text
HEALTHCARE_STAGE
       |
       ├── hospital_hierarchy.csv
       ├── treatment_hierarchy.csv
       ├── patients.csv
       └── insurance_claims.csv
```

The CSV files were first loaded into staging tables:

```text
STG_HOSPITAL_HIERARCHY
STG_TREATMENT_HIERARCHY
STG_PATIENTS
STG_INSURANCE_CLAIMS
```

The final Star and Snowflake tables were populated using:

```sql
INSERT INTO ... SELECT ...
```

This avoids hard-coding source records directly into the final warehouse tables.

---

# 📊 Analytical Queries

## 1. Claims by Diagnosis Group

The Star Schema was used to calculate:

```text
Diagnosis Group
Total Claimed Amount
Total Approved Amount
```

The same analysis was then performed using the Snowflake Schema.

Both schemas provide the same business-level analysis while using different dimensional structures.

---

## 2. Network Director Performance

The project also calculates:

```text
Network Director
Total Claims
Total Approved Amount
```

### Star Schema

The director information is available directly in:

```text
STAR_DIM_HOSPITAL
```

### Snowflake Schema

The director information is normalized into:

```text
SNOW_DIM_NETWORK
```

and accessed through:

```text
SNOW_FACT_CLAIMS
        ↓
SNOW_DIM_HOSPITAL
        ↓
SNOW_DIM_NETWORK
```

---

# 🔄 Master Data Update Test

One of the main comparisons in this project is updating the Apollo Healthcare Group's network director.

Original:

```text
Dr. Ramesh
```

Updated:

```text
Dr. Anand
```

## Star Schema

The director information is duplicated across the two Apollo hospital records.

Therefore, both hospital dimension rows need to be updated.

```text
Apollo Jubilee Hills → Dr. Anand
Apollo Reach         → Dr. Anand
```

## Snowflake Schema

The director is stored once in:

```text
SNOW_DIM_NETWORK
```

Therefore, only the Apollo network record needs to be updated.

This demonstrates how normalization can reduce repeated master-data updates.

---

# 🧾 Final Audit

The final warehouse audit verified the row counts of all major tables.

| Table                    | Expected Rows |
| ------------------------ | ------------: |
| STAR_DIM_HOSPITAL        |             3 |
| STAR_DIM_TREATMENT       |             3 |
| STAR_FACT_CLAIMS         |             4 |
| SNOW_DIM_NETWORK         |             2 |
| SNOW_DIM_HOSPITAL        |             3 |
| SNOW_DIM_DIAGNOSIS_GROUP |             3 |
| SNOW_DIM_TREATMENT       |             3 |
| SNOW_FACT_CLAIMS         |             4 |

The audit was performed using `UNION ALL` across the warehouse tables.

---

# ⚠️ Source Data Note

There is a discrepancy between one value in the supplied source CSV and the expected analytical output in the project specification.

For claim:

```text
CLM-9003
```

the supplied CSV contains:

```text
CLAIMED_AMOUNT  = 230000
APPROVED_AMOUNT = 22000
```

The project's expected analysis section lists the approved amount as `220000`.

For this implementation, the **actual CSV value was preserved** rather than manually modifying the source data.

Therefore, analytical results involving CLM-9003 reflect:

```text
APPROVED_AMOUNT = 22000
```

---

# 🎯 Learning Outcomes

Through this project, the following concepts were implemented:

* Data warehouse database and schema creation
* Staging-layer design
* CSV ingestion into Snowflake
* Star schema modeling
* Snowflake schema modeling
* Dimension and fact table design
* Surrogate keys
* Foreign key relationships
* Normalization
* Hierarchical dimensions
* SQL joins
* Aggregation and analytical queries
* Master-data update comparison
* Data warehouse auditing
* Star vs. Snowflake schema comparison

---

# ⭐ Star Schema vs. Snowflake Schema

| Feature                    | Star Schema               | Snowflake Schema        |
| -------------------------- | ------------------------- | ----------------------- |
| Dimension Structure        | Denormalized              | Normalized              |
| Hierarchy                  | Stored within dimensions  | Split across dimensions |
| Number of Dimension Tables | Fewer                     | More                    |
| Data Redundancy            | Higher                    | Lower                   |
| Query Joins                | Fewer                     | More                    |
| Master Data Update         | May require multiple rows | Centralized update      |
| Design Complexity          | Simpler                   | More complex            |

---

# 📌 Project Conclusion

This project demonstrates two approaches to dimensional modeling for the same healthcare analytics workload.

The **Star Schema** keeps related hierarchy information together in wider dimension tables, while the **Snowflake Schema** separates hierarchical information into normalized tables.

Both approaches can support analytical reporting, but they organize and maintain dimensional data differently.

The project also demonstrates the practical impact of normalization through the network-director update test, where the Star Schema requires multiple dimension-row updates while the Snowflake Schema centralizes the master data.

---

## 📁 Project Structure

```text
Project-13B/
│
├── hospital_hierarchy.csv
├── treatment_hierarchy.csv
├── patients.csv
├── insurance_claims.csv
├── Project_13b.md
└── README.md
```

---

## 🚀 Skills Demonstrated

```text
Snowflake SQL
Data Warehousing
ETL
Staging
Star Schema
Snowflake Schema
Dimensional Modeling
Fact Tables
Dimension Tables
Normalization
Surrogate Keys
SQL Joins
Aggregation
Data Analysis
Master Data Management
```
