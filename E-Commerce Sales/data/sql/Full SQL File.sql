/*==============================================================================
  E-COMMERCE SALES ANALYSIS PROJECT  |  SQL Server (SSMS)
  ------------------------------------------------------------------------------
  Source files (5):
    1. customer_master            -> one row per customer
    2. product_catalog            -> one row per product
    3. ecommerce_sales_customer   -> main Total Transactions (order level, 47 columns)
    4. order_items                -> order lines (order_id + product_id)
    5. dataset_statistics          -> summary row, used to reconcile our results

  Relationships:
    customer_master.customer_id  1 --- *  ecommerce_sales_customer.customer_id
    ecommerce_sales_customer.order_id 1 --- *  order_items.order_id
    product_catalog.product_id   1 --- *  order_items.product_id

  Script structure:
    PART 1  Create database and tables
    PART 2  Load the CSV files
    PART 3  Data quality checks
    PART 4  Reconcile with dataset_statistics
    PART 5  Indexes and views
    PART 6  Analysis queries (sales, products, customers, operations, marketing)
==============================================================================*/


/*==============================================================================
  PART 1: DATABASE AND TABLES
==============================================================================*/
IF DB_ID('e_commerce') IS NULL
    CREATE DATABASE e_commerce;
GO
USE e_commerce;
GO

-- 1.1 customer_master -------------------------------------------------------
--CREATE TABLE  customer_master (
--    customer_id               VARCHAR(15)    NOT NULL PRIMARY KEY,   -- e.g. CUST-000001
--    customer_name             NVARCHAR(150)  NULL,
--    customer_age              TINYINT        NULL,
--    gender                    VARCHAR(20)    NULL,
--    customer_segment          VARCHAR(50)    NULL,
--    customer_city             NVARCHAR(100)  NULL,
--    customer_state            NVARCHAR(100)  NULL,
--    customer_country          NVARCHAR(100)  NULL,
--    region                    VARCHAR(50)    NULL,
--    customer_postal_code      VARCHAR(20)    NULL,                   -- text keeps leading zeros
--    customer_acquisition_cost DECIMAL(10,2)  NULL
--);
--GO

-- 1.2 product_catalog -------------------------------------------------------
--CREATE TABLE  product_catalog (
--    product_id          VARCHAR(20)    NOT NULL PRIMARY KEY,
--    product_name        NVARCHAR(200)  NULL,
--    product_category    VARCHAR(100)   NULL,
--    product_subcategory VARCHAR(100)   NULL,
--    brand               NVARCHAR(100)  NULL,
--    supplier            NVARCHAR(150)  NULL,
--    unit_price          DECIMAL(12,2)  NULL,
--    product_cost        DECIMAL(12,2)  NULL,
--    product_rating      DECIMAL(3,1)   NULL
--);
--GO

-- 1.3 ecommerce_sales_customer (main fact table) ----------------------------
----CREATE TABLE  ecommerce_sales_customer (
--    order_id                    VARCHAR(20)    NOT NULL,
--    order_date                  DATE           NULL,
--    order_time                  TIME(0)        NULL,
--    order_status                VARCHAR(30)    NULL,
--    sales_channel               VARCHAR(50)    NULL,
--    customer_id                 VARCHAR(15)    NOT NULL,
--    customer_name               NVARCHAR(150)  NULL,
--    customer_age                TINYINT        NULL,
--    gender                      VARCHAR(20)    NULL,
--    customer_segment            VARCHAR(50)    NULL,
--    customer_type               VARCHAR(30)    NULL,
--    customer_city               NVARCHAR(100)  NULL,
--    customer_state              NVARCHAR(100)  NULL,
--    customer_country            NVARCHAR(100)  NULL,
--    region                      VARCHAR(50)    NULL,
--    customer_postal_code        VARCHAR(20)    NULL,
--    payment_method              VARCHAR(50)    NULL,
--    payment_status              VARCHAR(30)    NULL,
--    currency                    VARCHAR(10)    NULL,
--    shipping_method             VARCHAR(50)    NULL,
--    warehouse                   VARCHAR(100)   NULL,
--    delivery_days               SMALLINT       NULL,
--    estimated_delivery_days     SMALLINT       NULL,
--    delivery_status             VARCHAR(30)    NULL,
--    return_status               VARCHAR(30)    NULL,
--    return_reason               NVARCHAR(200)  NULL,
--    customer_rating             DECIMAL(3,1)   NULL,
--    review_sentiment            VARCHAR(30)    NULL,
--    customer_review             NVARCHAR(1000) NULL,
--    marketing_channel           VARCHAR(50)    NULL,
--    campaign_name               NVARCHAR(150)  NULL,
--    coupon_code                 VARCHAR(50)    NULL,
--    loyalty_points_earned       INT            NULL,
--    loyalty_points_redeemed     INT            NULL,
--    quantity                    INT            NULL,
--    gross_sales                 DECIMAL(14,2)  NULL,
--    discount_amount             DECIMAL(14,2)  NULL,
--    tax_amount                  DECIMAL(14,2)  NULL,
--    shipping_cost               DECIMAL(14,2)  NULL,
--    net_sales                   DECIMAL(14,2)  NULL,
--    product_cost                DECIMAL(14,2)  NULL,
--    profit                      DECIMAL(14,2)  NULL,
--    profit_margin_percentage    DECIMAL(8,2)   NULL,
--    customer_lifetime_value     DECIMAL(14,2)  NULL,
--    is_repeat_customer          VARCHAR(10)    NULL,                 -- Yes/No, True/False or 1/0
--    customer_order_count        INT            NULL
--)--/
--GO--

