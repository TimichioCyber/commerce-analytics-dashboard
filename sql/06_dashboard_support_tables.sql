-- BI-ready support tables for the Power BI dashboard.
-- Run this script after sql/04_user_segmentation.sql.

-- =====================================================
-- 01. Sequential user-level funnel
-- =====================================================

DROP TABLE IF EXISTS funnel_user_summary;

CREATE TABLE funnel_user_summary AS
WITH first_view AS (
    SELECT
        user_id,
        MIN(event_time) AS first_view_time
    FROM ecommerce_events
    WHERE event_type = 'view'
    GROUP BY user_id
),
first_cart_after_view AS (
    SELECT
        e.user_id,
        MIN(e.event_time) AS first_cart_time
    FROM ecommerce_events e
    JOIN first_view fv
        ON e.user_id = fv.user_id
    WHERE e.event_type = 'cart'
      AND e.event_time >= fv.first_view_time
    GROUP BY e.user_id
),
first_purchase_after_view AS (
    SELECT
        e.user_id,
        MIN(e.event_time) AS first_purchase_time
    FROM ecommerce_events e
    JOIN first_view fv
        ON e.user_id = fv.user_id
    WHERE e.event_type = 'purchase'
      AND e.event_time >= fv.first_view_time
    GROUP BY e.user_id
),
first_purchase_after_cart AS (
    SELECT
        e.user_id,
        MIN(e.event_time) AS first_purchase_after_cart_time
    FROM ecommerce_events e
    JOIN first_cart_after_view fc
        ON e.user_id = fc.user_id
    WHERE e.event_type = 'purchase'
      AND e.event_time >= fc.first_cart_time
    GROUP BY e.user_id
),
purchase_cart_flags AS (
    SELECT
        user_id,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM ecommerce_events
    GROUP BY user_id
),
purchase_cart_summary AS (
    SELECT
        SUM(CASE WHEN has_purchase = 1 AND has_cart = 1 THEN 1 ELSE 0 END) AS all_purchase_users_with_recorded_cart,
        SUM(CASE WHEN has_purchase = 1 AND has_cart = 0 THEN 1 ELSE 0 END) AS all_purchase_users_without_recorded_cart,
        ROUND(
            SUM(CASE WHEN has_purchase = 1 AND has_cart = 0 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END), 0),
            2
        ) AS all_purchase_users_without_cart_share
    FROM purchase_cart_flags
)
SELECT
    COUNT(fv.user_id) AS viewed_users,
    COUNT(fc.user_id) AS cart_after_view_users,
    COUNT(fpv.user_id) AS purchase_after_view_users,
    COUNT(fpc.user_id) AS strict_view_cart_purchase_users,
    COUNT(fpv.user_id) - COUNT(fpc.user_id) AS purchase_after_view_not_in_strict_funnel_users,
    (SELECT all_purchase_users_with_recorded_cart FROM purchase_cart_summary) AS all_purchase_users_with_recorded_cart,
    (SELECT all_purchase_users_without_recorded_cart FROM purchase_cart_summary) AS all_purchase_users_without_recorded_cart,
    (SELECT all_purchase_users_without_cart_share FROM purchase_cart_summary) AS all_purchase_users_without_cart_share,
    ROUND(COUNT(fc.user_id) * 100.0 / NULLIF(COUNT(fv.user_id), 0), 2) AS sequential_view_to_cart,
    ROUND(COUNT(fpc.user_id) * 100.0 / NULLIF(COUNT(fc.user_id), 0), 2) AS sequential_cart_to_purchase,
    ROUND(COUNT(fpv.user_id) * 100.0 / NULLIF(COUNT(fv.user_id), 0), 2) AS sequential_view_to_purchase,
    ROUND(COUNT(fpc.user_id) * 100.0 / NULLIF(COUNT(fv.user_id), 0), 2) AS strict_full_funnel_conversion
FROM first_view fv
LEFT JOIN first_cart_after_view fc
    ON fv.user_id = fc.user_id
LEFT JOIN first_purchase_after_view fpv
    ON fv.user_id = fpv.user_id
LEFT JOIN first_purchase_after_cart fpc
    ON fv.user_id = fpc.user_id;

DROP TABLE IF EXISTS funnel_user_stages;

CREATE TABLE funnel_user_stages AS
SELECT
    'View' AS stage,
    1 AS stage_order,
    viewed_users AS users_count,
    100.00 AS conversion_from_view_percent
FROM funnel_user_summary
UNION ALL
SELECT
    'Cart' AS stage,
    2 AS stage_order,
    cart_after_view_users AS users_count,
    sequential_view_to_cart AS conversion_from_view_percent
FROM funnel_user_summary
UNION ALL
SELECT
    'Purchase' AS stage,
    3 AS stage_order,
    strict_view_cart_purchase_users AS users_count,
    strict_full_funnel_conversion AS conversion_from_view_percent
FROM funnel_user_summary;

-- =====================================================
-- 02. Category revenue summary
-- =====================================================

DROP TABLE IF EXISTS category_revenue_summary;

CREATE TABLE category_revenue_summary AS
WITH category_revenue AS (
    SELECT
        COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_clean,
        COUNT(*) AS purchase_events,
        ROUND(SUM(price), 2) AS total_revenue,
        ROUND(AVG(price), 2) AS avg_purchase_value
    FROM ecommerce_events
    WHERE event_type = 'purchase'
    GROUP BY COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown')
),
ranked AS (
    SELECT
        category_clean,
        purchase_events,
        total_revenue,
        avg_purchase_value,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        SUM(total_revenue) OVER () AS all_category_revenue
    FROM category_revenue
)
SELECT
    category_clean AS category_group,
    revenue_rank AS category_sort_order,
    purchase_events,
    total_revenue,
    avg_purchase_value,
    ROUND(total_revenue * 100.0 / NULLIF(all_category_revenue, 0), 2) AS revenue_share_percent
FROM ranked
WHERE revenue_rank <= 10
ORDER BY category_sort_order;

-- =====================================================
-- 03. User segment revenue summary
-- =====================================================

DROP TABLE IF EXISTS user_segment_summary;

CREATE TABLE user_segment_summary AS
SELECT
    segment,
    CASE
        WHEN segment = '1 Purchase' THEN 1
        WHEN segment = '2-5 Purchases' THEN 2
        WHEN segment = '6-10 Purchases' THEN 3
        ELSE 4
    END AS segment_sort_order,
    COUNT(*) AS users_count,
    SUM(purchase_count) AS purchase_events,
    ROUND(SUM(total_spent), 2) AS segment_revenue,
    ROUND(AVG(total_spent), 2) AS avg_total_spent,
    ROUND(SUM(total_spent) * 100.0 / SUM(SUM(total_spent)) OVER (), 2) AS revenue_share_percent
FROM user_purchase_segments
GROUP BY segment
ORDER BY segment_sort_order;
