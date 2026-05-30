DROP TABLE IF EXISTS segment_purchase_events;

CREATE TABLE segment_purchase_events AS
WITH user_segments AS (
    SELECT
        user_id,
        COUNT(*) AS purchase_count,
        ROUND(SUM(price), 2) AS total_spent,
        CASE
            WHEN COUNT(*) = 1 THEN '1 Purchase'
            WHEN COUNT(*) BETWEEN 2 AND 5 THEN '2-5 Purchases'
            WHEN COUNT(*) BETWEEN 6 AND 10 THEN '6-10 Purchases'
            ELSE '10+ Purchases'
        END AS segment
    FROM ecommerce_events
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
purchase_events AS (
    SELECT
        user_id,
        DATE(event_time) AS event_date,
        price,
        COALESCE(NULLIF(TRIM(brand), ''), 'Unknown') AS brand_clean,
        COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_code_clean
    FROM ecommerce_events
    WHERE event_type = 'purchase'
),
category_parts AS (
    SELECT
        user_id,
        event_date,
        price,
        brand_clean,
        category_code_clean,
        STRING_TO_ARRAY(category_code_clean, '.') AS category_array
    FROM purchase_events
)
SELECT
    p.user_id,
    p.event_date,
    p.price,
    p.brand_clean,
    p.category_code_clean,
    CASE
        WHEN p.category_code_clean = 'Unknown' THEN 'Unknown'
        ELSE INITCAP(REPLACE(p.category_array[1], '_', ' '))
    END AS category,
    CASE
        WHEN p.category_code_clean = 'Unknown' THEN 'Unknown'
        WHEN ARRAY_LENGTH(p.category_array, 1) >= 2
            THEN INITCAP(REPLACE(p.category_array[2], '_', ' '))
        ELSE 'Other'
    END AS subcategory,
    CASE
        WHEN p.category_code_clean = 'Unknown' THEN 'Unknown'
        WHEN ARRAY_LENGTH(p.category_array, 1) >= 3
            THEN INITCAP(REPLACE(
                ARRAY_TO_STRING(
                    p.category_array[3:ARRAY_LENGTH(p.category_array, 1)],
                    ' '
                ),
                '_',
                ' '
            ))
        ELSE 'All'
    END AS product_type,
    us.segment,
    us.purchase_count,
    us.total_spent
FROM category_parts p
JOIN user_segments us
    ON p.user_id = us.user_id;

CREATE INDEX IF NOT EXISTS idx_segment_purchase_events_filters
ON segment_purchase_events (
    event_date,
    category,
    subcategory,
    product_type,
    brand_clean,
    segment
);

CREATE INDEX IF NOT EXISTS idx_segment_purchase_events_user
ON segment_purchase_events (user_id);

CREATE INDEX IF NOT EXISTS idx_segment_purchase_events_segment
ON segment_purchase_events (segment);