-- 1.4 order_items -----------------------------------------------------------
--CREATE TABLE  order_items (
--    order_id            VARCHAR(20)    NOT NULL,
--    product_id          VARCHAR(20)    NOT NULL,
--    quantity            INT            NULL,
--    unit_price          DECIMAL(12,2)  NULL,
--    discount_percentage DECIMAL(6,2)   NULL,
--    discount_amount     DECIMAL(14,2)  NULL,
--    gross_sales         DECIMAL(14,2)  NULL,
--    tax_amount          DECIMAL(14,2)  NULL,
--    shipping_cost       DECIMAL(14,2)  NULL,
--    net_sales           DECIMAL(14,2)  NULL,
--    product_cost        DECIMAL(14,2)  NULL,
--    profit              DECIMAL(14,2)  NULL
--);
--GO

---- 1.5 dataset_statistics (summary row) ---------------------------------------
--CREATE TABLE  dataset_statistics (
--    Total Transactions        INT            NULL,
--    total_columns       INT            NULL,
--    Total Customers     INT            NULL,
--    total_products_used INT            NULL,
--    date_range          VARCHAR(60)    NULL,                         -- text, e.g. '2022-01-01 to 2024-12-31'
--    total_revenue       DECIMAL(18,2)  NULL,
--    total_profit        DECIMAL(18,2)  NULL,
--    average_order_value DECIMAL(10,2)  NULL,
--    average_rating      DECIMAL(4,2)   NULL,
--    return_rate         DECIMAL(8,4)   NULL,                         -- check scale: 0.05 or 5.0
--    cancellation_rate   DECIMAL(8,4)   NULL
--);
--GO


/*==============================================================================
  PART 2: LOAD THE CSV FILES
  - Change the folder path. The SQL Server SERVICE must be able to read it.
  - If a load fails, use the wizard instead: right-click e_commerce ->
    Tasks -> Import Flat File (map to the existing table).
  - If dates are dd/mm/yyyy, run:  SET DATEFORMAT dmy;  before the load.
  - If rate columns contain '%' symbols, import dataset_statistics via the wizard
    and convert the columns manually.
==============================================================================*/
BULK INSERT  customer_master
FROM 'C:\EcommerceProject\customer_master.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);

BULK INSERT  product_catalog
FROM 'C:\EcommerceProject\product_catalog.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);

BULK INSERT  ecommerce_sales_customer
FROM 'C:\EcommerceProject\ecommerce_sales_customer.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);

BULK INSERT  order_items
FROM 'C:\EcommerceProject\order_items.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);

BULK INSERT  dataset_statistics
FROM 'C:\EcommerceProject\dataset_statistics.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', TABLOCK);
GO


/*==============================================================================
  PART 3: DATA QUALITY CHECKS
==============================================================================*/
USE e_commerce;
GO

-- 3.1 Row counts ------------------------------------------------------------
SELECT 'customer_master'          AS table_name, COUNT(*) AS row_count FROM  customer_master
UNION ALL SELECT 'product_catalog',            COUNT(*) FROM  product_catalog
UNION ALL SELECT 'ecommerce_sales_customer',   COUNT(*) FROM  ecommerce_sales_customer
UNION ALL SELECT 'order_items',                COUNT(*) FROM  order_items
UNION ALL SELECT 'dataset_statistics',          COUNT(*) FROM  dataset_statistics;

-- 3.2 Grain of the sales table: one row per order, or one row per order line? -
SELECT COUNT(*)                  AS rows_loaded,
       COUNT(DISTINCT order_id)  AS unique_orders
FROM  ecommerce_sales_customer;
-- If both numbers match: one row per order (you can add a primary key on order_id).
-- If not: the table holds order lines, and the analysis queries need adjusting.

