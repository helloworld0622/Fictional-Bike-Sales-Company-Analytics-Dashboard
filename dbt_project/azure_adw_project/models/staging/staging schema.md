# Staging Models (dbt)

The staging layer standardizes raw/source tables into clean, consistent inputs for downstream dimensional modeling.  
In general, staging focuses on **renaming, type cleanup, and controlled flattening**, while **business metrics and definitions live in marts**.

---

## stg_customer
**Source:** `Sales.Customer`  
**Purpose:** Standardize customer keys/identifiers for downstream joins (customer/person/store/territory).  

---

## stg_product
**Source:** `Production.Product`  
**Purpose:** Standardize product attributes needed for product dimension and profitability analysis.  

---

## stg_reseller
**Source:** `Sales.Store` + `Person.BusinessEntityAddress` + `Person.AddressType` + `Person.Address` + `Person.StateProvince` + `Person.CountryRegion`  
**Purpose:** Build a reseller staging table with geography attributes and `BusinessType` extracted from the XML `Demographics`.  

**Key rules/assumptions:**
- Keeps **Main Office** address when available; otherwise reseller may have null geography.
- XML parsing uses the AdventureWorks StoreSurvey namespace; `BusinessType` is extracted from `/StoreSurvey/BusinessType`.
- Left joins are used to avoid dropping resellers with incomplete address data.


---

## stg_sales_order_detail
**Source:** `raw_sales_order_detail`  
**Purpose:** Standardize sales order line grain for the fact table (quantity/price/discount/line total).  

---

## stg_sales_order_header
**Source:** `raw_sales_order_header`  
**Purpose:** Standardize order header fields for date logic, customer linkage, and channel identification (`OnlineOrderFlag`).  

---

## stg_sales_territory
**Source:** `Sales.SalesTerritory`  
**Purpose:** Standardize territory fields for territory dimension (region/group/country code).  
