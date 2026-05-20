-- =========================================================
-- 文件名：06_rfm_user_segmentation.sql
-- 项目名称：Olist 巴西电商平台数据分析
-- 分析主题：RFM 用户分层分析
--
-- 分析目的：
-- 1. 基于 Recency（近度）、Frequency（频次）、Monetary（金额）构建用户分层
-- 2. 识别高价值用户、潜力用户、沉睡老客、流失用户
-- 3. 统计各分层用户数量及占比
--
-- RFM 评分规则：
-- R 分：距2018-09-01天数 ≤180天=3分，≤360天=2分，其他=1分
-- F 分：购买次数 ≥3=3分，=2=2分，=1=1分
-- M 分：消费金额 ≥500=3分，≥200=2分，其他=1分
--
-- 数据口径：基准日期为 2018-09-01（数据集最后有效日期）
-- 数据依赖：orders、customers、order_items
-- =========================================================

USE olist;

-- 6.1 RFM 用户明细（含分层标签）
WITH user_rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF('2018-09-01', MAX(o.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT o.order_id)                              AS frequency,
        ROUND(SUM(oi.price + oi.freight_value), 2)             AS monetary
    FROM orders o
    JOIN customers c    ON o.customer_id  = c.customer_id
    JOIN order_items oi ON o.order_id     = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        CASE
            WHEN recency <= 180 THEN 3
            WHEN recency <= 360 THEN 2
            ELSE 1
        END AS r_score,
        CASE
            WHEN frequency >= 3 THEN 3
            WHEN frequency = 2  THEN 2
            ELSE 1
        END AS f_score,
        CASE
            WHEN monetary >= 500 THEN 3
            WHEN monetary >= 200 THEN 2
            ELSE 1
        END AS m_score
    FROM user_rfm
)
SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score = 3 AND f_score >= 2 AND m_score >= 2 THEN '高价值用户'
        WHEN r_score = 3 AND f_score = 1  AND m_score >= 2 THEN '新客高消费'
        WHEN r_score >= 2 AND f_score >= 2 AND m_score >= 2 THEN '潜力用户'
        WHEN r_score = 1 AND f_score >= 2                   THEN '沉睡老客'
        WHEN r_score = 1 AND f_score = 1                    THEN '流失用户'
        ELSE '普通用户'
    END AS user_segment
FROM rfm_scored
ORDER BY monetary DESC;

-- 6.2 各用户分层规模与占比
WITH user_rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF('2018-09-01', MAX(o.order_purchase_timestamp)) AS recency,
        COUNT(DISTINCT o.order_id)                              AS frequency,
        ROUND(SUM(oi.price + oi.freight_value), 2)             AS monetary
    FROM orders o
    JOIN customers c    ON o.customer_id  = c.customer_id
    JOIN order_items oi ON o.order_id     = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT
        customer_unique_id,
        CASE WHEN recency <= 180 THEN 3 WHEN recency <= 360 THEN 2 ELSE 1 END AS r_score,
        CASE WHEN frequency >= 3 THEN 3 WHEN frequency = 2  THEN 2 ELSE 1 END AS f_score,
        CASE WHEN monetary >= 500 THEN 3 WHEN monetary >= 200 THEN 2 ELSE 1 END AS m_score
    FROM user_rfm
),
segmented AS (
    SELECT
        CASE
            WHEN r_score = 3 AND f_score >= 2 AND m_score >= 2 THEN '高价值用户'
            WHEN r_score = 3 AND f_score = 1  AND m_score >= 2 THEN '新客高消费'
            WHEN r_score >= 2 AND f_score >= 2 AND m_score >= 2 THEN '潜力用户'
            WHEN r_score = 1 AND f_score >= 2                   THEN '沉睡老客'
            WHEN r_score = 1 AND f_score = 1                    THEN '流失用户'
            ELSE '普通用户'
        END AS user_segment
    FROM rfm_scored
)
SELECT
    user_segment,
    COUNT(*)                                                AS user_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2)        AS pct
FROM segmented
GROUP BY user_segment
ORDER BY user_count DESC;
