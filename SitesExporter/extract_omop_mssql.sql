--OMOP v5.3.1 extraction code for CGRNDC
--Created by Anna Tsvetkova, Odysseus 
--Based on N3C project written by Kristin Kostka and Robert Miller, OHDSI
--Code written for MS SQL Server
--This extract purposefully excludes the following OMOP tables: 
--    DOSE_ERA, NOTE, NOTE_NLP, COST, METADATA, CDM_SOURCE
--Currently this script extracts the derived tables for DRUG_ERA, CONDITION_ERA as well
--Assumptions:
--	1. You have already built the CGRNDC_COHORT table (with that name) prior to running this extract
--	2. You are extracting data with a lookback period to 1-1-@lookbakStartYear
--  3. You have existing tables for each of these extracted tables. If you do not, create a shell table so it can extract an empty table.

-- To run, you will need to find and replace @cdmDatabaseSchema and @resultsDatabaseSchema with your local OMOP schema details

--MANIFEST TABLE: CHANGE PER YOUR SITE'S SPECS
--OUTPUT_FILE: MANIFEST.csv
select
   '@siteAbbrev' as SITE_ABBREV,
   '@siteName'    AS SITE_NAME,
   '@contactName' as CONTACT_NAME,
   '@contactEmail' as CONTACT_EMAIL,
   '@cdmName' as CDM_NAME,
   '@cdmVersion' as CDM_VERSION,
   (SELECT TOP 1 vocabulary_version FROM @resultsDatabaseSchema.CGRNDC_COHORT) AS VOCABULARY_VERSION,
   'Y' as CGRNDC_PHENOTYPE_YN,
   (SELECT TOP 1 phenotype_version FROM @resultsDatabaseSchema.CGRNDC_COHORT) as CGRNDC_PHENOTYPE_VERSION,
   '@shiftDateYN' as SHIFT_DATE_YN,
   '@maxNumShiftDays' as MAX_NUM_SHIFT_DAYS,
   '@lookbakStartYear' as LOOKBACK_START_YEAR,
   CAST(GETDATE() as datetime) as RUN_DATE,
   CAST( DATEADD(day, -@dataLatencyNumDays, GETDATE()) as datetime) as UPDATE_DATE,	--change integer based on your site's data latency
   CAST( DATEADD(day, @daysBetweenSubmissions, GETDATE()) as datetime) as NEXT_SUBMISSION_DATE;





--VALIDATION_SCRIPT
--OUTPUT_FILE: EXTRACT_VALIDATION.csv
SELECT
	'PERSON' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.PERSON x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
GROUP BY x.person_id
HAVING COUNT(*) > 1

UNION
SELECT
	'OBSERVATION_PERIOD' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.OBSERVATION_PERIOD x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.observation_period_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.observation_period_id
HAVING COUNT(*) > 1

UNION
SELECT
  'VISIT_OCCURRENCE' TABLE_NAME
  ,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.VISIT_OCCURRENCE x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.visit_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.visit_occurrence_id
HAVING COUNT(*) > 1

UNION
SELECT
  'VISIT_DETAIL' TABLE_NAME
  ,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.VISIT_DETAIL x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.visit_detail_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.visit_detail_id
HAVING COUNT(*) > 1

UNION
SELECT
	'CONDITION_OCCURRENCE' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.condition_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.condition_occurrence_id
HAVING COUNT(*) > 1

UNION
SELECT
  'DRUG_EXPOSURE' TABLE_NAME
  ,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.DRUG_EXPOSURE x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.drug_exposure_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.drug_exposure_id
HAVING COUNT(*) > 1

UNION
SELECT
  'DEVICE_EXPOSURE' TABLE_NAME
  ,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.DEVICE_EXPOSURE x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.device_exposure_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.device_exposure_id
HAVING COUNT(*) > 1

UNION
SELECT
	'PROCEDURE_OCCURRENCE' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.PROCEDURE_OCCURRENCE x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.procedure_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.procedure_occurrence_id
HAVING COUNT(*) > 1

