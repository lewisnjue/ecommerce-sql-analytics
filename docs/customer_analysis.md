# Phase 9 — Customer Analysis

## Method and definitions

Customers are identified by `customer_unique_id`, the person-level key. The
source `customer_id` identifies an order-specific customer record; grouping on
it would incorrectly classify nearly every customer as a one-time buyer.

Order frequency and interpurchase time use all orders. Customer spend and
average order value use merchandise prices from delivered orders only; freight
is excluded. A customer with no delivered orders has zero delivered merchandise
spend. Geography is the state recorded on the order's customer account, so a
person with orders shipped to different states can appear in more than one
state's results.

Run the customer queries and assertions from the repository root:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/03_customers.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_customers.sql
```

The SQL includes customer-level order/spend summaries, frequency distribution,
top-value customers, time between purchases, and state-level customer value.

## Results from the current database

| Metric | Result |
|---|---:|
| Unique customers | 96,096 |
| Customers with one order | 93,099 |
| Repeat customers | 2,997 |
| Repeat-customer rate | 3.12% |
| Average delivered spend across all customers | R$ 137.59 |
| Average delivered spend among customers with a delivered order | R$ 141.62 |

The average of **R$ 137.59** includes customers with no delivered order, whose
delivered spend is zero. It is not the same as order-level AOV, which is
reported in [the revenue analysis](revenue_analysis.md).

### Orders and spend by customer frequency

| Orders per customer | Customers | Average delivered spend | Total delivered spend |
|---|---:|---:|---:|
| 1 order | 93,099 | R$ 133.85 | R$ 12,461,120.25 |
| 2 orders | 2,745 | R$ 238.97 | R$ 655,976.86 |
| 3 orders | 203 | R$ 357.65 | R$ 72,602.72 |
| 4+ orders | 49 | R$ 648.94 | R$ 31,798.28 |

The top customer by delivered merchandise spend is
`0a0a92112bd4c708ca5fde585afaa872`, with **R$ 13,440.00** on one delivered
order. The SQL returns the top 20 and reports both all-order frequency and
delivered-order count.

### Time between purchases

There are **3,345** consecutive-purchase intervals among **2,997** repeat
customers. The average interval is **78.23 days** and the median is
approximately **28.33 days**. The shortest interval is zero, and the longest is
608 days 23 hours 29 minutes. The median is more representative of the typical
interval because a small number of long gaps raise the mean.

### Customer value by state

The highest average delivered spend per customer-state grouping is in Paraíba
(`PB`): **R$ 216.93** across 519 unique customers with order records in that
state. Acre (`AC`) is next at R$ 206.90 across 77 customers. These averages
include customer-state groups with no delivered sales; low-population states
should be interpreted cautiously. São Paulo has the largest absolute delivered
sales, **R$ 5,067,633.16**, across 40,302 unique customers, but a lower average
per customer (**R$ 125.74**).

## Validation and limitations

`tests/test_customers.sql` passed. It verifies that person-level order counts
reconcile to all staged orders, every person-level key is represented, repeat
customers exist, and customer-attributed delivered merchandise spend reconciles
to delivered item sales.

These are descriptive, historical customer metrics, not predictions of future
behavior. The dataset covers a limited time window, and the customer identifier
represents de-identified identity matching supplied by the source.
