-- Revenue concentration and user purchase segmentation.

-- Purchase segments by number of purchases.
WITH user_purchases AS (
    SELECT
        user_id,
        COUNT(*) AS purchase_count,
        ROUND(SUM(price), 2) AS total_spent
    FROM ecommerce_events
    WHERE event_type = 'purchase'
    GROUP BY user_id
)
SELECT
    CASE
        WHEN purchase_count = 1 THEN '1 purchase'
        WHEN purchase_count BETWEEN 2 AND 5 THEN '2-5 purchases'
        WHEN purchase_count BETWEEN 6 AND 10 THEN '6-10 purchases'
        ELSE '10+ purchases'
    END AS user_segment,
    COUNT(*) AS users_count,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(SUM(total_spent), 2) AS segment_revenue
FROM user_purchases
GROUP BY user_segment
ORDER BY segment_revenue DESC;

-- Top spending users.
SELECT
    user_id,
    COUNT(*) AS purchase_count,
    ROUND(SUM(price), 2) AS total_spent,
    ROUND(AVG(price), 2) AS avg_purchase_value,
    MAX(DATE(event_time)) AS last_purchase_date
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY user_id
ORDER BY total_spent DESC
LIMIT 20;

-- Revenue by product category.
SELECT
    COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_code,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS total_revenue,
    ROUND(AVG(price), 2) AS avg_purchase_value
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown')
ORDER BY total_revenue DESC
LIMIT 20;

-- BI-ready table for Power BI user segmentation visuals.
DROP TABLE IF EXISTS user_purchase_segments;

CREATE TABLE user_purchase_segments AS
WITH user_purchases AS (
    SELECT
        user_id,
        COUNT(*) AS purchase_count,
        ROUND(SUM(price), 2) AS total_spent
    FROM ecommerce_events
    WHERE event_type = 'purchase'
    GROUP BY user_id
)
SELECT
    user_id,
    purchase_count,
    total_spent,
    CASE
        WHEN purchase_count = 1 THEN '1 Purchase'
        WHEN purchase_count BETWEEN 2 AND 5 THEN '2-5 Purchases'
        WHEN purchase_count BETWEEN 6 AND 10 THEN '6-10 Purchases'
        ELSE '10+ Purchases'
    END AS segment
FROM user_purchases;
