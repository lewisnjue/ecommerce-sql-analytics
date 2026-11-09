# Phase 8 — Revenue Analysis

## Revenue definition and reproducibility

The primary measure is **delivered merchandise sales**: `SUM(price_brl)` at
order-item grain for orders whose status is `delivered`. It excludes freight
and undelivered/canceled orders. Refunds and payment adjustments are not
modeled in the available tables. It is an operational sales measure, not
accounting revenue.

Freight is reported separately; `item price + freight` is shown as a
delivered-order total for comparison. Payment rows are not summed as revenue:
an order can have multiple payment rows, and voucher/zero-value rows were
flagged during Phase 5.

Run the analysis and reconciliation assertions from the repository root:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/02_revenue.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_revenue.sql
```

The SQL answers total revenue and average order value, monthly and yearly
revenue, category/state/seller/product rankings, top-product contribution, and
revenue change over time. Monthly output includes calendar months with no
delivered revenue and applies `LAG`, a cumulative `SUM`, a three-month rolling
`AVG`, `RANK`, and `DENSE_RANK`.

## Results from the current database

All amounts below are BRL.

### Total and average order value

| Metric | Result |
|---|---:|
| Delivered orders with items | 96,478 |
| Delivered merchandise sales | R$ 13,221,498.11 |
| Freight on delivered items | R$ 2,198,275.64 |
| Delivered item total including freight | R$ 15,419,773.75 |
| Average merchandise order value | R$ 137.04 |
| Average delivered order value including freight | R$ 159.83 |

Average order values use one aggregated total per delivered order as the
denominator, not item rows or payment rows.

### Revenue over time

| Purchase year | Delivered orders | Merchandise sales | Freight |
|---:|---:|---:|---:|
| 2016 | 267 | R$ 40,470.98 | R$ 6,182.76 |
| 2017 | 43,428 | R$ 5,962,902.01 | R$ 958,633.23 |
| 2018 | 52,783 | R$ 7,218,125.12 | R$ 1,233,459.65 |

2016 contains only September–December observations, and 2018 ends in October;
the annual figures and computed year-over-year percentages are not
full-year-like comparisons. In particular, 2018's 21.05% increase over 2017 is
for an incomplete year and should not be presented as a like-for-like annual
growth rate.

Delivered merchandise sales peaked in **November 2017 at R$ 987,765.37**.
October 2018 has four purchases but no delivered orders in the observed data;
the query therefore reports zero delivered merchandise sales for that month.
It does not mean there were no purchases. The continuous month calendar also
shows November 2016 with zero purchases and zero delivered revenue. Growth is
NULL where the prior-month baseline is zero.

The monthly SQL provides month-over-month change, cumulative sales, three-month
rolling average, and revenue rank. The rolling average includes zero-sales
calendar months rather than skipping them.

### Category, geography, seller, and product

Top categories by delivered merchandise sales:

| Rank | Category | Sales |
|---:|---|---:|
| 1 | health_beauty | R$ 1,233,131.72 |
| 2 | watches_gifts | R$ 1,166,176.98 |
| 3 | bed_bath_table | R$ 1,023,434.76 |
| 4 | sports_leisure | R$ 954,852.55 |
| 5 | computers_accessories | R$ 888,724.61 |

Top customer-state sales are São Paulo (`SP`) at **R$ 5,067,633.16**. State
sales are attributed using the customer's state; the query returns all states.

The top seller is seller `4869f7a5dfa277a7dca6462dcf3b52b2` in `SP`, with
**R$ 226,987.93** in merchandise sales across 1,124 delivered orders. The SQL
returns the top 20 sellers.

The top product is `bb50f2e236e5eea0100680137654686c` in `health_beauty`, with
**R$ 63,560.00** across 194 delivered item rows. The top 10 products together
contribute **R$ 442,814.82**, or **3.35%** of total delivered merchandise sales.
Product sales use a deterministic product ID tie-breaker to define the top-ten
set; product ranks use `RANK`.

## Validation and interpretation

`tests/test_revenue.sql` passed. It reconciles delivered merchandise totals
across monthly, yearly, product, category, customer-state, and seller-state
aggregations, verifies the final running total, and checks that the top-ten
share is within the valid range.

Revenue by customer state and seller state intentionally differ in distribution:
each assigns the same item sale to a different participant's location. Product
category labels fall back to the original category name or `[Uncategorized]`
when translation metadata is absent; the raw category key remains available.
