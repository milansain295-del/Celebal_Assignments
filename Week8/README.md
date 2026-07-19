# E-Commerce Order Analytics Pipeline

This is a self-contained data project I put together to practice the *whole*
pipeline, not just one piece of it: generating data, cleaning it, modeling
it properly in a relational database, querying it with real SQL, and
wrapping it up in something you can actually run from the command line.

The twist is that the data isn't clean to begin with — on purpose.

## Why the data is a mess on purpose

Anyone who's worked with a real e-commerce export knows it's never tidy.
Emails get typo'd, dates show up in two different formats in the same
column, someone double-clicks checkout and you end up with a duplicate
order, a product loses its price because of some export glitch nobody
noticed. Instead of skipping past that and starting with a nice clean
CSV, this project generates the mess itself, and the cleaning step has
to actually catch and fix it — the same way it would have to with a
vendor dump that showed up in your inbox on a Monday.

## How it's organized

```
ecommerce_analytics/
├── data/                   # raw, messy CSVs (generated)
│   ├── customers.csv
│   ├── products.csv
│   ├── orders.csv
│   └── order_items.csv
├── sql/
│   ├── schema.sql          # clean table definitions + constraints
│   └── queries.sql         # 10 analytical queries, documented
├── scripts/
│   ├── generate_data.py    # step 1: create messy raw data
│   ├── clean_data.py       # step 2: clean with Pandas, load into SQLite
│   └── report.py           # step 3: CLI reporting tool
├── reports/                # cleaning log + CSV exports land here
├── ecommerce.db            # SQLite database (generated)
├── requirements.txt
└── README.md
```

## The data model

Four tables, each with one clear job:

- **customers** — one row per person: name, email, city/state, signup date
- **products** — the catalog: name, category, unit price, active flag
- **orders** — one row per order: which customer, when, status, payment method
- **order_items** — the line items: which product, quantity, and the price
  *at the time of purchase*. That last part is deliberate — I kept it
  separate from the current catalog price because prices drift over time,
  and an old order shouldn't quietly change value just because a product
  got repriced later.

Foreign keys hold it all together: `orders.customer_id → customers.customer_id`,
`order_items.order_id → orders.order_id`, `order_items.product_id →
products.product_id`. `schema.sql` also enforces a couple of `CHECK`
constraints — no negative prices, no zero or negative quantities.

## The mess, itemized

`generate_data.py` deliberately seeds these problems into the raw CSVs so
there's real work for the cleaning step to do:

| Problem | Where |
|---|---|
| Duplicate rows (same ID, resubmitted) | customers, orders |
| Missing primary key | customers |
| Inconsistent casing (`upi` vs `UPI`, `MUMBAI` vs `Mumbai`) | customers, orders |
| Two different date formats in the same column | customers, orders |
| Unparsable date string | orders |
| Missing / negative product price | products |
| Malformed or blank emails | customers |
| Orphaned foreign keys (order → nonexistent customer, item → nonexistent order/product) | orders, order_items |
| Negative / zero quantities | order_items |
| Orders with zero line items | orders |

## How the cleaning decisions were made

Every fix here is a judgment call, and I tried to be upfront in the code
about which call I made and why, rather than just silently dropping or
patching things:

- Rows with a **missing primary key** get dropped — there's nothing to
  anchor them to.
- **Exact duplicates** get deduped, keeping whichever copy showed up first.
- **Orphaned foreign keys** get dropped — an order item pointing at an
  order that doesn't exist isn't really data, it's noise.
- **Missing or negative prices** get repaired instead of dropped (median
  fill by category, or just flipping the sign on negatives) — the product
  itself is still real, it just has a bad number attached.
- **Bad quantities** get dropped at the line-item level, since there's no
  reliable way to guess whether a `-1` was meant to be `1` or `2`.
- **Unparsable order dates** cause the order to be dropped outright, but an
  unparsable *signup* date just gets filled with the earliest known signup
  date rather than losing the whole customer over one bad field.

Every one of these decisions gets logged to `reports/cleaning_log.txt`. After
loading, `clean_data.py` also re-queries the database to double-check
referential integrity actually holds — zero orphaned rows, zero bad
quantities or prices — before it calls the run a success.

## The SQL side (`sql/queries.sql`)

Ten queries, roughly in order of how hard they were to get right:

1. Revenue by category (join + aggregation)
2. Monthly revenue trend with month-over-month growth (CTE + `LAG`)
3. Cumulative revenue (window function running total)
4. Top 3 products per category (`RANK() ... PARTITION BY`)
5. RFM customer segmentation — Recency/Frequency/Monetary, using `NTILE`
   and a few nested CTEs
6. Cohort retention analysis — the one I'm most proud of: for each
   signup-month cohort, what percentage of customers were still ordering
   N months later
7. Customer lifetime value leaderboard (`DENSE_RANK`)
8. Cancellation rate by payment method
9. Repeat buyers vs one-time buyers
10. New vs returning customer revenue split, per month

## The CLI (`scripts/report.py`)

```bash
python report.py revenue-by-category
python report.py monthly-trend
python report.py top-customers --limit 15
python report.py cohort-retention
python report.py segments
python report.py all --export ../reports/
```

Each command prints a plain-text table to the terminal. Add `--export
path/to/file.csv` (or point it at a folder, for `all`) and it'll also dump
the results as CSV. If the database hasn't been built yet, it tells you to
run the pipeline first instead of blowing up with a raw traceback.

## Running the whole thing

```bash
pip install -r requirements.txt

cd scripts
python generate_data.py --customers 600 --orders 5000   # step 1: make messy data
python clean_data.py                                    # step 2: clean + load
python report.py all --export ../reports/                # step 3: generate reports
```

You can re-run `generate_data.py` with different `--customers` /
`--orders` counts and re-run `clean_data.py` to rebuild `ecommerce.db`
from scratch each time. It's meant to be a repeatable pipeline, not a
run-once script.

## What I'd still change

This was a learning project, so a few corners were cut on purpose rather
than by accident:

- I used SQLite instead of Postgres or MySQL for simplicity. The schema
  and queries are close enough to standard SQL that porting to Postgres
  would mostly mean swapping out date functions (`strftime` → `to_char`,
  etc.).
- The CLI output is plain text right now — piping through `column -t` or
  swapping in `tabulate` would make it look a lot better.
- There's no incremental or upsert loading; every run is a full rebuild.
  That's fine for a batch analytics exercise, but not how I'd want it
  running in production.
