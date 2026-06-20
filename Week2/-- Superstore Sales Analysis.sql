-- Superstore Sales Analysis
-- Dataset: 9,994 orders | 2020 - 2023

-- 1. Explore the table

PRAGMA table_info(orders);

SELECT * FROM orders LIMIT 5;

SELECT COUNT(*) AS total_rows FROM orders;

SELECT
    COUNT(DISTINCT Customer_ID) AS unique_customers,
    COUNT(DISTINCT Order_ID)    AS unique_orders,
    COUNT(DISTINCT Product_ID)  AS unique_products,
    COUNT(DISTINCT Region)      AS regions,
    COUNT(DISTINCT Category)    AS categories,
    COUNT(DISTINCT State)       AS states
FROM orders;

SELECT
    MIN(Order_Date) AS first_order,
    MAX(Order_Date) AS last_order
FROM orders;


-- 2. Filtering with WHERE

-- Orders from the West region
SELECT Region,
       COUNT(*)             AS orders,
       ROUND(SUM(Sales), 2) AS total_sales
FROM orders
WHERE Region = 'West'
GROUP BY Region;

-- Technology orders only
SELECT Category,
       COUNT(*)             AS orders,
       ROUND(SUM(Sales), 2) AS total_sales,
       ROUND(AVG(Sales), 2) AS avg_sale
FROM orders
WHERE Category = 'Technology'
GROUP BY Category;

-- Orders placed in 2023
SELECT strftime('%Y', Order_Date) AS year,
       COUNT(*)                   AS orders,
       ROUND(SUM(Sales), 2)       AS total_sales
FROM orders
WHERE strftime('%Y', Order_Date) = '2023'
GROUP BY year;

-- High-value orders (sales above $1,000)
SELECT Customer_Name,
       Product_Name,
       Sales,
       Profit,
       Region
FROM orders
WHERE Sales > 1000
ORDER BY Sales DESC
LIMIT 10;

-- Full-price orders that turned a profit
SELECT COUNT(*)             AS orders,
       ROUND(SUM(Profit), 2) AS total_profit
FROM orders
WHERE Discount = 0 AND Profit > 0;

-- 3. Aggregations with GROUP BY

-- Revenue and profit by region
SELECT Region,
       COUNT(*)                  AS orders,
       ROUND(SUM(Sales), 2)      AS total_sales,
       ROUND(SUM(Profit), 2)     AS total_profit,
       ROUND(AVG(Sales), 2)      AS avg_order_value,
       SUM(Quantity)             AS units_sold
FROM orders
GROUP BY Region
ORDER BY total_sales DESC;

-- Category performance with profit margin
SELECT Category,
       COUNT(*)                                 AS orders,
       ROUND(SUM(Sales), 2)                     AS total_sales,
       ROUND(SUM(Profit), 2)                    AS total_profit,
       ROUND(AVG(Discount) * 100, 1)            AS avg_discount_pct,
       ROUND(SUM(Profit) / SUM(Sales) * 100, 2) AS margin_pct
FROM orders
GROUP BY Category
ORDER BY total_sales DESC;

-- Revenue by customer segment
SELECT Segment,
       COUNT(*)                        AS orders,
       ROUND(SUM(Sales), 2)            AS total_sales,
       ROUND(SUM(Profit), 2)           AS total_profit,
       COUNT(DISTINCT Customer_ID)     AS unique_customers
FROM orders
GROUP BY Segment
ORDER BY total_sales DESC;

-- Average order size by shipping mode
SELECT Ship_Mode,
       COUNT(*)                  AS orders,
       ROUND(AVG(Sales), 2)      AS avg_sale,
       ROUND(AVG(Quantity), 2)   AS avg_quantity,
       ROUND(SUM(Sales), 2)      AS total_sales
FROM orders
GROUP BY Ship_Mode
ORDER BY total_sales DESC;

-- 4. Top performers (ORDER BY + LIMIT)

-- Top 10 products by revenue
SELECT Product_Name,
       Category,
       COUNT(*)              AS times_ordered,
       SUM(Quantity)         AS units_sold,
       ROUND(SUM(Sales), 2)  AS revenue,
       ROUND(SUM(Profit), 2) AS profit
FROM orders
GROUP BY Product_Name, Category
ORDER BY revenue DESC
LIMIT 10;

-- Top 10 sub-categories
SELECT Sub_Category,
       Category,
       COUNT(*)                                 AS orders,
       ROUND(SUM(Sales), 2)                     AS total_sales,
       ROUND(SUM(Profit), 2)                    AS total_profit,
       ROUND(SUM(Profit) / SUM(Sales) * 100, 1) AS margin_pct
