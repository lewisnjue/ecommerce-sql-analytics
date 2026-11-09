# Phase 7 — Exploratory SQL

## Reproduce

Phase 7 queries use the normalized staging tables:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/01_exploration.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_exploration.sql
```

The exploration query reports dataset size, first/last order, monthly and
yearly order counts, status distribution, customer/seller counts by state, and
delivered merchandise revenue by customer and seller state.

## Findings from the current database

### Dataset size and time

| Entity | Rows |
|---|---:|
| Customer accounts | 99,441 |
| Distinct customers (`customer_unique_id`) | 96,096 |
| Orders | 99,441 |
| Products | 32,951 |
| Sellers | 3,095 |
| Order items | 112,650 |
| Payments | 103,886 |
| Reviews | 99,224 |
| Geolocation rows | 1,000,163 |

Orders range from **2016-09-04 21:15:19** through **2018-10-17 17:30:18**.
There are orders in 25 distinct months. Monthly results show no orders in
November 2016; months without orders are omitted rather than zero-filled. The
2018 data ends in October, so year-to-year totals are not full-year comparable.

| Year | Orders |
|---:|---:|
| 2016 | 329 |
| 2017 | 45,101 |
| 2018 (partial through October) | 54,011 |

The busiest month is **November 2017**, with **7,544 orders**. The next busiest
months are January 2018 (7,269) and March 2018 (7,211). Ten months have at least
5,000 orders; the SQL `HAVING` query surfaces those without filtering out
smaller months from the full monthly result.

### Order status

| Status | Orders | Share |
|---|---:|---:|
| Delivered | 96,478 | 97.02% |
| Shipped | 1,107 | 1.11% |
| Cancelled | 625 | 0.63% |
| Unavailable | 609 | 0.61% |
| Invoiced | 314 | 0.32% |
| Processing | 301 | 0.30% |
| Created | 5 | 0.01% |
| Approved | 2 | <0.01% |

Percentages are rounded to two decimal places and may not sum to exactly 100%.

### Geography and delivered merchandise sales

Customers are distributed across 27 states; sellers are recorded in 23 states.
São Paulo (`SP`) has the most unique customers (**40,302**) and sellers
(**1,849**).

For the state revenue comparisons, **delivered merchandise revenue** means the
sum of order-item `price_brl` for orders with delivered status. It excludes
freight and payments, and counts item prices at item grain; it is not an
accounting or net-revenue measure. The state totals reconcile to **R$
13,221,498.11** for both customer and seller state perspectives.

| Perspective | State | Delivered merchandise revenue |
|---|---|---:|
| Customer state | SP | R$ 5,067,633.16 |
| Seller state | SP | R$ 8,509,511.46 |

The difference is expected: customer and seller state assign the same delivered
item sales to different geographies. The query also returns delivered order
and item counts per state for context.

## Validation

`tests/test_exploration.sql` passed. It asserts that monthly, yearly, and
status aggregates reconcile to the complete staged order count, and that
customer-state and seller-state revenue each reconcile to the total delivered
item-price amount.
