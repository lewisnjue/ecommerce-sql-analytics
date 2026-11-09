# Phase 10 — Customer Segmentation

## Methodology

Purchase frequency and monetary value are based on **delivered orders only**.
The RFM reference date is one day after the last order purchase date in the
dataset, making recency reproducible and independent of when the query runs.
Customers with no delivered orders are retained in the basic purchase/value
segments but excluded from RFM scores because they have no purchase recency.

Scores range from 1 to 5: higher recency score means more recent; higher
frequency and monetary scores mean more delivered purchases and spend. To avoid
arbitrarily splitting customers with identical metric values across score
boundaries, `NTILE(5)` assigns scores across **distinct observed metric values**,
then those scores are joined back to customers. The resulting score groups need
not contain equal numbers of customers. This is a relative, dataset-specific
segmentation, not a business-validated customer lifecycle model.

Segment rules:

| Segment | Rule |
|---|---|
| Champions | Recency, frequency, and monetary scores all at least 4 |
| Loyal Customers | Recency at least 3 and frequency at least 4 |
| Potential Loyalists | Recency at least 4 and frequency at least 2 |
| At Risk | Recency at most 2 and frequency at least 3 |
| Hibernating | Recency and frequency at most 2 |
| Recent One-time | Recency at least 4 and frequency exactly 1 |
| Needs Attention | Other scored buyers |

Basic value tiers use a tie-preserving `NTILE` over distinct delivered-spend
amounts among buyers. The highest quintile of distinct amounts is “High value,”
the lowest is “Low value,” and the middle three are “Mid value.” “One-time” and
“Repeat” refer to delivered-order counts, not merely any recorded order.

Run the segmentation and assertions from the repository root:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/04_customer_segmentation.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_customer_segmentation.sql
```

## Results from the current database

Of 96,096 unique customers, 2,738 have no delivered order. Among buyers, the
segments were:

| RFM segment | Customers | Share of buyers | Avg. delivered orders | Avg. delivered spend |
|---|---:|---:|---:|---:|
| Recent One-time | 51,751 | 55.43% | 1.03 | R$ 140.58 |
| Needs Attention | 20,775 | 22.25% | 1.03 | R$ 144.33 |
| Hibernating | 20,679 | 22.15% | 1.03 | R$ 139.15 |
| Potential Loyalists | 147 | 0.16% | 3.34 | R$ 450.62 |
| Champions | 5 | 0.01% | 9.00 | R$ 799.10 |
| At Risk | 1 | <0.01% | 6.00 | R$ 58.40 |

The very small high-frequency segment is consistent with the previously
observed low repeat-purchase rate. Segment definitions are score-threshold
rules, not claims that segment sizes should be balanced.

The spend-tier query retains every customer. For example, 3,971 one-time
customers are in the high-value tier and 31,613 are in the low-value tier;
spend tiers are based on distinct observed spend levels, not fixed customer
percentiles.

## Validation and limitations

`tests/test_customer_segmentation.sql` passed. It verifies all unique customers
are included once in the base segmentation, zero-delivered-purchase customers
are preserved outside the RFM population, and RFM scores remain within 1–5.

Recency is relative to the data's last purchase date, and these segments are
not predictive. The small number of repeat customers makes RFM frequency
granularity especially limited; review the methodology before using these
labels for targeting or business decisions.
