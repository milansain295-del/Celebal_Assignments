"""
Spark Data Engineering Project
Bank Account Analytics Pipeline
"""

import os
os.environ["PYSPARK_PYTHON"] = "python3"
os.environ["SPARK_LOCAL_IP"] = "127.0.0.1"

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import (
    StructType, StructField,
    StringType, DoubleType, IntegerType, LongType
)


# ─────────────────────────────────────────────
# 1. SparkSession — entry point to everything
# ─────────────────────────────────────────────
# The Driver lives here. It communicates with the Cluster Manager
# (local[2] in dev, YARN/K8s in prod) which allocates Executors.
# Each Executor runs tasks on partitions of your data in parallel.

spark = SparkSession.builder \
    .appName("BankAccountPipeline") \
    .master("local[2]") \
    .config("spark.sql.shuffle.partitions", "4") \
    .config("spark.ui.enabled", "false") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")

print("=" * 60)
print(f"  App      : {spark.sparkContext.appName}")
print(f"  Master   : {spark.sparkContext.master}")
print(f"  Version  : {spark.version}")
print("=" * 60)


# ─────────────────────────────────────────────
# 2. Schema Definition
# ─────────────────────────────────────────────
# Always define schema explicitly on large datasets.
# Avoids the full-file scan that inferSchema triggers,
# and gives you type safety from the start.

account_schema = StructType([
    StructField("account_id",        StringType(),  False),
    StructField("customer_name",     StringType(),  True),
    StructField("account_type",      StringType(),  True),
    StructField("balance",           DoubleType(),  True),
    StructField("city",              StringType(),  True),
    StructField("account_open_date", StringType(),  True),
    StructField("credit_score",      IntegerType(), True),
    StructField("status",            StringType(),  True),
])


# ─────────────────────────────────────────────
# 3. Read CSV
# ─────────────────────────────────────────────
# This is LAZY — no data moves yet. Spark just records what
# you want to do and builds a logical plan (DAG).

raw_df = spark.read \
    .schema(account_schema) \
    .option("header",    "true") \
    .option("nullValue", "") \
    .csv("data/accounts.csv")

print("\n── Schema ──────────────────────────────────")
raw_df.printSchema()

# .count() is an ACTION — this is where Spark actually executes the DAG
print(f"Total records: {raw_df.count()}")

print("\nSample rows (raw):")
raw_df.show(5, truncate=False)


# ─────────────────────────────────────────────
# 4. Null Analysis
# ─────────────────────────────────────────────
# Cast bool → int and sum to get a per-column null count in one pass.

print("\n── Null Count per Column ───────────────────")
null_report = raw_df.select([
    F.sum(F.col(c).isNull().cast("int")).alias(c)
    for c in raw_df.columns
])
null_report.show()


# ─────────────────────────────────────────────
# 5. Filter — Narrow Transformation
# ─────────────────────────────────────────────
# Narrow = each input partition maps to at most one output partition.
# No shuffle. Catalyst Optimizer pushes these filters down to the scan.

active_df = raw_df.filter(
    (F.col("status") == "Active") &
    F.col("balance").isNotNull()
)

print(f"\nActive accounts with valid balance: {active_df.count()}")


# ─────────────────────────────────────────────
# 6. Transformations — still lazy
# ─────────────────────────────────────────────

transformed_df = active_df \
    .withColumnRenamed("customer_name", "customer") \
    .withColumn("balance",           F.col("balance").cast(LongType())) \
    .withColumn("account_open_date", F.to_date(F.col("account_open_date"), "yyyy-MM-dd")) \
    .withColumn("balance_band",
        F.when(F.col("balance") < 25_000,   "Low")
         .when(F.col("balance") < 100_000,  "Mid")
         .when(F.col("balance") < 500_000,  "High")
         .otherwise("Premium")
    ) \
    .withColumn("projected_annual_interest",
        F.round(F.col("balance") * 0.065, 2)
    ) \
    .withColumn("tenure_years",
        F.round(
            F.datediff(F.current_date(), F.col("account_open_date")) / 365.0,
            1
        )
    ) \
    .select(
        "account_id", "customer", "account_type",
        "balance", "projected_annual_interest", "balance_band",
        "city", "account_open_date", "tenure_years", "credit_score"
    )

