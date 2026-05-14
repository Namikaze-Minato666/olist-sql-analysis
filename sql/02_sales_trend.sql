-- =========================================================
-- 文件名：02_sales_trend.sql
-- 项目名称：Olist 巴西电商平台数据分析
-- 分析主题：销售趋势分析
--
-- 分析目的：
-- 1. 按月统计订单量、GMV、AOV
-- 2. 计算订单量和GMV的环比增长率
--
-- 数据口径：
-- 仅统计2017-01至2018-08，去除canceled和unavailable订单。
-- 数据集2016年数据不完整，2018年9月后数据量异常，均排除。
--
-- 数据依赖：orders、order_items
-- =========================================================

USE olist;

-- 2.1 月度销售趋势（含环比增长率）
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')            AS month,
        COUNT(DISTINCT o.order_id)                                  AS order_count,
        ROUND(SUM(oi.price + oi.freight_value), 2)                  AS gmv,
        ROUND(SUM(oi.price + oi.freight_value)
              / COUNT(DISTINCT o.order_id), 2)                      AS aov
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
      AND o.order_purchase_timestamp IS NOT NULL
    GROUP BY month
)
SELECT
    month,
    order_count,
    gmv,
    aov,
    LAG(order_count) OVER (ORDER BY month)                          AS last_month_orders,
    ROUND(
        (order_count - LAG(order_count) OVER (ORDER BY month))
        / LAG(order_count) OVER (ORDER BY month) * 100, 2
    )                                                               AS order_growth_pct,
    LAG(gmv) OVER (ORDER BY month)                                  AS last_month_gmv,
    ROUND(
        (gmv - LAG(gmv) OVER (ORDER BY month))
        / LAG(gmv) OVER (ORDER BY month) * 100, 2
    )                                                               AS gmv_growth_pct
FROM monthly
ORDER BY month;

-- 2.2 月度趋势简版（用于可视化导出）
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')                AS month,
    COUNT(DISTINCT o.order_id)                                      AS order_count,
    ROUND(SUM(oi.price + oi.freight_value), 2)                      AS gmv,
    ROUND(SUM(oi.price + oi.freight_value)
          / COUNT(DISTINCT o.order_id), 2)                          AS aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY month
ORDER BY month;
