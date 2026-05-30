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

SELECT
    COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_clean,
    COUNT(*) AS purchase_events,
    ROUND(SUM(price), 2) AS total_revenue
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY category_clean
ORDER BY total_revenue DESC
LIMIT 20;
