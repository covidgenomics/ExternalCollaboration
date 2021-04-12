# Exporter kit for CGRN project

This exporter kit is created to help the sites to extract COVID-19 patients data, stored in OMOP CDM dataset. The kit builds a cohort of such patients, extracts the patients data and upload it to the aggregating storage.

#### The kit consists of:

1. Consented patients SQL script, creating an empty consented patients list.
    * This script is a placeholder for an actual script, building a consented patients list, which is to be implemented on site.
1. Phenotype SQL script, building the cohort.
1. Extraction SQL script, extracting the data.
1. Exporter python script, packing and uploading the data to the given bucket.
1. Configuration file(s).

#### Expected environment:

* The OMOP CDM dataset is stored in MS SQL Server.
* The target bucket is a Google Storage bucket.

#### Prerequisities:

* python 3
* Google Cloud Storage python library
    * `pip install --upgrade google-cloud-storage`

```
 
```


### How to run the kit:

You can run individual steps or all steps together by combining the parameters.

Available parameters are:

Parameter | Required | Default | Description | Example of a value
--------- | -------- | ------- | ----------- | ------------------
config | True | None | specify the name of the configuration ini file. See file config.ini | config.ini
extract | False | None | specify the name of the file that contains the extract sql, must meet format spec, including ";" and OUTPUT_FILE: | extract_omop_mssql.sql
database | False | None | specify database, use values oracle or mssql | mssql, oracle
output_dir | False | "." | specify the directory the csv files will be exported to. This directory will be zipped if the zip option is set | ../files/phenotype_csv
arraysize | False | "10000" | specify the cursor array size, must be integer. The default is 10000. This is how many records are fetched at once from DB, if you run into memory issues reduce this number | 
phenotype | False | None | specify the name of the file that contains the phenotype sql. This will create the CGRNDC_COHORT table | phenotype_omop_mssql.sql
consented | False | None | specify the name of the file that contains the consented patients sql. This will create the CGRNDC_CONSENTED_PATIENTS table | consented_patients_create_mssql.sql
zip | False | None | create zip of output data files. The name of the archive is concatenated from the site abbreviation, CDM model name, and the current date in format YYYYMMDD. See the config file for the site and model details | No value is expected
zip_dir | False | "." | specify the directory where the zip archive will be saved to | ../files
~~sftp~~ | ~~False~~ | ~~None~~ | ~~sftp zip file, setup credentials and server in config file.~~ **\*** | ~~No value is expected~~
debug | False | None | debug mode, print sql as it is executed and other helpful information | No value is expected
upload | False | None | upload created file to the bucket path indicated in the config file | No value is expected

```
 
```

**\***  *SFTP functionality is not available because NYGC is using direct push to GCP bucket instead of SFTP.*

If parameters are combined together, the steps of the extraction process are executed in the following order:

* Build the consented patients list
* Build the cohort
* Extract CDM data filtered by the consented patients list and the cohort
* Zip the extracted CSVs
* Upload the zip archive to the GCP bucket

```
 
```

Examples, assuming that current directory is where this README file is located:

```
 
```


```
# Run the process from the beginning to the end :
python db_exp.py --config config.ini --database mssql \
    --consent consented_patients_create_mssql.sql \
    --phenotype phenotype_omop_mssql.sql \
    --extract extract_omop_mssql.sql \
    --output_dir ../files/phenotype_csv \
    --zip \
    --zip_dir ../files \
    --upload

# Run upload step only
python db_exp.py --config config.ini --upload --zip_dir ../../files

# Run zip step only
python db_exp.py --config config.ini --zip --output_dir ../files/phenotype_csv --zip_dir ../../files

# Run consented patients step, and see the queries which are executed
python db_exp.py --config config.ini --database mssql --debug --consent consented_patients_create_mssql.sql

# See the list of the parameters available:
python db_exp.py

```


```
 
```

#### The end