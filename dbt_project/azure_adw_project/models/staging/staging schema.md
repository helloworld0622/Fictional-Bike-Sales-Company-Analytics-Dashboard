# Staging Models (dbt)

The staging layer standardizes raw/source tables into clean, consistent inputs for downstream dimensional modeling.  
In general, staging focuses on **renaming, type cleanup, and controlled flattening**, while **business metrics and definitions live in marts**.

---

## stg_customer
**Source:** `Sales.Customer`  
**Purpose:** Standardize customer keys/identifiers for downstream joins (customer/person/store/territory).  
**Notes:** Minimal logic (rename only); preserves source granularity (1 row per `CustomerID`).

---

## stg_product
**Source:** `Production.Product`  
**Purpose:** Standardize product attributes needed for product dimension and profitability analysis.  
**Notes:** Minimal logic (rename only); keeps core pricing fields (`ListPrice`, `StandardCost`) and hierarchy keys.

---

## stg_reseller
**Source:** `Sales.Store` + `Person.BusinessEntityAddress` + `Person.AddressType` + `Person.Address` + `Person.StateProvince` + `Person.CountryRegion`  
**Purpose:** Build a reseller staging table with geography attributes and `BusinessType` extracted from the XML `Demographics`.  

**Key rules/assumptions:**
- Keeps **Main Office** address when available; otherwise reseller may have null geography.
- XML parsing uses the AdventureWorks StoreSurvey namespace; `BusinessType` is extracted from `/StoreSurvey/BusinessType`.
- Left joins are used to avoid dropping resellers with incomplete address data.

**Interview one-liner:**  
"Reseller staging is where I flatten Store + Geography and parse BusinessType from XML, so marts stay clean."

---

## stg_sales_order_detail
**Source:** `raw_sales_order_detail`  
**Purpose:** Standardize sales order line grain for the fact table (quantity/price/discount/line total).  
**Notes:** Rename + keep key measures at order line level.

---

## stg_sales_order_header
**Source:** `raw_sales_order_header`  
**Purpose:** Standardize order header fields for date logic, customer linkage, and channel identification (`OnlineOrderFlag`).  
**Notes:** Rename only; provides `order_date` / `due_date` / `ship_date` for lead-time metrics downstream.

---

## stg_sales_territory
**Source:** `Sales.SalesTerritory`  
**Purpose:** Standardize territory fields for territory dimension (region/group/country code).  
**Notes:** Rename only; uses source grain (1 row per `TerritoryID`).