-- 3.3 Orphan checks (relationships) ----------------------------------------
-- Sales rows whose customer is not in customer_master
SELECT COUNT(*) AS sales_without_customer
FROM  ecommerce_sales_customer s
LEFT JOIN  customer_master c ON c.customer_id = s.customer_id
WHERE c.customer_id IS NULL;

-- Order lines whose order is not in the sales table
SELECT COUNT(*) AS items_without_order
FROM  order_items i
LEFT JOIN  ecommerce_sales_customer s ON s.order_id = i.order_id
WHERE s.order_id IS NULL;

-- Order lines whose product is not in product_catalog
SELECT COUNT(*) AS items_without_product
FROM  order_items i
LEFT JOIN  product_catalog p ON p.product_id = i.product_id
WHERE p.product_id IS NULL;

-- Orders with no order lines
SELECT COUNT(DISTINCT s.order_id) AS orders_without_items
FROM  ecommerce_sales_customer s
LEFT JOIN  order_items i ON i.order_id = s.order_id
WHERE i.order_id IS NULL;

-- 3.4 Categorical values (use these to adjust the flags in PART 5) ----------
SELECT order_status,    COUNT(*) AS n FROM  ecommerce_sales_customer GROUP BY order_status    ORDER BY n DESC;
SELECT return_status,   COUNT(*) AS n FROM  ecommerce_sales_customer GROUP BY return_status   ORDER BY n DESC;
SELECT delivery_status, COUNT(*) AS n FROM  ecommerce_sales_customer GROUP BY delivery_status ORDER BY n DESC;
SELECT payment_status,  COUNT(*) AS n FROM  ecommerce_sales_customer GROUP BY payment_status  ORDER BY n DESC;
SELECT is_repeat_customer, COUNT(*) AS n FROM  ecommerce_sales_customer GROUP BY is_repeat_customer;
SELECT sales_channel,   COUNT(*) AS n FROM  ecommerce_sales_customer GROUP BY sales_channel   ORDER BY n DESC;
SELECT currency,        COUNT(*) AS n FROM  ecommerce_sales_customer GROUP BY currency        ORDER BY n DESC;

-- 3.5 Missing values in key columns ----------------------------------------
SELECT
    COUNT(CASE WHEN order_date       IS NULL THEN 1 END) AS null_order_date,
    COUNT(CASE WHEN customer_id      IS NULL THEN 1 END) AS null_customer_id,
    COUNT(CASE WHEN net_sales        IS NULL THEN 1 END) AS null_net_sales,
    COUNT(CASE WHEN profit           IS NULL THEN 1 END) AS null_profit,
    COUNT(CASE WHEN customer_rating  IS NULL THEN 1 END) AS null_rating,
    COUNT(CASE WHEN delivery_days    IS NULL THEN 1 END) AS null_delivery_days
FROM  ecommerce_sales_customer;

-- 3.6 Date range and value ranges ------------------------------------------
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order
FROM  ecommerce_sales_customer;

SELECT MIN(customer_age) AS min_age, MAX(customer_age) AS max_age,
       MIN(net_sales) AS min_net_sales, MAX(net_sales) AS max_net_sales,
       MIN(customer_rating) AS min_rating, MAX(customer_rating) AS max_rating
FROM  ecommerce_sales_customer;

-- 3.7 Financial logic: find which formula the data follows -------------------
-- Candidate A: net_sales = gross_sales - discount_amount
-- Candidate B: net_sales = gross_sales - discount_amount + tax_amount + shipping_cost
SELECT
    SUM(CASE WHEN ABS(net_sales - (gross_sales - discount_amount)) <= 0.01 THEN 1 ELSE 0 END) AS match_formula_A,
    SUM(CASE WHEN ABS(net_sales - (gross_sales - discount_amount + tax_amount + shipping_cost)) <= 0.01 THEN 1 ELSE 0 END) AS match_formula_B,
    COUNT(*) AS total_rows
FROM  ecommerce_sales_customer;

-- Profit: profit = net_sales - product_cost ?
SELECT
    SUM(CASE WHEN ABS(profit - (net_sales - product_cost)) <= 0.01 THEN 1 ELSE 0 END) AS profit_matches,
    COUNT(*) AS total_rows
FROM  ecommerce_sales_customer;

-- 3.8 Do customer attributes in the sales table match customer_master? -------
SELECT COUNT(*) AS mismatched_rows
FROM  ecommerce_sales_customer s
JOIN  customer_master c ON c.customer_id = s.customer_id
WHERE ISNULL(s.customer_segment,'') <> ISNULL(c.customer_segment,'')
   OR ISNULL(s.customer_city,'')    <> ISNULL(c.customer_city,'')
   OR ISNULL(s.region,'')           <> ISNULL(c.region,'')
   OR ISNULL(s.customer_age,0)      <> ISNULL(c.customer_age,0);