UNION
SELECT
	'MEASUREMENT' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.MEASUREMENT x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.measurement_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.measurement_id
HAVING COUNT(*) > 1

UNION
SELECT
	'OBSERVATION' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.OBSERVATION x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.observation_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.observation_id
HAVING COUNT(*) > 1

UNION
SELECT
	'LOCATION' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.LOCATION x
GROUP BY x.location_id
HAVING COUNT(*) > 1

UNION
SELECT
	'CARE_SITE' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.CARE_SITE x
GROUP BY x.care_site_id
HAVING COUNT(*) > 1

UNION
SELECT
	'PROVIDER' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.PROVIDER x
GROUP BY x.provider_id
HAVING COUNT(*) > 1

UNION
SELECT
	'DRUG_ERA' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.DRUG_ERA x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.drug_era_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.drug_era_id
HAVING COUNT(*) > 1

UNION
SELECT
	'DOSE_ERA' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.DOSE_ERA x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.dose_era_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.dose_era_id
HAVING COUNT(*) > 1

UNION
SELECT
	'CONDITION_ERA' TABLE_NAME
	,COUNT(*) DUP_COUNT
FROM @cdmDatabaseSchema.CONDITION_ERA x
INNER JOIN @resultsDatabaseSchema.CGRNDC_COHORT cgrndc
ON x.person_id = cgrndc.person_id
AND x.condition_era_start_date > DATEFROMPARTS(@lookbakStartYear,01,01)
GROUP BY x.condition_era_id
HAVING COUNT(*) > 1;




--PERSON
--OUTPUT_FILE: PERSON.csv
SELECT
   p.PERSON_ID,
   GENDER_CONCEPT_ID,
   ISNULL(YEAR_OF_BIRTH, DATEPART(year, birth_datetime )) as YEAR_OF_BIRTH,
   ISNULL(MONTH_OF_BIRTH, DATEPART(month, birth_datetime)) as MONTH_OF_BIRTH,
   RACE_CONCEPT_ID,
   ETHNICITY_CONCEPT_ID,
   LOCATION_ID,
   PROVIDER_ID,
   CARE_SITE_ID,
   NULL as PERSON_SOURCE_VALUE,
   GENDER_SOURCE_VALUE,
   RACE_SOURCE_VALUE,
   RACE_SOURCE_CONCEPT_ID,
   ETHNICITY_SOURCE_VALUE,
   ETHNICITY_SOURCE_CONCEPT_ID
  FROM @cdmDatabaseSchema.PERSON p
  JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
    ON p.PERSON_ID = n.PERSON_ID;

--OBSERVATION_PERIOD
--OUTPUT_FILE: OBSERVATION_PERIOD.csv
SELECT
   OBSERVATION_PERIOD_ID,
   p.PERSON_ID,
   CAST(OBSERVATION_PERIOD_START_DATE as date) as OBSERVATION_PERIOD_START_DATE,
   CAST(OBSERVATION_PERIOD_END_DATE as date) as OBSERVATION_PERIOD_END_DATE,
   PERIOD_TYPE_CONCEPT_ID
 FROM @cdmDatabaseSchema.OBSERVATION_PERIOD p
 JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
   ON p.PERSON_ID = n.PERSON_ID;

--VISIT_OCCURRENCE
--OUTPUT_FILE: VISIT_OCCURRENCE.csv
SELECT
   VISIT_OCCURRENCE_ID,
   n.PERSON_ID,
   VISIT_CONCEPT_ID,
   CAST(VISIT_START_DATE as date) as VISIT_START_DATE,
   CAST(VISIT_START_DATETIME as datetime) as VISIT_START_DATETIME,
   CAST(VISIT_END_DATE as date) as VISIT_END_DATE,
   CAST(VISIT_END_DATETIME as datetime) as VISIT_END_DATETIME,
   VISIT_TYPE_CONCEPT_ID,
   PROVIDER_ID,
   CARE_SITE_ID,
   VISIT_SOURCE_VALUE,
   VISIT_SOURCE_CONCEPT_ID,
   ADMITTING_SOURCE_CONCEPT_ID,
   ADMITTING_SOURCE_VALUE,
   DISCHARGE_TO_CONCEPT_ID,
   DISCHARGE_TO_SOURCE_VALUE,
   PRECEDING_VISIT_OCCURRENCE_ID
