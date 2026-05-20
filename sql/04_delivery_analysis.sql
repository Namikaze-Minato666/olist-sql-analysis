-- =========================================================
-- 文件名：04_delivery_analysis.sql
-- 项目名称：Olist 巴西电商平台数据分析
-- 分析主题：配送时长与超时分析
--
-- 分析目的：
-- 1. 分析整体配送时长和超时率
-- 2. 按州分析配送时长和超时率差异
-- 3. 分析超时对用户评分的影响
-- 4. 分析超时天数与评分的关系
--
-- 数据依赖：orders、customers、order_reviews
-- 超时判断口径：采用日期级口径，DATEDIFF(实际送达日期, 预计送达日期) > 0 视为超时，
-- DATEDIFF(...) <= 0 视为准时，避免同一天不同时间点引入口径漂移。
-- 涉及评分的 4.3、4.4 先将 order_reviews 聚合到订单级，仅统计能关联到评价的已送达订单，
-- 因此订单数可能小于 4.1；评分分布按订单级平均评分四舍五入后统计。
-- =========================================================

USE olist;

-- 4.1 整体配送时长概览
SELECT
    ROUND(AVG(DATEDIFF(order_delivered_customer_date,
                       order_purchase_timestamp)), 1)       AS avg_delivery_days,
    ROUND(AVG(DATEDIFF(order_estimated_delivery_date,
                       order_purchase_timestamp)), 1)       AS avg_estimated_days,
    ROUND(AVG(DATEDIFF(order_estimated_delivery_date,
                       order_delivered_customer_date)), 1)  AS avg_days_ahead,
    COUNT(*)                                                AS total_orders,
    SUM(CASE WHEN DATEDIFF(order_delivered_customer_date,
                           order_estimated_delivery_date) > 0
             THEN 1 ELSE 0 END)                             AS late_orders,
    ROUND(
        SUM(CASE WHEN DATEDIFF(order_delivered_customer_date,
                               order_estimated_delivery_date) > 0
                 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    )                                                       AS late_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- 4.2 各州配送时长与超时率
SELECT
    c.customer_state                                                        AS state,
    COUNT(*)                                                                AS total_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp)), 1)                    AS avg_delivery_days,
    ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date,
                       o.order_delivered_customer_date)), 1)               AS avg_days_ahead,
    SUM(CASE WHEN DATEDIFF(o.order_delivered_customer_date,
                           o.order_estimated_delivery_date) > 0
             THEN 1 ELSE 0 END)                                            AS late_orders,
    ROUND(
        SUM(CASE WHEN DATEDIFF(o.order_delivered_customer_date,
                               o.order_estimated_delivery_date) > 0
                 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    )                                                                       AS late_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_rate_pct DESC;

-- 4.3 超时与准时订单的评分对比
WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    CASE
        WHEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_estimated_delivery_date) > 0
        THEN '超时'
        ELSE '准时'
    END                                                     AS delivery_status,
    COUNT(*)                                                AS order_count,
    ROUND(AVG(r.review_score), 2)                           AS avg_score,
    SUM(CASE WHEN ROUND(r.review_score) = 1 THEN 1 ELSE 0 END) AS score_1,
    SUM(CASE WHEN ROUND(r.review_score) = 2 THEN 1 ELSE 0 END) AS score_2,
    SUM(CASE WHEN ROUND(r.review_score) = 3 THEN 1 ELSE 0 END) AS score_3,
    SUM(CASE WHEN ROUND(r.review_score) = 4 THEN 1 ELSE 0 END) AS score_4,
    SUM(CASE WHEN ROUND(r.review_score) = 5 THEN 1 ELSE 0 END) AS score_5
FROM orders o
JOIN review_by_order r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

-- 4.4 超时天数分级与评分关系
WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    CASE
        WHEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_estimated_delivery_date) <= 0  THEN '准时'
        WHEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_estimated_delivery_date) <= 3  THEN '超时1-3天'
        WHEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_estimated_delivery_date) <= 7  THEN '超时4-7天'
        WHEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_estimated_delivery_date) <= 14 THEN '超时8-14天'
        ELSE '超时14天以上'
    END                                                     AS delay_level,
    COUNT(*)                                                AS order_count,
    ROUND(AVG(r.review_score), 2)                           AS avg_score,
    ROUND(
        SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    )                                                       AS low_score_pct
FROM orders o
JOIN review_by_order r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delay_level
ORDER BY avg_score DESC;

-- 4.5 各州配送时长与超时率（用于可视化导出）
SELECT
    c.customer_state                                                        AS state,
    COUNT(*)                                                                AS total_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp)), 1)                    AS avg_delivery_days,
    ROUND(
        SUM(CASE WHEN DATEDIFF(o.order_delivered_customer_date,
                               o.order_estimated_delivery_date) > 0
                 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    )                                                                       AS late_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_rate_pct DESC;
