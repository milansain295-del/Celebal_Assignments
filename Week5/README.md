# Cleaning a Messy Retail Dataset with PySpark

This started out as a standard "15 PySpark questions" practice exercise — the kind where you get a tidy synthetic dataset and walk through duplicates, nulls, groupbys, and a final pipeline. I swapped in a real (well, realistically messy) retail transactions file instead, and it turned out to be a much better teacher than the clean version ever was.

`retail_transactions_dirty.csv` has 62,425 rows of fake retail transactions, and almost every column has *something* wrong with it — duplicate rows, missing values, inconsistent casing, and a date column that genuinely mixes three different formats. So instead of writing code that technically answers each question, this notebook actually has to deal with the data being dirty, which is closer to what cleaning a real dataset feels like.

## What's in here

- `retail_data_clean_pyspark_.ipynb` — the notebook, walking through 15 questions/tasks (a mix of "explain this Spark concept" and "write code to do X")
- `retail_transactions_dirty.csv` — the dataset

## The dataset

Columns: `transaction_id, customer_id, customer_name, age, gender, category, region, quantity, unit_price, purchase_amount, rating, payment_method, purchase_date, signup_date, email`

A few things you'll run into pretty quickly if you poke around in it:

- **`region` and `category` are a casing/whitespace mess.** `region` alone shows up as 26 different raw strings for what are really only 5 regions — `'west'`, `'West'`, `' West '`, `'WEST'`, `'West  '`, etc. Same story with `category` (41 raw spellings → 9 real categories). If you filter or group on these columns without cleaning them first, you'll get garbage results and not even realize it.
- **`purchase_date` mixes three date formats in the same column** — ISO (`2023-12-22`), day/month with slashes (`04/10/2022`), and month-day with dashes (`08-28-2021`). This is exactly the kind of thing that makes `inferSchema=True` give up and leave the column as a plain string. Trying to cast it with one fixed format only works for the rows that happen to match that format — everything else quietly turns into `NULL`. In this dataset that's 22,949 rows.
- **2,400 exact duplicate rows**, plus one row that's entirely blank except for a leftover `transaction_id` (`TXN_BLANK21`) — feels like a planted edge case, but it's a good reminder that "row exists" doesn't mean "row has data."
- **Nulls everywhere**, not concentrated in one or two columns. `rating`, `purchase_date`, and `signup_date` have the most, but pretty much every column has some.

## What the notebook covers

It's organized as 15 questions, alternating between Spark concepts and actual code against this file:

1–2. Why Spark beats traditional MapReduce, and how in-memory computing helps iterative workloads
3. Dropping duplicate rows based on `customer_id` + `purchase_date`
4. Filtering by region and averaging purchase amount by category (after cleaning up the casing mess first)
5. `.na.drop()` vs `.na.fill()`, filling missing `payment_method` values
6. Counting records per category, keeping only groups above a threshold
7. Why DataFrame immutability matters when you're chaining cleaning steps
8. Filtering by age range and gender
9. Why you should deal with nulls *before* you aggregate, not after
10. Casting `purchase_date` to a real timestamp — and watching it fail for two-thirds of the mismatched-format rows
11. What a shuffle actually is, and why grouping operations are "wide" transformations
12. Dropping rows with missing email or customer name
13. Getting min/max/mean of `unit_price` in one `agg()` call
14. Why `inferSchema=True` is risky with inconsistent date formats (Q10 is the proof, not just the theory)
15. A full pipeline: dedupe → fill missing amounts → clean region names → total revenue by region

## What actually came out of it

- Total revenue lands pretty evenly across the five regions once you clean up the region names — roughly $2.3–2.4M each — with about $364K sitting in an unclassified/NULL bucket that's probably tied to the same null/blank rows showing up elsewhere.
- The "average purchase amount by category" numbers barely move (low-to-mid $200s across categories), which tells you the messiness here is mostly structural — bad strings and bad dates — rather than weird outlier amounts.
- The date-parsing failure is the headline lesson: one fixed format recovers about 60% of the dates and silently drops the rest. If you actually needed all the dates, you'd want something like `coalesce()` over a few `try_to_timestamp()` calls, one per format, rather than trusting a single pattern.

## Running it

```bash
pip install pyspark
```

Then open the notebook and run the cells top to bottom — it reads `retail_transactions_dirty.csv` from the same directory. The first code cell checks if the file exists and, if you're running this in Google Colab, will prompt you to upload it.

Needs Java installed for Spark to run locally (Java 8/11/17 all work fine with recent PySpark versions).

## Why bother adapting the questions instead of just using the clean dataset

Because the clean version doesn't teach you anything you'll actually need. Real data doesn't have one consistent spelling of "West," and it definitely doesn't hand you dates in a single format. The exercises are the same on paper, but solving them against data that fights back a little is a much better rehearsal for whatever messy CSV shows up on your desk next.