FROM @cdmDatabaseSchema.VISIT_OCCURRENCE v
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON v.PERSON_ID = n.PERSON_ID
WHERE v.VISIT_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);

--VISIT_DETAIL
--OUTPUT_FILE: VISIT_DETAIL.csv
SELECT
   VISIT_DETAIL_ID,
   n.PERSON_ID,
   VISIT_DETAIL_CONCEPT_ID,
   CAST(VISIT_DETAIL_START_DATE as date) as VISIT_DETAIL_START_DATE,
   CAST(VISIT_DETAIL_START_DATETIME as datetime) as VISIT_DETAIL_START_DATETIME,
   CAST(VISIT_DETAIL_END_DATE as date) as VISIT_DETAIL_END_DATE,
   CAST(VISIT_DETAIL_END_DATETIME as datetime) as VISIT_DETAIL_END_DATETIME,
   VISIT_DETAIL_TYPE_CONCEPT_ID,
   PROVIDER_ID,
   CARE_SITE_ID,
   ADMITTING_SOURCE_CONCEPT_ID,
   DISCHARGE_TO_CONCEPT_ID,
   PRECEDING_VISIT_DETAIL_ID,
   VISIT_DETAIL_SOURCE_VALUE,
   VISIT_DETAIL_SOURCE_CONCEPT_ID,
   ADMITTING_SOURCE_VALUE,
   DISCHARGE_TO_SOURCE_VALUE,
   VISIT_DETAIL_PARENT_ID,
   VISIT_OCCURRENCE_ID
FROM @cdmDatabaseSchema.VISIT_DETAIL v
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON v.PERSON_ID = n.PERSON_ID
WHERE v.VISIT_DETAIL_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);

--CONDITION_OCCURRENCE
--OUTPUT_FILE: CONDITION_OCCURRENCE.csv
SELECT
   CONDITION_OCCURRENCE_ID,
   n.PERSON_ID,
   CONDITION_CONCEPT_ID,
   CAST(CONDITION_START_DATE as date) as CONDITION_START_DATE,
   CAST(CONDITION_START_DATETIME as datetime) as CONDITION_START_DATETIME,
   CAST(CONDITION_END_DATE as date) as CONDITION_END_DATE,
   CAST(CONDITION_END_DATETIME as datetime) as CONDITION_END_DATETIME,
   CONDITION_TYPE_CONCEPT_ID,
   CONDITION_STATUS_CONCEPT_ID,
   NULL as STOP_REASON,
   VISIT_OCCURRENCE_ID,
   VISIT_DETAIL_ID,
   CONDITION_SOURCE_VALUE,
   CONDITION_SOURCE_CONCEPT_ID,
   NULL as CONDITION_STATUS_SOURCE_VALUE
FROM @cdmDatabaseSchema.CONDITION_OCCURRENCE co
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON CO.person_id = n.person_id
WHERE co.CONDITION_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);

--DRUG_EXPOSURE
--OUTPUT_FILE: DRUG_EXPOSURE.csv
SELECT
   DRUG_EXPOSURE_ID,
   n.PERSON_ID,
   DRUG_CONCEPT_ID,
   CAST(DRUG_EXPOSURE_START_DATE as date) as DRUG_EXPOSURE_START_DATE,
   CAST(DRUG_EXPOSURE_START_DATETIME as datetime) as DRUG_EXPOSURE_START_DATETIME,
   CAST(DRUG_EXPOSURE_END_DATE as date) as DRUG_EXPOSURE_END_DATE,
   CAST(DRUG_EXPOSURE_END_DATETIME as datetime) as DRUG_EXPOSURE_END_DATETIME,
   DRUG_TYPE_CONCEPT_ID,
   NULL as STOP_REASON,
   REFILLS,
   QUANTITY,
   DAYS_SUPPLY,
   NULL as SIG,
   ROUTE_CONCEPT_ID,
   LOT_NUMBER,
   PROVIDER_ID,
   VISIT_OCCURRENCE_ID,
   VISIT_DETAIL_ID,
   DRUG_SOURCE_VALUE,
   DRUG_SOURCE_CONCEPT_ID,
   ROUTE_SOURCE_VALUE,
   DOSE_UNIT_SOURCE_VALUE
