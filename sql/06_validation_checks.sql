-- Validation checks for reconciling PostgreSQL results with Power BI.
-- The October 2019 dataset is large, so the script is split into:
-- 1) core checks that should be run first;
-- 2) optional heavy checks for deeper QA.

-- =====================================================
-- CORE CHECKS
-- =====================================================

-- 00. Create a smaller temporary purchase-only table.
-- This scans the raw table once, then makes revenue/category checks much faster.
DROP TABLE IF EXISTS qa_purchase_events;

CREATE TEMP TABLE qa_purchase_events AS
SELECT
    event_time,
    DATE(event_time) AS event_date,
    user_id,
    product_id,
    price,
    COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_clean,
    CASE
        WHEN category_code IS NULL THEN 'NULL'
        WHEN TRIM(category_code) = '' THEN 'blank'
        ELSE 'filled'
    END AS category_status
FROM ecommerce_events
WHERE event_type = 'purchase';

-- 01. Purchase revenue reconciliation.
SELECT
    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_id) AS purchase_users,
    ROUND(SUM(price), 2) AS total_purchase_revenue,
    ROUND(AVG(price), 2) AS avg_purchase_value
FROM qa_purchase_events;

-- 02. Missing category revenue impact.
SELECT
    category_status,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS purchase_revenue,
    ROUND(SUM(price) * 100.0 / SUM(SUM(price)) OVER (), 2) AS revenue_share_percent
FROM qa_purchase_events
GROUP BY category_status
ORDER BY purchase_revenue DESC;

-- 03. Top categories after standardizing missing values as Unknown.
SELECT
    category_clean,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(AVG(price), 2) AS avg_purchase_value
FROM qa_purchase_events
GROUP BY category_clean
ORDER BY total_revenue DESC
LIMIT 20;

-- 04. Daily revenue reconciliation for the Power BI revenue trend.
SELECT
    event_date,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS revenue
FROM qa_purchase_events
GROUP BY event_date
ORDER BY event_date;

-- 05. Weekday revenue reconciliation for the Power BI weekday chart.
SELECT
    EXTRACT(DOW FROM event_time) AS weekday_number,
    TRIM(TO_CHAR(event_time, 'Day')) AS weekday_name,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS revenue
FROM qa_purchase_events
GROUP BY
    weekday_number,
    weekday_name
ORDER BY weekday_number;

-- 06. Price quality checks on purchase events.
SELECT
    COUNT(*) AS purchase_events,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price_events,
    COUNT(*) FILTER (WHERE price < 0) AS negative_price_events,
    COUNT(*) FILTER (WHERE price = 0) AS zero_price_events,
    ROUND(MIN(price), 2) AS min_price,
    ROUND(MAX(price), 2) AS max_price,
    ROUND(AVG(price), 2) AS avg_price
FROM qa_purchase_events;

-- 07. BI-ready user segment reconciliation.
-- Run sql/04_user_segmentation.sql first so user_purchase_segments exists.
SELECT
    segment,
    COUNT(*) AS users_count,
    SUM(purchase_count) AS purchase_events,
    ROUND(SUM(total_spent), 2) AS segment_revenue,
    ROUND(AVG(total_spent), 2) AS avg_total_spent
FROM user_purchase_segments
GROUP BY segment
ORDER BY segment_revenue DESC;

-- 08. BI-ready retention table check.
-- Run sql/03_retention_analysis.sql first so retention_cohorts exists.
SELECT
    COUNT(*) AS rows_count,
    MIN(cohort_date) AS min_cohort_date,
    MAX(cohort_date) AS max_cohort_date,
    MIN(day_number) AS min_day_number,
    MAX(day_number) AS max_day_number
FROM retention_cohorts;

-- =====================================================
-- OPTIONAL HEAVY CHECKS
-- =====================================================

-- 09. Full dataset coverage. This can be slow because of exact distinct counts.
SELECT
    COUNT(*) AS total_events,
    MIN(event_time) AS min_event_time,
    MAX(event_time) AS max_event_time,
    COUNT(DISTINCT DATE(event_time)) AS active_days,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT user_session) AS unique_sessions,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown')) AS unique_categories_clean
FROM ecommerce_events;

-- 10. Event type distribution. Useful for validating that the October file loaded correctly.
SELECT
    event_type,
    COUNT(*) AS events_count,
    COUNT(DISTINCT user_id) AS unique_users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS event_share_percent
FROM ecommerce_events
GROUP BY event_type
ORDER BY events_count DESC;

-- 11. User-level funnel reconciliation. This is heavy because it groups all users.
WITH user_flags AS (
    SELECT
        user_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS has_view,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT
    COUNT(*) AS total_users,
    SUM(has_view) AS viewed_users,
    SUM(has_cart) AS cart_users,
    SUM(has_purchase) AS purchase_users,
    SUM(CASE WHEN has_purchase = 1 AND has_cart = 0 THEN 1 ELSE 0 END) AS purchase_without_cart_users,
    ROUND(SUM(has_cart) * 100.0 / NULLIF(SUM(has_view), 0), 2) AS view_to_cart_conversion,
    ROUND(SUM(has_purchase) * 100.0 / NULLIF(SUM(has_cart), 0), 2) AS cart_to_purchase_conversion,
    ROUND(SUM(has_purchase) * 100.0 / NULLIF(SUM(has_view), 0), 2) AS view_to_purchase_conversion
FROM user_flags;