-- 3.9 Do order_items totals match the sales table? ---------------------------
-- Matters because joining both tables and summing money columns can double count.
SELECT
    (SELECT SUM(net_sales) FROM  ecommerce_sales_customer) AS sales_table_net_sales,
    (SELECT SUM(net_sales) FROM  order_items)              AS items_table_net_sales,
    (SELECT SUM(profit)    FROM  ecommerce_sales_customer) AS sales_table_profit,
    (SELECT SUM(profit)    FROM  order_items)              AS items_table_profit;

-- 3.10 Exact duplicate order lines ------------------------------------------
SELECT order_id, product_id, COUNT(*) AS copies
FROM  order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;
GO


/*==============================================================================
  PART 4: RECONCILE WITH dataset_statistics
  The summary file is your answer key: if these do not match, investigate.
==============================================================================*/
SELECT
    d.[Total Transactions],
    (SELECT COUNT(DISTINCT order_id) FROM  ecommerce_sales_customer)               AS calc_transactions,
    d.[Total Products Used],
    (SELECT COUNT(DISTINCT customer_id) FROM  ecommerce_sales_customer)            AS calc_customers,
    d.[Total Products Used],
    (SELECT COUNT(DISTINCT product_id) FROM  order_items)                          AS calc_products,
    d.[Total Revenue],
    (SELECT SUM(net_sales) FROM  ecommerce_sales_customer)                         AS calc_revenue,
    d.[Total Profit],
    (SELECT SUM(profit) FROM  ecommerce_sales_customer)                            AS calc_profit,
    d.[Average Order Value],
    (SELECT AVG(net_sales) FROM  ecommerce_sales_customer)                         AS calc_aov,
    d.[Average Rating],
    (SELECT AVG(customer_rating) FROM  ecommerce_sales_customer)                   AS calc_avg_rating,
    d.[Date Range],
    (SELECT CONCAT(MIN(order_date), ' to ', MAX(order_date)) FROM  ecommerce_sales_customer) AS calc_date_range
FROM  dataset_statistics d;
GO


/*==============================================================================
  PART 5: INDEXES AND VIEWS
==============================================================================*/

-- 5.1 Indexes (speed up joins and filters) ----------------------------------
CREATE INDEX IX_sales_order_id    ON  ecommerce_sales_customer (order_id);
CREATE INDEX IX_sales_customer_id ON  ecommerce_sales_customer (customer_id);
CREATE INDEX IX_sales_order_date  ON  ecommerce_sales_customer (order_date);
CREATE INDEX IX_items_order_id    ON  order_items (order_id);
CREATE INDEX IX_items_product_id  ON  order_items (product_id);
GO

-- 5.2 Optional: enforce relationships (only after PART 3 shows zero orphans) --
-- ALTER TABLE  ecommerce_sales_customer ADD CONSTRAINT PK_sales PRIMARY KEY (order_id);  -- only if order_id is unique
-- ALTER TABLE  ecommerce_sales_customer ADD CONSTRAINT FK_sales_customer
--     FOREIGN KEY (customer_id) REFERENCES  customer_master (customer_id);
-- ALTER TABLE  order_items ADD CONSTRAINT FK_items_product
--     FOREIGN KEY (product_id) REFERENCES  product_catalog (product_id);
-- ALTER TABLE  order_items ADD CONSTRAINT FK_items_order
--     FOREIGN KEY (order_id) REFERENCES  ecommerce_sales_customer (order_id);

-- 5.3 View: one row per order, with flags and customer cost ------------------
-- ADJUST the text literals in the flags to match the values found in PART 3.4.
CREATE OR ALTER VIEW  vw_sales_orders AS
SELECT
    s.*,
    DATEFROMPARTS(YEAR(s.order_date), MONTH(s.order_date), 1)             AS order_month,
    YEAR(s.order_date)                                                    AS order_year,
    c.customer_acquisition_cost,
    CASE WHEN s.order_status LIKE '%cancel%' THEN 1 ELSE 0 END            AS is_cancelled,
    CASE WHEN s.return_status IS NOT NULL
          AND s.return_status NOT IN ('', 'None', 'No', 'Not Returned', 'N/A')
         THEN 1 ELSE 0 END                                                AS is_returned,
    CASE WHEN s.delivery_days > s.estimated_delivery_days THEN 1 ELSE 0 END AS is_late,
    s.delivery_days - s.estimated_delivery_days                           AS delay_days,
    CASE WHEN s.is_repeat_customer IN ('Yes','Y','True','1') THEN 1 ELSE 0 END AS is_repeat_flag
FROM  ecommerce_sales_customer s
LEFT JOIN  customer_master c ON c.customer_id = s.customer_id;
GO

