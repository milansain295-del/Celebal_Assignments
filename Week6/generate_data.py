"""
Generates a synthetic bank accounts dataset for the Spark pipeline.
Produces data/accounts.csv with intentional nulls and mixed statuses
to simulate real-world messiness (same idea as the reference project,
different domain: bank accounts instead of employees).
"""

import csv
import random
from datetime import date, timedelta

random.seed(7)

NUM_RECORDS = 1000

ACCOUNT_TYPES = ["Savings", "Current", "Fixed Deposit", "Recurring Deposit", "Loan", "Credit Card"]
CITIES = ["Mumbai", "Delhi", "Bangalore", "Chennai", "Kolkata", "Pune", "Hyderabad"]
STATUSES = ["Active", "Dormant", "Closed", "Frozen"]

FIRST_NAMES = ["Aarav", "Vivaan", "Aditi", "Diya", "Kabir", "Ishaan", "Meera",
               "Ananya", "Rohan", "Sara", "Kunal", "Priya", "Arjun", "Neha",
               "Vikram", "Pooja", "Rahul", "Simran", "Karan", "Tanvi"]
LAST_NAMES = ["Sharma", "Verma", "Iyer", "Nair", "Gupta", "Reddy", "Khan",
              "Mehta", "Joshi", "Patel", "Singh", "Rao", "Kapoor", "Chatterjee"]

BALANCE_RANGE = {
    "Savings":            (5000, 250000),
    "Current":            (10000, 800000),
    "Fixed Deposit":      (50000, 2000000),
    "Recurring Deposit":  (10000, 500000),
    "Loan":               (100000, 3000000),
    "Credit Card":        (0, 200000),
}

START_DATE = date(2016, 1, 1)
END_DATE = date(2026, 6, 30)
DATE_RANGE_DAYS = (END_DATE - START_DATE).days


def random_date():
    return START_DATE + timedelta(days=random.randint(0, DATE_RANGE_DAYS))


def main():
    rows = []
    for i in range(1, NUM_RECORDS + 1):
        account_id = f"ACC{i:05d}"
        customer_name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        account_type = random.choice(ACCOUNT_TYPES)
        low, high = BALANCE_RANGE[account_type]

        # ~5% missing balance
        balance = "" if random.random() < 0.05 else round(random.uniform(low, high), 2)

        city = random.choice(CITIES)
        account_open_date = random_date().isoformat()
        credit_score = random.randint(300, 900)

        # ~22% missing status
        status = "" if random.random() < 0.22 else random.choice(STATUSES)

        rows.append([account_id, customer_name, account_type, balance,
                     city, account_open_date, credit_score, status])

    with open("data/accounts.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["account_id", "customer_name", "account_type",
                          "balance", "city", "account_open_date", "credit_score",
                          "status"])
        writer.writerows(rows)

    print(f"Generated {NUM_RECORDS} records -> data/accounts.csv")


if __name__ == "__main__":
    main()
