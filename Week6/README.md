# Spark Data Engineering — Bank Account Analytics Pipeline

This project was built to understand how Apache Spark works beyond just its syntax. Instead of treating Spark like a faster version of pandas, the goal was to learn how Spark executes distributed workloads through Drivers, Executors, lazy evaluation, DAGs, and optimizations such as predicate pushdown.

The pipeline processes a raw dataset of bank accounts, cleans the data, performs transformations and aggregations, writes optimized Parquet output, and verifies Spark's partition pruning capabilities.

---

## What I Built

A complete PySpark data pipeline that:

- Reads a raw CSV dataset containing **1,000 bank accounts**
- Uses an **explicit schema** instead of `inferSchema`
- Cleans missing and invalid records
- Creates several derived business features
- Performs aggregations using Spark SQL functions
- Writes output in both **CSV** and **Parquet**
- Reads the Parquet data back to verify **predicate pushdown** and **partition pruning**

The dataset contains:

- 6 Account Types
- 7 Cities
- Missing balances
- Missing account statuses
- Realistic banking-style data for analytics

---

# Spark Concepts Learned

## Driver vs Executors

One of the biggest differences from normal Python programs is that the Driver never processes the data itself.

The Driver creates the execution plan while Executors perform the actual computations.

This project was executed using:

```python
local[2]
```

which simulates a small two-executor Spark cluster locally.

---

## Lazy Evaluation

Spark transformations are lazy.

Operations such as:

```python
filter()

select()

withColumn()
```

do not execute immediately.

Spark first builds a **Directed Acyclic Graph (DAG)**.

Execution only begins after an **Action** such as:

```python
show()

count()

collect()

write()
```

This allows the Catalyst Optimizer to optimize the complete execution plan before any computation begins.

---

## Explicit Schema

Instead of using

```python
inferSchema=True
```

the pipeline defines every column manually using:

```python
StructType
StructField
```

Benefits include:

- Faster file loading
- Predictable datatypes
- Better production practices

---

## Handling Missing Values

The dataset intentionally contains missing values.

Null counts were calculated using:

```python
isNull()
cast("int")
sum()
```

Records were kept only when:

- Account Status = Active
- Balance is not NULL

This avoids unnecessary processing on invalid records.

---

## Narrow vs Wide Transformations

### Narrow Transformations

- Filter
- Select
- withColumn

These execute within individual partitions without moving data.

### Wide Transformations

```python
groupBy().agg()
```

These require a **shuffle**, where Spark redistributes data across partitions.

Since the dataset is small, shuffle partitions were reduced from the default 200 to:

```python
spark.sql.shuffle.partitions = 4
```

to minimize unnecessary overhead.

---

# Transformations Performed

The pipeline performs several feature engineering steps.

### Column Renaming

- Renamed one existing column for clarity.

### Data Type Conversion

- Balance converted from Double → Long
- Account opening date converted from String → Date

### Derived Columns

Created:

- **balance_band**
  - Low
  - Mid
  - High
  - Premium

- **projected_annual_interest**

```
balance × flat interest rate
```

- **tenure_years**

Calculated from the account opening date until today.

---

# Aggregations

Grouped data using:

```python
groupBy()
```

Aggregated by:

- Account Type
- City
- Balance Band

Calculated metrics include:

- Average Balance
- Maximum Balance
- Minimum Balance
- Total Accounts

---

# Predicate Pushdown & Partition Pruning

The processed dataset is written as Parquet using:

```python
partitionBy("account_type")
```

The data is then read back and filtered:

```python
account_type = "Loan"
```

Using

```python
.explain()
```

Spark shows:

```
PartitionFilters
```

confirming that only the required partition is scanned instead of every folder.

---

# Why Parquet Instead of CSV?

CSV stores information row-by-row.

Reading one column still requires reading the complete file.

Parquet stores data column-wise.

Advantages include:

- Faster analytical queries
- Better compression
- Lower disk I/O
- Predicate Pushdown
- Partition Pruning

This makes Parquet significantly better for analytical workloads.

---

# Pipeline Flow

```text
accounts.csv
     │
     ▼
Read using Explicit Schema
     │
     ▼
Check Missing Values
     │
     ▼
Keep only:
Active Accounts
+
Valid Balance
     │
     ▼
Transform Data
 • Rename Columns
 • Cast Data Types
 • Parse Dates
 • Create balance_band
 • Create projected_annual_interest
 • Create tenure_years
     │
     ▼
Group & Aggregate
     │
     ▼
Write CSV Summary
     │
     ▼
Write Partitioned Parquet
     │
     ▼
Read Parquet Again
     │
     ▼
Verify Partition Pruning
```

---

# Project Structure

```text
Bank-Account-Analytics/
│
├── accounts.csv
├── generate_data.py
├── spark_pipeline.py
│
├── output/
│   ├── accounts_parquet/
│   └── type_summary_csv/
│
└── README.md
```

---

# Results

Dataset Size:

- **1,000 Bank Accounts**

After Cleaning:

- **191 Active accounts with valid balances**

Observations:

- Loan accounts had the highest average balance (~₹16.8 lakh)
- Credit Card accounts had the lowest average balance (~₹1.04 lakh)
- High balance band contained the largest number of accounts (88)
- Premium balance band had the highest average balance
- Partition pruning successfully skipped unnecessary account-type folders during reads

---

# How to Run

## Install PySpark

```bash
pip install pyspark
```

Generate the dataset:

```bash
python generate_data.py
```

Run the Spark pipeline:

```bash
python spark_pipeline.py
```

---

# Requirements

- Python 3.x
- Apache Spark
- PySpark
- Java 8 or newer

Verify Java installation:

```bash
java -version
```

If Spark cannot locate Java, configure:

```bash
JAVA_HOME
```

before running the project.

---

# Key Technologies

- Apache Spark
- PySpark
- Spark SQL
- DataFrames
- Parquet
- CSV
- Predicate Pushdown
- Partition Pruning
- Lazy Evaluation
- Catalyst Optimizer
- Python