-- 5.4 View: one row per order line, with product and order context -----------
CREATE OR ALTER VIEW  vw_order_items_detail AS
SELECT
    i.order_id,
    i.product_id,
    p.product_name,
    p.product_category,
    p.product_subcategory,
    p.brand,
    p.supplier,
    p.product_rating,
    i.quantity,
    i.unit_price,
    i.discount_percentage,
    i.discount_amount,
    i.gross_sales,
    i.tax_amount,
    i.shipping_cost,
    i.net_sales,
    i.product_cost,
    i.profit,
    o.order_date,
    o.order_month,
    o.order_status,
    o.sales_channel,
    o.customer_id,
    o.customer_segment,
    o.region,
    o.is_cancelled,
    o.is_returned
FROM  order_items i
JOIN  vw_sales_orders o      ON o.order_id   = i.order_id
LEFT JOIN  product_catalog p ON p.product_id = i.product_id;
GO


/*==============================================================================
  PART 6: ANALYSIS QUERIES
  Revenue = net_sales, excluding cancelled orders unless stated otherwise.
  Rule to avoid double counting: use vw_sales_orders for order-level metrics
  and vw_order_items_detail for product-level metrics. Do not join the two
  and then SUM money columns.
==============================================================================*/

---------------------------------------------------------------------------
-- 6A. SALES PERFORMANCE
---------------------------------------------------------------------------

-- A1. Headline KPIs
SELECT
    COUNT(DISTINCT order_id)                         AS orders,
    COUNT(DISTINCT customer_id)                      AS customers,
    SUM(net_sales)                                   AS revenue,
    SUM(profit)                                      AS profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(net_sales),0), 2) AS profit_margin_pct,
    ROUND(AVG(net_sales), 2)                         AS avg_order_value,
    ROUND(AVG(customer_rating), 2)                   AS avg_rating
FROM  vw_sales_orders
WHERE is_cancelled = 0;

-- A2. Monthly revenue, profit and month-over-month growth
WITH monthly AS (
    SELECT order_month,
           COUNT(DISTINCT order_id) AS orders,
           SUM(net_sales)           AS revenue,
           SUM(profit)              AS profit
    FROM  vw_sales_orders
    WHERE is_cancelled = 0
    GROUP BY order_month
)
SELECT order_month, orders, revenue, profit,
       LAG(revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY order_month))
             / NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0), 2) AS revenue_growth_pct
FROM monthly
ORDER BY order_month;

-- A3. Yearly summary
SELECT order_year,
       COUNT(DISTINCT order_id) AS orders,
       SUM(net_sales)           AS revenue,
       SUM(profit)              AS profit,
       ROUND(AVG(net_sales),2)  AS avg_order_value
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY order_year
ORDER BY order_year;

-- A4. Seasonality: revenue by calendar month (all years combined)
SELECT MONTH(order_date) AS month_number,
       DATENAME(MONTH, order_date) AS month_name,
       SUM(net_sales) AS revenue
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY MONTH(order_date), DATENAME(MONTH, order_date)
ORDER BY month_number;

-- A5. Revenue by sales channel
SELECT sales_channel,
       COUNT(DISTINCT order_id) AS orders,
       SUM(net_sales)           AS revenue,
       SUM(profit)              AS profit,
       ROUND(100.0 * SUM(profit) / NULLIF(SUM(net_sales),0), 2) AS margin_pct
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY sales_channel
ORDER BY revenue DESC;

-- A6. Revenue by region, country and city (top 15 cities)
SELECT region, SUM(net_sales) AS revenue, SUM(profit) AS profit
FROM  vw_sales_orders WHERE is_cancelled = 0
GROUP BY region ORDER BY revenue DESC;

SELECT TOP 15 customer_country, customer_city, SUM(net_sales) AS revenue
FROM  vw_sales_orders WHERE is_cancelled = 0
GROUP BY customer_country, customer_city ORDER BY revenue DESC;

-- A7. Payment methods
SELECT payment_method,
       COUNT(*) AS orders,
       SUM(net_sales) AS revenue,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM  vw_sales_orders
GROUP BY payment_method
ORDER BY orders DESC;

---------------------------------------------------------------------------
-- 6B. PRODUCTS
---------------------------------------------------------------------------

-- B1. Top 10 products by revenue
SELECT TOP 10 product_id, product_name, product_category,
       SUM(quantity) AS units_sold,
       SUM(net_sales) AS revenue,
       SUM(profit)    AS profit
FROM  vw_order_items_detail
WHERE is_cancelled = 0
GROUP BY product_id, product_name, product_category
ORDER BY revenue DESC;

