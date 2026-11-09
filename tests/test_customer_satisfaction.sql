-- Phase 16 assertions: review scores are valid and the score distribution
-- accounts for every source review row.
DO $$
DECLARE
    invalid_scores BIGINT;
    total_reviews BIGINT;
    distributed_reviews BIGINT;
    category_observations BIGINT;
    seller_observations BIGINT;
BEGIN
    SELECT COUNT(*) FILTER (WHERE review_score NOT BETWEEN 1 AND 5),
           COUNT(*)
    INTO invalid_scores, total_reviews
    FROM staging.order_reviews;

    SELECT COALESCE(SUM(review_rows), 0)
    INTO distributed_reviews
    FROM (
        SELECT COUNT(*) AS review_rows
        FROM staging.order_reviews
        GROUP BY review_score
    ) score_distribution;

    IF invalid_scores <> 0 OR total_reviews = 0
       OR distributed_reviews <> total_reviews THEN
        RAISE EXCEPTION 'Review score domain or distribution check failed';
    END IF;

    SELECT COUNT(*) INTO category_observations
    FROM (
        SELECT DISTINCT r.review_id, r.order_id,
               COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
                   AS category
        FROM staging.order_reviews r
        JOIN staging.order_items oi ON oi.order_id = r.order_id
        JOIN staging.products p ON p.product_id = oi.product_id
    ) review_categories;

    SELECT COUNT(*) INTO seller_observations
    FROM (
        SELECT DISTINCT r.review_id, r.order_id, oi.seller_id
        FROM staging.order_reviews r
        JOIN staging.order_items oi ON oi.order_id = r.order_id
    ) review_sellers;

    IF category_observations = 0 OR seller_observations = 0 THEN
        RAISE EXCEPTION 'Review category or seller associations are empty';
    END IF;
END
$$;

SELECT 'Customer satisfaction checks passed' AS result;
