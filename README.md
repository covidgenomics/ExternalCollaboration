# External Collaboration
Welcome to the NYGC COVID-19 Data Commons External Collaboration Repository! The purpose of this repository is to enable sites with key information on how to engage and submit extracts from local OMOP CDMs to the central OMOP CDM.

### What's in Your Toolbox ###
This Site Exporter kit is created to help the sites to extract COVID-19 patients data, stored in a local OMOP CDM dataset. The kit builds a cohort of such patients, extracts the patients data and upload it to the GPC bucket.

The kit consists of:

1) Consented patients SQL script, only pulling consented patients.
1) Phenotype SQL script, building the cohort.
1) Extraction SQL script, extracting the data.
1) Exporter python script, packing and uploading the data to the given bucket.
1) Configuration file(s).

### [Click here to review Site Instructions](https://github.com/covidgenomics/ExternalCollaboration/wiki/Instructions-for-Sites)
