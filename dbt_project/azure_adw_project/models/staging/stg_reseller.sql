-- ==============================================
--  Staging for Reseller Dimension (AdventureWorks2022 OLTP)
--  Combines Store + Geography information
-- ==============================================

-- and extract BusinessType from the XML Demographics column
WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/StoreSurvey'
),

store_with_address AS (
    SELECT
        s.BusinessEntityID                         AS ResellerKey,
        s.Name                                     AS Reseller,
        TRY_CAST(s.Demographics AS xml)            AS DemographicsXml,

        a.City                                     AS City,
        a.PostalCode                               AS PostalCode,
        sp.Name                                    AS StateProvince,
        cr.Name                                    AS CountryRegion
    FROM Sales.Store                    AS s
    LEFT JOIN Person.BusinessEntityAddress AS bea
        ON s.BusinessEntityID = bea.BusinessEntityID
    LEFT JOIN Person.AddressType AS at
        ON bea.AddressTypeID = at.AddressTypeID
    LEFT JOIN Person.Address AS a
        ON bea.AddressID = a.AddressID
    LEFT JOIN Person.StateProvince AS sp
        ON a.StateProvinceID = sp.StateProvinceID
    LEFT JOIN Person.CountryRegion AS cr
        ON sp.CountryRegionCode = cr.CountryRegionCode
    -- Keep only the "Main Office" address when it exists
    WHERE at.Name = 'Main Office'
       OR at.Name IS NULL
)

SELECT
    -- Keys / IDs
    sw.ResellerKey                              AS ResellerKey,
    sw.ResellerKey                              AS ResellerID,

    -- Name
    sw.Reseller                                 AS Reseller,

    -- Business Type parsed from XML Demographics
    CASE
        WHEN sw.DemographicsXml IS NULL THEN NULL
        ELSE sw.DemographicsXml.value(
                 '(/StoreSurvey/BusinessType/text())[1]',
                 'nvarchar(50)'
             )
    END                                         AS [Business Type],

    -- Geography attributes
    sw.City                                     AS City,
    sw.StateProvince                            AS [State-Province],
    sw.CountryRegion                            AS [Country-Region],
    sw.PostalCode                               AS [Postal Code]

FROM store_with_address AS sw;