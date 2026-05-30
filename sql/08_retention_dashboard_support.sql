DROP TABLE IF EXISTS retention_weekly_key_days;

CREATE TABLE retention_weekly_key_days AS
WITH params AS (
    SELECT MAX(activity_date) AS max_activity_date
    FROM retention_cohorts
),
key_days AS (
    SELECT *
    FROM (
        VALUES
            (1, 'D1', 1),
            (2, 'D2', 2),
            (3, 'D3', 3),
            (7, 'D7', 4),
            (14, 'D14', 5),
            (21, 'D21', 6),
            (30, 'D30', 7)
    ) AS d(day_number, retention_key_day, retention_key_day_sort)
),
cohort_sizes AS (
    SELECT
        cohort_date,
        CASE
            WHEN cohort_date BETWEEN DATE '2019-10-01' AND DATE '2019-10-07' THEN 'Oct 01-07'
            WHEN cohort_date BETWEEN DATE '2019-10-08' AND DATE '2019-10-14' THEN 'Oct 08-14'
            WHEN cohort_date BETWEEN DATE '2019-10-15' AND DATE '2019-10-21' THEN 'Oct 15-21'
            ELSE 'Oct 22-31'
        END AS cohort_week,
        CASE
            WHEN cohort_date BETWEEN DATE '2019-10-01' AND DATE '2019-10-07' THEN 1
            WHEN cohort_date BETWEEN DATE '2019-10-08' AND DATE '2019-10-14' THEN 2
            WHEN cohort_date BETWEEN DATE '2019-10-15' AND DATE '2019-10-21' THEN 3
            ELSE 4
        END AS cohort_week_sort,
        retained_users AS cohort_users
    FROM retention_cohorts
    WHERE day_number = 0
),
eligible_cohorts AS (
    SELECT
        cs.cohort_week,
        cs.cohort_week_sort,
        kd.retention_key_day,
        kd.retention_key_day_sort,
        kd.day_number,
        cs.cohort_date,
        cs.cohort_users
    FROM cohort_sizes cs
    CROSS JOIN key_days kd
    CROSS JOIN params p
    WHERE cs.cohort_date + kd.day_number <= p.max_activity_date
),
eligible_denominator AS (
    SELECT
        cohort_week,
        cohort_week_sort,
        retention_key_day,
        retention_key_day_sort,
        day_number,
        SUM(cohort_users) AS eligible_cohort_users
    FROM eligible_cohorts
    GROUP BY
        cohort_week,
        cohort_week_sort,
        retention_key_day,
        retention_key_day_sort,
        day_number
),
retained_by_week AS (
    SELECT
        CASE
            WHEN rc.cohort_date BETWEEN DATE '2019-10-01' AND DATE '2019-10-07' THEN 'Oct 01-07'
            WHEN rc.cohort_date BETWEEN DATE '2019-10-08' AND DATE '2019-10-14' THEN 'Oct 08-14'
            WHEN rc.cohort_date BETWEEN DATE '2019-10-15' AND DATE '2019-10-21' THEN 'Oct 15-21'
            ELSE 'Oct 22-31'
        END AS cohort_week,
        CASE
            WHEN rc.cohort_date BETWEEN DATE '2019-10-01' AND DATE '2019-10-07' THEN 1
            WHEN rc.cohort_date BETWEEN DATE '2019-10-08' AND DATE '2019-10-14' THEN 2
            WHEN rc.cohort_date BETWEEN DATE '2019-10-15' AND DATE '2019-10-21' THEN 3
            ELSE 4
        END AS cohort_week_sort,
        kd.retention_key_day,
        kd.retention_key_day_sort,
        kd.day_number,
        SUM(rc.retained_users) AS retained_users
    FROM retention_cohorts rc
    JOIN key_days kd
        ON rc.day_number = kd.day_number
    GROUP BY
        cohort_week,
        cohort_week_sort,
        kd.retention_key_day,
        kd.retention_key_day_sort,
        kd.day_number
)
SELECT
    ed.cohort_week,
    ed.cohort_week_sort,
    ed.retention_key_day,
    ed.retention_key_day_sort,
    ed.day_number,
    ed.eligible_cohort_users,
    COALESCE(rw.retained_users, 0) AS retained_users,
    ROUND(
        COALESCE(rw.retained_users, 0) * 100.0
        / NULLIF(ed.eligible_cohort_users, 0),
        2
    ) AS retention_rate_percent
