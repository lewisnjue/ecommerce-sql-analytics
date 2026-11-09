-- Cross-cutting Phase 20 checks. Known source anomalies are allowed when
-- their staging flags accurately preserve them.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM staging.customers
        WHERE customer_id IS NULL OR customer_unique_id IS NULL
           OR zip_code_prefix IS NULL OR city IS NULL OR state IS NULL
    ) OR EXISTS (
        SELECT 1 FROM staging.orders
        WHERE order_id IS NULL OR customer_id IS NULL OR status IS NULL
           OR purchased_at IS NULL OR purchase_date IS NULL
           OR purchase_month IS NULL OR estimated_delivery_at IS NULL
    ) OR EXISTS (
        SELECT 1 FROM staging.order_items
        WHERE order_id IS NULL OR order_item_id IS NULL OR product_id IS NULL
           OR seller_id IS NULL OR price_brl IS NULL OR freight_brl IS NULL
    ) OR EXISTS (
        SELECT 1 FROM staging.order_reviews
        WHERE review_id IS NULL OR order_id IS NULL OR review_score IS NULL
           OR created_at IS NULL OR answered_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Required staged fields contain NULL values';
    END IF;

    IF EXISTS (
        SELECT 1 FROM staging.order_reviews
        WHERE review_score NOT BETWEEN 1 AND 5
    ) OR EXISTS (
        SELECT 1 FROM staging.order_items
        WHERE price_brl < 0 OR freight_brl < 0
           OR item_total_brl <> price_brl + freight_brl
    ) THEN
        RAISE EXCEPTION 'Review or order-item value validation failed';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM staging.orders o
        WHERE o.approval_before_purchase IS DISTINCT FROM
                  COALESCE(o.approved_at < o.purchased_at, FALSE)
           OR o.carrier_before_purchase IS DISTINCT FROM
                  COALESCE(o.carrier_handoff_at < o.purchased_at, FALSE)
           OR o.carrier_before_approval IS DISTINCT FROM
                  COALESCE(
                      o.approved_at IS NOT NULL
                      AND o.carrier_handoff_at < o.approved_at,
                      FALSE
                  )
           OR o.delivery_before_purchase IS DISTINCT FROM
                  COALESCE(o.customer_delivered_at < o.purchased_at, FALSE)
           OR o.delivery_before_carrier IS DISTINCT FROM
                  COALESCE(
                      o.customer_delivered_at IS NOT NULL
                      AND o.carrier_handoff_at IS NOT NULL
                      AND o.customer_delivered_at < o.carrier_handoff_at,
                      FALSE
                  )
           OR o.delivered_status_missing_delivery IS DISTINCT FROM
                  (o.status = 'delivered' AND o.customer_delivered_at IS NULL)
           OR o.non_delivered_status_has_delivery IS DISTINCT FROM
                  (o.status <> 'delivered' AND o.customer_delivered_at IS NOT NULL)
           OR o.is_late_delivery IS DISTINCT FROM
                  CASE
                      WHEN o.status = 'delivered'
                       AND o.customer_delivered_at IS NOT NULL
                      THEN o.customer_delivered_at > o.estimated_delivery_at
                  END
    ) THEN
        RAISE EXCEPTION 'Order chronology flags do not match source timestamps';
    END IF;

    IF EXISTS (
        SELECT 1 FROM staging.order_payments
        WHERE has_invalid_installments IS DISTINCT FROM (installments < 1)
           OR is_zero_value IS DISTINCT FROM (payment_value_brl = 0)
    ) THEN
        RAISE EXCEPTION 'Payment quality flags do not match staged values';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM staging.order_reviews r
        JOIN staging.orders o ON o.order_id = r.order_id
        WHERE r.created_before_purchase IS DISTINCT FROM
              (r.created_at < o.purchased_at)
           OR r.comment_title = ''
           OR r.comment_message = ''
    ) THEN
        RAISE EXCEPTION 'Review quality flags or blank normalization failed';
    END IF;
END
$$;

SELECT 'Data quality checks passed' AS result;
