## Superstore Sales Analysis Project
This project provides an end-to-end data analysis workflow for a retail dataset using Python, Pandas, and SQLite. It covers data ingestion, cleaning, exploratory data analysis (EDA), and data visualization.

##  Project Overview
The analysis focuses on the 'Sample - Superstore' dataset, which contains sales and profit data for a US-based retail chain. The goal is to identify trends, evaluate product performance, and understand the relationship between discounts and profitability.

##  Tech Stack
Environment: Google Colab
Language: Python 3
Database: SQLite3 (for structured querying)
Libraries: Pandas (Data manipulation), Matplotlib/Seaborn (Visualization)
## Key Features
Data Ingestion: Automated unzipping and loading of CSV data into an SQLite database.
Database Optimization: Pre-processing of date strings into ISO datetime formats to enable accurate time-series SQL queries.
Financial Analysis:
Revenue and Profit tracking across Regions and Categories.
Identification of top-performing products and high-value customers.
Trend Analysis: Visualizing monthly and yearly sales trajectories.
Strategic Insights: Analyzing the 'Discount Impact' to pinpoint where high discounts lead to operational losses.
##  Key Findings
Top Performer: The 'Technology' category leads in both revenue and profit margin.
Profitability Drain: 'Tables' and 'Bookcases' were identified as consistently loss-making sub-categories.
The 40% Threshold: Analysis shows that discounts exceeding 40% are a primary driver of negative profit across all segments.
Regional Lead: The West region generates the highest total sales and profit.
