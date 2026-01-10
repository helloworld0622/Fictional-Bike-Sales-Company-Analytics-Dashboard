--  Staging for Reseller Dimension (AdventureWorks2022 OLTP)
--  Combines Store + Geography information
-- aextract BusinessType from the XML Demographics column
with XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/StoreSurvey'
),
store_with_address as (
    select
        s.BusinessEntityID as ResellerKey,
        s.Name as Reseller,
        TRY_CAST(s.Demographics as xml) as DemographicsXml,
        a.City as City,
        a.PostalCode as PostalCode,
        sp.Name as StateProvince,
        cr.Name as CountryRegion
    from Sales.Store as s
    left join Person.BusinessEntityAddress as bea
        ON s.BusinessEntityID = bea.BusinessEntityID
    left join Person.AddressType as at
        ON bea.AddressTypeID = at.AddressTypeID
    left join Person.Address as a
        ON bea.AddressID = a.AddressID
    left join Person.StateProvince as sp
        ON a.StateProvinceID = sp.StateProvinceID
    left join Person.CountryRegion as cr
        ON sp.CountryRegionCode = cr.CountryRegionCode
    -- Keep only the "Main Office" address when it exists
    where at.Name = 'Main Office'
       or at.Name IS NULL
)
select
    sw.ResellerKey as ResellerKey,
    sw.ResellerKey as ResellerID,
    sw.Reseller as Reseller,
    -- Business Type parsed from XML Demographics
    case
        when sw.DemographicsXml IS NULL then NULL
        else sw.DemographicsXml.value(
                 '(/StoreSurvey/BusinessType/text())[1]',
                 'nvarchar(50)'
             )
    end as [Business Type],
    -- Geography attributes
    sw.City as City,
    sw.StateProvince as [State-Province],
    sw.CountryRegion as [Country-Region],
    sw.PostalCode as [Postal Code]
from store_with_address as sw;