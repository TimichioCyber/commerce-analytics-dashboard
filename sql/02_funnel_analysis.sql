-- Funnel analysis from product view to cart to purchase.

-- User-level purchase funnel.
-- Cart -> Purchase is calculated from users who had both cart and purchase events.
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
    SUM(has_view) AS viewed_users,
    SUM(has_cart) AS cart_users,
    SUM(has_purchase) AS purchase_users,
    SUM(CASE WHEN has_cart = 1 AND has_purchase = 1 THEN 1 ELSE 0 END) AS cart_and_purchase_users,
    SUM(CASE WHEN has_purchase = 1 AND has_cart = 0 THEN 1 ELSE 0 END) AS purchase_without_cart_users,
    ROUND(SUM(has_cart) * 100.0 / NULLIF(SUM(has_view), 0), 2) AS view_to_cart_conversion,
    ROUND(
        SUM(CASE WHEN has_cart = 1 AND has_purchase = 1 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(has_cart), 0),
        2
    ) AS cart_to_purchase_conversion,
    ROUND(SUM(has_purchase) * 100.0 / NULLIF(SUM(has_view), 0), 2) AS view_to_purchase_conversion
FROM user_flags;

-- Users who purchased without having a recorded cart event.
WITH user_events AS (
    SELECT
        user_id,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT
    COUNT(*) AS purchase_without_cart_users
FROM user_events
WHERE has_purchase = 1
  AND has_cart = 0;

-- Session-level funnel flags.
WITH session_flags AS (
    SELECT
        user_session,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS has_view,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM ecommerce_events
    GROUP BY user_session
)
SELECT
    COUNT(*) AS total_sessions,
    SUM(has_view) AS sessions_with_view,
    SUM(has_cart) AS sessions_with_cart,
    SUM(has_purchase) AS sessions_with_purchase,
    SUM(CASE WHEN has_cart = 1 AND has_purchase = 1 THEN 1 ELSE 0 END) AS sessions_with_cart_and_purchase,
    SUM(CASE WHEN has_purchase = 1 AND has_cart = 0 THEN 1 ELSE 0 END) AS sessions_with_purchase_without_cart,
    ROUND(SUM(has_cart) * 100.0 / NULLIF(SUM(has_view), 0), 2) AS view_to_cart_conversion,
    ROUND(
        SUM(CASE WHEN has_cart = 1 AND has_purchase = 1 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(has_cart), 0),
        2
    ) AS cart_to_purchase_conversion,
    ROUND(SUM(has_purchase) * 100.0 / NULLIF(SUM(has_view), 0), 2) AS view_to_purchase_conversion
FROM session_flags;
