-- General data overview and executive-level revenue metrics.

-- Event distribution by event type.
SELECT
    event_type,
    COUNT(*) AS events_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS share_percent
FROM ecommerce_events
GROUP BY event_type
ORDER BY events_count DESC;

-- Unique users by event type.
SELECT
    event_type,
    COUNT(DISTINCT user_id) AS unique_users
FROM ecommerce_events
GROUP BY event_type
ORDER BY unique_users DESC;

-- High-level KPI summary.
SELECT
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchase_users,
    ROUND(SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END), 2) AS total_revenue,
    ROUND(
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) * 100.0
        / NULLIF(COUNT(DISTINCT user_id), 0),
        2
    ) AS purchase_user_conversion
FROM ecommerce_events;

-- Daily revenue trend.
SELECT
    DATE(event_time) AS event_date,
    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_id) AS purchase_users,
    ROUND(SUM(price), 2) AS revenue
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY event_date
ORDER BY event_date;

-- Revenue by weekday.
SELECT
    EXTRACT(DOW FROM event_time) AS weekday_number,
    TRIM(TO_CHAR(event_time, 'Day')) AS weekday_name,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS revenue
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY
    weekday_number,
    weekday_name
ORDER BY weekday_number;

-- Top revenue-driving product categories.
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