FROM @cdmDatabaseSchema.DRUG_EXPOSURE de
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON de.PERSON_ID = n.PERSON_ID
WHERE de.DRUG_EXPOSURE_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);

--DEVICE_EXPOSURE
--OUTPUT_FILE: DEVICE_EXPOSURE.csv
SELECT
   DEVICE_EXPOSURE_ID,
   n.PERSON_ID,
   DEVICE_CONCEPT_ID,
   CAST(DEVICE_EXPOSURE_START_DATE as date) as DEVICE_EXPOSURE_START_DATE,
   CAST(DEVICE_EXPOSURE_START_DATETIME as datetime) as DEVICE_EXPOSURE_START_DATETIME,
   CAST(DEVICE_EXPOSURE_END_DATE as date) as DEVICE_EXPOSURE_END_DATE,
   CAST(DEVICE_EXPOSURE_END_DATETIME as datetime) as DEVICE_EXPOSURE_END_DATETIME,
   DEVICE_TYPE_CONCEPT_ID,
   UNIQUE_DEVICE_ID,
   QUANTITY,
   PROVIDER_ID,
   VISIT_OCCURRENCE_ID,
   VISIT_DETAIL_ID,
   DEVICE_SOURCE_VALUE,
   DEVICE_SOURCE_CONCEPT_ID
FROM @cdmDatabaseSchema.DEVICE_EXPOSURE dde
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON dde.PERSON_ID = n.PERSON_ID
WHERE dde.DEVICE_EXPOSURE_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);

--PROCEDURE_OCCURRENCE
--OUTPUT_FILE: PROCEDURE_OCCURRENCE.csv
SELECT
   PROCEDURE_OCCURRENCE_ID,
   n.PERSON_ID,
   PROCEDURE_CONCEPT_ID,
   CAST(PROCEDURE_DATE as date) as PROCEDURE_DATE,
   CAST(PROCEDURE_DATETIME as datetime) as PROCEDURE_DATETIME,
   PROCEDURE_TYPE_CONCEPT_ID,
   MODIFIER_CONCEPT_ID,
   QUANTITY,
   PROVIDER_ID,
   VISIT_OCCURRENCE_ID,
   VISIT_DETAIL_ID,
   PROCEDURE_SOURCE_VALUE,
   PROCEDURE_SOURCE_CONCEPT_ID,
   NULL as MODIFIER_SOURCE_VALUE
FROM @cdmDatabaseSchema.PROCEDURE_OCCURRENCE po
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON PO.PERSON_ID = N.PERSON_ID
WHERE po.PROCEDURE_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);

--MEASUREMENT
--OUTPUT_FILE: MEASUREMENT.csv
SELECT
   MEASUREMENT_ID,
   n.PERSON_ID,
   MEASUREMENT_CONCEPT_ID,
   CAST(MEASUREMENT_DATE as date) as MEASUREMENT_DATE,
   CAST(MEASUREMENT_DATETIME as datetime) as MEASUREMENT_DATETIME,
   NULL as MEASUREMENT_TIME,
   MEASUREMENT_TYPE_CONCEPT_ID,
   OPERATOR_CONCEPT_ID,
   VALUE_AS_NUMBER,
   VALUE_AS_CONCEPT_ID,
   UNIT_CONCEPT_ID,
   RANGE_LOW,
   RANGE_HIGH,
   PROVIDER_ID,
   VISIT_OCCURRENCE_ID,
   VISIT_DETAIL_ID,
   MEASUREMENT_SOURCE_VALUE,
   MEASUREMENT_SOURCE_CONCEPT_ID,
   NULL as UNIT_SOURCE_VALUE,
   NULL as VALUE_SOURCE_VALUE
