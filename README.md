# Data Engineering Internship @ Celebal Technologies

This repo is where I've been keeping everything from my Data Engineering internship at Celebal Technologies — not just a folder of finished assignments, but a running record of what I actually learned each week, what I built, where I got stuck, and how I worked my way through it.

Inside you'll find code, notes, screenshots, and short explanations of each project. The goal was to actually understand the tools, not just get an assignment to run once and move on.

---

## Repo layout

```
Data-Engineering-Internship/
│
├── Week 1/
├── Week 2/
├── Week 3/
├── Week 4/
├── Week 5/
├── Week 6/
├── Week 7/
├── Week 8/
└── README.md
```

Each week's folder generally has:
- a README walking through what the assignment was
- the actual code
- screenshots as proof it ran
- output files, when there were any worth keeping

---

## Week-by-week

### Week 1 – Python basics

Getting comfortable with the language itself: variables, data types, conditionals, loops, functions, lists/tuples/dictionaries, basic file handling, and a handful of small programming exercises to make sure it all actually stuck.

### Week 2 – SQL basics

Started with plain SQL: `SELECT` statements, filtering with `WHERE`, sorting, aggregate functions, `GROUP BY`, `HAVING`, and joins. Mostly practice queries to build the muscle memory.

### Week 3 – SQL subqueries

Went a level deeper — single-row and multi-row subqueries, correlated subqueries, nested queries, and a set of problems designed to force actual SQL thinking rather than copy-pasting patterns.

### Week 4 – Data engineering concepts

This week was more conceptual than hands-on: what data engineering actually is, ETL vs ELT, batch vs stream processing, data warehouses vs data lakes, the basics of big data, an intro to Apache Spark, and enough distributed computing theory to understand why any of this matters at scale.

### Week 5 – Data cleaning & Spark

First real hands-on work with PySpark, doing the kind of preprocessing you'd actually need on messy data: handling nulls, removing duplicates, converting data types, creating derived columns, grouping and aggregating (sums, averages, counts), and general transformations. Also spent time understanding *why* Spark exists in the first place — what breaks down with plain Pandas once data gets big enough.

Assignment work included Spark data cleaning tasks, transformation questions, and aggregation exercises.

### Week 6 – Apache Spark

Went deeper into how Spark actually works under the hood: driver and executor architecture, `SparkSession`, DataFrames, lazy evaluation, the difference between actions and transformations, reading/writing CSV and Parquet, Spark SQL, and some basic performance considerations.

### Week 7 – Databricks

Moved into Databricks itself — workspaces, clusters, notebooks, DBFS, uploading datasets, running Spark jobs, and working through a few end-to-end Spark workflows in that environment.

### Week 8 – Planning

Less about new tools, more about pulling everything together: project planning, pipeline design, documentation habits, general best practices, and laying the groundwork for a final assignment.

---

## Azure Data Factory project

One of the bigger pieces of the internship was building a full Azure Data Factory pipeline from scratch. That covered:

- Azure Storage Accounts and Blob Containers
- Linked Services
- Datasets
- Copy Data activities
- Metadata validation
- Pipeline monitoring
- Moving data end-to-end through the pipeline

Screenshots of the key steps are in the repo so it's not just a description — there's actual evidence it worked.

---

## Tools & tech used

- Python
- SQL
- Apache Spark
- Databricks
- Microsoft Azure
  - Storage Account
  - Blob Storage
  - Azure Data Factory
  - IAM
- Git & GitHub

---

## Why this repo exists

A few reasons:

- It's a learning journal I can actually look back on
- It doubles as a portfolio of what I did during the internship
- It's an archive of the assignments themselves
- It documents the Azure project in detail
- It's a place to keep the Spark practice work
- It tracks progress over the full eight weeks

The point was never to just show a polished final result — it's meant to show the actual path from Python fundamentals to cloud tools and distributed data processing.

---

## Author

**Milan Sain**
Data Engineering Intern, Celebal Technologies

---

*A running collection of assignments, projects, and hands-on learning from my Data Engineering Internship at Celebal Technologies.*
