-- =========================================================
-- 文件名：03_category_analysis.sql
-- 项目名称：Olist 巴西电商平台数据分析
-- 分析主题：商品品类分析
--
-- 分析目的：
-- 1. 分析各品类销售额、订单量、客单价排名
-- 2. 识别高销售低评分、高销售高评分品类
-- 3. 识别高订单低客单、低订单高客单品类
--
-- 数据依赖：orders、order_items、products、category_translation、order_reviews
-- =========================================================

USE olist;

-- 3.1 各品类销售额 Top 20
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    ROUND(SUM(oi.price + oi.freight_value), 2)                          AS gmv
FROM order_items oi
JOIN orders o       ON oi.order_id   = o.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY category
ORDER BY gmv DESC
LIMIT 20;

-- 3.2 各品类订单量 Top 20
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id)                                          AS order_count
FROM order_items oi
JOIN orders o       ON oi.order_id   = o.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY category
ORDER BY order_count DESC
LIMIT 20;

-- 3.3 各品类客单价 Top 20
-- 说明：排除订单量少于100的品类，避免小样本干扰
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id)                                          AS order_count,
    ROUND(SUM(oi.price + oi.freight_value)
          / COUNT(DISTINCT oi.order_id), 2)                             AS aov
FROM order_items oi
JOIN orders o       ON oi.order_id   = o.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY category
HAVING order_count >= 100
ORDER BY aov DESC
LIMIT 20;

-- 3.4 品类销售额与评分矩阵
-- 说明：识别高销售但低评分的问题品类
WITH category_stats AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
        COUNT(DISTINCT oi.order_id)                 AS order_count,
        ROUND(SUM(oi.price + oi.freight_value), 2)  AS gmv,
        ROUND(AVG(r.review_score), 2)               AS avg_score
    FROM order_items oi
    JOIN orders o       ON oi.order_id   = o.order_id
    JOIN products p     ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
    LEFT JOIN order_reviews r          ON oi.order_id = r.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY category
)
SELECT
    category,
    order_count,
    gmv,
    avg_score,
    CASE
        WHEN gmv > 500000 AND avg_score < 3.5  THEN '高销售低评分'
        WHEN gmv > 500000 AND avg_score >= 4.0 THEN '高销售高评分'
        ELSE '普通'
    END AS flag
FROM category_stats
WHERE avg_score IS NOT NULL
ORDER BY gmv DESC
LIMIT 30;

-- 3.5 品类订单量与客单价矩阵
-- 说明：识别高量低价、低量高价品类，辅助运营策略制定
WITH category_stats AS (
    SELECT
        COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
        COUNT(DISTINCT oi.order_id)                                          AS order_count,
        ROUND(SUM(oi.price + oi.freight_value)
              / COUNT(DISTINCT oi.order_id), 2)                             AS aov
    FROM order_items oi
    JOIN orders o       ON oi.order_id   = o.order_id
    JOIN products p     ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY category
    HAVING order_count >= 100
)
SELECT
    category,
    order_count,
    aov,
    CASE
        WHEN order_count >= 3000 AND aov < 100  THEN '高订单低客单'
        WHEN order_count < 500  AND aov >= 300  THEN '低订单高客单'
        ELSE '普通'
    END AS flag
FROM category_stats
ORDER BY order_count DESC;

-- 3.6 品类销售额与订单量概览（用于可视化导出）
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id)                                          AS order_count,
    ROUND(SUM(oi.price + oi.freight_value), 2)                          AS gmv
FROM order_items oi
JOIN orders o       ON oi.order_id   = o.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY category
ORDER BY gmv DESC
LIMIT 15;
