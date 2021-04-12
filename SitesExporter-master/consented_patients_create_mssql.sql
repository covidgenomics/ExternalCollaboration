/**
CGRNDC Phenotype 1.0 for OMOP MSSQL
Created by: Anna Tsvetkova, Odysseus
HOW TO RUN:
If you are not using the R or Python exporters, you will need to replace @resultsDatabaseSchema, @cdmDatabaseSchema, @siteSourceSchema with your local OMOP schema details.
Create your own script or use this one as a template to implement your logic to populate the list of consented paitents.
USER NOTES:
A list of patients, who gave their consent to transfer their data, is required for the Phenotype extraction script.
The list is expected to be in CGRNDC_CONSENTED_PATIENTS table in the result schema, having person_id field as primary key.
The table is created in the results schema because OMOP analysts do not always have write access to their @cdmDatabaseSchema.
If you have read/write to your cdmDatabaseSchema, you would use the same schema name for both.
SCRIPT RELEASE DATE: 2021-04-02

**/

IF OBJECT_ID('@resultsDatabaseSchema.CGRNDC_CONSENTED_PATIENTS', 'U') IS NULL
    CREATE TABLE @resultsDatabaseSchema.CGRNDC_CONSENTED_PATIENTS (
        person_id INT NOT NULL
    	);

-- -- before beginning, remove any patients from the last run
-- TRUNCATE TABLE @resultsDatabaseSchema.CGRNDC_CONSENTED_PATIENTS;

-- -- populate the consented paitents table
-- INSERT INTO @resultsDatabaseSchema.CGRNDC_CONSENTED_PATIENTS
-- SELECT p.person_id
-- FROM @siteSourceSchema.GET_CONSENTED_LIST() ccl
-- INNER JOIN @cdmDatabaseSchema.PERSON p ON ccl.patient_anonimized_id = p.person_source_value
-- ;
