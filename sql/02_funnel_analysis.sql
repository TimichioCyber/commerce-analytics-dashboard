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
)
SELECT
    COUNT(fv.user_id) AS viewed_users,
    COUNT(fc.user_id) AS cart_after_view_users,
    COUNT(fpv.user_id) AS purchase_after_view_users,
    COUNT(fpc.user_id) AS strict_view_cart_purchase_users,
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

WITH user_flags AS (
    SELECT
        user_id,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT
    SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END) AS purchase_users,
    SUM(CASE WHEN has_purchase = 1 AND has_cart = 1 THEN 1 ELSE 0 END) AS all_purchase_users_with_recorded_cart,
    SUM(CASE WHEN has_purchase = 1 AND has_cart = 0 THEN 1 ELSE 0 END) AS all_purchase_users_without_recorded_cart,
    ROUND(
        SUM(CASE WHEN has_purchase = 1 AND has_cart = 0 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN has_purchase = 1 THEN 1 ELSE 0 END), 0),
        2
    ) AS all_purchase_users_without_cart_share
FROM user_flags;