FROM eligible_denominator ed
LEFT JOIN retained_by_week rw
    ON ed.cohort_week = rw.cohort_week
   AND ed.retention_key_day = rw.retention_key_day
ORDER BY
    ed.cohort_week_sort,
    ed.retention_key_day_sort;

DROP TABLE IF EXISTS retention_daily_key_days;

CREATE TABLE retention_daily_key_days AS
WITH params AS (
    SELECT MAX(activity_date) AS max_activity_date
    FROM retention_cohorts
),
key_days AS (
    SELECT *
    FROM (
        VALUES
            (1, 'D1', 1),
            (2, 'D2', 2),
            (3, 'D3', 3),
            (7, 'D7', 4),
            (14, 'D14', 5),
            (21, 'D21', 6),
            (30, 'D30', 7)
    ) AS d(day_number, retention_key_day, retention_key_day_sort)
),
cohort_sizes AS (
    SELECT
        cohort_date,
        TO_CHAR(cohort_date, 'Mon DD') AS cohort_date_label,
        CASE
            WHEN cohort_date BETWEEN DATE '2019-10-01' AND DATE '2019-10-07' THEN 'Oct 01-07'
            WHEN cohort_date BETWEEN DATE '2019-10-08' AND DATE '2019-10-14' THEN 'Oct 08-14'
            WHEN cohort_date BETWEEN DATE '2019-10-15' AND DATE '2019-10-21' THEN 'Oct 15-21'
            ELSE 'Oct 22-31'
        END AS cohort_week,
        CASE
            WHEN cohort_date BETWEEN DATE '2019-10-01' AND DATE '2019-10-07' THEN 1
            WHEN cohort_date BETWEEN DATE '2019-10-08' AND DATE '2019-10-14' THEN 2
            WHEN cohort_date BETWEEN DATE '2019-10-15' AND DATE '2019-10-21' THEN 3
            ELSE 4
        END AS cohort_week_sort,
        retained_users AS cohort_users
    FROM retention_cohorts
    WHERE day_number = 0
),
eligible_daily_cohorts AS (
    SELECT
        cs.cohort_date,
        cs.cohort_date_label,
        cs.cohort_week,
        cs.cohort_week_sort,
        kd.retention_key_day,
        kd.retention_key_day_sort,
        kd.day_number,
        cs.cohort_users
    FROM cohort_sizes cs
    CROSS JOIN key_days kd
    CROSS JOIN params p
    WHERE cs.cohort_date + kd.day_number <= p.max_activity_date
),
retained_daily AS (
    SELECT
        rc.cohort_date,
        kd.retention_key_day,
        kd.retention_key_day_sort,
        kd.day_number,
        rc.retained_users
    FROM retention_cohorts rc
    JOIN key_days kd
        ON rc.day_number = kd.day_number
)
SELECT
    ed.cohort_date,
    ed.cohort_date_label,
    ed.cohort_week,
    ed.cohort_week_sort,
    ed.retention_key_day,
    ed.retention_key_day_sort,
    ed.day_number,
    ed.cohort_users AS eligible_cohort_users,
    COALESCE(rd.retained_users, 0) AS retained_users,
    ROUND(
        COALESCE(rd.retained_users, 0) * 100.0
        / NULLIF(ed.cohort_users, 0),
        2
    ) AS retention_rate_percent
FROM eligible_daily_cohorts ed
LEFT JOIN retained_daily rd
    ON ed.cohort_date = rd.cohort_date
   AND ed.retention_key_day = rd.retention_key_day
ORDER BY
    ed.cohort_date,
    ed.retention_key_day_sort;
