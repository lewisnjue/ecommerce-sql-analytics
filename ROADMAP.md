
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

# 4. Repository Structure

The target repository structure is:

```text
ecommerce-sql-analytics/
│
├── README.md
├── ROADMAP.md
├── LICENSE
├── .gitignore
├── .env.example
├── docker-compose.yml
│
├── docker/
│   └── postgres/
│       └── init/
│
├── data/
│   ├── raw/
│   └── README.md
│
├── sql/
│   │
│   ├── 01_database/
│   │   ├── 01_create_database.sql
│   │   ├── 02_create_schemas.sql
│   │   └── 03_create_extensions.sql
│   │
│   ├── 02_raw/
│   │   ├── 01_create_raw_tables.sql
│   │   └── 02_load_raw_data.sql
│   │
│   ├── 03_staging/
│   │   ├── 01_stg_customers.sql
│   │   ├── 02_stg_orders.sql
│   │   ├── 03_stg_order_items.sql
│   │   ├── 04_stg_products.sql
│   │   ├── 05_stg_sellers.sql
│   │   ├── 06_stg_payments.sql
│   │   └── 07_stg_reviews.sql
│   │
│   ├── 04_quality/
│   │   ├── 01_null_checks.sql
│   │   ├── 02_duplicate_checks.sql
│   │   ├── 03_referential_integrity.sql
│   │   ├── 04_value_validation.sql
│   │   └── 05_date_validation.sql
│   │
│   ├── 05_analytics/
│   │   ├── 01_exploration.sql
│   │   ├── 02_revenue.sql
│   │   ├── 03_customers.sql
│   │   ├── 04_products.sql
│   │   ├── 05_sellers.sql
│   │   ├── 06_delivery.sql
│   │   ├── 07_reviews.sql
│   │   └── 08_geography.sql
│   │
│   ├── 06_advanced_analytics/
│   │   ├── 01_rfm.sql
│   │   ├── 02_cohort_analysis.sql
│   │   ├── 03_retention.sql
│   │   ├── 04_customer_lifetime_value.sql
│   │   ├── 05_revenue_concentration.sql
│   │   └── 06_product_affinity.sql
│   │
│   ├── 07_views/
│   │   ├── customer_summary.sql
│   │   ├── product_summary.sql
│   │   ├── seller_summary.sql
│   │   └── monthly_kpis.sql
│   │
│   ├── 08_indexes/
│   │   └── analytical_indexes.sql
│   │
│   └── 09_performance/
│       ├── explain_examples.sql
│       └── optimization.sql
│
├── tests/
│   ├── test_data_quality.sql
│   ├── test_relationships.sql
│   └── test_analytics.sql
│
├── reports/
│   ├── executive_summary.md
│   └── technical_report.md
│
├── docs/
│   ├── data_dictionary.md
│   ├── database_schema.md
│   └── methodology.md
│
├── notebooks/
│   └── optional_analysis.ipynb
│
└── dashboard/
    └── README.md
```

The exact structure can evolve as the project develops.

---

# 5. Phase 1 — Project Setup

## Goals

Create a reproducible PostgreSQL development environment.

### Tasks

* [ ] Create Git repository
* [ ] Initialize project structure
* [ ] Create `.gitignore`
* [ ] Create `.env.example`
* [ ] Create Docker Compose configuration
* [ ] Run PostgreSQL inside Docker
* [ ] Connect to PostgreSQL
* [ ] Verify database persistence
* [ ] Document how another person can start the project

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

# 6. Phase 2 — Understand the Dataset

Before writing SQL, understand the data.

### Tasks

* [ ] Download the dataset
* [ ] Identify all source files
* [ ] Understand each column
* [ ] Identify primary keys
* [ ] Identify foreign keys
* [ ] Identify relationships
* [ ] Determine data types
* [ ] Identify missing values
* [ ] Identify possible duplicate records
* [ ] Identify timestamp fields
* [ ] Identify categorical fields
* [ ] Document assumptions

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

# 7. Phase 3 — Design the Database

Create a proper relational database.

The project should distinguish between:

```text
raw
staging
analytics
```

For example:

```text
raw.orders
staging.orders
analytics.customer_summary
```

### Tasks

* [ ] Create schemas
* [ ] Create raw tables
* [ ] Define data types
* [ ] Define primary keys
* [ ] Define foreign keys where appropriate
* [ ] Define constraints
* [ ] Document relationships
* [ ] Create an ERD

### Deliverable

```text
docs/database_schema.md
```

---

# 8. Phase 4 — Load Raw Data

Load the original data into PostgreSQL without unnecessarily transforming it.

### Tasks

* [ ] Load customers
* [ ] Load orders
* [ ] Load order items
* [ ] Load products
* [ ] Load sellers
* [ ] Load payments
* [ ] Load reviews
* [ ] Load geographic data
* [ ] Verify row counts

