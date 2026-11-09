# Phase 5 — Data Quality Investigation

- **Status:** Complete
- **Database:** PostgreSQL 14, database `olist`
- **Run date:** 2026-11-09

## Scope and method

The raw tables were investigated before applying any cleaning. All findings
below are from the loaded database on the run date; no source rows were changed.
Counts from checks using `CURRENT_TIMESTAMP` are date-dependent and should be
re-run when the data is refreshed.

Run each query from the repository root, for example:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/04_quality/01_null_checks.sql
```

The five executable scripts cover nullable fields, duplicates and join grain,
relationships, values, and event chronology:

* [Null checks](../sql/04_quality/01_null_checks.sql)
* [Duplicate checks](../sql/04_quality/02_duplicate_checks.sql)
* [Referential integrity](../sql/04_quality/03_referential_integrity.sql)
* [Value validation](../sql/04_quality/04_value_validation.sql)
* [Date validation](../sql/04_quality/05_date_validation.sql)

The database schema enforces primary keys, declared foreign keys, and selected
value checks. The independent queries below validate the data that made it into
the database; they cannot reveal source rows rejected during loading.

## Findings

### NULLs and missing information

| Problem | Detection query | Affected rows | Decision and reason |
|---|---|---:|---|
| Missing review titles | `01_null_checks.sql`, `order_reviews.review_comment_title` | 87,656 / 99,224 (88.34%) | Treat as optional customer feedback, not automatically defective. Keep NULL distinct from an empty string. |
| Missing review messages | `01_null_checks.sql`, `order_reviews.review_comment_message` | 58,247 / 99,224 (58.70%) | Same decision: comments are optional. The query also found 2 blank titles and 9 blank messages, which are distinct from NULLs. |
| Missing approval timestamps | `01_null_checks.sql`, status breakdown | 160 / 99,441 (0.16%); 141 canceled, 5 created, 14 delivered | Missing approval is plausible for canceled or not-yet-approved orders. The 14 delivered orders warrant source review; do not impute dates. |
| Missing carrier handoff timestamps | `01_null_checks.sql`, status breakdown | 1,783 / 99,441 (1.79%); 550 canceled, 5 created, 2 delivered, and the rest in other non-final statuses | Mostly associated with statuses where handoff may not have occurred. Investigate the 2 delivered orders; retain NULL for orders without a handoff. |
| Missing customer delivery timestamps | `01_null_checks.sql`, status breakdown | 2,965 / 99,441 (2.98%); 8 delivered, with the rest in other statuses | Expected for many canceled/in-progress orders. The 8 delivered orders are inconsistent with their status and need follow-up. |
| Missing product category and descriptive attributes | `01_null_checks.sql`, product profile | 610 / 32,951 (1.85%) have NULL category, name length, description length, and photo quantity | Preserve as incomplete product metadata; only fill in staging when a trustworthy source mapping exists. |
| Missing shipping dimensions | `01_null_checks.sql`, product profile | 2 products have all four dimension/weight fields NULL | Keep missing rather than inventing shipping measurements; exclude or handle explicitly in shipping analyses. |

### Duplicates and join grain

| Problem | Detection query | Affected rows | Decision and reason |
|---|---|---:|---|
| Duplicate primary keys | `02_duplicate_checks.sql`, nine primary/composite key checks | 0 duplicate groups | No key collisions were found. The schema also prevents duplicate key values from being inserted. |
| Duplicate order business signatures | `02_duplicate_checks.sql`, order attributes grouped without `order_id` | 0 duplicate signatures | No identical order signatures were found. |
| Repeated full geolocation records | `02_duplicate_checks.sql`, grouped by ZIP, coordinates, city, and state | 128,174 repeated groups; 261,831 excess rows | The ZIP prefix is not unique, and the source also contains exact repeated records. Preserve the raw table; deduplicate only in a staging/model layer when the intended grain is defined. |
| Repeated review IDs across orders | `02_duplicate_checks.sql`, review identity and content profile | 789 repeated IDs; 814 excess rows across those IDs | All 789 IDs have identical scores, comments, and review timestamps across their linked orders. Treat as a source-level duplicate/reused-review risk. Do not count distinct review IDs as order reviews without confirming the intended source semantics. |
| Multiple order-specific customer IDs for one person | `02_duplicate_checks.sql`, `customer_unique_id` profile | 2,997 people; 3,345 additional IDs | Expected: `customer_id` is order-specific while `customer_unique_id` identifies a person. Do not remove these rows as duplicates. |
| Item rows multiplied by payment joins | `02_duplicate_checks.sql`, item/order/payment join-grain check | 117,604 joined rows for 112,650 distinct items (4,954 extra joined rows) | Expected one-to-many payment fan-out, not duplicate source items. Aggregate payments to order grain before joining them to item-level metrics. |

### Referential integrity

| Problem | Detection query | Affected rows | Decision and reason |
|---|---|---:|---|
| Orphan orders, items, payments, or reviews across declared foreign keys | `03_referential_integrity.sql`, six declared relationships | 0 orphan rows in every relationship | No referential-integrity violations were found in the loaded rows. |
| Product categories without an English translation | `03_referential_integrity.sql`, product-to-translation anti-join | 13 products: `portateis_cozinha_e_preparadores_de_alimentos` (10) and `pc_gamer` (3) | Keep the products. Add verified translation mappings or preserve the source category in downstream models; do not drop unmatched products. |

### Value validation

| Problem | Detection query | Affected rows | Decision and reason |
|---|---|---:|---|
| Negative item prices or zero item prices | `04_value_validation.sql` | 0 negative; 0 zero | No issue observed. |
| Negative freight or zero freight | `04_value_validation.sql` | 0 negative; 383 zero | Zero freight may represent free shipping. Preserve it unless source/business rules establish otherwise. |
| Negative payment values or zero payment values | `04_value_validation.sql` | 0 negative; 9 zero | The zero-value rows use `voucher` or `not_defined`. These may represent voucher/payment artifacts; retain and investigate before excluding them from payment analysis. |
| Payment installments below one | `04_value_validation.sql`, including examples | 2 rows, both zero-installment credit-card payments with positive values (129.94 and 58.69) | Suspicious because the payment values are nonzero. Verify source semantics before correcting or excluding them. |
| Invalid item/payment sequence, product dimensions/counts, review scores, geographic coordinates, ZIP prefixes, state codes, or blank location fields | `04_value_validation.sql` | 0 across the checks | No invalid values were observed for these rules. Review-score range is also constrained by the schema. |

### Date validation

| Problem | Detection query | Affected rows | Decision and reason |
|---|---|---:|---|
| Carrier handoff before payment approval | `05_date_validation.sql` | 1,359 | Chronology is inconsistent under the recorded event definitions. Verify source timestamps before changing them; this can distort fulfillment lead-time metrics. |
| Carrier handoff before order purchase | `05_date_validation.sql` | 166 | Impossible under the expected event order. Investigate source records; do not reorder timestamps automatically. |
| Customer delivery before carrier handoff | `05_date_validation.sql` | 23 | Delivery chronology is inconsistent. Review source event semantics and preserve raw values pending verification. |
| Review created before its order was purchased | `05_date_validation.sql` | 74 | The review and order timeline do not agree. Verify review/order association before using these rows in timing analyses. |
| Delivered orders missing customer delivery timestamps | `05_date_validation.sql` and `01_null_checks.sql` | 8 | Status/date mismatch; investigate before calculating delivery duration. |
| Non-delivered orders with customer delivery timestamps | `05_date_validation.sql` | 6; all are canceled orders in the returned examples | Status/date mismatch; preserve both fields and resolve from authoritative source data before deriving delivered-order metrics. |
| Delivered after estimated date | `05_date_validation.sql` | 7,827 | This is late-delivery performance, not an invalid date. Keep it as a service KPI rather than treating it as a data defect. |
| Future timestamps; approval before purchase; delivery before purchase; estimated delivery before purchase; shipping limit before purchase; review answer before review creation | `05_date_validation.sql` | 0 for each check | No violations were observed as of 2026-11-09. Future-date checks are time-dependent. |

## Conclusion and next steps

The declared relationships and primary keys are sound in the loaded data, but
the investigation identified date/status inconsistencies, repeated raw
geolocation records, repeated review IDs, 13 untranslated product categories,
and two zero-installment payments. Optional feedback and many status-related
NULLs appear to be expected. Zero freight and zero voucher/undefined payments
may also be legitimate.

No cleaning was applied, in accordance with Phase 5. Carry these findings into
the staging phase: preserve raw values and lineage, handle expected missingness
explicitly, and make any corrections only after confirming the source meaning.
