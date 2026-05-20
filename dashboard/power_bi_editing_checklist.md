# Power BI Editing Checklist

Use these changes for the final dashboard version.

## Funnel Analysis

* Replace the event-level `Cart -> Purchase` card with sequential user-level conversion from `funnel_user_summary`.
* Use `funnel_user_stages` for the funnel chart.
* Sort `stage` by `stage_order`.
* Use the stage order `View -> Cart -> Purchase`.
* Keep a note that many purchasers do not have a recorded cart event, which suggests direct checkout behavior or incomplete cart tracking.

Expected checked values:

* View users: `3,022,130`
* Cart after view users: `336,812`
* Strict View -> Cart -> Purchase users: `196,505`
* All purchase users with recorded cart: `202,777`
* All purchase users without recorded cart: `144,341`
* All purchase users without recorded cart share: `41.59%`
* Sequential View -> Cart: `11.14%`
* Sequential Cart -> Purchase: `58.34%`
* Strict full funnel conversion: `6.50%`

## Executive Overview

* Use `category_revenue_summary` for the category revenue chart.
* Sort categories by `category_sort_order`.
* Show Top 10 categories by revenue.
* Show `Unknown` explicitly because it ranks second by revenue.

Expected checked values:

* Total revenue: `229.96M`
* `electronics.smartphone` revenue: `157.05M`
* `Unknown` revenue: `22.92M`
* `Unknown` revenue share: `9.97%`

## Retention & Cohorts

* Keep the cohort heatmap.
* Note that later cohorts have fewer observable days, so early and late cohorts should not be compared as if they had equal follow-up windows.

## Revenue & User Segmentation

* Use `user_segment_summary` for segment-level visuals.
* Add or replace one visual with `revenue_share_percent` by segment.
* Sort segments by `segment_sort_order`.

Expected checked values:

* `1 Purchase`: `215,691` users, `57.06M` revenue
* `2-5 Purchases`: `111,882` users, `88.23M` revenue
* `6-10 Purchases`: `12,938` users, `32.61M` revenue
* `10+ Purchases`: `6,607` users, `52.06M` revenue
