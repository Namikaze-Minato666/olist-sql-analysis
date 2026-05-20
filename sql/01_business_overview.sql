-- =========================================================
-- 文件名：01_business_overview.sql
-- 项目名称：Olist 巴西电商平台数据分析
-- 分析主题：基础经营指标概览
--
-- 分析目的：
-- 1. 统计平台整体规模（订单数、GMV、用户数、卖家数）
-- 2. 计算核心经营指标（AOV、平均运费、平均评分、取消率）
-- 3. 分析用户复购情况
--
-- 数据依赖：orders、order_items、customers、order_reviews
-- =========================================================

USE olist;

-- 1.1 平台整体经营指标
-- 口径说明：
-- 1) total_orders 为 orders 与 order_items 内连接后的订单数，即参与 GMV 统计且有商品明细的订单数。
-- 2) total_customers 为上述订单覆盖到的 customer_unique_id 去重用户数，不等同于 customers 全表去重用户数。
-- 3) cancel_rate_pct 按订单级去重计算，避免多商品订单在 order_items 明细行中被重复计数。
-- 4) avg_review_score 先将 order_reviews 按 order_id 聚合到订单级，再计算订单级平均评分。
WITH order_scope AS (
    SELECT DISTINCT
        o.order_id
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
),
review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    COUNT(DISTINCT o.order_id)                                              AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)                             AS total_gmv,
    COUNT(DISTINCT c.customer_unique_id)                                    AS total_customers,
    COUNT(DISTINCT oi.seller_id)                                            AS total_sellers,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS aov,
    ROUND(AVG(oi.freight_value), 2)                                         AS avg_freight,
    ROUND((
        SELECT AVG(r.review_score)
        FROM order_scope os
        JOIN review_by_order r ON os.order_id = r.order_id
    ), 2)                                                                   AS avg_review_score,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.order_status = 'canceled' THEN o.order_id END)
        / COUNT(DISTINCT o.order_id) * 100, 2
    )                                                                       AS cancel_rate_pct
FROM orders o
JOIN order_items oi   ON o.order_id  = oi.order_id
JOIN customers c      ON o.customer_id = c.customer_id;

-- 1.2 用户平均下单次数
SELECT
    COUNT(DISTINCT customer_unique_id)                              AS real_customers,
    COUNT(*)                                                        AS total_orders,
    ROUND(COUNT(*) / COUNT(DISTINCT customer_unique_id), 2)        AS avg_orders_per_customer
FROM customers;

-- 1.3 用户复购分布
-- 说明：统计下单1次、2次、3次及以上的用户各有多少
SELECT
    order_count,
    COUNT(*) AS customer_count
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(*) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) t
GROUP BY order_count
ORDER BY order_count;