### Required validation

For every table:

```sql
SELECT COUNT(*)
FROM table_name;
```

Compare database row counts against the source files.

Document discrepancies.

---

# 9. Phase 5 — Data Quality Investigation

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

Create a formal data quality report.

Document:

```text
Problem
Detection query
Number of affected rows
Decision
Reason
```

---

# 10. Phase 6 — Staging Layer

Create cleaned/staged tables.

The staging layer should:

* Normalize data types
* Standardize column names
* Handle obvious data-quality issues
* Convert timestamps appropriately
* Create useful derived fields
* Preserve traceability to raw data

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

# 11. Phase 7 — Exploratory SQL

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

# 12. Phase 8 — Revenue Analysis

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

# 13. Phase 9 — Customer Analysis

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

# 14. Phase 10 — Customer Segmentation

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

# 15. Phase 11 — Cohort Analysis

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

# 16. Phase 12 — Customer Lifetime Value

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

# 17. Phase 13 — Product Analysis

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

# 18. Phase 14 — Seller Analysis

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

# 19. Phase 15 — Delivery & Logistics Analysis

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

# 20. Phase 16 — Customer Satisfaction

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

# 21. Phase 17 — Advanced SQL

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

# 22. Phase 18 — Analytical Views

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

# 23. Phase 19 — Indexing & Query Performance

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

# 24. Phase 20 — SQL Testing

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

# 25. Phase 21 — KPI Layer

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

# 26. Phase 22 — Dashboard

Optional but strongly recommended.

Build a simple dashboard using:

* Power BI
* Tableau
* Metabase

The dashboard should use PostgreSQL analytical views rather than raw tables.

Recommended pages:

### Executive Overview

* Revenue
* Orders
* Customers
* AOV
* Revenue trend

### Customer Analytics

* New vs repeat customers
* RFM segments
* Cohort retention
* Customer value

### Product Analytics

* Category revenue
* Top products
* Product ratings

### Operations

* Delivery performance
* Seller performance
* Regional performance

The dashboard is supplementary.

The SQL remains the core project.

---

# 27. Phase 23 — Executive Report

Create:

```text
reports/executive_summary.md
```

The report should contain:

## Executive Summary

What did the analysis discover?

## Key Findings

List the most important findings.

## Business Impact

Why do the findings matter?

## Recommendations

What should the company do?

## Limitations

What cannot be concluded from the dataset?

Avoid reporting statistics without interpretation.

---

# 28. Phase 24 — Technical Report

Create:

```text
reports/technical_report.md
```

Document:

* Dataset
* Architecture
* Database design
* Data ingestion
* Data cleaning
* Data quality
* SQL methodology
* Analytical models
* Advanced SQL techniques
* Performance optimization
* Testing
* Limitations

---

# 29. Phase 25 — Documentation

Complete:

```text
README.md
ROADMAP.md
docs/data_dictionary.md
docs/database_schema.md
docs/methodology.md
reports/executive_summary.md
reports/technical_report.md
```

Someone unfamiliar with the project should be able to reproduce it.

---

# 30. Phase 26 — Git & GitHub

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

# 31. Phase 27 — Final Portfolio Review

Before considering the project complete:

### Database

* [ ] PostgreSQL runs through Docker
* [ ] Database can be recreated
* [ ] Data can be loaded
* [ ] Relationships are documented

### SQL

* [ ] Basic SQL
* [ ] Joins
* [ ] Aggregations
* [ ] CTEs
* [ ] Subqueries
* [ ] Window functions
* [ ] Date analysis
* [ ] Conditional aggregation
* [ ] Ranking
* [ ] Cohorts
* [ ] RFM
* [ ] CLV
* [ ] Performance analysis

### Data Quality

* [ ] NULL checks
* [ ] Duplicate checks
* [ ] Referential integrity
* [ ] Date validation
* [ ] Value validation

### Analytics

* [ ] Revenue
* [ ] Customers
* [ ] Products
* [ ] Sellers
* [ ] Delivery
* [ ] Reviews
* [ ] Geography

### Engineering

* [ ] Docker
* [ ] Git
* [ ] Reproducible setup
* [ ] Environment variables
* [ ] Organized SQL files
* [ ] Tests
* [ ] Documentation

### Communication

* [ ] Executive summary
* [ ] Technical report
* [ ] Dashboard
* [ ] Business recommendations
* [ ] Limitations

---

# 32. Definition of Done

The project is complete when a recruiter can clone the repository, start PostgreSQL with Docker, load the dataset, inspect the database, read the SQL, understand the analytical methodology, reproduce the analysis, and understand the business conclusions without needing to contact me.

The final project should demonstrate:

> **I don't just know SQL syntax. I can use SQL to work with a relational database, validate data, build analytical datasets, perform sophisticated analysis, optimize queries, and communicate business insights.**