FROM @cdmDatabaseSchema.MEASUREMENT m
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON m.PERSON_ID = n.PERSON_ID
WHERE m.MEASUREMENT_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);

--OBSERVATION
--OUTPUT_FILE: OBSERVATION.csv
SELECT
   OBSERVATION_ID,
   n.PERSON_ID,
   OBSERVATION_CONCEPT_ID,
   CAST(OBSERVATION_DATE as date) as OBSERVATION_DATE,
   CAST(OBSERVATION_DATETIME as datetime) as OBSERVATION_DATETIME,
   OBSERVATION_TYPE_CONCEPT_ID,
   VALUE_AS_NUMBER,
   VALUE_AS_STRING,
   VALUE_AS_CONCEPT_ID,
   QUALIFIER_CONCEPT_ID,
   UNIT_CONCEPT_ID,
   PROVIDER_ID,
   VISIT_OCCURRENCE_ID,
   VISIT_DETAIL_ID,
   OBSERVATION_SOURCE_VALUE,
   OBSERVATION_SOURCE_CONCEPT_ID,
   NULL as UNIT_SOURCE_VALUE,
   NULL as QUALIFIER_SOURCE_VALUE
FROM @cdmDatabaseSchema.OBSERVATION o
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON O.PERSON_ID = N.PERSON_ID
WHERE o.OBSERVATION_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);

--DEATH
--OUTPUT_FILE: DEATH.csv
SELECT
   n.PERSON_ID,
    CAST(DEATH_DATE as date) as DEATH_DATE,
	CAST(DEATH_DATETIME as datetime) as DEATH_DATETIME,
	DEATH_TYPE_CONCEPT_ID,
	CAUSE_CONCEPT_ID,
	NULL as CAUSE_SOURCE_VALUE,
	CAUSE_SOURCE_CONCEPT_ID
FROM @cdmDatabaseSchema.DEATH d
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
ON D.PERSON_ID = N.PERSON_ID
WHERE d.DEATH_DATE >= DATEFROMPARTS(2020,01,01);

--LOCATION
--OUTPUT_FILE: LOCATION.csv
SELECT
   l.LOCATION_ID,
   null as ADDRESS_1, -- to avoid identifying information
   null as ADDRESS_2, -- to avoid identifying information
   CITY,
   STATE,
   ZIP,
   COUNTY,
   NULL as LOCATION_SOURCE_VALUE
FROM @cdmDatabaseSchema.LOCATION l
JOIN (
        SELECT DISTINCT p.LOCATION_ID
        FROM @cdmDatabaseSchema.PERSON p
        JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON p.person_id = n.person_id
      ) a
  ON l.location_id = a.location_id
;

--CARE_SITE
--OUTPUT_FILE: CARE_SITE.csv
SELECT
   cs.CARE_SITE_ID,
   CARE_SITE_NAME,
   PLACE_OF_SERVICE_CONCEPT_ID,
   NULL as LOCATION_ID,
   NULL as CARE_SITE_SOURCE_VALUE,
   NULL as PLACE_OF_SERVICE_SOURCE_VALUE
FROM @cdmDatabaseSchema.CARE_SITE cs
JOIN (
        SELECT DISTINCT CARE_SITE_ID
        FROM @cdmDatabaseSchema.VISIT_OCCURRENCE vo
        JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON vo.person_id = n.person_id
      ) a
  ON cs.CARE_SITE_ID = a.CARE_SITE_ID
;

--PROVIDER
--OUTPUT_FILE: PROVIDER.csv
SELECT
   pr.PROVIDER_ID,
   null as PROVIDER_NAME, -- to avoid accidentally identifying sites
   null as NPI, -- to avoid accidentally identifying sites
   null as DEA, -- to avoid accidentally identifying sites
   SPECIALTY_CONCEPT_ID,
   CARE_SITE_ID,
   null as YEAR_OF_BIRTH,
   GENDER_CONCEPT_ID,
   null as PROVIDER_SOURCE_VALUE, -- to avoid accidentally identifying sites
   SPECIALTY_SOURCE_VALUE,
   SPECIALTY_SOURCE_CONCEPT_ID,
   GENDER_SOURCE_VALUE,
   GENDER_SOURCE_CONCEPT_ID
