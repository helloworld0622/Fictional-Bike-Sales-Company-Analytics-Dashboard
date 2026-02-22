# Data Modeling Overview

This project follows a layered dbt modeling approach to transform AdventureWorks OLTP data into a clean, analytics-ready dimensional model.

The design separates **data standardization (staging)** from **business logic and metrics (marts)**, and enforces data quality through custom tests.

---

# Modeling Philosophy

- Raw data is preserved.
- Staging standardizes structure and cleans data.
- Business logic and metrics are defined only in marts.
- Power BI consumes marts directly (no downstream transformation logic).
- Data quality is enforced at the modeling layer.

---

# Layer 1 – Staging

The staging layer prepares source tables for dimensional modeling.

General principles:
- Rename fields to consistent naming conventions.
- Type casting and normalization.
- Minimal transformations.
- No business metrics defined here.

## Key Staging Models

### stg_customer
Standardizes customer identifiers for downstream joins.  
Preserves 1 row per `CustomerID`.

### stg_product
Standardizes product attributes required for product dimension and cost calculations.

### stg_reseller
Flattens Store + Geography tables and extracts `BusinessType` from XML.  
Main Office address is prioritized when available.

### stg_sales_order_header / stg_sales_order_detail
Standardizes order header and order line grain.  
Provides clean inputs for fact table construction.

---

# Layer 2 – Marts (Dimensional Model)

The marts layer defines the analytics contract.

## Fact Table – `fact_sales`

Grain:
> One row per SalesOrderLineKey (order line level)

Key characteristics:
- Combines Online and Reseller sales.
- Placeholder keys (-1) used for non-applicable dimensions.
- All revenue and profitability metrics are computed here.
- No metric logic is implemented in BI tools.

Core measures:
- Sales Amount
- Total Product Cost
- Gross Profit
- Gross Profit Ratio
- Order Quantity
- Lead Time (DaysDifference)

Channel integrity rule:
- Online → valid CustomerKey, ResellerKey = -1
- Reseller → valid ResellerKey, CustomerKey = -1

---

## Dimension Tables

- dim_customer
- dim_reseller
- dim_product
- dim_date
- dim_sales_territory

Each dimension:
- Has one row per business entity.
- Uses stable surrogate keys.
- Contains descriptive attributes only.
- Avoids business metric definitions.

---

## Analytical Model – RFM

`dim_rfm` computes customer-level Recency, Frequency, and Monetary metrics:

- Recency: Days since last purchase
- Frequency: Distinct purchase dates
- Monetary: Total sales amount (log-transformed for scoring)

RFM scores are mapped to business-defined customer segments via `dim_customer_segment`.

Segmentation logic is centrally defined in the data model, not in BI.

---

# Data Quality & Testing

Data quality is enforced using custom dbt tests located under `/tests/marts`.

## Referential Integrity

All fact foreign keys must resolve to corresponding dimensions:

- CustomerKey → dim_customer
- ProductKey → dim_product
- ResellerKey → dim_reseller
- SalesTerritoryKey → dim_sales_territory

## Channel-Key Consistency

- Online transactions must not reference ResellerKey.
- Reseller transactions must not reference CustomerKey.

## RFM Coverage

- All online customers with transactions must have RFM records.
- Placeholder key (-1) must not appear in dim_rfm.

## Sanity Checks (Warning Level)

- Negative gross profit
- Negative unit price
- Extreme product cost vs list price
- Duplicate business identifiers

Error-level tests break the build.  
Warning-level tests surface anomalies without blocking deployment.