-- B2. Category and subcategory performance
SELECT product_category, product_subcategory,
       SUM(quantity)  AS units_sold,
       SUM(net_sales) AS revenue,
       SUM(profit)    AS profit,
       ROUND(100.0 * SUM(profit) / NULLIF(SUM(net_sales),0), 2) AS margin_pct
FROM  vw_order_items_detail
WHERE is_cancelled = 0
GROUP BY product_category, product_subcategory
ORDER BY revenue DESC;

-- B3. Brand and supplier performance
SELECT brand, SUM(net_sales) AS revenue, SUM(profit) AS profit,
       ROUND(100.0 * SUM(profit) / NULLIF(SUM(net_sales),0), 2) AS margin_pct
FROM  vw_order_items_detail
WHERE is_cancelled = 0
GROUP BY brand ORDER BY revenue DESC;

SELECT supplier, SUM(net_sales) AS revenue, SUM(profit) AS profit
FROM  vw_order_items_detail
WHERE is_cancelled = 0
GROUP BY supplier ORDER BY revenue DESC;

-- B4. Products that sell a lot but earn little (high revenue, low margin)
SELECT TOP 20 product_id, product_name,
       SUM(net_sales) AS revenue,
       ROUND(100.0 * SUM(profit) / NULLIF(SUM(net_sales),0), 2) AS margin_pct
FROM  vw_order_items_detail
WHERE is_cancelled = 0
GROUP BY product_id, product_name
HAVING SUM(net_sales) > (SELECT AVG(r) FROM (SELECT SUM(net_sales) AS r
                                             FROM  vw_order_items_detail
                                             WHERE is_cancelled = 0
                                             GROUP BY product_id) x)
ORDER BY margin_pct ASC;

-- B5. Discount impact: margin by discount band
SELECT CASE WHEN discount_percentage = 0  THEN '0%'
            WHEN discount_percentage <= 10 THEN '1-10%'
            WHEN discount_percentage <= 20 THEN '11-20%'
            ELSE '20%+' END AS discount_band,
       COUNT(*)        AS order_lines,
       SUM(quantity)   AS units,
       SUM(net_sales)  AS revenue,
       ROUND(100.0 * SUM(profit) / NULLIF(SUM(net_sales),0), 2) AS margin_pct
FROM  order_items
GROUP BY CASE WHEN discount_percentage = 0  THEN '0%'
              WHEN discount_percentage <= 10 THEN '1-10%'
              WHEN discount_percentage <= 20 THEN '11-20%'
              ELSE '20%+' END
ORDER BY MIN(discount_percentage);

-- B6. Does the catalog rating relate to sales?
SELECT ROUND(product_rating, 0) AS rating_band,
       COUNT(DISTINCT product_id) AS products,
       SUM(net_sales) AS revenue
FROM  vw_order_items_detail
WHERE is_cancelled = 0
GROUP BY ROUND(product_rating, 0)
ORDER BY rating_band;

---------------------------------------------------------------------------
-- 6C. CUSTOMERS
---------------------------------------------------------------------------

-- C1. Segment performance
SELECT customer_segment,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(DISTINCT order_id)    AS orders,
       SUM(net_sales)              AS revenue,
       ROUND(SUM(net_sales) / NULLIF(COUNT(DISTINCT customer_id),0), 2) AS revenue_per_customer
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY customer_segment
ORDER BY revenue DESC;

-- C2. Age groups and gender
SELECT CASE WHEN customer_age < 25 THEN '<25'
            WHEN customer_age < 35 THEN '25-34'
            WHEN customer_age < 45 THEN '35-44'
            WHEN customer_age < 55 THEN '45-54'
            ELSE '55+' END AS age_group,
       gender,
       COUNT(DISTINCT customer_id) AS customers,
       SUM(net_sales)              AS revenue
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY CASE WHEN customer_age < 25 THEN '<25'
              WHEN customer_age < 35 THEN '25-34'
              WHEN customer_age < 45 THEN '35-44'
              WHEN customer_age < 55 THEN '45-54'
              ELSE '55+' END, gender
ORDER BY age_group, gender;

-- C3. Top 20 customers by revenue
SELECT TOP 20 o.customer_id, c.customer_name, c.customer_segment,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(o.net_sales)           AS revenue,
       SUM(o.profit)              AS profit
FROM  vw_sales_orders o
JOIN  customer_master c ON c.customer_id = o.customer_id
WHERE o.is_cancelled = 0
GROUP BY o.customer_id, c.customer_name, c.customer_segment
ORDER BY revenue DESC;

-- C4. Repeat vs one-time customers
WITH per_customer AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS orders, SUM(net_sales) AS revenue
    FROM  vw_sales_orders
    WHERE is_cancelled = 0
    GROUP BY customer_id
)
SELECT CASE WHEN orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_group,
       COUNT(*)                 AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers,
       SUM(revenue)             AS revenue,
       ROUND(AVG(revenue), 2)   AS avg_revenue_per_customer