FROM @cdmDatabaseSchema.PROVIDER pr
JOIN (
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.VISIT_OCCURRENCE vo
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON vo.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.VISIT_DETAIL vd
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON vd.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.DRUG_EXPOSURE de
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON de.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.DEVICE_EXPOSURE dde
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON dde.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.MEASUREMENT m
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON m.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.PROCEDURE_OCCURRENCE po
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON po.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.OBSERVATION o
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON o.PERSON_ID = n.PERSON_ID
     ) a
 ON pr.PROVIDER_ID = a.PROVIDER_ID
;

--Note: it has yet to be decided if Era tables will be constructured downstream in Palantir platform.
-- If it is decided that eras will be reconstructed, these three tables will be omitted.

--DRUG_ERA
--OUTPUT_FILE: DRUG_ERA.csv
SELECT
   DRUG_ERA_ID,
   n.PERSON_ID,
   DRUG_CONCEPT_ID,
   CAST(DRUG_ERA_START_DATE as date) as DRUG_ERA_START_DATE,
   CAST(DRUG_ERA_END_DATE as date) as DRUG_ERA_END_DATE,
   DRUG_EXPOSURE_COUNT,
   GAP_DAYS
FROM @cdmDatabaseSchema.DRUG_ERA dre
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
  ON DRE.PERSON_ID = N.PERSON_ID
WHERE DRUG_ERA_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);


--CONDITION_ERA
--OUTPUT_FILE: CONDITION_ERA.csv
SELECT
   CONDITION_ERA_ID,
   n.PERSON_ID,
   CONDITION_CONCEPT_ID,
   CAST(CONDITION_ERA_START_DATE as date) as CONDITION_ERA_START_DATE,
   CAST(CONDITION_ERA_END_DATE as date) as CONDITION_ERA_END_DATE,
   CONDITION_OCCURRENCE_COUNT
FROM @cdmDatabaseSchema.CONDITION_ERA ce 
JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON CE.PERSON_ID = N.PERSON_ID
WHERE CONDITION_ERA_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01);





--CONCEPT
--OUTPUT_FILE: CONCEPT.csv
SELECT
   CONCEPT_ID,
   CONCEPT_NAME,
   DOMAIN_ID,
   VOCABULARY_ID,
   CONCEPT_CLASS_ID,
   STANDARD_CONCEPT,
   CONCEPT_CODE,
   VALID_START_DATE,
   VALID_END_DATE,
   INVALID_REASON
FROM @cdmDatabaseSchema.CONCEPT voc;

--VOCABULARY
--OUTPUT_FILE: VOCABULARY.csv
SELECT
   VOCABULARY_ID,
   VOCABULARY_NAME,
   VOCABULARY_REFERENCE,
   VOCABULARY_VERSION,
   VOCABULARY_CONCEPT_ID
FROM @cdmDatabaseSchema.VOCABULARY voc;

--DOMAIN
--OUTPUT_FILE: DOMAIN.csv
SELECT
   DOMAIN_ID,
   DOMAIN_NAME,
   DOMAIN_CONCEPT_ID
FROM @cdmDatabaseSchema.DOMAIN voc;

--CONCEPT_CLASS
--OUTPUT_FILE: CONCEPT_CLASS.csv
SELECT
   CONCEPT_CLASS_ID,
   CONCEPT_CLASS_NAME,
   CONCEPT_CLASS_CONCEPT_ID
FROM @cdmDatabaseSchema.CONCEPT_CLASS voc;

