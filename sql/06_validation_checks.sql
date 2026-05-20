-- Validation checks for reconciling PostgreSQL results with Power BI.
-- Run this script after loading the raw data and creating BI-ready tables.

-- 01. Dataset coverage and row-level summary.
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

-- 02. Event type distribution.
SELECT
    event_type,
    COUNT(*) AS events_count,
    COUNT(DISTINCT user_id) AS unique_users,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS event_share_percent
FROM ecommerce_events
GROUP BY event_type
ORDER BY events_count DESC;

-- 03. Revenue reconciliation by category completeness.
SELECT
    ROUND(SUM(price) FILTER (WHERE event_type = 'purchase'), 2) AS total_purchase_revenue,
    ROUND(SUM(price) FILTER (
        WHERE event_type = 'purchase'
          AND COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') = 'Unknown'
    ), 2) AS unknown_category_revenue,
    ROUND(SUM(price) FILTER (
        WHERE event_type = 'purchase'
          AND COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') <> 'Unknown'
    ), 2) AS known_category_revenue,
    COUNT(*) FILTER (WHERE event_type = 'purchase') AS purchase_events,
    COUNT(*) FILTER (
        WHERE event_type = 'purchase'
          AND COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') = 'Unknown'
    ) AS unknown_category_purchase_events,
    ROUND(
        SUM(price) FILTER (
            WHERE event_type = 'purchase'
              AND COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') = 'Unknown'
        ) * 100.0
        / NULLIF(SUM(price) FILTER (WHERE event_type = 'purchase'), 0),
        2
    ) AS unknown_revenue_share_percent
FROM ecommerce_events;

-- 04. Missing category status.
SELECT
    CASE
        WHEN category_code IS NULL THEN 'NULL'
        WHEN TRIM(category_code) = '' THEN 'blank'
        ELSE 'filled'
    END AS category_status,
    COUNT(*) AS total_events,
    COUNT(*) FILTER (WHERE event_type = 'purchase') AS purchase_events,
    ROUND(SUM(price) FILTER (WHERE event_type = 'purchase'), 2) AS purchase_revenue
FROM ecommerce_events
GROUP BY category_status
ORDER BY purchase_revenue DESC NULLS LAST;

-- 05. Top categories after standardizing missing values as Unknown.
SELECT
    COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_clean,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(AVG(price), 2) AS avg_purchase_value
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY category_clean
ORDER BY total_revenue DESC
LIMIT 20;

-- 06. Price quality checks.
SELECT
    event_type,
    COUNT(*) AS events_count,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price_events,
    COUNT(*) FILTER (WHERE price < 0) AS negative_price_events,
    COUNT(*) FILTER (WHERE price = 0) AS zero_price_events,
    ROUND(MIN(price), 2) AS min_price,
    ROUND(MAX(price), 2) AS max_price,
    ROUND(AVG(price), 2) AS avg_price
FROM ecommerce_events
GROUP BY event_type
ORDER BY events_count DESC;

-- 07. User-level funnel reconciliation.
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

-- 08. BI-ready table checks.
SELECT
    'retention_cohorts' AS table_name,
    COUNT(*) AS rows_count,
    MIN(cohort_date) AS min_date,
    MAX(cohort_date) AS max_date
FROM retention_cohorts
UNION ALL
SELECT
    'user_purchase_segments' AS table_name,
    COUNT(*) AS rows_count,
    NULL AS min_date,
    NULL AS max_date
FROM user_purchase_segments;

-- 09. User purchase segment reconciliation.
SELECT
    segment,
    COUNT(*) AS users_count,
    SUM(purchase_count) AS purchase_events,
    ROUND(SUM(total_spent), 2) AS segment_revenue,
    ROUND(AVG(total_spent), 2) AS avg_total_spent
FROM user_purchase_segments
GROUP BY segment
ORDER BY segment_revenue DESC;
