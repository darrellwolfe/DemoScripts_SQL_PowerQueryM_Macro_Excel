-- !preview conn=conn
/*
AsTxDBProd
GRM_Main

SELECT * FROM information_schema.columns 
WHERE table_name LIKE 'TIF%';

--Find a table with a Column Name like...
SELECT * FROM information_schema.columns 
WHERE column_name LIKE 'TaxCalcDetail%';

Select *
From CadRoll
Where AssessmentYear = 2022


*/

WITH 

CTE_ParcelMaster AS (
--------------------------------
--ParcelMaster
--------------------------------
  Select Distinct
  pm.lrsn
, CASE
    WHEN pm.neighborhood >= 9000 THEN 'Manufactured_Homes'
    WHEN pm.neighborhood >= 6003 THEN 'District_6'
    WHEN pm.neighborhood = 6002 THEN 'Manufactured_Homes'
    WHEN pm.neighborhood = 6001 THEN 'District_6'
    WHEN pm.neighborhood = 6000 THEN 'Manufactured_Homes'
    WHEN pm.neighborhood >= 5003 THEN 'District_5'
    WHEN pm.neighborhood = 5002 THEN 'Manufactured_Homes'
    WHEN pm.neighborhood = 5001 THEN 'District_5'
    WHEN pm.neighborhood = 5000 THEN 'Manufactured_Homes'
    WHEN pm.neighborhood >= 4000 THEN 'District_4'
    WHEN pm.neighborhood >= 3000 THEN 'District_3'
    WHEN pm.neighborhood >= 2000 THEN 'District_2'
    WHEN pm.neighborhood >= 1021 THEN 'District_1'
    WHEN pm.neighborhood = 1020 THEN 'Manufactured_Homes'
    WHEN pm.neighborhood >= 1001 THEN 'District_1'
    WHEN pm.neighborhood = 1000 THEN 'Manufactured_Homes'
    WHEN pm.neighborhood >= 451 THEN 'Commercial'
    WHEN pm.neighborhood = 450 THEN 'Specialized_Cell_Towers'
    WHEN pm.neighborhood >= 1 THEN 'Commercial'
    WHEN pm.neighborhood = 0 THEN 'N/A_or_Error'
    ELSE NULL
  END AS District
, pm.neighborhood AS GEO
, TRIM(pm.NeighborHoodName) AS GEO_Name
,  TRIM(pm.pin) AS PIN
,  TRIM(pm.AIN) AS AIN
, pm.ClassCD
, TRIM(pm.PropClassDescr) AS Property_Class_Desc
, CASE 
    WHEN pm.ClassCD IN ('010', '020', '021', '022', '030', '031', '032', '040', '050', '060', '070', '080', '090') THEN 'Business_Personal_Property'
    WHEN pm.ClassCD IN ('314', '317', '322', '336', '339', '343', '413', '416', '421', '435', '438', '442', '451', '527','461') THEN 'Commercial_Industrial'
    WHEN pm.ClassCD IN ('411', '512', '515', '520', '534', '537', '541', '546', '548', '549', '550', '555', '565','526','561') THEN 'Residential'
    WHEN pm.ClassCD IN ('441', '525', '690') THEN 'Mixed_Use_Residential_Commercial'
    WHEN pm.ClassCD IN ('101','103','105','106','107','110','118') THEN 'Timber_Ag_Land'
    WHEN pm.ClassCD = '667' THEN 'Operating_Property'
    WHEN pm.ClassCD = '681' THEN 'Exempt_Property'
    WHEN pm.ClassCD = 'Unasigned' THEN 'Unasigned_or_OldInactiveParcel'
    ELSE 'Unasigned_or_OldInactiveParcel'
  END AS Property_Type_Class
, TRIM(pm.TAG) AS TAG
--,  TRIM(pm.DisplayName)) AS Owner
, TRIM(pm.SitusAddress) AS SitusAddress
, TRIM(pm.SitusCity) AS SitusCity
, TRIM(pm.SitusState) AS SitusState
, TRIM(pm.SitusZip) AS SitusZip
, TRIM(pm.DisplayName) AS Owner
, TRIM(pm.AttentionLine) AS Attn
, TRIM(pm.MailingAddress) AS MailingAddress
, TRIM(pm.MailingCityStZip) AS MailingCSZ
, TRIM(pm.DisplayDescr) AS LegalDescription

, TRIM(pm.CountyNumber) AS CountyNumber
, CASE
    WHEN pm.CountyNumber = '28' THEN 'Kootenai_County'
    ELSE NULL
  END AS County_Name
,  pm.LegalAcres
,  pm.Improvement_Status -- <Improved vs Vacant


  From TSBv_PARCELMASTER AS pm
  
  Where pm.EffStatus = 'A'
    --AND pm.ClassCD NOT LIKE '010%'
    --AND pm.ClassCD NOT LIKE '020%'
    --AND pm.ClassCD NOT LIKE '021%'
    --AND pm.ClassCD NOT LIKE '022%'
    --AND pm.ClassCD NOT LIKE '030%'
    --AND pm.ClassCD NOT LIKE '031%'
    --AND pm.ClassCD NOT LIKE '032%'
--    AND pm.ClassCD NOT LIKE '060%'
--    AND pm.ClassCD NOT LIKE '070%'
--    AND pm.ClassCD NOT LIKE '090%'
      
  Group By
  pm.lrsn
, pm.pin
, pm.PINforGIS
, pm.AIN
, pm.ClassCD
, pm.PropClassDescr
, pm.neighborhood
, pm.NeighborHoodName
, pm.TAG
, pm.AttentionLine
, pm.MailingAddress
, pm.MailingCityStZip
, pm.DisplayDescr
, pm.DisplayName
, pm.SitusAddress
, pm.SitusCity
, pm.SitusState
, pm.SitusZip
, pm.CountyNumber
, pm.LegalAcres
, pm.Improvement_Status

--Order By District,GEO;
),

CTE_CadasterInventory AS (
SELECT DISTINCT
r.AssessmentYear
,r.Descr AS AssessmentType
,l.CadRollId
,l.RollLevel 
,i.TranId
,i.CadLevelId
,i.RevObjEffStatus
,i.RevObjId AS CadRoll_LRSN
,TRIM(i.PIN) AS CadRoll_PIN
,TRIM(i.AIN ) AS CadRoll_AIN
,TRIM(i.GeoCd) AS CadRoll_GEO
,TRIM(i.TAGDescr) AS CadRoll_TAG


FROM CadRoll r
JOIN CadLevel l ON r.Id = l.CadRollId
JOIN CadInv i ON l.Id = i.CadLevelId

--Tax Year 2023 (Annual Roll Only) so far
--WHERE r.Id IN ('559', '560', '561','562','563')
--WHERE r.Id IN ('563')

WHERE r.AssessmentYear = 2023
)




SELECT DISTINCT

pmd.Property_Type_Class
,pmd.lrsn
,pmd.AIN
,pmd.PIN
,CAST(pmd.ClassCD AS INT) AS ClassCD
,pmd.Property_Class_Desc
--Other Audits
,'Check>' AS AuditCadaster
,ci.AssessmentYear
,ci.AssessmentType

,ci.CadRoll_PIN
,pmd.PIN
,ci.CadRoll_AIN
,pmd.AIN

,ci.CadRoll_TAG
,pmd.TAG

FROM CTE_CadasterInventory AS ci

LEFT JOIN CTE_ParcelMaster AS pmd
  ON pmd.lrsn = ci.CadRoll_LRSN

--WHERE CAST(pmd.ClassCD AS INT) IN ('20','30')

--ORDER BY GEO, PIN