--CONCEPT_RELATIONSHIP
--OUTPUT_FILE: CONCEPT_RELATIONSHIP.csv
SELECT
   CONCEPT_ID_1,
   CONCEPT_ID_2,
   RELATIONSHIP_ID,
   VALID_START_DATE,
   VALID_END_DATE,
   INVALID_REASON
FROM @cdmDatabaseSchema.CONCEPT_RELATIONSHIP voc;

--RELATIONSHIP
--OUTPUT_FILE: RELATIONSHIP.csv
SELECT
   RELATIONSHIP_ID,
   RELATIONSHIP_NAME,
   IS_HIERARCHICAL,
   DEFINES_ANCESTRY,
   REVERSE_RELATIONSHIP_ID,
   RELATIONSHIP_CONCEPT_ID
FROM @cdmDatabaseSchema.RELATIONSHIP voc;

--CONCEPT_ANCESTOR
--OUTPUT_FILE: CONCEPT_ANCESTOR.csv
SELECT
   ANCESTOR_CONCEPT_ID,
   DESCENDANT_CONCEPT_ID,
   MIN_LEVELS_OF_SEPARATION,
   MAX_LEVELS_OF_SEPARATION
FROM @cdmDatabaseSchema.CONCEPT_ANCESTOR voc;

--SOURCE_TO_CONCEPT_MAP
--OUTPUT_FILE: SOURCE_TO_CONCEPT_MAP.csv
SELECT
   SOURCE_CODE,
   SOURCE_CONCEPT_ID,
   SOURCE_VOCABULARY_ID,
   SOURCE_CODE_DESCRIPTION,
   TARGET_CONCEPT_ID,
   TARGET_VOCABULARY_ID,
   VALID_START_DATE,
   VALID_END_DATE,
   INVALID_REASON
FROM @cdmDatabaseSchema.SOURCE_TO_CONCEPT_MAP voc;

--DRUG_STRENGTH
--OUTPUT_FILE: DRUG_STRENGTH.csv
SELECT
   DRUG_CONCEPT_ID,
   INGREDIENT_CONCEPT_ID,
   AMOUNT_VALUE,
   AMOUNT_UNIT_CONCEPT_ID,
   NUMERATOR_VALUE,
   NUMERATOR_UNIT_CONCEPT_ID,
   DENOMINATOR_VALUE,
   DENOMINATOR_UNIT_CONCEPT_ID,
   BOX_SIZE,
   VALID_START_DATE,
   VALID_END_DATE,
   INVALID_REASON
FROM @cdmDatabaseSchema.DRUG_STRENGTH voc;




--DATA_COUNTS TABLE
--OUTPUT_FILE: DATA_COUNTS.csv
SELECT * from
(select
   'PERSON' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.PERSON p JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON p.PERSON_ID = n.PERSON_ID) as ROW_COUNT

UNION

select
   'OBSERVATION_PERIOD' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.OBSERVATION_PERIOD op JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON op.PERSON_ID = n.PERSON_ID AND OBSERVATION_PERIOD_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

select
   'VISIT_OCCURRENCE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.VISIT_OCCURRENCE vo JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON vo.PERSON_ID = n.PERSON_ID AND VISIT_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

select
   'VISIT_DETAIL' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.VISIT_DETAIL vo JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON vo.PERSON_ID = n.PERSON_ID AND VISIT_DETAIL_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

select
   'CONDITION_OCCURRENCE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CONDITION_OCCURRENCE co JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON co.PERSON_ID = n.PERSON_ID AND CONDITION_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

select
   'DRUG_EXPOSURE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.DRUG_EXPOSURE de JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON de.PERSON_ID = n.PERSON_ID AND DRUG_EXPOSURE_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

select
   'DEVICE_EXPOSURE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.DEVICE_EXPOSURE de JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON de.PERSON_ID = n.PERSON_ID AND DEVICE_EXPOSURE_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

select
   'PROCEDURE_OCCURRENCE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.PROCEDURE_OCCURRENCE po JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON po.PERSON_ID = n.PERSON_ID AND PROCEDURE_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

