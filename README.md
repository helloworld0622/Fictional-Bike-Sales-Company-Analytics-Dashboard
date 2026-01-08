# Fictional Bike Sales Company – Analytics Data Platform

## Overview
This repository demonstrates how a **Data / BI Engineer** builds an analytics-ready data platform from a transactional OLTP system.

Using **Microsoft AdventureWorks 2022 (OLTP)** as the source, I implemented a **dbt-based ELT pipeline** and designed a **star schema** optimized for BI consumption, with **Power BI** as the downstream analytics layer.

---

## Engineering Focus
This project highlights:
- Translating **OLTP schemas → dimensional analytics models**
- Implementing **raw → staging → marts** using dbt (SQL-first ELT)
- Designing a **star schema** for scalable BI reporting
- Enforcing **data quality and referential integrity**
- Delivering **BI-ready tables with no downstream transformation logic**

---

## Data Architecture
AdventureWorks2022 (OLTP)
↓
Raw
↓
Staging
↓
Marts (Star Schema)
↓
Power BI

### Raw
- One-to-one representations of source tables  
- No business logic applied  
- Preserves source fidelity  

### Staging
- Cleans and standardizes raw data  
- Type casting, naming conventions, XML parsing, and joins  
- Produces stable inputs for analytics modeling  
- Reseller staging flattens store and geography tables, enforces a single Main Office address per reseller, and extracts BusinessType from XML demographics
  
### Marts (Dimensional Model)
- Central fact table: `fact_sales`
- Dimensions:
  - Customer
  - Product
  - Reseller
  - Sales Territory
  - Date
  - RFM & Customer Segment (derived)

### Marts (Dimensional & Analytical Models)

The marts layer contains **fully defined analytics models**, where business metrics and analytical attributes are explicitly specified and standardized.

#### Fact Model: `fact_sales`
`fact_sales` is built at **sales order line grain** and serves as the single source of truth for transactional measures.

Key design choices:
- Revenue, cost, and profitability metrics are **computed once** in the marts layer.
- Online and reseller sales are unified in the same fact table, with channel-specific keys populated accordingly.
- Non-applicable dimensions are handled explicitly using placeholder keys (`-1`) to preserve referential integrity.

Key measures defined in this layer include:
- Sales Amount
- Product Cost and Gross Profit
- Gross Profit Ratio
- Order quantity, unit price, and discount
- Order-to-ship lead time (days)

All calculations follow **explicit and deterministic formulas**, ensuring consistent metric definitions across downstream consumers.

---

#### Dimensional Models
Core dimensions (customer, reseller, product, date, sales territory) provide descriptive context for slicing and filtering.

Design principles:
- One row per natural business entity
- Stable surrogate keys
- Attributes standardized and resolved in staging before dimensional modeling
- No business logic deferred to BI tools

---

#### Analytical Models: RFM & Customer Segmentation
RFM metrics and customer segments are **explicitly modeled analytical dimensions**, not inferred automatically.

- **Recency (R)** is defined as days since the customer's most recent purchase.
- **Frequency (F)** is defined as the number of distinct purchase dates.
- **Monetary (M)** is defined as total sales amount, with a log transformation applied to reduce skewness.

Customer segments are assigned based on explicitly defined RFM score combinations.
Each customer receives a three-digit RFM score (R, F, M ∈ {1,…,5}), which is mapped to a business segment as follows:

| Customer Segment         | RFM Score Patterns |
|--------------------------|--------------------|
| Champions                | 555, 554, 545, 455, 454, 445 |
| Loyal                    | 543, 444, 435, 355, 354, 345, 344, 335 |
| Potential Loyalist       | 553, 552, 551, 542, 541, 533, 532, 531, 453, 452, 451, 442, 441, 433, 432, 423, 353, 352, 351, 342, 341, 333, 323 |
| New Customers            | 512, 511, 422, 421, 412, 411, 311 |
| Promising                | 525, 524, 523, 522, 521, 515, 514, 513, 425, 424, 415, 414, 413, 315, 314, 313 |
| Need Attention           | 535, 534, 443, 434, 343, 334, 325, 324 |
| About To Sleep           | 331, 321, 312, 251, 241, 231, 221, 213 |
| At Risk                  | 255, 254, 253, 252, 245, 244, 243, 242, 235, 234, 225, 224, 153, 152, 145, 143, 142, 135, 134, 133, 125, 124 |
| Cannot Lose Them         | 155, 154, 144, 215, 214, 115, 114, 113 |
| Hibernating Customers    | 332, 322, 233, 223, 222, 212, 211, 132, 123, 122 |
| Lost Customers           | 111, 112, 121, 131, 141, 151 |

All segment definitions are centrally maintained in the marts layer.
No segmentation logic is implemented or overridden in downstream BI tools.

---

## Star Schema

- `fact_sales` contains revenue, gross profit, quantities, and channel
- Dimension tables provide descriptive slicing and filtering
- Power BI connects **directly to marts**, without additional transformation layers

```mermaid
erDiagram
    FACT_SALES {
        int SalesOrderLineKey PK
        int CustomerKey FK
        int ResellerKey FK
        int ProductKey FK
        int SalesTerritoryKey FK
        int OrderDateKey FK
        int ShipDateKey FK
        int DueDateKey FK
    }

    DIM_CUSTOMER {
        int CustomerKey PK
        string CustomerID
    }

    DIM_RESELLER {
        int ResellerKey PK
        string ResellerID
    }

    DIM_PRODUCT {
        int ProductKey PK
        string Product
    }

    DIM_SALES_TERRITORY {
        int SalesTerritoryKey PK
        string Country
        string Region
    }

    DIM_DATE {
        int DateKey PK
        date Date
    }

    DIM_RFM {
        int CustomerKey PK
        string RFM
    }

    DIM_CUSTOMER_SEGMENT {
        string Score PK
        string Segment
    }

    FACT_SALES }o--|| DIM_CUSTOMER : CustomerKey
    FACT_SALES }o--|| DIM_RESELLER : ResellerKey
    FACT_SALES }o--|| DIM_PRODUCT : ProductKey
    FACT_SALES }o--|| DIM_SALES_TERRITORY : SalesTerritoryKey
    FACT_SALES }o--|| DIM_DATE : OrderDateKey
    FACT_SALES }o--|| DIM_DATE : ShipDateKey
    FACT_SALES }o--|| DIM_DATE : DueDateKey

    DIM_CUSTOMER ||--|| DIM_RFM : CustomerKey
    DIM_RFM }o--|| DIM_CUSTOMER_SEGMENT : RFM

---

## Data Quality & Governance
Custom dbt tests validate:
- Primary key uniqueness
- Foreign key consistency between fact and dimensions
- Invalid business scenarios (e.g. negative prices, negative gross profit)
- Schema and analytical completeness (e.g. RFM coverage)

Data quality is treated as an **engineering responsibility**, not a BI concern.

---

## BI Consumption
The marts layer feeds Power BI dashboards covering:
- Executive sales performance (revenue, units, gross profit)
- Product profitability and margin analysis
- Online customer RFM segmentation

All metrics are derived from the marts layer.

---

## Tech Stack
- **Cloud**: Azure  
- **Warehouse**: Azure SQL / Analytics DB  
- **Transformations**: dbt (SQL)  
- **Modeling**: Star Schema  
- **BI**: Power BI  
- **Version Control**: Git & GitHub  

---

## Notes
- Connection credentials (`profiles.yml`) are excluded from version control
- This repository focuses on **analytics engineering and data modeling**, not dashboard aesthetics




