-- Phase 16: customer satisfaction across products, sellers, geography, time,
-- and delivery. A review row is the observation unless otherwise noted.

-- Overall score and review coverage.
SELECT COUNT(*) AS review_rows,
       COUNT(DISTINCT order_id) AS reviewed_orders,
       ROUND(AVG(review_score)::NUMERIC, 3) AS average_review_score,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY review_score)
           AS median_review_score
FROM staging.order_reviews;

-- Review score distribution.
SELECT review_score, COUNT(*) AS review_rows,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM staging.order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Category ratings: one observation per review/category pair, so an order
-- containing multiple products in the same category is not over-counted.
WITH review_categories AS (
    SELECT DISTINCT r.review_id, r.order_id, r.review_score,
           COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
               AS category
    FROM staging.order_reviews r
    JOIN staging.order_items oi ON oi.order_id = r.order_id
    JOIN staging.products p ON p.product_id = oi.product_id
)
SELECT category, COUNT(*) AS review_category_observations,
       ROUND(AVG(review_score)::NUMERIC, 3) AS average_review_score,
       COUNT(*) FILTER (WHERE review_score <= 2) AS low_score_observations
FROM review_categories
GROUP BY category
ORDER BY average_review_score, review_category_observations DESC;

-- Seller ratings: each review is associated once with each seller represented
-- in the reviewed order, regardless of how many items that seller supplied.
WITH review_sellers AS (
    SELECT DISTINCT r.review_id, r.order_id, r.review_score, oi.seller_id
    FROM staging.order_reviews r
    JOIN staging.order_items oi ON oi.order_id = r.order_id
)
SELECT rs.seller_id, s.state,
       COUNT(*) AS review_observations,
       ROUND(AVG(rs.review_score)::NUMERIC, 3) AS average_review_score,
       COUNT(*) FILTER (WHERE rs.review_score <= 2) AS low_score_observations
FROM review_sellers rs
JOIN staging.sellers s ON s.seller_id = rs.seller_id
GROUP BY rs.seller_id, s.state
HAVING COUNT(*) >= 20
ORDER BY average_review_score, review_observations DESC
LIMIT 25;

-- Scores by customer destination state.
SELECT c.state AS customer_state,
       COUNT(*) AS review_rows,
       COUNT(DISTINCT r.order_id) AS reviewed_orders,
       ROUND(AVG(r.review_score)::NUMERIC, 3) AS average_review_score
FROM staging.order_reviews r
JOIN staging.orders o ON o.order_id = r.order_id
JOIN staging.customers c ON c.customer_id = o.customer_id
GROUP BY c.state
ORDER BY average_review_score, review_rows DESC;

-- Monthly trend by review creation timestamp, not purchase month.
SELECT DATE_TRUNC('month', r.created_at)::DATE AS review_month,
       COUNT(*) AS review_rows,
       ROUND(AVG(r.review_score)::NUMERIC, 3) AS average_review_score,
       COUNT(*) FILTER (WHERE r.review_score <= 2) AS low_score_reviews,
       ROUND(
           100.0 * COUNT(*) FILTER (WHERE r.review_score <= 2) / COUNT(*),
           2
       ) AS low_score_share_pct
FROM staging.order_reviews r
GROUP BY DATE_TRUNC('month', r.created_at)::DATE
ORDER BY review_month;

-- Satisfaction by delivery-time bucket for delivered orders. Reviews remain
-- the scoring grain; distinct orders are reported to show the coverage.
WITH reviewed_deliveries AS (
    SELECT r.review_id, r.order_id, r.review_score,
           o.delivery_duration_hours,
           CASE
               WHEN o.delivery_duration_hours <= 72 THEN '0-3 days'
               WHEN o.delivery_duration_hours <= 168 THEN '4-7 days'
               WHEN o.delivery_duration_hours <= 336 THEN '8-14 days'
               WHEN o.delivery_duration_hours <= 720 THEN '15-30 days'
               ELSE '31+ days'
           END AS delivery_time_bucket
    FROM staging.order_reviews r
    JOIN staging.orders o ON o.order_id = r.order_id
    WHERE o.status = 'delivered'
      AND o.delivery_duration_hours >= 0
)
SELECT delivery_time_bucket,
       COUNT(*) AS review_rows,
       COUNT(DISTINCT order_id) AS reviewed_orders,
       ROUND(AVG(review_score)::NUMERIC, 3) AS average_review_score,
       ROUND(AVG(delivery_duration_hours)::NUMERIC, 2)
           AS average_delivery_hours,
       ROUND(
           100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*),
           2
       ) AS low_score_share_pct
FROM reviewed_deliveries
GROUP BY delivery_time_bucket
ORDER BY CASE delivery_time_bucket
             WHEN '0-3 days' THEN 1
             WHEN '4-7 days' THEN 2
             WHEN '8-14 days' THEN 3
             WHEN '15-30 days' THEN 4
             ELSE 5
         END;