FROM per_customer
GROUP BY CASE WHEN orders = 1 THEN 'One-time' ELSE 'Repeat' END;

-- C5. RFM segmentation (Recency, Frequency, Monetary)
WITH cust AS (
    SELECT customer_id,
           MAX(order_date)          AS last_order,
           COUNT(DISTINCT order_id) AS frequency,
           SUM(net_sales)           AS monetary
    FROM  vw_sales_orders
    WHERE is_cancelled = 0
    GROUP BY customer_id
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY last_order) AS r_score,   -- 5 = most recent
           NTILE(5) OVER (ORDER BY frequency)  AS f_score,
           NTILE(5) OVER (ORDER BY monetary)   AS m_score
    FROM cust
)
SELECT customer_id, last_order, frequency, monetary, r_score, f_score, m_score,
       CASE WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal'
            WHEN r_score >= 4 AND f_score <= 2                  THEN 'New / Promising'
            WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2                  THEN 'Lost'
            ELSE 'Needs Attention' END AS rfm_segment
FROM scored
ORDER BY monetary DESC;

-- C6. Acquisition cost vs revenue (is each customer worth what it cost to get them?)
WITH rev AS (
    SELECT customer_id, SUM(net_sales) AS revenue, SUM(profit) AS profit
    FROM  vw_sales_orders
    WHERE is_cancelled = 0
    GROUP BY customer_id
)
SELECT c.customer_segment,
       COUNT(*)                                   AS customers,
       ROUND(AVG(c.customer_acquisition_cost),2)  AS avg_cac,
       ROUND(AVG(r.revenue),2)                    AS avg_revenue,
       ROUND(AVG(r.profit),2)                     AS avg_profit,
       ROUND(AVG(r.profit) / NULLIF(AVG(c.customer_acquisition_cost),0), 2) AS profit_to_cac_ratio
FROM  customer_master c
JOIN rev r ON r.customer_id = c.customer_id
GROUP BY c.customer_segment
ORDER BY profit_to_cac_ratio DESC;

-- C7. First-order cohorts: how many customers come back in later months?
WITH first_order AS (
    SELECT customer_id, MIN(order_month) AS cohort_month
    FROM  vw_sales_orders
    WHERE is_cancelled = 0
    GROUP BY customer_id
),
activity AS (
    SELECT DISTINCT o.customer_id, f.cohort_month, o.order_month,
           DATEDIFF(MONTH, f.cohort_month, o.order_month) AS month_index
    FROM  vw_sales_orders o
    JOIN first_order f ON f.customer_id = o.customer_id
    WHERE o.is_cancelled = 0
)
SELECT cohort_month, month_index, COUNT(*) AS active_customers
FROM activity
GROUP BY cohort_month, month_index
ORDER BY cohort_month, month_index;

-- C8. Customer lifetime value by segment, and loyalty points usage
SELECT customer_segment,
       ROUND(AVG(customer_lifetime_value), 2) AS avg_clv,
       SUM(loyalty_points_earned)             AS points_earned,
       SUM(loyalty_points_redeemed)           AS points_redeemed,
       ROUND(100.0 * SUM(loyalty_points_redeemed) / NULLIF(SUM(loyalty_points_earned),0), 2) AS redemption_pct
FROM  vw_sales_orders
GROUP BY customer_segment
ORDER BY avg_clv DESC;

---------------------------------------------------------------------------
-- 6D. OPERATIONS: DELIVERY, RETURNS, CANCELLATIONS
---------------------------------------------------------------------------

-- D1. Delivery performance by shipping method
SELECT shipping_method,
       COUNT(*)                                   AS orders,
       ROUND(AVG(CAST(delivery_days AS FLOAT)),2) AS avg_delivery_days,
       ROUND(AVG(CAST(estimated_delivery_days AS FLOAT)),2) AS avg_estimated_days,
       ROUND(100.0 * SUM(is_late) / COUNT(*), 2)  AS late_pct,
       ROUND(AVG(shipping_cost), 2)               AS avg_shipping_cost
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY shipping_method
ORDER BY late_pct DESC;

-- D2. Warehouse performance
SELECT warehouse,
       COUNT(*)                                   AS orders,
       ROUND(AVG(CAST(delivery_days AS FLOAT)),2) AS avg_delivery_days,
       ROUND(100.0 * SUM(is_late) / COUNT(*), 2)  AS late_pct,
       ROUND(100.0 * SUM(is_returned) / COUNT(*), 2) AS return_pct
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY warehouse
ORDER BY late_pct DESC;