FROM orders
GROUP BY Sub_Category, Category
ORDER BY total_sales DESC
LIMIT 10;

-- Top 10 customers by lifetime value
SELECT Customer_Name,
       Segment,
       Region,
       COUNT(DISTINCT Order_ID)  AS orders,
       ROUND(SUM(Sales), 2)      AS lifetime_value,
       ROUND(SUM(Profit), 2)     AS total_profit,
       ROUND(AVG(Sales), 2)      AS avg_order_value
FROM orders
GROUP BY Customer_Name, Segment, Region
ORDER BY lifetime_value DESC
LIMIT 10;

-- Top 10 states by revenue
SELECT State,
       Region,
       COUNT(*)              AS orders,
       ROUND(SUM(Sales), 2)  AS total_sales,
       ROUND(SUM(Profit), 2) AS total_profit
FROM orders
GROUP BY State, Region
ORDER BY total_sales DESC
LIMIT 10;

-- 5. Business use cases

-- Monthly sales trend
SELECT strftime('%Y-%m', Order_Date) AS month,
       COUNT(*)                      AS orders,
       ROUND(SUM(Sales), 2)          AS monthly_sales,
       ROUND(SUM(Profit), 2)         AS monthly_profit,
       ROUND(AVG(Sales), 2)          AS avg_order_value
FROM orders
GROUP BY month
ORDER BY month;

-- Year-over-year summary
SELECT strftime('%Y', Order_Date)  AS year,
       COUNT(*)                    AS orders,
       ROUND(SUM(Sales), 2)        AS annual_sales,
       ROUND(SUM(Profit), 2)       AS annual_profit,
       COUNT(DISTINCT Customer_ID) AS customers
FROM orders
GROUP BY year
ORDER BY year;

-- Quarterly sales broken down by category
SELECT strftime('%Y', Order_Date) AS year,
       CASE
           WHEN CAST(strftime('%m', Order_Date) AS INT) BETWEEN 1 AND 3 THEN 'Q1'
           WHEN CAST(strftime('%m', Order_Date) AS INT) BETWEEN 4 AND 6 THEN 'Q2'
           WHEN CAST(strftime('%m', Order_Date) AS INT) BETWEEN 7 AND 9 THEN 'Q3'
           ELSE 'Q4'
       END                        AS quarter,
       Category,
       ROUND(SUM(Sales), 2)       AS sales
FROM orders
GROUP BY year, quarter, Category
ORDER BY year, quarter, Category;

-- How discounting affects profitability
SELECT
    CASE
        WHEN Discount = 0     THEN 'No discount'
        WHEN Discount <= 0.20 THEN 'Low (1–20%)'
        WHEN Discount <= 0.40 THEN 'Medium (21–40%)'
        ELSE                       'High (>40%)'
    END                       AS discount_tier,
    COUNT(*)                  AS orders,
    ROUND(AVG(Profit), 2)     AS avg_profit,
    ROUND(SUM(Sales), 2)      AS total_sales
FROM orders
GROUP BY discount_tier
ORDER BY avg_profit DESC;


-- 6. Data quality checks

-- Check for nulls in key columns
SELECT
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN Sales       IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN Order_Date  IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN Region      IS NULL THEN 1 ELSE 0 END) AS null_region,
    SUM(CASE WHEN Category    IS NULL THEN 1 ELSE 0 END) AS null_category
FROM orders;

-- Duplicate rows per order + product combination
SELECT Order_ID,
       Customer_ID,
       Product_ID,
       COUNT(*) AS occurrences
FROM orders
GROUP BY Order_ID, Customer_ID, Product_ID
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 5;

-- Orders that lost money and what discount they had
SELECT COUNT(*)                                              AS loss_making_orders,
       ROUND(SUM(Profit), 2)                                 AS total_loss,
       ROUND(AVG(Discount) * 100, 1)                         AS avg_discount_pct,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1) AS pct_of_all_orders
FROM orders
WHERE Profit < 0;

-- Sales and profit value range
SELECT
    ROUND(MIN(Sales),  2) AS min_sale,
    ROUND(MAX(Sales),  2) AS max_sale,
    ROUND(AVG(Sales),  2) AS avg_sale,
    ROUND(MIN(Profit), 2) AS min_profit,
    ROUND(MAX(Profit), 2) AS max_profit,
    ROUND(AVG(Profit), 2) AS avg_profit
FROM orders;