# Executive Summary — Olist Brazilian E-Commerce

## Executive summary

This analysis examined Olist's Brazilian marketplace orders, customers,
products, sellers, delivery records, and reviews in PostgreSQL. As of the
dataset reference date, **2018-10-18**, the dataset contains **R$ 13.22 million
in delivered merchandise sales** across **96,478 delivered orders**. This is
the sum of item prices for orders marked delivered; it excludes freight and
must not be interpreted as accounting revenue, gross payment volume, or
profit.

The strongest business signals are sparse repeat purchasing, a material
delivery/satisfaction association, and sales spread across a large product
catalog. These are descriptive findings from a limited historical extract.
They should guide investigation and controlled tests, not be treated as
causal evidence or forecasts.

## Key findings

| Area | Finding | Business interpretation |
|---|---|---|
| Sales | Delivered merchandise sales were **R$ 13,221,498.11** on **96,478 orders**; average order value was **R$ 137.04**. Delivered freight was a separate **R$ 2,198,275.64**. | Item price and freight are distinct measures. Neither is net accounting revenue or margin. |
| Customers | **93,358** distinct customers had a delivered order; **2,801 (3.00%)** had more than one delivered order. Pooled month-one cohort retention was **0.45%** (421 of 93,358 customers across 23 eligible cohorts). | Repeat behavior is limited in this observation window. The cohort figure uses eligible cohorts, including those with no month-one return. |
| Segments | **55.43%** of delivered buyers were classified as `Recent One-time`; **22.25%** as `Needs Attention`; and **22.15%** as `Hibernating`. | Most buyers were not frequent delivered-order customers. RFM labels are relative to this dataset, not validated lifecycle states. |
| Products | Health and beauty led category sales at **R$ 1,233,131.72**. **8,352 of 32,951 products (25.93%)** accounted for at least 80% of delivered merchandise sales. | A comparatively small part of the catalog drives most sales, while a substantial long tail remains. Sales alone do not establish profitability or assortment value. |
| Delivery | Average eligible delivery time was **301.40 hours (12.56 days)**; **8.11%** of classifiable deliveries were late. Reviewed on-time deliveries averaged **4.294/5**, versus **2.566/5** for late deliveries. | Delivery performance is a high-priority operational signal. The review-score difference is an association, not proof that lateness alone caused lower scores. |
| Reviews | The **99,224** review rows averaged **4.086/5**; **14.69%** were scores of 1 or 2. | The positive mean masks a meaningful dissatisfied group. Review rows are not necessarily unique orders. |
| Data quality | The source contains untranslated product categories and repeated geolocation observations, among other investigated anomalies. | Repairing lookup coverage and defining geolocation deduplication rules would improve future analysis, but raw records should remain traceable. |

## Business impact and recommendations

1. **Investigate repeat-purchase opportunities.** Treat the large one-time
   segment and low month-one return as hypotheses for targeted, measurable
   retention experiments. Compare eligible customer groups over a consistent
   follow-up window before adopting a campaign.
2. **Prioritize delivery reliability.** Review late rates and elapsed times by
   destination and seller, with minimum sample sizes and a repeatable monitoring
   cadence. The longest state averages include small samples; investigate
   operational causes before reallocating resources.
3. **Connect delivery and customer feedback.** Track review scores alongside
   delivery promise accuracy and late status. Use an experiment or an adjusted
   analysis to separate delivery effects from product mix, seller, and customer
   differences.
4. **Use category and product concentration for investigation, not automatic
   delisting.** Review leading categories and products together with margin,
   returns, availability, and customer acquisition data before changing
   assortment.
5. **Build a trusted commercial measurement layer.** Preserve delivered item
   sales, freight, payments, refunds, and costs as distinct concepts. Reconcile
   them before presenting a financial revenue or profitability figure.
6. **Improve source-data coverage.** Maintain category translations and
   document a stable geolocation aggregation rule. Add repeatable checks for
   nulls, duplicates, relationships, and date/value anomalies to the ingestion
   workflow.

## Limitations

- The data is a finite historical extract ending in October 2018; the final
  months are incomplete and newer customer behavior is not represented.
- Delivered merchandise item price is an operational sales measure. Refunds,
  payment adjustments, taxes, discounts, cost of goods, and operating costs
  are not modeled as a complete accounting ledger.
- Customer repeat rate and retention depend on the delivered-order definition
  and the available observation window. Cohort percentages for late cohorts
  have less follow-up time.
- RFM, seller quartiles, and the 12-month customer-spend proxy are descriptive
  constructs, not validated predictions. The customer-spend proxy is especially
  uncertain for short observed histories.
- Delivery duration and review-score differences are observational and may be
  confounded by product, seller, geography, or other factors.
- Low-volume state, product, and seller averages are unstable. Review records
  may include multiple observations per order, depending on the analysis grain.
- The source does not establish why customers did or did not return, nor does
  it provide a representative control group for evaluating business actions.

## Supporting analysis

Definitions and reproducible SQL are in [the KPI layer](../docs/kpi_layer.md),
[revenue analysis](../docs/revenue_analysis.md), [customer analysis](../docs/customer_analysis.md),
[cohort analysis](../docs/cohort_analysis.md), [product analysis](../docs/product_analysis.md),
[delivery analysis](../docs/delivery_analysis.md), and
[customer satisfaction analysis](../docs/customer_satisfaction.md).
