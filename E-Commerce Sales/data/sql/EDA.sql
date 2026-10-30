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
