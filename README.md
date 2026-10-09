
# E-Commerce Customer & Revenue Analytics

> An end-to-end PostgreSQL analytics project exploring e-commerce revenue, customer behavior, product performance, seller performance, delivery operations, and customer satisfaction using advanced SQL.

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED)
![SQL](https://img.shields.io/badge/SQL-Advanced-orange)
![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)

---

## Table of Contents

* [Project Overview](#project-overview)
* [Business Problem](#business-problem)
* [Objectives](#objectives)
* [Dataset](#dataset)
* [Technology Stack](#technology-stack)
* [Architecture](#architecture)
* [Database Structure](#database-structure)
* [Analytical Questions](#analytical-questions)
* [SQL Skills Demonstrated](#sql-skills-demonstrated)
* [Data Quality](#data-quality)
* [Advanced Analytics](#advanced-analytics)
* [Project Structure](#project-structure)
* [Getting Started](#getting-started)
* [Analysis Areas](#analysis-areas)
* [Key Findings](#key-findings)
* [Business Recommendations](#business-recommendations)
* [Performance & Optimization](#performance--optimization)
* [Testing](#testing)
* [Limitations](#limitations)
* [Future Improvements](#future-improvements)
* [Author](#author)

---

# Project Overview

This project is a comprehensive SQL analytics case study built with **PostgreSQL** and **Docker**.

The goal is to simulate a real-world e-commerce analytics environment where a company wants to understand its customers, revenue, products, sellers, logistics operations, and customer satisfaction.

Rather than performing a small collection of isolated SQL exercises, this project follows a complete analytical workflow:

```text
Raw Data
    │
    ▼
PostgreSQL
    │
    ▼
Data Validation
    │
    ▼
Data Cleaning & Staging
    │
    ▼
Exploratory SQL
    │
    ▼
Business Analysis
    │
    ├── Revenue
    ├── Customers
    ├── Products
    ├── Sellers
    ├── Delivery
    ├── Reviews
    └── Geography
    │
    ▼
Advanced Analytics
    │
    ├── RFM Segmentation
    ├── Cohort Analysis
    ├── Retention
    ├── Customer Lifetime Value
    └── Revenue Concentration
    │
    ▼
Analytical Views
    │
    ▼
Reporting / Dashboard
```

The primary objective is to demonstrate the ability to use SQL to solve realistic analytical problems rather than simply demonstrate SQL syntax.

---

# Business Problem

An e-commerce company has accumulated transactional data from customers, orders, products, sellers, payments, reviews, and logistics operations.

Management wants to understand:

* How is revenue changing over time?
* Which products and categories generate the most revenue?
* Who are the most valuable customers?
* How many customers return after their first purchase?
* Which customers are at risk of becoming inactive?
* Which sellers perform best?
* Which regions generate the most revenue?
* How efficient is the delivery operation?
* Does delivery performance affect customer satisfaction?
* How concentrated is revenue among high-value customers?

The objective of this project is to answer these questions using PostgreSQL and produce reproducible, documented analysis.

---

# Objectives

The project aims to demonstrate practical ability in:

### Database Engineering

* Relational database design
* PostgreSQL
* Database schemas
* Primary and foreign keys
* Constraints
* Indexes
* Views
* Materialized views

### SQL

* Complex JOINs
* Aggregations
* CTEs
* Subqueries
* Correlated subqueries
* CASE expressions
* Conditional aggregation
* Date/time analysis
* Window functions
* Ranking
* Running totals
* Rolling averages
* LAG / LEAD
* Percentiles
* Cohort analysis
* RFM segmentation

### Data Quality

* NULL analysis
* Duplicate detection
* Referential integrity
* Date validation
* Value validation
* Consistency checks

### Analytics

* Revenue analysis
* Customer analytics
* Product analytics
* Seller analytics
* Logistics analytics
* Customer satisfaction
* Retention
* Customer lifetime value

### Engineering & Professional Practice

* Docker
* Git
* GitHub
* Reproducible environments
* SQL project organization
* Documentation
* Testing
* Query optimization

---

# Dataset

The project uses the **Brazilian E-Commerce Public Dataset by Olist**.

The dataset contains approximately 100,000 orders and multiple related datasets covering:

* Customers
* Orders
* Order items
* Products
* Sellers
* Payments
* Reviews
* Geographical information

The relational structure makes the dataset suitable for demonstrating complex SQL joins and analytical workflows.

The Docker Compose setup downloads and extracts the dataset automatically if its CSV files are not present in `data/`.

The imported tables are available in the PostgreSQL `olist` schema. Raw source data is kept in `data/` and is not needed in Git.

---

# Technology Stack

| Technology          | Purpose                                   |
| ------------------- | ----------------------------------------- |
| PostgreSQL          | Relational database and analytical engine |
| SQL                 | Data transformation and analysis          |
| Docker              | Reproducible PostgreSQL environment       |
| Docker Compose      | Container orchestration                   |
| Git                 | Version control                           |
| GitHub              | Portfolio and project hosting             |
| Python              | Optional supporting analysis              |
| Power BI / Metabase | Optional visualization layer              |

The analytical core of the project is PostgreSQL and SQL.

---

# Architecture

The project follows a layered database architecture.

```text
                    ┌─────────────────────┐
                    │      Raw Data       │
                    │       CSVs          │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    RAW Schema       │
                    │ Original structures  │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  STAGING Schema     │
                    │ Cleaned / Standard  │
                    │      Structures      │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │ ANALYTICS Schema    │
                    │ Business-ready      │
                    │ analytical models   │
                    └──────────┬──────────┘
                               │
                 ┌─────────────┼─────────────┐
                 ▼             ▼             ▼
             SQL Analysis   Views        Dashboard
```

This separation makes the project easier to understand, test, maintain, and reproduce.

---

# Database Structure

The main entities include:

```text
Customers
    │
    │
    ▼
Orders ──────────── Payments
    │
    ├────────────── Reviews
    │
    └────────────── Order Items
                         │
                         ├──────── Products
                         │
                         └──────── Sellers
```

A more detailed schema and entity relationship diagram will be documented in:

```text
docs/database_schema.md
```

---

# Analytical Questions

## Revenue

* What is total revenue?
* How has revenue changed over time?
* What is monthly revenue?
* What is the month-over-month growth rate?
* What is the average order value?
* Which product categories generate the most revenue?
* Which states generate the most revenue?
* What percentage of revenue comes from the top products?

---

## Customers

* How many unique customers are there?
* How many orders does each customer make?
* What is average customer spend?
* Who are the highest-value customers?
* What percentage of customers make repeat purchases?
* What is the average time between purchases?
* Which regions have the highest-value customers?

---

## Customer Segmentation

Customers will be segmented using behavioral metrics including:

```text
Recency
Frequency
Monetary Value
```

The project will implement an RFM framework to identify segments such as:

```text
Champions
Loyal Customers
Potential Loyalists
At Risk
Lost Customers
```

---

## Customer Retention

The project will investigate:

* First purchase behavior
* Repeat purchases
* Customer retention
* Cohort performance
* Monthly retention
* Customer lifecycle

---

## Customer Lifetime Value

Customer-level metrics will be used to estimate customer lifetime value.

The methodology and assumptions will be explicitly documented rather than treating CLV as a single universally correct formula.

---

## Products

* Top products by revenue
* Top products by units sold
* Product category performance
* Average product price
* Product review performance
* High-sales / low-rating products
* Revenue concentration

---

## Sellers

* Top sellers by revenue
* Top sellers by order volume
* Average seller order value
* Seller delivery performance
* Seller cancellation rates
* Seller review performance

---

## Logistics

* Average delivery time
* Median delivery time
* Late delivery rate
* Delivery performance by region
* Delivery performance by seller
* Delivery performance by product category

---

## Customer Satisfaction

* Average review score
* Review score distribution
* Review score by product category
* Review score by seller
* Review score by region
* Relationship between delivery performance and review score

---

# SQL Skills Demonstrated

The project intentionally progresses from fundamental SQL to advanced analytical SQL.

## Fundamental SQL

```text
SELECT
WHERE
ORDER BY
DISTINCT
GROUP BY
HAVING
CASE
COALESCE
NULLIF
```

## Joins

```text
INNER JOIN
LEFT JOIN
RIGHT JOIN
FULL OUTER JOIN
SELF JOIN
```

## Aggregation

```text
COUNT
SUM
AVG
MIN
MAX
COUNT DISTINCT
Conditional aggregation
```

## Intermediate SQL

```text
Subqueries
Correlated subqueries
Common Table Expressions
UNION
INTERSECT
EXCEPT
Date/time functions
String functions
```

## Advanced SQL

```text
Window functions
ROW_NUMBER
RANK
DENSE_RANK
NTILE
LAG
LEAD
Running totals
Rolling averages
Percentiles
Top-N analysis
Cohort analysis
RFM segmentation
Pareto analysis
```

---

# Data Quality

Data quality is treated as part of the analytical process rather than an afterthought.

The project includes checks for:

### Completeness

* NULL values
* Missing timestamps
* Missing identifiers

### Uniqueness

* Duplicate primary keys
* Duplicate business records

### Validity

* Invalid prices
* Invalid review scores
* Invalid dates
* Impossible delivery durations

### Consistency

* Customer/order relationships
* Order/order-item relationships
* Product relationships
* Seller relationships

### Referential Integrity

The project verifies that records reference valid entities.

All significant data quality issues will be documented with:

```text
Issue
Detection method
Affected records
Treatment
Reasoning
```

---

# Advanced Analytics

The project goes beyond descriptive statistics.

## RFM Segmentation

Customers will be scored using:

```text
Recency
Frequency
Monetary Value
```

This will produce actionable customer segments.

---

## Cohort Analysis

Customers will be grouped according to their first purchase month.

Retention will then be tracked across subsequent months.

Example:

```text
             Month 0   Month 1   Month 2   Month 3
Jan Cohort     100%      42%       31%       25%
Feb Cohort     100%      39%       28%        ...
Mar Cohort     100%      45%        ...        ...
```

---

## Customer Lifetime Value

Customer-level purchase behavior will be used to estimate lifetime value.

The calculation methodology and assumptions will be documented in the technical report.

---

## Revenue Concentration

The project will investigate whether a small percentage of customers or products generate a disproportionate percentage of revenue.

This will include Pareto-style analysis.

---

# Project Structure

```text
ecommerce-sql-analytics/
│
├── README.md
├── ROADMAP.md
├── docker-compose.yml
├── .env.example
├── .gitignore
│
├── data/
│   ├── raw/
│   └── README.md
│
├── sql/
│   ├── 01_database/
│   ├── 02_raw/
│   ├── 03_staging/
│   ├── 04_quality/
│   ├── 05_analytics/
│   ├── 06_advanced_analytics/
│   ├── 07_views/
│   ├── 08_indexes/
│   └── 09_performance/
│
├── tests/
│
├── docs/
│   ├── data_dictionary.md
│   ├── database_schema.md
│   └── methodology.md
│
├── reports/
│   ├── executive_summary.md
│   └── technical_report.md
│
├── notebooks/
│
└── dashboard/
```

---

# Getting Started

## Prerequisites

Install:

* Docker
* Docker Compose
* Git
* PostgreSQL client or database GUI

A GUI such as DBeaver can be used for development, but all important transformations and analyses should remain reproducible through SQL files.

---

## 1. Clone the Repository

```bash
git clone <repository-url>
cd ecommerce-sql-analytics
```

---

## 2. Start PostgreSQL and Load the Dataset

```bash
docker compose up --build -d && docker compose wait loader
```

Compose starts PostgreSQL, downloads and extracts the dataset if needed, creates the `olist` tables and relationships, and imports the CSV data. The command waits until loading is complete; PostgreSQL remains running.

The equivalent bootstrap script is:

```bash
bash download.sh
```

Check service status and loader output:

```bash
docker compose ps
docker compose logs loader
```

## 3. Connect to PostgreSQL

Defaults: host `localhost`, port `5432`, database `olist_analytics`, username `olist`, password `olist`. Override these with `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` environment variables.

---

## 4. Run the Analysis

The SQL files are organized according to the analytical workflow.

Start with:

```text
sql/01_database/
```

then:

```text
sql/02_raw/
sql/03_staging/
sql/04_quality/
sql/05_analytics/
sql/06_advanced_analytics/
```

---

# Analysis Areas

| Area      | Main Questions                     | SQL Techniques                 |
| --------- | ---------------------------------- | ------------------------------ |
| Revenue   | How much are we selling?           | Aggregations, CTEs, windows    |
| Customers | Who buys from us?                  | Joins, CTEs                    |
| Retention | Do customers return?               | Cohorts, windows               |
| RFM       | Who are our best customers?        | NTILE, CASE, CTEs              |
| Products  | What sells?                        | Ranking, aggregation           |
| Sellers   | Who performs best?                 | Ranking, joins                 |
| Logistics | Where are operational problems?    | Date analysis                  |
| Reviews   | Are customers satisfied?           | Aggregation, conditional logic |
| Geography | Where is the business strongest?   | GROUP BY, joins                |
| CLV       | Which customers are most valuable? | Multi-stage CTEs               |

---

# Key Findings

> **Status: To be completed after analysis.**

The final project will document the most important discoveries here.

Example format:

### Finding 1 — Revenue Concentration

**Finding:**
[Insert result]

**Evidence:**
[Insert SQL query / metric]

**Business implication:**
[Explain why this matters]

---

### Finding 2 — Customer Retention

**Finding:**
[Insert result]

**Evidence:**
[Insert cohort analysis]

**Business implication:**
[Explain why this matters]

---

### Finding 3 — Delivery Performance

**Finding:**
[Insert result]

**Evidence:**
[Insert analysis]

**Business implication:**
[Explain why this matters]

---

# Business Recommendations

> **Status: To be completed after analysis.**

Recommendations will be based directly on analytical findings.

Potential areas include:

* Customer retention
* High-value customer targeting
* Product strategy
* Seller management
* Logistics optimization
* Regional expansion
* Customer experience

Recommendations will not be made without supporting evidence from the analysis.

---

# Performance & Optimization

The project also investigates PostgreSQL query performance.

The analysis will use:

```sql
EXPLAIN
EXPLAIN ANALYZE
```

to understand query execution.

Topics include:

* Sequential scans
* Index scans
* Join strategies
* Aggregation costs
* Sorting
* Index selection
* Query optimization

Performance experiments will be documented rather than simply adding indexes without justification.

---

# Testing

The project includes SQL-based data quality and analytical tests.

Examples include:

```text
Primary key uniqueness
Foreign key validity
NULL expectations
Date validity
Value ranges
Relationship consistency
Revenue consistency
Analytical output validation
```

Tests should produce predictable results.

For example:

```text
Expected:
0 duplicate customer IDs

Actual:
0
```

---

# Reporting

The project will contain two main reports.

## Executive Summary

Designed for a business audience.

Contains:

* Key KPIs
* Major findings
* Business implications
* Recommendations

Located at:

```text
reports/executive_summary.md
```

---

## Technical Report

Designed for a technical audience.

Contains:

* Architecture
* Data model
* Data quality methodology
* SQL techniques
* Analytical methodology
* Performance optimization
* Testing
* Limitations

Located at:

```text
reports/technical_report.md
```

---

# Dashboard

A dashboard may be developed using:

* Power BI
* Tableau
* Metabase

The dashboard will consume analytical views from PostgreSQL rather than directly reproducing all transformations inside the BI tool.

Potential dashboard pages:

```text
Executive Overview
Customer Analytics
Product Analytics
Seller Analytics
Operations
Customer Satisfaction
```

---

# Limitations

The dataset has limitations that should be considered when interpreting the results.

Potential limitations include:

* Historical data rather than real-time transactions
* Observational rather than experimental data
* Limited information about marketing campaigns
* Limited customer demographic information
* Potential data-quality issues
* Customer behavior observed only within the available time period

The project will clearly distinguish between:

```text
Correlation
vs.
Causation
```

No causal claims will be made without appropriate evidence.

---

# Future Improvements

Potential future extensions include:

* Automated data ingestion
* Scheduled SQL pipelines
* dbt implementation
* Automated data quality testing
* Airflow orchestration
* Customer churn prediction
* Product recommendation modeling
* Customer lifetime value prediction
* Demand forecasting
* Advanced statistical analysis
* Machine learning models using SQL-generated features

These extensions are intentionally outside the core project so that the SQL analytics foundation remains clear.

---

# Portfolio Goals

This project is designed to demonstrate that I can:

1. Work with a relational database.
2. Design and understand relational data models.
3. Load and validate real-world data.
4. Write complex SQL queries.
5. Use advanced PostgreSQL functionality.
6. Perform data quality analysis.
7. Build reusable analytical datasets.
8. Analyze customer behavior.
9. Perform business-oriented analysis.
10. Communicate analytical findings.
11. Optimize database queries.
12. Build reproducible data projects.

The goal is not simply to demonstrate that I know SQL syntax.

The goal is to demonstrate that I can use SQL as a **professional analytical tool**.

---

# Author

**[Your Name]**

Data Science Student

### Skills Demonstrated

```text
Python
SQL
PostgreSQL
Docker
Data Analysis
Statistics
Data Visualization
Machine Learning
Git/GitHub
```

---

# License

This project is intended for educational and portfolio purposes.

Dataset licensing and attribution should follow the terms of the original dataset provider.

---

# Project Status

🚧 **In Progress**

The project is being developed incrementally following the roadmap in [`ROADMAP.md`](ROADMAP.md).
