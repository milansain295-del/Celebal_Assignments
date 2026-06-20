-- ==============================================================================
-- ENTERPRISE DATA ENGINEERING & RELATIONAL ANALYTICS FRAMEWORK (v2.0)
-- Dialect: SQLite / PostgreSQL Compatible
-- Scope: Full 3rd Normal Form (3NF) Transition, Time-Series Analytics,
--        Multi-Layered CTE Chains, and Window Function Logic.
-- ==============================================================================

/* 
   PROJECT ARCHITECTURE OVERVIEW:
   1. STAGING LAYER: Raw data ingestion from flat sources.
   2. DIMENSIONAL LAYER: Unique entity isolation (Clients, Inventory, Geography).
   3. FACT LAYER: Transactional records with relational constraints.
   4. ANALYTICS LAYER: Business Intelligence through advanced SQL structures.
*/

-- ==============================================================================
-- SECTION 1: DATABASE DDL - SCHEMATIC NORMALIZATION
-- ==============================================================================

-- Entity: Customer Master Table
CREATE TABLE dim_customers (
    customer_key TEXT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    market_segment TEXT,
    loyalty_tier TEXT DEFAULT 'Standard',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Entity: Product & Inventory Catalog
CREATE TABLE dim_products (
    product_key TEXT PRIMARY KEY,
    product_title TEXT NOT NULL,
    major_category TEXT,
    sub_category TEXT,
    unit_cost REAL,
    is_active BOOLEAN DEFAULT 1
);

-- Entity: Geographic Dimensions
CREATE TABLE dim_geography (
    geo_key INTEGER PRIMARY KEY AUTOINCREMENT,
    city_name TEXT,
    state_province TEXT,
    region_zone TEXT,
    postal_code TEXT
);

-- Entity: Time Dimension (Virtual Table Concept)
CREATE TABLE dim_calendar (
    date_key TEXT PRIMARY KEY,
    calendar_year INTEGER,
    calendar_quarter INTEGER,
    calendar_month INTEGER,
    day_of_week TEXT,
    is_business_day BOOLEAN
);

-- Transactional Fact Table: Sales & Logistics
CREATE TABLE fact_sales (
    txn_id INTEGER PRIMARY KEY,
    order_id TEXT NOT NULL,
    customer_key TEXT,
    product_key TEXT,
    geo_key INTEGER,
    order_date TEXT,
    ship_date TEXT,
    ship_mode TEXT,
    quantity INTEGER,
    revenue REAL,
    discount_applied REAL,
    net_profit REAL,
    FOREIGN KEY (customer_key) REFERENCES dim_customers(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_products(product_key),
    FOREIGN KEY (geo_key) REFERENCES dim_geography(geo_key)
);

-- Operational Audit Log Table
CREATE TABLE sys_migration_logs (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    step_name TEXT,
    records_processed INTEGER,
    status TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- SECTION 2: DATA MIGRATION LOGIC (DML)
-- ==============================================================================

-- Extracting Distinct Geographic Points
INSERT INTO dim_geography (city_name, state_province)
SELECT DISTINCT City, State FROM superstore_raw;

-- Normalizing Customer Records
INSERT INTO dim_customers (customer_key, customer_name, market_segment)
SELECT DISTINCT `Customer ID`, `Customer Name`, Segment FROM superstore_raw;

-- Populating Product Catalog
INSERT INTO dim_products (product_key, product_title, major_category, sub_category)
SELECT DISTINCT `Product ID`, `Product Name`, Category, `Sub-Category` FROM superstore_raw;

-- Mapping Transactions into the Fact Layer
INSERT INTO fact_sales (order_id, customer_key, product_key, order_date, ship_date, ship_mode, quantity, revenue, discount_applied, net_profit)
SELECT `Order ID`, `Customer ID`, `Product ID`, `Order Date`, `Ship Date`, `Ship Mode`, Quantity, Sales, Discount, Profit
FROM superstore_raw;

-- ==============================================================================
-- SECTION 3: ADVANCED ANALYTICS & BUSINESS INTELLIGENCE
-- ==============================================================================

-- TASK 1: Dynamic Rolling Average Sales (Window Function)
-- Analyzes revenue trends per customer over their last 3 transactions
SELECT 
    customer_key, 
    order_date, 
    revenue,
    AVG(revenue) OVER(
        PARTITION BY customer_key 
        ORDER BY order_date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as rolling_3_order_avg
FROM fact_sales;

-- TASK 2: High-Velocity Regional Markets (Subqueries)
-- Filters for cities where profit margins exceed the 90th percentile of all cities
SELECT city_name, state_province
FROM dim_geography
WHERE geo_key IN (
    SELECT g.geo_key
    FROM fact_sales s
    JOIN dim_geography g ON s.geo_key = g.geo_key
    GROUP BY g.geo_key
    HAVING SUM(net_profit) > (
        SELECT AVG(total_p) * 1.5 FROM (
            SELECT SUM(net_profit) as total_p FROM fact_sales GROUP BY geo_key
        )
    )
);

-- TASK 3: Year-over-Year (YoY) Growth Simulation (CTE Chaining)
WITH MonthlyRevenue AS (
    SELECT 
        strftime('%Y', order_date) as yr,
        strftime('%m', order_date) as mo,
        SUM(revenue) as m_rev
    FROM fact_sales
    GROUP BY 1, 2
),
GrowthMetrics AS (
    SELECT 
        yr, mo, m_rev,
        LAG(m_rev, 12) OVER(ORDER BY yr, mo) as prev_year_rev
    FROM MonthlyRevenue
)
SELECT 
    yr, mo, m_rev, 
    prev_year_rev,
    ROUND(((m_rev - prev_year_rev) / prev_year_rev) * 100, 2) as yoy_pct_change
FROM GrowthMetrics
WHERE prev_year_rev IS NOT NULL;

-- TASK 4: Pareto Analysis (80/20 Rule) for Customers
WITH CustomerTotals AS (
    SELECT customer_key, SUM(revenue) as total_revenue
    FROM fact_sales
    GROUP BY customer_key
),
CumulativeRevenue AS (
    SELECT 
        customer_key, 
        total_revenue,
        SUM(total_revenue) OVER(ORDER BY total_revenue DESC) as running_total,
        SUM(total_revenue) OVER() as global_total
    FROM CustomerTotals
)
SELECT 
    customer_key, 
    total_revenue, 
    (running_total / global_total) * 100 as cumulative_percentage
FROM CumulativeRevenue
WHERE cumulative_percentage <= 80;

-- ==============================================================================
-- SECTION 4: LOGISTICS & PERFORMANCE AUDITS
-- ==============================================================================

-- Audit A: Order-to-Ship Latency Analysis
SELECT 
    order_id,
    order_date,
    ship_date,
    (julianday(ship_date) - julianday(order_date)) as processing_days,
    CASE 
        WHEN (julianday(ship_date) - julianday(order_date)) <= 2 THEN 'Elite Efficiency'
        WHEN (julianday(ship_date) - julianday(order_date)) <= 5 THEN 'Standard'
        ELSE 'Delayed'
    END as efficiency_rating
FROM fact_sales
WHERE ship_date IS NOT NULL;

-- Audit B: Discount Cannibalization Report
-- Identifies products where high discounts are destroying net profit
SELECT 
    p.product_title, 
    AVG(s.discount_applied) as avg_discount,
    SUM(s.net_profit) as total_impact
FROM fact_sales s
JOIN dim_products p ON s.product_key = p.product_key
GROUP BY p.product_key
HAVING avg_discount > 0.2 AND total_impact < 0
ORDER BY total_impact ASC;

-- ==============================================================================
-- SECTION 5: FINAL CLEANUP & DATA EXPORT PREPARATION
-- ==============================================================================

-- Create a flattened Analytics View for visualization export
CREATE VIEW view_executive_dashboard AS
SELECT 
    s.order_id, 
    c.customer_name, 
    c.market_segment,
    p.product_title,
    p.major_category,
    s.revenue,
    s.net_profit,
    s.order_date
FROM fact_sales s
JOIN dim_customers c ON s.customer_key = c.customer_key
JOIN dim_products p ON s.product_key = p.product_key;
