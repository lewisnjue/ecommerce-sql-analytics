
# E-Commerce SQL Analytics — Project Roadmap

> A comprehensive PostgreSQL analytics project designed to demonstrate practical SQL, relational database, data quality, analytical thinking, and business intelligence skills.

---

## 1. Project Overview

This project analyzes a Brazilian e-commerce dataset containing information about:

* Customers
* Orders
* Order items
* Products
* Sellers
* Payments
* Reviews
* Geographical information

The project will simulate a real-world analytics workflow in which an e-commerce company provides transactional data and asks for insights into:

* Revenue
* Customer behavior
* Customer retention
* Product performance
* Seller performance
* Delivery performance
* Customer satisfaction
* Geographic performance
* Revenue concentration
* Customer segmentation

The primary technology will be **PostgreSQL**, running inside **Docker**.

The project will intentionally emphasize **raw SQL** rather than hiding transformations behind high-level tools.

---

# 2. Project Objectives

By completing this project, I should be able to demonstrate practical knowledge of:

### PostgreSQL

* Database creation
* Schemas
* Tables
* Data types
* Primary keys
* Foreign keys
* Constraints
* Indexes
* Views
* Materialized views
* Transactions
* Query planning
* PostgreSQL-specific functions

### SQL

* SELECT
* WHERE
* ORDER BY
* GROUP BY
* HAVING
* DISTINCT
* CASE
* NULL handling
* Aggregate functions
* Date/time operations
* String operations
* JOINs
* Subqueries
* CTEs
* Recursive CTEs where appropriate
* Window functions
* Ranking
* Running totals
* Rolling averages
* LAG / LEAD
* Percentiles
* Conditional aggregation
* Set operations
* Correlated subqueries

### Data Engineering / Analytics Engineering

* Loading raw data
* Data validation
* Data cleaning
* Staging tables
* Analytical models
* Data lineage
* Reusable SQL transformations
* Data quality checks
* Documentation

### Analytics

* KPI development
* Revenue analysis
* Customer analysis
* Product analysis
* Seller analysis
* Delivery analysis
* Review analysis
* Geographic analysis
* Cohort analysis
* Retention analysis
* RFM segmentation
* Customer Lifetime Value
* Revenue concentration
* Pareto analysis

### Professional Skills

* Git
* GitHub
* Docker
* Documentation
* SQL organization
* Reproducibility
* Analytical storytelling
* Business recommendations

---

# 3. Technology Stack

## Core

* PostgreSQL
* SQL
* Docker
* Docker Compose
* Git
* GitHub

## Optional

* Python
* pandas
* Jupyter
* Power BI
* Metabase
* DBeaver
* pgAdmin

Python should not replace SQL.

The main analytical transformations should be performed in PostgreSQL.

---

# 4. Phase 1 — Project Setup

## Goals

Create a reproducible PostgreSQL development environment.

### Tasks

* [ done ] Create Git repository
* [ done ] Initialize project structure
* [ done  ] Create `.gitignore`
* [ done ] Create `.env.example`
* [ done ] Create Docker Compose configuration
* [ done] Run PostgreSQL inside Docker
* [ done] Connect to PostgreSQL
* [ done] Verify database persistence
* [ done] Document how another person can start the project

### Deliverables

```text
docker-compose.yml
.env.example
README.md
ROADMAP.md
```

### Skills practiced

* Docker
* PostgreSQL
* Environment variables
* Git
* Repository organization

---

# 5. Phase 2 — Understand the Dataset

Before writing SQL, understand the data.

### Tasks

* [ done] Download the dataset
* [ done] Identify all source files
* [ done] Understand each column
* [ done] Identify primary keys
* [ done] Identify foreign keys
* [ done] Identify relationships
* [ done] Determine data types
* [ done] Identify missing values
* [ done] Identify possible duplicate records
* [ done] Identify timestamp fields
* [ done] Identify categorical fields
* [ done] Document assumptions

### Deliverable

Create:

```text
docs/data_dictionary.md
```

The data dictionary should contain:

| Column       | Data Type | Description             | Nullable | Key |
| ------------ | --------- | ----------------------- | -------- | --- |
| order_id     | UUID/Text | Unique order identifier | No       | PK  |
| customer_id  | UUID/Text | Customer identifier     | No       | FK  |
| order_status | Text      | Current order status    | No       | -   |

---

# 6. Phase 3 — Design the Database

