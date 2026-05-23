-- =========================================================
-- 文件名：00_setup.sql
-- 项目名称：Olist 巴西电商平台数据分析
-- 主题：环境配置、数据库创建与数据导入
--
-- 文件目的：
-- 1. 开启本地文件导入权限
-- 2. 创建数据库和9张核心表
-- 3. 导入CSV数据
-- 4. 验证导入结果
--
-- 运行说明：
-- 本文件建议在空库或首次复现时执行。
-- 如需重复执行，请先清理旧表或重建 olist 数据库，否则 CREATE TABLE 可能因表已存在而失败。
-- 导入前请确认 CSV 文件路径与本机实际路径一致。
-- =========================================================

-- 0.1 开启本地文件导入
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

-- 0.2 创建数据库
CREATE DATABASE IF NOT EXISTS olist
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE olist;

-- =========================================================
-- 0.3 建表
-- =========================================================

CREATE TABLE customers (
    customer_id            VARCHAR(50) PRIMARY KEY,
    customer_unique_id     VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city          VARCHAR(100),
    customer_state         VARCHAR(5)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat             DOUBLE,
    geolocation_lng             DOUBLE,
    geolocation_city            VARCHAR(100),
    geolocation_state           VARCHAR(5)
);

CREATE TABLE orders (
    order_id                      VARCHAR(50) PRIMARY KEY,
    customer_id                   VARCHAR(50),
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
    order_id           VARCHAR(50),
    order_item_id      INT,
    product_id         VARCHAR(50),
    seller_id          VARCHAR(50),
    shipping_limit_date DATETIME,
    price              DECIMAL(10,2),
    freight_value      DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id              VARCHAR(50),
    payment_sequential    INT,
    payment_type          VARCHAR(30),
    payment_installments  INT,
    payment_value         DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
    review_id              VARCHAR(50),
    order_id               VARCHAR(50),
    review_score           INT,
    review_comment_title   VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date   DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id, order_id)
);

CREATE TABLE products (
    product_id                  VARCHAR(50) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_length         INT,
    product_description_length  INT,
    product_photos_qty          INT,
    product_weight_g            DOUBLE,
    product_length_cm           DOUBLE,
    product_height_cm           DOUBLE,
    product_width_cm            DOUBLE
);

CREATE TABLE sellers (
    seller_id               VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix  VARCHAR(10),
    seller_city             VARCHAR(100),
    seller_state            VARCHAR(5)
);

CREATE TABLE category_translation (
    product_category_name         VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- =========================================================
-- 0.4 导入数据
-- 注意：请将路径替换为本机 CSV 文件路径
-- 示例中的 D:/your_path/olist_csv/ 仅为路径占位，复现时请改为你的 Olist CSV 文件所在目录。
-- =========================================================

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/your_path/olist_csv/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- =========================================================
-- 0.5 数据导入验证
-- =========================================================

SELECT 'customers'           AS tbl, COUNT(*) AS cnt FROM customers
UNION ALL
SELECT 'geolocation',                 COUNT(*) FROM geolocation
UNION ALL
SELECT 'orders',                      COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',                 COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments',              COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews',               COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products',                    COUNT(*) FROM products
UNION ALL
SELECT 'sellers',                     COUNT(*) FROM sellers
UNION ALL
SELECT 'category_translation',        COUNT(*) FROM category_translation;

-- 0.6 字段格式抽查
SELECT order_id,
       order_purchase_timestamp,
       order_approved_at,
       order_delivered_carrier_date,
       order_delivered_customer_date,
       order_estimated_delivery_date
FROM orders
LIMIT 10;

SELECT product_id,
       product_category_name,
       product_weight_g
FROM products
LIMIT 10;
