WITH first_visit AS (
    SELECT
        user_id,
        MIN(DATE(event_time)) AS first_visit_date
    FROM ecommerce_events
    GROUP BY user_id
),
user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE(event_time) AS activity_date
    FROM ecommerce_events
)
SELECT
    COUNT(DISTINCT fv.user_id) AS cohort_size,
    COUNT(DISTINCT ua.user_id) AS retained_users,
    ROUND(
        COUNT(DISTINCT ua.user_id) * 100.0
        / NULLIF(COUNT(DISTINCT fv.user_id), 0),
        2
    ) AS day1_retention
FROM first_visit fv
LEFT JOIN user_activity ua
    ON fv.user_id = ua.user_id
   AND ua.activity_date = fv.first_visit_date + 1;

WITH first_visit AS (
    SELECT
        user_id,
        MIN(DATE(event_time)) AS first_visit_date
    FROM ecommerce_events
    GROUP BY user_id
),
user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE(event_time) AS activity_date
    FROM ecommerce_events
),
retention_table AS (
    SELECT
        fv.user_id,
        fv.first_visit_date,
        ua.activity_date,
        ua.activity_date - fv.first_visit_date AS day_number
    FROM first_visit fv
    JOIN user_activity ua
        ON fv.user_id = ua.user_id
)
SELECT
    first_visit_date AS cohort_date,
    day_number,
    COUNT(DISTINCT user_id) AS retained_users
FROM retention_table
GROUP BY
    cohort_date,
    day_number
ORDER BY
    cohort_date,
    day_number;

WITH first_visit AS (
    SELECT
        user_id,
        MIN(DATE(event_time)) AS first_visit_date
    FROM ecommerce_events
    GROUP BY user_id
),
user_activity AS (
    SELECT DISTINCT
        user_id,
        DATE(event_time) AS activity_date
    FROM ecommerce_events
),
retention_table AS (
    SELECT
        fv.user_id,
        fv.first_visit_date,
        ua.activity_date,
        ua.activity_date - fv.first_visit_date AS day_number
    FROM first_visit fv
    JOIN user_activity ua
        ON fv.user_id = ua.user_id
),
cohort_size AS (
    SELECT
        first_visit_date,
        COUNT(DISTINCT user_id) AS cohort_users
    FROM first_visit
    GROUP BY first_visit_date
)
SELECT
    rt.first_visit_date AS cohort_date,
    rt.day_number,
    cs.cohort_users,
    COUNT(DISTINCT rt.user_id) AS retained_users,
    ROUND(
        COUNT(DISTINCT rt.user_id) * 100.0
        / NULLIF(cs.cohort_users, 0),
        2
    ) AS retention_rate
FROM retention_table rt
JOIN cohort_size cs
    ON rt.first_visit_date = cs.first_visit_date
GROUP BY
    cohort_date,
    rt.day_number,
    cs.cohort_users
ORDER BY
    cohort_date,
    rt.day_number;

DROP TABLE IF EXISTS retention_cohorts;

CREATE TABLE retention_cohorts AS
WITH first_visit AS (
    SELECT
        user_id,
        MIN(DATE(event_time)) AS cohort_date
    FROM ecommerce_events
    GROUP BY user_id
),
user_activity AS (
    SELECT DISTINCT
        e.user_id,
        DATE(e.event_time) AS activity_date,
        f.cohort_date
    FROM ecommerce_events e
    JOIN first_visit f
        ON e.user_id = f.user_id
),
retention_data AS (
    SELECT
        cohort_date,
        activity_date,
        activity_date - cohort_date AS day_number,
        COUNT(DISTINCT user_id) AS retained_users
    FROM user_activity
    GROUP BY 1, 2, 3
)
SELECT
    cohort_date,
    activity_date,
    day_number,
    retained_users
FROM retention_data
ORDER BY cohort_date, day_number;
