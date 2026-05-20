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

### 1. Executive Overview

This page provides a high-level view of platform performance.

Main metrics and visuals:

* Total Revenue
* Total Users
* Purchase Users
* Purchase Conversion
* Revenue Trend
* Revenue by Weekday
* Revenue by Product Category

### 2. Funnel Analysis

This page analyzes how users move through the purchase journey:

View -> Cart -> Purchase

Main metrics:

* View -> Cart conversion
* Cart -> Purchase conversion
* View -> Purchase conversion

Key insight:

Purchase users slightly exceeded cart users, which suggests either direct checkout behavior or incomplete cart event tracking.

### 3. Retention & Cohorts

This page analyzes whether users return after their first visit.

Main analysis:

* Cohort retention table
* Day-N retention
* Retention heatmap

Key insight:

User retention drops sharply after Day 1 and then gradually stabilizes, which is typical for e-commerce behavior.

### 4. Revenue & User Segmentation

This page focuses on revenue concentration and customer value.

Main analysis:

* User purchase segmentation
* Repeat buyers
* High-value users
* Top spending users

Key insight:

Most customers purchase only once, while a small group of repeat buyers generates significantly higher spending.

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

---

## Key Business Insights

* Product views represent the majority of user activity.
* Only around 11% of users who viewed products added products to cart.
* Purchase conversion is slightly higher than cart conversion, which may indicate direct checkout behavior or missing cart tracking.
* Day-1 retention is relatively low, showing that many users do not return after their first visit.
* Earlier cohorts showed stronger retention than later cohorts.
* Smartphones were the strongest revenue-driving category.
* Most customers purchased only once.
* Repeat buyers and high-value users contribute disproportionately to revenue.

---

## Data Quality Notes

Some product category values were missing in the original dataset.

Instead of removing these rows, missing categories were standardized as `Unknown` in Power BI. This approach keeps revenue totals consistent while making data quality limitations visible.

---

## Project Structure

```text
commerce-analytics-dashboard/
|
|-- dashboard/
|   |-- README.md
|
|-- sql/
|   |-- 00_create_table.sql
|   |-- 01_data_overview.sql
|   |-- 02_funnel_analysis.sql
|   |-- 03_retention_analysis.sql
|   |-- 04_user_segmentation.sql
|
|-- screenshots/
|   |-- executive_overview.png
|   |-- funnel_analysis.png
|   |-- retention_cohorts.png
|   |-- revenue_segmentation.png
|
|-- README.md
```

The Power BI `.pbix` file is kept locally and is not tracked in this public repository because the exported file is large. Dashboard screenshots will be added to the `screenshots/` folder.

---

## How to Use This Project

1. Download the dataset from Kaggle.
2. Load the October 2019 e-commerce CSV dataset into PostgreSQL.
3. Run the SQL scripts from the `sql/` folder in order.
4. Open the local Power BI dashboard file.
5. Review the dashboard pages and business insights.

---

## Author

Created as a data analytics portfolio project focused on SQL, Power BI, product analytics, and business intelligence.