print("\n── Transformed Sample ──────────────────────")
transformed_df.show(8, truncate=False)


# ─────────────────────────────────────────────
# 7. Aggregations — Wide Transformation
# ─────────────────────────────────────────────
# groupBy causes a SHUFFLE. Spark redistributes rows across
# partitions so that all rows with the same key land together.
# This is the most expensive operation — minimize where possible.

print("\n── Account Type Stats (shuffle happens here) ─")
type_stats = transformed_df.groupBy("account_type").agg(
    F.count("*")                      .alias("account_count"),
    F.round(F.avg("balance"), 2)      .alias("avg_balance"),
    F.min("balance")                  .alias("min_balance"),
    F.max("balance")                  .alias("max_balance"),
    F.round(F.avg("tenure_years"), 1) .alias("avg_tenure"),
    F.round(F.avg("credit_score"), 1) .alias("avg_credit_score")
).orderBy("avg_balance", ascending=False)

type_stats.show(truncate=False)

print("\n── Balance Band Distribution ───────────────")
transformed_df.groupBy("balance_band").agg(
    F.count("*")               .alias("count"),
    F.round(F.avg("balance"), 0).alias("avg_balance")
).orderBy("avg_balance").show()

print("\n── City-wise Account Volume ─────────────────")
transformed_df.groupBy("city").agg(
    F.count("*")                  .alias("accounts"),
    F.round(F.avg("balance"), 2)  .alias("avg_balance")
).orderBy("accounts", ascending=False).show()

print("\n── Top 10 Accounts by Balance ──────────────")
transformed_df \
    .select("account_id", "customer", "account_type", "balance", "balance_band", "city") \
    .orderBy(F.col("balance").desc()) \
    .limit(10) \
    .show(truncate=False)


# ─────────────────────────────────────────────
# 8. Write — Parquet (columnar, compressed)
# ─────────────────────────────────────────────
# Parquet stores data by column, not row.
# Benefit: if you only query "balance", Spark reads only that column's bytes.
# partitionBy("account_type") creates subdirectories like account_type=Savings/
# This lets Spark skip entire partitions when a filter matches — Predicate Pushdown.

print("\n── Writing Parquet (partitioned by account_type) ─")
transformed_df.write \
    .mode("overwrite") \
    .partitionBy("account_type") \
    .parquet("output/accounts_parquet")
print("Done.")

print("\n── Writing account type summary as CSV ─────")
type_stats.coalesce(1).write \
    .mode("overwrite") \
    .option("header", "true") \
    .csv("output/type_summary_csv")
print("Done.")


# ─────────────────────────────────────────────
# 9. Read back Parquet — Predicate Pushdown
# ─────────────────────────────────────────────
# Spark reads ONLY the account_type=Savings/ folder.
# It never opens the other five partitions — massive I/O saving at scale.

print("\n── Reading Parquet with Partition Filter ───")
savings_df = spark.read.parquet("output/accounts_parquet") \
    .filter(F.col("account_type") == "Savings")

print(f"Savings records: {savings_df.count()}")
savings_df.show(5, truncate=False)

print("\n── Physical Plan (see PartitionFilters line) ─")
savings_df.explain(mode="simple")


# ─────────────────────────────────────────────
# 10. DAG / Lineage of the main pipeline
# ─────────────────────────────────────────────
# The Optimized Logical Plan shows how Catalyst rewrote your query:
#   - Collapsed multiple Projects into one
#   - Pushed the filter all the way down to the FileScan
# The Physical Plan shows what actually runs on Executors.

print("\n── DAG Lineage — transformed_df ────────────")
transformed_df.explain(mode="extended")


# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────
spark.stop()
print("\n" + "=" * 60)
print("  Pipeline complete.")
print("  Output → output/accounts_parquet/")
print("           output/type_summary_csv/")
print("=" * 60)
