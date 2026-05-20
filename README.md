# E-Commerce User Behavior & Revenue Analysis

## Project Overview

This project analyzes user behavior and revenue performance in an e-commerce platform using PostgreSQL and Power BI.

The goal of the project is to answer practical business questions:

* How do users move through the purchase funnel?
* Where do users drop off before buying?
* Do users return after their first visit?
* Which product categories generate the most revenue?
* How valuable are repeat buyers compared to one-time buyers?

The project combines SQL-based data preparation, cohort analysis, funnel analysis, revenue analysis, customer segmentation, and Power BI dashboarding.

---

## Dataset

The analysis is based on the open Kaggle dataset [Ecommerce behavior data from multi category store](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store/data).

This project uses user event data from October 2019. Each row represents one user event.

Main fields:

| Column | Description |
| --- | --- |
| `event_time` | Timestamp of the user event |
| `event_type` | Type of event: view, cart, purchase |
| `product_id` | Product identifier |
| `category_code` | Product category |
| `brand` | Product brand |
| `price` | Product price |
| `user_id` | User identifier |
| `user_session` | Session identifier |

---

## Tools Used

* PostgreSQL
* Power BI
* SQL
* DAX

---

## Dashboard Pages

### Executive Overview

High-level platform performance: revenue, users, purchase conversion, revenue trend, weekday revenue, and revenue by product category.

### Funnel Analysis

User movement through the purchase journey:

View -> Cart -> Purchase

Key insight:

The cart step shows a tracking gap: almost all purchasing users had a prior product view, but many purchasing users did not have a recorded cart event.

The final dashboard uses a sequential user-level funnel. In this approach, users must move through the observed order View -> Cart -> Purchase. This avoids mixing user-level and event-level conversion metrics.

### Retention & Cohorts

Retention heatmap and Day-N cohort analysis.

Later cohorts have fewer observable days in the October dataset, so earlier and later cohorts should be compared with that limitation in mind.

### Revenue & User Segmentation

Purchase frequency segments, high-value users, and revenue share by buyer segment.

---

## Key SQL Techniques Used

* Data aggregation
* Conditional aggregation
* Common Table Expressions
* Cohort analysis
* Retention calculation
* User segmentation
* Revenue analysis
* Data cleaning
* BI-ready table creation
* Data validation

---

## Key Business Insights

* Product views represent the majority of user activity.
* Only around 11% of users who viewed products added products to cart.
* A large share of purchasing users had no recorded cart event, which may indicate direct checkout behavior or incomplete cart tracking.
* Sequential funnel analysis confirms that the cart step is the main tracking or behavioral gap.
* Day-1 retention is relatively low, showing that many users do not return after their first visit.
* Earlier cohorts showed stronger retention than later cohorts.
* Smartphones were the strongest revenue-driving category.
* `Unknown` was the second-highest revenue category and represented 9.97% of purchase revenue.
* Most customers purchased only once.
* Repeat buyers and high-value users contribute disproportionately to revenue.

---

## Data Quality Decision

Some product category values were missing in the original dataset.

Decision: missing product categories are kept in the analysis and standardized as `Unknown` in both SQL and Power BI.

In the loaded October 2019 data, missing categories represented 173,425 purchase events and 22.9M in revenue, making `Unknown` the second-highest revenue category. Removing these rows would materially understate total revenue and change the category ranking.

This is treated as a data quality limitation rather than a reason to exclude the records. The approach keeps financial totals complete while making the missing category issue visible to dashboard users.

---

## Project Structure

```text
commerce-analytics-dashboard/
|
|-- sql/
|   |-- 00_create_table.sql
|   |-- 01_data_overview.sql
|   |-- 02_funnel_analysis.sql
|   |-- 03_retention_analysis.sql
|   |-- 04_user_segmentation.sql
|   |-- 05_data_quality_checks.sql
|   |-- 06_dashboard_support_tables.sql
|
|-- README.md
```

The Power BI `.pbix` file is kept locally and is not tracked in this public repository because the exported file is large.

---

## How to Use This Project

1. Download the dataset from Kaggle.
2. Load the October 2019 e-commerce CSV dataset into PostgreSQL.
3. Run the SQL scripts from the `sql/` folder in order.
4. Open the local Power BI dashboard file.
5. Refresh the Power BI model and use the dashboard support tables for the final visuals.
6. Review the dashboard pages and business insights.

---

## Author

Created as a data analytics portfolio project focused on SQL, Power BI, product analytics, and business intelligence.
