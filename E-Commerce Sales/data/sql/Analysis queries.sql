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