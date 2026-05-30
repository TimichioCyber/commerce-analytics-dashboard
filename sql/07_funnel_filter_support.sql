DROP TABLE IF EXISTS funnel_filter_user_paths;
DROP TABLE IF EXISTS funnel_first_purchase_after_cart;
DROP TABLE IF EXISTS funnel_first_purchase_after_view;
DROP TABLE IF EXISTS funnel_first_cart_after_view;
DROP TABLE IF EXISTS funnel_first_view;
DROP TABLE IF EXISTS ecommerce_events_clean_funnel;

CREATE TABLE ecommerce_events_clean_funnel AS
SELECT
    user_id,
    event_time,
    DATE(event_time) AS event_date,
    event_type,
    COALESCE(NULLIF(TRIM(brand), ''), 'Unknown') AS brand_clean,
    COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_code_clean,
    CASE
        WHEN COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') = 'Unknown' THEN 'Unknown'
        ELSE INITCAP(REPLACE(SPLIT_PART(TRIM(category_code), '.', 1), '_', ' '))
    END AS category,
    CASE
        WHEN COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') = 'Unknown' THEN 'Unknown'
        WHEN SPLIT_PART(TRIM(category_code), '.', 2) <> ''
            THEN INITCAP(REPLACE(SPLIT_PART(TRIM(category_code), '.', 2), '_', ' '))
        ELSE 'Other'
    END AS subcategory,
    CASE
        WHEN COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') = 'Unknown' THEN 'Unknown'
        WHEN ARRAY_LENGTH(STRING_TO_ARRAY(TRIM(category_code), '.'), 1) >= 3
            THEN INITCAP(REPLACE(
                ARRAY_TO_STRING(
                    (STRING_TO_ARRAY(TRIM(category_code), '.'))[
                        3:ARRAY_LENGTH(STRING_TO_ARRAY(TRIM(category_code), '.'), 1)
                    ],
                    ' '
                ),
                '_',
                ' '
            ))
        ELSE 'All'
    END AS product_type
FROM ecommerce_events
WHERE event_type IN ('view', 'cart', 'purchase');

CREATE INDEX idx_clean_funnel_view_lookup
ON ecommerce_events_clean_funnel (
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean,
    event_time
)
WHERE event_type = 'view';

CREATE INDEX idx_clean_funnel_cart_lookup
ON ecommerce_events_clean_funnel (
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean,
    event_time
)
WHERE event_type = 'cart';

CREATE INDEX idx_clean_funnel_purchase_lookup
ON ecommerce_events_clean_funnel (
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean,
    event_time
)
WHERE event_type = 'purchase';

ANALYZE ecommerce_events_clean_funnel;

CREATE TABLE funnel_first_view AS
SELECT
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean,
    MIN(event_time) AS first_view_time
FROM ecommerce_events_clean_funnel
WHERE event_type = 'view'
GROUP BY
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean;

CREATE INDEX idx_funnel_first_view_join
ON funnel_first_view (
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean,
    first_view_time
);

ANALYZE funnel_first_view;

CREATE TABLE funnel_first_cart_after_view AS
SELECT
    e.user_id,
    e.category,
    e.subcategory,
    e.product_type,
    e.brand_clean,
    MIN(e.event_time) AS first_cart_after_view_time
FROM ecommerce_events_clean_funnel e
JOIN funnel_first_view fv
    ON e.user_id = fv.user_id
   AND e.category = fv.category
   AND e.subcategory = fv.subcategory
   AND e.product_type = fv.product_type
   AND e.brand_clean = fv.brand_clean
WHERE e.event_type = 'cart'
  AND e.event_time >= fv.first_view_time
GROUP BY
    e.user_id,
    e.category,
    e.subcategory,
    e.product_type,
    e.brand_clean;

CREATE INDEX idx_funnel_cart_join
ON funnel_first_cart_after_view (
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean,
    first_cart_after_view_time
);

ANALYZE funnel_first_cart_after_view;

CREATE TABLE funnel_first_purchase_after_view AS
SELECT
    e.user_id,
    e.category,
    e.subcategory,
    e.product_type,
    e.brand_clean,
    MIN(e.event_time) AS first_purchase_after_view_time
FROM ecommerce_events_clean_funnel e
JOIN funnel_first_view fv
    ON e.user_id = fv.user_id
   AND e.category = fv.category
   AND e.subcategory = fv.subcategory
   AND e.product_type = fv.product_type
   AND e.brand_clean = fv.brand_clean
WHERE e.event_type = 'purchase'
  AND e.event_time >= fv.first_view_time
GROUP BY
    e.user_id,
    e.category,
    e.subcategory,
    e.product_type,
    e.brand_clean;

CREATE INDEX idx_funnel_purchase_view_join
ON funnel_first_purchase_after_view (
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean,
    first_purchase_after_view_time
);