-- D3. Does late delivery hurt ratings?
SELECT CASE WHEN is_late = 1 THEN 'Late' ELSE 'On time / early' END AS delivery_result,
       COUNT(*)                        AS orders,
       ROUND(AVG(customer_rating), 2)  AS avg_rating,
       ROUND(100.0 * SUM(is_returned) / COUNT(*), 2) AS return_pct
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY CASE WHEN is_late = 1 THEN 'Late' ELSE 'On time / early' END;

-- D4. Return rate by category and top return reasons
SELECT product_category,
       COUNT(*) AS order_lines,
       SUM(is_returned) AS returned_lines,
       ROUND(100.0 * SUM(is_returned) / COUNT(*), 2) AS return_rate_pct
FROM  vw_order_items_detail
WHERE is_cancelled = 0
GROUP BY product_category
ORDER BY return_rate_pct DESC;

SELECT return_reason, COUNT(*) AS returns, SUM(net_sales) AS revenue_returned
FROM  vw_sales_orders
WHERE is_returned = 1
GROUP BY return_reason
ORDER BY returns DESC;

-- D5. Cancellation rate by channel and payment method
SELECT sales_channel,
       COUNT(*) AS orders,
       SUM(is_cancelled) AS cancelled,
       ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancellation_rate_pct
FROM  vw_sales_orders
GROUP BY sales_channel
ORDER BY cancellation_rate_pct DESC;

SELECT payment_method,
       ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2) AS cancellation_rate_pct
FROM  vw_sales_orders
GROUP BY payment_method
ORDER BY cancellation_rate_pct DESC;

---------------------------------------------------------------------------
-- 6E. MARKETING AND PROMOTIONS
---------------------------------------------------------------------------

-- E1. Marketing channel performance
SELECT marketing_channel,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(DISTINCT order_id)    AS orders,
       SUM(net_sales)              AS revenue,
       SUM(profit)                 AS profit,
       ROUND(AVG(customer_acquisition_cost), 2) AS avg_cac
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY marketing_channel
ORDER BY revenue DESC;

-- E2. Campaign performance
SELECT campaign_name,
       COUNT(DISTINCT order_id) AS orders,
       SUM(net_sales)           AS revenue,
       SUM(discount_amount)     AS discount_given,
       SUM(profit)              AS profit,
       ROUND(100.0 * SUM(profit) / NULLIF(SUM(net_sales),0), 2) AS margin_pct
FROM  vw_sales_orders
WHERE is_cancelled = 0 AND campaign_name IS NOT NULL AND campaign_name <> ''
GROUP BY campaign_name
ORDER BY profit DESC;

-- E3. Coupon impact: orders with vs without a coupon
SELECT CASE WHEN coupon_code IS NULL OR coupon_code = '' THEN 'No coupon' ELSE 'Coupon used' END AS coupon_use,
       COUNT(*)                  AS orders,
       ROUND(AVG(net_sales), 2)  AS avg_order_value,
       ROUND(AVG(profit), 2)     AS avg_profit,
       ROUND(100.0 * SUM(profit) / NULLIF(SUM(net_sales),0), 2) AS margin_pct
FROM  vw_sales_orders
WHERE is_cancelled = 0
GROUP BY CASE WHEN coupon_code IS NULL OR coupon_code = '' THEN 'No coupon' ELSE 'Coupon used' END;

---------------------------------------------------------------------------
-- 6F. CUSTOMER EXPERIENCE
---------------------------------------------------------------------------

-- F1. Ratings and sentiment
SELECT customer_rating, COUNT(*) AS orders
FROM  vw_sales_orders
WHERE customer_rating IS NOT NULL
GROUP BY customer_rating
ORDER BY customer_rating;

SELECT review_sentiment, COUNT(*) AS orders,
       ROUND(AVG(customer_rating), 2) AS avg_rating
FROM  vw_sales_orders
GROUP BY review_sentiment
ORDER BY orders DESC;

-- F2. Worst-rated product categories
SELECT TOP 10 p.product_category,
       ROUND(AVG(o.customer_rating), 2) AS avg_customer_rating,
       COUNT(DISTINCT o.order_id)       AS orders
FROM  order_items i
JOIN  vw_sales_orders o ON o.order_id = i.order_id
JOIN  product_catalog p ON p.product_id = i.product_id
WHERE o.customer_rating IS NOT NULL
GROUP BY p.product_category
ORDER BY avg_customer_rating ASC;
GO

/*==============================================================================
  NEXT STEPS
  - Connect Power BI to e_commerce and import vw_sales_orders and
    vw_order_items_detail (plus customer_master and product_catalog for slicers).
  - Turn queries A2, B1, C5, D1 and E2 into the main dashboard pages.
  - Save your findings as a short written summary for your portfolio / GitHub.
==============================================================================*/