Create a proper relational database.

The project separates unchanged source data, standardized staging tables, and
analytics. Source tables currently reside in PostgreSQL's `public` schema:

```text
public (source/raw)
staging
analytics
```

For example:

```text
public.orders
staging.orders
analytics.customer_summary
```

### Tasks

* [x] Create schemas
* [x] Create source tables
* [x] Define data types
* [x] Define primary keys
* [x] Define foreign keys where appropriate
* [x] Define constraints
* [x] Document relationships
* [x] Create an ERD

### Deliverable

```text
docs/database_schema.md
```

---

# 7. Phase 4 — Load Raw Data

Load the original data into PostgreSQL without unnecessarily transforming it.

### Tasks

* [x] Load customers
* [x] Load orders
* [x] Load order items
* [x] Load products
* [x] Load sellers
* [x] Load payments
* [x] Load reviews
* [x] Load geographic data
* [x] Verify row counts

### Required validation

For every table:

```sql
SELECT COUNT(*)
FROM table_name;
```

Compare database row counts against the source files.

Document discrepancies.

---

# 8. Phase 5 — Data Quality Investigation

Do not immediately clean the data.

First investigate it.

## Null Analysis

Identify:

* Missing values
* Columns with unusually high NULL rates
* Whether NULLs have business meaning

Example:

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(delivered_date) AS populated_dates,
    COUNT(*) - COUNT(delivered_date) AS missing_dates
FROM orders;
```

---

## Duplicate Analysis

Identify:

* Duplicate primary keys
* Duplicate business records
* Unexpected duplicates caused by joins

---

## Referential Integrity

Check whether:

```text
every order belongs to a customer
every order item belongs to an order
every order item references a product
every seller exists
```

---

## Value Validation

Investigate:

* Negative prices
* Zero prices
* Impossible quantities
* Invalid review scores
* Invalid dates
* Future dates
* Delivery before purchase

---

## Deliverable

Completed: [docs/data_quality_report.md](docs/data_quality_report.md). The report
records the problem, detection query, affected-row count, and decision without
cleaning the raw data.

Document:

```text
Problem
Detection query
Number of affected rows
Decision
Reason
```

---

# 9. Phase 6 — Staging Layer

**Status: Complete.** The typed staging tables and refresh workflow are
documented in [docs/staging_layer.md](docs/staging_layer.md).

The staging layer should:

* [x] Normalize data types
* [x] Standardize column names
* [x] Handle obvious data-quality issues without silently correcting source values
* [x] Preserve source timestamp semantics
* [x] Create useful derived fields
* [x] Preserve traceability to raw data

Example:

```sql
CREATE TABLE staging.orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp::timestamp AS purchase_timestamp
FROM raw.orders;
```

---

# 10. Phase 7 — Exploratory SQL

**Status: Complete.** Queries and findings are documented in
[docs/exploration.md](docs/exploration.md). The runnable exploration SQL is
[sql/05_analytics/01_exploration.sql](sql/05_analytics/01_exploration.sql).

Before sophisticated analytics, understand the data.

Investigate:

### Dataset size

* Number of customers
* Number of orders
* Number of products
* Number of sellers
* Number of reviews

### Time

* First order
* Last order
* Orders per month
* Orders per year

### Status

* Delivered
* Cancelled
* Unavailable
* Processing
* Shipped

### Geography

* Customers by state
* Sellers by state
* Revenue by state

### SQL skills

Use:

* SELECT
* WHERE
* GROUP BY
* HAVING
* ORDER BY
* CASE
* JOIN
* Aggregations

---

# 11. Phase 8 — Revenue Analysis

**Status: Complete.** Definitions, queries, results, and validation are
documented in [docs/revenue_analysis.md](docs/revenue_analysis.md); the
executable analysis is [sql/05_analytics/02_revenue.sql](sql/05_analytics/02_revenue.sql).

Answer:

1. What is total revenue?
2. What is revenue by month?
3. What is revenue by year?
4. What is average order value?
5. What is revenue by product category?
6. What is revenue by customer state?
7. What is revenue by seller?
8. What are the top products?
9. What percentage of revenue comes from top products?
10. How does revenue change over time?

### Advanced SQL

Implement:

* Monthly revenue
* Month-over-month growth
* Running revenue total
* Rolling average
* Revenue ranking

Use:

```text
LAG()
SUM() OVER()
AVG() OVER()
RANK()
DENSE_RANK()
```

---

# 12. Phase 9 — Customer Analysis

**Status: Complete.** Definitions, results, and validation are documented in
[docs/customer_analysis.md](docs/customer_analysis.md); the runnable analysis
is [sql/05_analytics/03_customers.sql](sql/05_analytics/03_customers.sql).

Analyze customer behavior.

Answer:

* How many unique customers are there?
* How many orders does each customer make?
* What is average customer spend?
* Who are the highest-value customers?
* What is the average order value per customer?
* What percentage of customers purchase more than once?
* How long between purchases?
* Which geographic regions have the highest-value customers?

---

# 13. Phase 10 — Customer Segmentation

**Status: Complete.** Methodology and results are documented in
[docs/customer_segmentation.md](docs/customer_segmentation.md); the runnable
segmentation is
[sql/05_analytics/04_customer_segmentation.sql](sql/05_analytics/04_customer_segmentation.sql).

Implement SQL-based segmentation.

At minimum:

```text
One-time customers
Repeat customers
High-value customers
Low-value customers
```

Then implement **RFM segmentation**.

### Recency

How recently did the customer purchase?

### Frequency

How frequently does the customer purchase?

### Monetary

How much did the customer spend?

Create segments such as:

```text
Champions
Loyal Customers
Potential Loyalists
At Risk
Lost Customers
```

Use:

* CTEs
* NTILE
* CASE
* Window functions

---

# 14. Phase 11 — Cohort Analysis

**Status: Complete.** Methodology and findings are documented in
[docs/cohort_analysis.md](docs/cohort_analysis.md); the runnable analysis is
[sql/05_analytics/05_cohort_analysis.sql](sql/05_analytics/05_cohort_analysis.sql).

Build customer cohorts based on first purchase month.

Example:

```text
Cohort Month
    ↓