ANALYZE funnel_first_purchase_after_view;

CREATE TABLE funnel_first_purchase_after_cart AS
SELECT
    e.user_id,
    e.category,
    e.subcategory,
    e.product_type,
    e.brand_clean,
    MIN(e.event_time) AS first_purchase_after_cart_time
FROM ecommerce_events_clean_funnel e
JOIN funnel_first_cart_after_view fc
    ON e.user_id = fc.user_id
   AND e.category = fc.category
   AND e.subcategory = fc.subcategory
   AND e.product_type = fc.product_type
   AND e.brand_clean = fc.brand_clean
WHERE e.event_type = 'purchase'
  AND e.event_time >= fc.first_cart_after_view_time
GROUP BY
    e.user_id,
    e.category,
    e.subcategory,
    e.product_type,
    e.brand_clean;

CREATE INDEX idx_funnel_purchase_cart_join
ON funnel_first_purchase_after_cart (
    user_id,
    category,
    subcategory,
    product_type,
    brand_clean,
    first_purchase_after_cart_time
);

ANALYZE funnel_first_purchase_after_cart;

CREATE TABLE funnel_filter_user_paths AS
SELECT
    fv.user_id,
    DATE(fv.first_view_time) AS first_view_date,
    fv.category,
    fv.subcategory,
    fv.product_type,
    fv.brand_clean,
    fv.first_view_time,
    fc.first_cart_after_view_time,
    fpv.first_purchase_after_view_time,
    fpc.first_purchase_after_cart_time,
    1 AS has_view,
    CASE WHEN fc.user_id IS NOT NULL THEN 1 ELSE 0 END AS has_cart_after_view,
    CASE WHEN fpv.user_id IS NOT NULL THEN 1 ELSE 0 END AS has_purchase_after_view,
    CASE WHEN fpc.user_id IS NOT NULL THEN 1 ELSE 0 END AS has_strict_purchase,
    CASE
        WHEN fpv.user_id IS NOT NULL
         AND fc.user_id IS NULL THEN 1
        ELSE 0
    END AS has_purchase_without_recorded_cart
FROM funnel_first_view fv
LEFT JOIN funnel_first_cart_after_view fc
    ON fv.user_id = fc.user_id
   AND fv.category = fc.category
   AND fv.subcategory = fc.subcategory
   AND fv.product_type = fc.product_type
   AND fv.brand_clean = fc.brand_clean
LEFT JOIN funnel_first_purchase_after_view fpv
    ON fv.user_id = fpv.user_id
   AND fv.category = fpv.category
   AND fv.subcategory = fpv.subcategory
   AND fv.product_type = fpv.product_type
   AND fv.brand_clean = fpv.brand_clean
LEFT JOIN funnel_first_purchase_after_cart fpc
    ON fv.user_id = fpc.user_id
   AND fv.category = fpc.category
   AND fv.subcategory = fpc.subcategory
   AND fv.product_type = fpc.product_type
   AND fv.brand_clean = fpc.brand_clean;

CREATE INDEX idx_funnel_paths_filters
ON funnel_filter_user_paths (
    first_view_date,
    category,
    subcategory,
    product_type,
    brand_clean
);

CREATE INDEX idx_funnel_paths_user
ON funnel_filter_user_paths (user_id);

CREATE INDEX idx_funnel_paths_flags
ON funnel_filter_user_paths (
    has_cart_after_view,
    has_purchase_after_view,
    has_strict_purchase,
    has_purchase_without_recorded_cart
);

ANALYZE funnel_filter_user_paths;

SELECT
    COUNT(DISTINCT user_id) AS viewed_users,
    COUNT(DISTINCT user_id) FILTER (WHERE has_cart_after_view = 1) AS cart_after_view_users,
    COUNT(DISTINCT user_id) FILTER (WHERE has_purchase_after_view = 1) AS purchase_after_view_users,
    COUNT(DISTINCT user_id) FILTER (WHERE has_strict_purchase = 1) AS strict_purchase_users,
    COUNT(DISTINCT user_id) FILTER (WHERE has_purchase_without_recorded_cart = 1) AS purchase_without_recorded_cart_users,
    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE has_cart_after_view = 1)::numeric
        / NULLIF(COUNT(DISTINCT user_id), 0) * 100,
        2
    ) AS view_to_cart_percent,
    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE has_strict_purchase = 1)::numeric
        / NULLIF(COUNT(DISTINCT user_id) FILTER (WHERE has_cart_after_view = 1), 0) * 100,
        2
    ) AS cart_to_purchase_percent,
    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE has_purchase_after_view = 1)::numeric
        / NULLIF(COUNT(DISTINCT user_id), 0) * 100,
        2
    ) AS view_to_purchase_percent
FROM funnel_filter_user_paths;
