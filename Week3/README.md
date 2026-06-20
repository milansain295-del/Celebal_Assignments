## SQL Data Analysis — Superstore Sales


## What this project is
This started as a question I wanted to answer: what actually happens between a raw CSV file and a meaningful business insight? This project is my attempt to build that bridge — taking messy, flat sales data and turning it into something you can properly query and reason about.
The core idea is normalization. Instead of leaving everything in one giant table, I broke the data into proper relational tables for customers, products, and orders. That structure makes the analysis cleaner and the SQL more realistic — closer to what you'd actually work with on the job.


## What it covers
The notebook walks through the full workflow in order: load the raw data into Pandas, push it into a SQLite database, define the schema, migrate the data across tables, then start querying.
The SQL side goes beyond basic SELECT statements. I worked through subqueries, CTEs, and window functions to answer specific business questions — things like identifying top and bottom revenue generators, spotting customers who haven't ordered in a while, and ranking products within categories.


## Tools used
Python and Pandas handle the data loading and orchestration. SQLite runs the database — lightweight enough to work entirely in memory, which keeps the setup simple. Everything runs in Jupyter or Colab, cell by cell.


## How to run it
You just need Python with pandas and sqlite3 (sqlite3 ships with Python, so no install needed). Open the notebook and run the cells top to bottom — each one builds on the last.
