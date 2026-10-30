IF DB_ID('e_commerce') IS NULL
    CREATE DATABASE e_commerce;
GO
USE e_commerce;
GO

 1.1 customer_master -------------------------------------------------------
CREATE TABLE  customer_master (
    customer_id               VARCHAR(15)    NOT NULL PRIMARY KEY,   -- e.g. CUST-000001
    customer_name             NVARCHAR(150)  NULL,
    customer_age              TINYINT        NULL,
    gender                    VARCHAR(20)    NULL,
    customer_segment          VARCHAR(50)    NULL,
    customer_city             NVARCHAR(100)  NULL,
    customer_state            NVARCHAR(100)  NULL,
    customer_country          NVARCHAR(100)  NULL,
    region                    VARCHAR(50)    NULL,
    customer_postal_code      VARCHAR(20)    NULL,                   -- text keeps leading zeros
    customer_acquisition_cost DECIMAL(10,2)  NULL
);
GO

 1.2 product_catalog -------------------------------------------------------
CREATE TABLE  product_catalog (
    product_id          VARCHAR(20)    NOT NULL PRIMARY KEY,
    product_name        NVARCHAR(200)  NULL,
    product_category    VARCHAR(100)   NULL,
    product_subcategory VARCHAR(100)   NULL,
    brand               NVARCHAR(100)  NULL,
    supplier            NVARCHAR(150)  NULL,
    unit_price          DECIMAL(12,2)  NULL,
    product_cost        DECIMAL(12,2)  NULL,
    product_rating      DECIMAL(3,1)   NULL
);
GO

 1.3 ecommerce_sales_customer (main fact table) ----------------------------
--CREATE TABLE  ecommerce_sales_customer (
    order_id                    VARCHAR(20)    NOT NULL,
    order_date                  DATE           NULL,
    order_time                  TIME(0)        NULL,
    order_status                VARCHAR(30)    NULL,
    sales_channel               VARCHAR(50)    NULL,
    customer_id                 VARCHAR(15)    NOT NULL,
    customer_name               NVARCHAR(150)  NULL,
    customer_age                TINYINT        NULL,
    gender                      VARCHAR(20)    NULL,
    customer_segment            VARCHAR(50)    NULL,
    customer_type               VARCHAR(30)    NULL,
    customer_city               NVARCHAR(100)  NULL,
    customer_state              NVARCHAR(100)  NULL,
    customer_country            NVARCHAR(100)  NULL,
    region                      VARCHAR(50)    NULL,
    customer_postal_code        VARCHAR(20)    NULL,
    payment_method              VARCHAR(50)    NULL,
    payment_status              VARCHAR(30)    NULL,
    currency                    VARCHAR(10)    NULL,
    shipping_method             VARCHAR(50)    NULL,
    warehouse                   VARCHAR(100)   NULL,
    delivery_days               SMALLINT       NULL,
    estimated_delivery_days     SMALLINT       NULL,
    delivery_status             VARCHAR(30)    NULL,
    return_status               VARCHAR(30)    NULL,
    return_reason               NVARCHAR(200)  NULL,
    customer_rating             DECIMAL(3,1)   NULL,
    review_sentiment            VARCHAR(30)    NULL,
    customer_review             NVARCHAR(1000) NULL,
    marketing_channel           VARCHAR(50)    NULL,
    campaign_name               NVARCHAR(150)  NULL,
    coupon_code                 VARCHAR(50)    NULL,
    loyalty_points_earned       INT            NULL,
    loyalty_points_redeemed     INT            NULL,
    quantity                    INT            NULL,
    gross_sales                 DECIMAL(14,2)  NULL,
    discount_amount             DECIMAL(14,2)  NULL,
    tax_amount                  DECIMAL(14,2)  NULL,
    shipping_cost               DECIMAL(14,2)  NULL,
    net_sales                   DECIMAL(14,2)  NULL,
    product_cost                DECIMAL(14,2)  NULL,
    profit                      DECIMAL(14,2)  NULL,
    profit_margin_percentage    DECIMAL(8,2)   NULL,
    customer_lifetime_value     DECIMAL(14,2)  NULL,
    is_repeat_customer          VARCHAR(10)    NULL,                 -- Yes/No, True/False or 1/0
    customer_order_count        INT            NULL
)--/
GO--

 1.4 order_items -----------------------------------------------------------
CREATE TABLE  order_items (
    order_id            VARCHAR(20)    NOT NULL,
    product_id          VARCHAR(20)    NOT NULL,
    quantity            INT            NULL,
    unit_price          DECIMAL(12,2)  NULL,
    discount_percentage DECIMAL(6,2)   NULL,
    discount_amount     DECIMAL(14,2)  NULL,
    gross_sales         DECIMAL(14,2)  NULL,
    tax_amount          DECIMAL(14,2)  NULL,
    shipping_cost       DECIMAL(14,2)  NULL,
    net_sales           DECIMAL(14,2)  NULL,
    product_cost        DECIMAL(14,2)  NULL,
    profit              DECIMAL(14,2)  NULL
);
GO

-- 1.5 dataset_statistics (summary row) ---------------------------------------
CREATE TABLE  dataset_statistics (
    Total Transactions        INT            NULL,
    total_columns       INT            NULL,
    Total Customers     INT            NULL,
    total_products_used INT            NULL,
    date_range          VARCHAR(60)    NULL,                         -- text, e.g. '2022-01-01 to 2024-12-31'
    total_revenue       DECIMAL(18,2)  NULL,
    total_profit        DECIMAL(18,2)  NULL,
    average_order_value DECIMAL(10,2)  NULL,
    average_rating      DECIMAL(4,2)   NULL,
    return_rate         DECIMAL(8,4)   NULL,                         -- check scale: 0.05 or 5.0
    cancellation_rate   DECIMAL(8,4)   NULL
);
GO