select
   'MEASUREMENT' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.MEASUREMENT m JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON m.PERSON_ID = n.PERSON_ID AND MEASUREMENT_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

select
   'OBSERVATION' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.OBSERVATION o JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON o.PERSON_ID = n.PERSON_ID AND OBSERVATION_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT

UNION

SELECT
   'DEATH' as TABLE_NAME,
  (select count(*) from @cdmDatabaseSchema.DEATH d JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON d.PERSON_ID = n.PERSON_ID AND DEATH_DATE >= DATEFROMPARTS(2020,01,01)) as ROW_COUNT

UNION

--OMOP does not have PERSON_ID for Location, Care Site and Provider tables so we need to determine the applicability of this check
--We could re-engineer the cohort table to include the JOIN variables
select
   'LOCATION' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.LOCATION l
   JOIN (
        SELECT DISTINCT p.LOCATION_ID
        FROM @cdmDatabaseSchema.PERSON p
        JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON p.person_id = n.person_id
      ) a
  ON l.location_id = a.location_id) as ROW_COUNT

UNION

select
   'CARE_SITE' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CARE_SITE cs
	JOIN (
        SELECT DISTINCT CARE_SITE_ID
        FROM @cdmDatabaseSchema.VISIT_OCCURRENCE vo
        JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON vo.person_id = n.person_id
      ) a
  ON cs.CARE_SITE_ID = a.CARE_SITE_ID) as ROW_COUNT

UNION

 select
   'PROVIDER' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.PROVIDER pr
	JOIN (
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.VISIT_OCCURRENCE vo
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON vo.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.VISIT_DETAIL vd
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON vd.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.DRUG_EXPOSURE de
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON de.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.DEVICE_EXPOSURE dde
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON dde.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.MEASUREMENT m
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON m.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.PROCEDURE_OCCURRENCE po
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON po.PERSON_ID = n.PERSON_ID
       UNION
       SELECT DISTINCT PROVIDER_ID
       FROM @cdmDatabaseSchema.OBSERVATION o
       JOIN @resultsDatabaseSchema.CGRNDC_COHORT n
          ON o.PERSON_ID = n.PERSON_ID
     ) a
 ON pr.PROVIDER_ID = a.PROVIDER_ID) as ROW_COUNT

UNION

select
   'DRUG_ERA' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.DRUG_ERA de JOIN @resultsDatabaseSchema.CGRNDC_COHORT n ON de.PERSON_ID = n.PERSON_ID AND DRUG_ERA_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT
UNION

select
   'CONDITION_ERA' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CONDITION_ERA JOIN @resultsDatabaseSchema.CGRNDC_COHORT ON CONDITION_ERA.PERSON_ID = CGRNDC_COHORT.PERSON_ID AND CONDITION_ERA_START_DATE >= DATEFROMPARTS(@lookbakStartYear,01,01)) as ROW_COUNT
) s

UNION

SELECT
   'CONCEPT' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CONCEPT voc) as ROW_COUNT
UNION

SELECT
   'VOCABULARY' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.VOCABULARY voc) as ROW_COUNT
UNION

SELECT
   'DOMAIN' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.DOMAIN voc) as ROW_COUNT
UNION

SELECT
   'CONCEPT_CLASS' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CONCEPT_CLASS voc) as ROW_COUNT
UNION

SELECT
   'CONCEPT_RELATIONSHIP' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CONCEPT_RELATIONSHIP voc) as ROW_COUNT
UNION

SELECT
   'RELATIONSHIP' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.RELATIONSHIP voc) as ROW_COUNT
UNION

SELECT
   'CONCEPT_ANCESTOR' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.CONCEPT_ANCESTOR voc) as ROW_COUNT
UNION

SELECT
   'SOURCE_TO_CONCEPT_MAP' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.SOURCE_TO_CONCEPT_MAP voc) as ROW_COUNT
UNION

SELECT
   'DRUG_STRENGTH' as TABLE_NAME,
   (select count(*) from @cdmDatabaseSchema.DRUG_STRENGTH voc) as ROW_COUNT

;