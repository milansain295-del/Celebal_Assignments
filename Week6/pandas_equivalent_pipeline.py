"""
Pandas re-implementation of spark_pipeline.py logic, used ONLY because
PySpark could not be installed in this sandboxed environment (no network
access). Mirrors the same steps so the expected output/numbers can be seen.
"""

import pandas as pd
import os

pd.set_option("display.width", 120)

print("=" * 60)
print("  App      : BankAccountPipeline (pandas stand-in)")
print("  Version  : pandas", pd.__version__)
print("=" * 60)

raw_df = pd.read_csv(
    "data/accounts.csv",
    dtype={"account_id": str, "customer_name": str, "account_type": str,
           "city": str, "status": str},
)
raw_df["balance"] = pd.to_numeric(raw_df["balance"], errors="coerce")
raw_df["credit_score"] = pd.to_numeric(raw_df["credit_score"], errors="coerce").astype("Int64")

print(f"Total records: {len(raw_df)}")

print("\n── Null Count per Column ───────────────────")
print(raw_df.isnull().sum().to_frame().T.to_string(index=False))

active_df = raw_df[(raw_df["status"] == "Active") & raw_df["balance"].notnull()].copy()
print(f"\nActive accounts with valid balance: {len(active_df)}")

active_df = active_df.rename(columns={"customer_name": "customer"})
active_df["account_open_date"] = pd.to_datetime(active_df["account_open_date"], format="%Y-%m-%d")
active_df["balance"] = active_df["balance"].astype("int64")

def band(b):
    if b < 25000: return "Low"
    if b < 100000: return "Mid"
    if b < 500000: return "High"
    return "Premium"

active_df["balance_band"] = active_df["balance"].apply(band)
active_df["projected_annual_interest"] = (active_df["balance"] * 0.065).round(2)
today = pd.Timestamp("2026-07-05")
active_df["tenure_years"] = ((today - active_df["account_open_date"]).dt.days / 365.0).round(1)

transformed_df = active_df[["account_id", "customer", "account_type", "balance",
                             "projected_annual_interest", "balance_band", "city",
                             "account_open_date", "tenure_years", "credit_score"]]

print("\n── Account Type Stats ──────────────────────")
type_stats = transformed_df.groupby("account_type").agg(
    account_count=("balance", "count"),
    avg_balance=("balance", lambda s: round(s.mean(), 2)),
    min_balance=("balance", "min"),
    max_balance=("balance", "max"),
    avg_tenure=("tenure_years", lambda s: round(s.mean(), 1)),
    avg_credit_score=("credit_score", lambda s: round(s.mean(), 1)),
).reset_index().sort_values("avg_balance", ascending=False)
print(type_stats.to_string(index=False))

print("\n── Balance Band Distribution ───────────────")
band_dist = transformed_df.groupby("balance_band").agg(
    count=("balance", "count"),
    avg_balance=("balance", lambda s: round(s.mean(), 0)),
).reset_index().sort_values("avg_balance")
print(band_dist.to_string(index=False))

print("\n── City-wise Account Volume ─────────────────")
city_vol = transformed_df.groupby("city").agg(
    accounts=("balance", "count"),
    avg_balance=("balance", lambda s: round(s.mean(), 2)),
).reset_index().sort_values("accounts", ascending=False)
print(city_vol.to_string(index=False))

print("\n── Top 10 Accounts by Balance ──────────────")
top10 = transformed_df[["account_id", "customer", "account_type", "balance", "balance_band", "city"]] \
    .sort_values("balance", ascending=False).head(10)
print(top10.to_string(index=False))

os.makedirs("output", exist_ok=True)
transformed_df.to_csv("output/accounts_transformed.csv", index=False)
type_stats.to_csv("output/type_summary.csv", index=False)
print("\nWritten: output/accounts_transformed.csv, output/type_summary.csv")

print("\n" + "=" * 60)
print("  Pipeline complete (pandas stand-in).")
print("=" * 60)
