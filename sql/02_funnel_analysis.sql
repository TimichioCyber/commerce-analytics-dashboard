-- Funnel analysis from product view to cart to purchase.

-- User-level purchase funnel.
WITH funnel AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS viewed_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS cart_users,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users
    FROM ecommerce_events
)
SELECT
    viewed_users,
    cart_users,
    purchase_users,
    ROUND(cart_users * 100.0 / NULLIF(viewed_users, 0), 2) AS view_to_cart_conversion,
    ROUND(purchase_users * 100.0 / NULLIF(cart_users, 0), 2) AS cart_to_purchase_conversion,
    ROUND(purchase_users * 100.0 / NULLIF(viewed_users, 0), 2) AS view_to_purchase_conversion
FROM funnel;

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
    ROUND(SUM(has_cart) * 100.0 / NULLIF(SUM(has_view), 0), 2) AS view_to_cart_conversion,
    ROUND(SUM(has_purchase) * 100.0 / NULLIF(SUM(has_cart), 0), 2) AS cart_to_purchase_conversion,
    ROUND(SUM(has_purchase) * 100.0 / NULLIF(SUM(has_view), 0), 2) AS view_to_purchase_conversion
FROM session_flags;