First Purchase
    ↓
Month 0
Month 1
Month 2
Month 3
...
```

Calculate:

* Customer retention
* Cohort size
* Retention percentage
* Revenue by cohort

This should demonstrate advanced SQL and analytical thinking.

---

# 15. Phase 12 — Customer Lifetime Value

**Status: Complete.** CLV methodology and limitations are documented in
[docs/customer_lifetime_value.md](docs/customer_lifetime_value.md); SQL is in
[sql/05_analytics/06_customer_lifetime_value.sql](sql/05_analytics/06_customer_lifetime_value.sql).

Develop a practical customer lifetime value analysis.

Calculate metrics such as:

```text
total_orders
total_revenue
average_order_value
purchase_frequency
customer_lifespan
estimated_lifetime_value
```

Clearly document the methodology.

Do not present an arbitrary formula as "true CLV."

Explain the assumptions.

---

# 16. Phase 13 — Product Analysis

**Status: Complete.** Results and method are in
[docs/product_analysis.md](docs/product_analysis.md); runnable SQL is
[sql/05_analytics/07_products.sql](sql/05_analytics/07_products.sql).

Investigate:

* Best-selling products
* Highest-revenue products
* Lowest-performing products
* Revenue by category
* Average product price
* Average review score
* Products with high sales but poor ratings
* Products with low sales but high ratings

Implement:

* Product ranking
* Category ranking
* Revenue contribution
* Pareto analysis

---

# 17. Phase 14 — Seller Analysis

**Status: Complete.** Methodology and results are in
[docs/seller_analysis.md](docs/seller_analysis.md); runnable SQL is
[sql/05_analytics/08_sellers.sql](sql/05_analytics/08_sellers.sql).

Investigate:

* Seller revenue
* Orders per seller
* Average order value
* Seller ranking
* Cancellation rate
* Delivery performance
* Review performance

Create seller performance tiers.

Example:

```text
Top performers
Strong performers
Average performers
Underperformers
```

Document the classification methodology.

---

# 18. Phase 15 — Delivery & Logistics Analysis

**Status: Complete.** Results and caveats are documented in
[docs/delivery_analysis.md](docs/delivery_analysis.md); runnable SQL and
assertions are in [sql/05_analytics/09_delivery.sql](sql/05_analytics/09_delivery.sql)
and [tests/test_delivery.sql](tests/test_delivery.sql).

Calculate:

* Average delivery time
* Median delivery time
* Delivery time by region
* Delivery time by seller
* Late delivery rate
* Delivery performance by product category

Investigate:

> Does delivery performance affect customer satisfaction?

Compare:

```text
On-time deliveries
vs.
Late deliveries
```

against review scores.

---

# 19. Phase 16 — Customer Satisfaction

**Status: Complete.** Methodology and results are in
[docs/customer_satisfaction.md](docs/customer_satisfaction.md); runnable SQL
and checks are in
[sql/05_analytics/10_customer_satisfaction.sql](sql/05_analytics/10_customer_satisfaction.sql)
and [tests/test_customer_satisfaction.sql](tests/test_customer_satisfaction.sql).

Analyze:

* Average review score
* Review score distribution
* Review score by category
* Review score by seller
* Review score by state
* Review score over time
* Review score versus delivery time

Investigate relationships rather than merely reporting averages.

---

# 20. Phase 17 — Advanced SQL

**Status: Complete.** Examples and findings are documented in
[docs/advanced_sql.md](docs/advanced_sql.md); the runnable patterns and
assertions are in
[sql/06_advanced_analytics/01_advanced_sql.sql](sql/06_advanced_analytics/01_advanced_sql.sql)
and [tests/test_advanced_sql.sql](tests/test_advanced_sql.sql).

Create a dedicated advanced SQL section.

The project should contain examples of:

### CTEs

```sql
WITH customer_orders AS (...)
SELECT ...
```

### Recursive CTEs

Use only where they provide a meaningful example.

### Window functions

```text
ROW_NUMBER()
RANK()
DENSE_RANK()
NTILE()
LAG()
LEAD()
SUM() OVER()
AVG() OVER()
```

### Conditional aggregation

```sql
COUNT(*) FILTER (WHERE ...)
```

### Subqueries

### Correlated subqueries

### Percentiles

### Running totals

### Rolling averages

### Pareto analysis

### Top-N-per-group

### First/last event analysis

---

# 21. Phase 18 — Analytical Views

**Status: Complete.** View definitions and grain are documented in
[docs/analytics_views.md](docs/analytics_views.md); create and validate them
with [sql/07_views/01_create_analytics_views.sql](sql/07_views/01_create_analytics_views.sql)
and [tests/test_analytics_views.sql](tests/test_analytics_views.sql).

Create reusable views.

Examples:

```text
analytics.customer_summary
analytics.product_summary
analytics.seller_summary
analytics.monthly_revenue
analytics.customer_rfm
analytics.customer_cohorts
analytics.delivery_performance
analytics.monthly_kpis
```

These should become the main interface for downstream reporting.

---

# 22. Phase 19 — Indexing & Query Performance

**Status: Complete.** Benchmark results and tradeoffs are documented in
[docs/performance_analysis.md](docs/performance_analysis.md), with the plan
query in [sql/09_performance/01_explain_examples.sql](sql/09_performance/01_explain_examples.sql),
the measured index in [sql/08_indexes/01_analytical_indexes.sql](sql/08_indexes/01_analytical_indexes.sql),
and a result check in [tests/test_performance.sql](tests/test_performance.sql).

Do not only write queries.

Learn how PostgreSQL executes them.

Investigate:

```sql
EXPLAIN
EXPLAIN ANALYZE
```

Compare queries before and after indexing.

Investigate indexes on:

* Foreign keys
* Date columns
* Frequently filtered columns
* Frequently joined columns

Document:

```text
Query
Execution plan
Problem
Optimization
Result
```

Do not blindly create indexes.

Explain why each index exists.

---

# 23. Phase 20 — SQL Testing

**Status: Complete.** Test coverage and expected outcomes are documented in
[docs/sql_testing.md](docs/sql_testing.md); the complete suite runs with
[`bash tests/run_all.sh`](tests/run_all.sh).

Create basic analytical/data-quality tests.

Examples:

### Primary key uniqueness

```sql
SELECT
    customer_id,
    COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
