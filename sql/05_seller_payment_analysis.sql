-- =========================================================
-- 文件名：05_seller_payment_analysis.sql
-- 项目名称：Olist 巴西电商平台数据分析
-- 分析主题：卖家分析与支付方式分析
--
-- 分析目的：
-- 1. 找出Top20高销售额卖家
-- 2. 分析各州卖家分布
-- 3. 分析各支付方式的订单占比和平均支付金额
-- 4. 分析信用卡分期偏好
--
-- 数据依赖：order_items、orders、sellers、order_reviews、order_payments
-- =========================================================

USE olist;

-- 5.1 Top 20 卖家（按销售额）
SELECT
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                 AS order_count,
    ROUND(SUM(oi.price + oi.freight_value), 2)  AS gmv,
    ROUND(AVG(r.review_score), 2)               AS avg_score
FROM order_items oi
JOIN orders o       ON oi.order_id  = o.order_id
JOIN sellers s      ON oi.seller_id = s.seller_id
LEFT JOIN order_reviews r ON oi.order_id = r.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY oi.seller_id, s.seller_city, s.seller_state
ORDER BY gmv DESC
LIMIT 20;

-- 5.2 各州卖家数量分布
SELECT
    seller_state,
    COUNT(DISTINCT seller_id) AS seller_count
FROM sellers
GROUP BY seller_state
ORDER BY seller_count DESC;

-- 5.3 支付方式分析
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                                                AS order_count,
    ROUND(
        COUNT(DISTINCT order_id)
        / (SELECT COUNT(DISTINCT order_id) FROM order_payments) * 100, 2
    )                                                                       AS order_pct,
    ROUND(AVG(payment_value), 2)                                            AS avg_payment,
    ROUND(AVG(payment_installments), 2)                                     AS avg_installments,
    ROUND(SUM(payment_value), 2)                                            AS total_payment
FROM order_payments
GROUP BY payment_type
ORDER BY order_count DESC;

-- 5.4 信用卡分期偏好分析
SELECT
    payment_installments,
    COUNT(DISTINCT order_id)        AS order_count,
    ROUND(AVG(payment_value), 2)    AS avg_payment
FROM order_payments
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;
