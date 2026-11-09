# Phase 16 — Customer Satisfaction

The analysis treats each `(review_id, order_id)` row as a review observation.
Category and seller breakdowns associate each review once with each category
or seller present in the order, rather than multiplying it by repeated item
rows. A seller or category may still have multiple observations from the same
order if that order has multiple reviews. Seller results require at least 20
review observations. Monthly trends use review creation month, not purchase
month. Delivery comparisons include delivered orders with non-negative
purchase-to-delivery durations.

Run and validate:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/10_customer_satisfaction.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_customer_satisfaction.sql
```

Across **99,224 review rows** and **98,673 reviewed orders**, the mean score
was **4.086 / 5** and the median was **5**. Scores were polarized toward the
high end: 57.78% were 5 and 19.29% were 4; 14.69% were 1 or 2. The difference
between review rows and orders reflects orders with multiple review records.

Satisfaction varies by category, but low-count categories should not be ranked
as if their averages were stable. For example, office furniture averaged
**3.618** across 1,268 review/category observations, while categories with
only a handful of observations had much wider uncertainty. Seller averages
are similarly descriptive and affected by seller volume and assortment. By
destination state, scores ranged from **3.609** in RR (46 review rows) to
**4.194** in AP (67 review rows); this does not establish a geographic cause.

The delivery-time relationship is pronounced: reviewed orders delivered in
0–3 days averaged **4.483**, while those taking 31+ days averaged **2.254**.
The low-score share rose from **6.63%** to **62.96%** across those buckets.
This association is consistent with the on-time/late comparison in
[docs/delivery_analysis.md](delivery_analysis.md), but does not establish
causality or account for all confounding factors.

Scores by review month fluctuated: the largest month-level sample was August
2018 (8,987 rows, mean 4.210), while March 2018 had a lower mean of 3.727
across 7,803 rows. The period is observational and ends with the available
dataset, so the trend should not be extrapolated.

`tests/test_customer_satisfaction.sql` passed. It verifies all source scores
are in the 1–5 domain, the distribution accounts for every review, and
category/seller associations are non-empty.