```

Expected result:

```text
0 rows
```

### Null validation

### Foreign-key validation

### Revenue validation

### Date validation

### Relationship validation

Document expected results.

---

# 24. Phase 21 — KPI Layer

**Status: Complete.** Definitions, interpretations, and current values are in
[docs/kpi_layer.md](docs/kpi_layer.md); the reusable view and reconciliation
checks are in [sql/07_views/02_create_kpi_summary.sql](sql/07_views/02_create_kpi_summary.sql)
and [tests/test_kpis.sql](tests/test_kpis.sql).

Define a consistent KPI layer.

Potential KPIs:

```text
Total Revenue
Total Orders
Total Customers
Average Order Value
Revenue per Customer
Repeat Customer Rate
Customer Retention Rate
Cancellation Rate
Average Delivery Time
Late Delivery Rate
Average Review Score
Top Product Category
Top Customer Segment
```

Every KPI must have:

1. Definition
2. SQL calculation
3. Business interpretation

---

# 25. Phase 22 — Dashboard

**Status: Complete.**

Built a local Streamlit dashboard with Matplotlib and Seaborn charts. The app
uses the `analytics` reporting views and supports executive, customer, product,
and operations sections. Seven static PNG charts are generated into
`dashboard/images/` by a reproducible Python script.

Run the app and regenerate its charts using the commands in
[`dashboard/README.md`](dashboard/README.md). The dashboard is supplementary;
SQL remains the core project.

The app and chart export were smoke-tested against the live PostgreSQL
database, and all seven PNG outputs were generated.

---

# 26. Phase 23 — Executive Report

**Status: Complete.**

The executive summary, business impact, recommendations, and limitations are
documented in [reports/executive_summary.md](reports/executive_summary.md).

---

# 27. Phase 24 — Technical Report

**Status: Complete.**

Dataset, architecture, schema, ingestion, staging and quality decisions,
analytical methods, performance, tests, reproduction, and limitations are
documented in [reports/technical_report.md](reports/technical_report.md).

---

# 28. Phase 25 — Documentation

**Status: Complete.**

The README, roadmap, source data dictionary, database schema, analytical
methodology, executive summary, and technical report are complete. Local data
requirements and first-load behavior are documented in
[data/README.md](data/README.md). Together, these explain how to inspect and
reproduce the project without relying on undocumented analyst context.

---

# 29. Phase 26 — Git & GitHub

**Status: Readiness review complete.**

The current branch is `main` and tracks the configured `origin/main` remote.
Downloaded source data remains excluded from Git, while `data/README.md` is
included as project documentation. The completed phase deliverables remain
uncommitted; no commit was created because a commit was not requested.

Use meaningful commits.

Examples:

```text
feat: add PostgreSQL docker environment
feat: create raw database schema
feat: load Olist datasets
feat: add data quality checks
feat: add revenue analysis
feat: implement customer RFM segmentation
feat: implement cohort retention analysis
feat: add analytical views
perf: optimize customer aggregation queries
docs: add technical methodology
```

Avoid:

```text
update
stuff
changes
final
final2
```

---

# 30. Phase 27 — Final Portfolio Review

**Status: Complete.**

The database initialization was tested in a separate disposable PostgreSQL 14
container; all nine source-table row counts matched the populated project
database. The complete SQL suite passed, all four Streamlit sections ran
without app exceptions, and the seven chart files were generated and inspected.

Before considering the project complete:

### Database

* [x] PostgreSQL runs through Docker
* [x] Database can be recreated
* [x] Data can be loaded
* [x] Relationships are documented

### SQL

* [x] Basic SQL
* [x] Joins
* [x] Aggregations
* [x] CTEs
* [x] Subqueries
* [x] Window functions
* [x] Date analysis
* [x] Conditional aggregation
* [x] Ranking
* [x] Cohorts
* [x] RFM
* [x] CLV proxy
* [x] Performance analysis

### Data Quality

* [x] NULL checks
* [x] Duplicate checks
* [x] Referential integrity
* [x] Date validation
* [x] Value validation

### Analytics

* [x] Revenue
* [x] Customers
* [x] Products
* [x] Sellers
* [x] Delivery
* [x] Reviews
* [x] Geography

### Engineering

* [x] Docker
* [x] Git readiness reviewed
* [x] Reproducible setup
* [x] Environment variables for dashboard connection
* [x] Organized SQL files
* [x] Tests
* [x] Documentation

### Communication

* [x] Executive summary
* [x] Technical report
* [x] Dashboard
* [x] Business recommendations
* [x] Limitations

---

# 31. Definition of Done

The project is complete when a recruiter can clone the repository, start PostgreSQL with Docker, load the dataset, inspect the database, read the SQL, understand the analytical methodology, reproduce the analysis, and understand the business conclusions without needing to contact me.

The final project should demonstrate:

> **I don't just know SQL syntax. I can use SQL to work with a relational database, validate data, build analytical datasets, perform sophisticated analysis, optimize queries, and communicate business insights.**
