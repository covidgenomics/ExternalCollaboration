import csv
import configparser
import os
import argparse
import datetime
import shutil

def mssql_connect(config):
    host = config['mssql']['host']
    port = config['mssql']['port']
    database = config['mssql']['database']
    user = config['mssql']['user']
    pwd = config['mssql']['pwd']
    if 'driver' in config['mssql']:
        driver = config['mssql']['driver']
    else:
        driver = 'SQL Server'

    constr = 'DRIVER={'+driver+'};SERVER='+host+';DATABASE='+database+';PORT='+port+';UID='+user+';PWD='+ pwd
    conn = pyodbc.connect(constr)
    return(conn)

def oracle_connect(config):
    host = config['oracle']['host']
    port = config['oracle']['port']
    if 'sid' in config['oracle']:
        sid = config['oracle']['sid']
    else:
        sid = None
    if 'service_name' in config['oracle']:
        service_name = config['oracle']['service_name']
    else:
        service_name = None
    user = config['oracle']['user']
    pwd = config['oracle']['pwd']

    if sid != None:
        dsn_tns = cx_Oracle.makedsn(host, port, sid=sid)
    elif service_name != None:
        dsn_tns = cx_Oracle.makedsn(host, port, service_name=service_name)
    else:
        print("ERROR:  oracle sid and service_name not found in config file")
        exit()
    conn = cx_Oracle.connect(user, pwd, dsn_tns)

    return(conn)

def parse_sql(sql_fname,sql_params):
    exports = []
    output_file_tag = "OUTPUT_FILE:"
    validation_tag = "VALIDATION_SCRIPT"
    output_file = None

    with open(sql_fname,"r") as inf:
        inrows = inf.readlines()

    sql = ""
    block = False
    validation = False
    for row in inrows:
        if (row.strip().startswith('--') == True) and (row.find(output_file_tag) < 0) and (row.find(validation_tag) < 0):
            continue
        # replace sql params
        for param in sql_params:
            row = row.replace(param['tag'], param['value'])

        if row.strip().upper().startswith('BEGIN'):
            block = True;

        sql = sql + row
        if row.find(output_file_tag) >= 0:
            output_file = row[ row.find(output_file_tag) + len(output_file_tag):].strip()
        if row.find(validation_tag) >= 0:
            validation = True

        if block == True:
            if row.strip().upper().startswith('END;'):
                if output_file != None:
                    exports.append({"output_file": output_file, "sql":sql, "validation": validation })
                else:
                    exports.append({"sql":sql, "validation": validation  })
                sql = ""
                block = False
                validation = False

        else:
            if row.find(';') >= 0:
                sql = sql.split(';')[0]
                if output_file != None:
                    exports.append({"output_file": output_file, "sql":sql, "validation": validation })
                else:
                    exports.append({"sql":sql, "validation": validation  })
                sql = ""
                validation = False

    return(exports)

def run_sql(conn, fname, sql_params, debug):
    cursor=conn.cursor()
    sql_arr = parse_sql(fname, sql_params)

    #print and return
    for sql in sql_arr:
        if debug == True:
            print("Execute SQL -----------------------------")
            print(sql['sql'])
            print("-----------------------------------------")
        cursor.execute(sql['sql'])
        conn.commit()

def db_export(conn, sql, csvwriter, arraysize, debug):
    cursor=conn.cursor()
    cursor.arraysize = arraysize

    if debug == True:
        print("Execute SQL -----------------------------")
        print(sql)
        print("-----------------------------------------")
    cursor.execute(sql);
    header = [column[0] for column in cursor.description]
    csvwriter.writerow(header)

    while True:
        rows = cursor.fetchmany()
        if not rows:
            break
        for row in rows:
            csvwriter.writerow(row)

    cursor.close()

def db_export_validate(conn, sql, csvwriter, arraysize, debug):
    cursor=conn.cursor()
    cursor.arraysize = 100

    if debug == True:
        print("Execute SQL -----------------------------")
        print(sql)
        print("-----------------------------------------")
    cursor.execute(sql);
    header = [column[0] for column in cursor.description]
    csvwriter.writerow(header)

    rows = cursor.fetchmany()
    if not rows:
        return(True)
    for row in rows:
        csvwriter.writerow(row)
        return(False)

    cursor.close()

def test_env(database=None, sftp=None):
    import subprocess
    import sys
    db_req_packages = {'oracle': 'cx-Oracle', 'mssql': 'pyodbc'} # DB Specific Packages
    reqs = subprocess.check_output([sys.executable, '-m', 'pip', 'freeze'])
    installed_packages = [r.decode().split('==')[0] for r in reqs.split()]

    err_mess = ''
    if database != None: #test db packages
        if database not in db_req_packages:
            err_mess = err_mess + "Invalid database type, use mssql or oracle\n"
        else:
            if db_req_packages[database] not in installed_packages:
                err_mess = err_mess + "Package not installed for database connection: {}\n".format(db_req_packages[database])

    if sftp != None:
        if 'paramiko' not in installed_packages:
                err_mess = err_mess + "Package not installed for sftp: {}\n".format('paramiko')

    return(err_mess)

def upload_file(source_file_path, bucket_name, key_pass):
    import os
    from google.cloud import storage
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = key_pass
    
    file_name = os.path.basename(source_file_path)

    print("To: " + bucket_name)
    print("With: " + os.environ["GOOGLE_APPLICATION_CREDENTIALS"])
    print("")

    storage.Client() \
        .bucket(bucket_name) \
        .blob(file_name) \
        .upload_from_filename(source_file_path)
    
    print("File {} has been uploaded to {}".format(file_name, bucket_name))

# safely creates a directory structure, is not confused by '..' elements
def mkdirs_safe(dir_path):
    d = ''
    for s in dir_path.split(os.sep):
        d = os.path.join(d, s)
        if not os.path.isdir(d) and not s in (os.pardir, os.curdir):
            os.mkdir(d)
    return os.path.isdir(dir_path)

# --------------------------------------------------------------------------
# go

# get command line args
clparse = argparse.ArgumentParser(description='Export from DB using formatted SQL file, optionally create CGRNDC_COHORT table')
clparse.add_argument('--extract', required=False, default=None, help='specify the name of the file that contains the extract sql, must meet format spec, including ";" and OUTPUT_FILE:')
clparse.add_argument('--config', required=True, help='specify the name of the configuration ini file, see file configuration_ini_example.txt')
clparse.add_argument('--database', required=False, default=None, help='specify database, use values oracle or mssql')
clparse.add_argument('--output_dir', default=".", help='specify the directory the csv files will be exported to.  This directory will be zipped if the zip option is set')
clparse.add_argument('--arraysize', default="10000", help='specify the cursor array size, must be integer. The default is 10000.  This is how many records are fetched at once from DB, if you run into memory issues reduce this number')
clparse.add_argument('--phenotype', default=None, help='specify the name of the file that contains the phenotype sql.  This will create the CGRNDC_COHORT table')
clparse.add_argument('--consented', default=None, help='specify the name of the file that contains the consented patients sql.  This will create the CGRNDC_CONSENTED_PATIENTS table')
clparse.add_argument('--zip', default=None, help='create zip of output data files', action='store_true')
clparse.add_argument('--zip_dir', default=".", help='specify the directory where the zip archive will be saved to')
# clparse.add_argument('--sftp', default=None, help='sftp zip file, setup credentials and server in config file', action='store_true')
clparse.add_argument('--debug', default=None, help='debug mode, print sql as it is executed and other helpful information', action='store_true')
clparse.add_argument('--upload', default=None, help='upload created file on the bucket', action='store_true')
args = clparse.parse_args()

output_dir = args.output_dir
zip_dir = args.zip_dir
sql_fname = args.extract
config_fname = args.config
database = args.database
arraysize = int(args.arraysize)
phenotype_fname = args.phenotype
consented_fname = args.consented
create_zip = args.zip
# sftp_zip = args.sftp
debug = args.debug
upload = args.upload

config = configparser.ConfigParser()
config.read(config_fname)

# Check enviromnent for SFTP #
# env_err = test_env(database, sftp_zip) 
# if env_err != '':
#     print('Failed Initialization Tests')
#     print(env_err)
#     exit()

# Validate CDM model name #
# valid_cdm_name = ['pcornet', 'omop', 'act']
valid_cdm_name = ['omop']
if config['site']['cdm_name'] not in valid_cdm_name:
    print("Invalid cdm_name from config file")
    print("must be one of the values below:")
    print(valid_cdm_name)
    exit()

# sql params
sql_params = [
    {'tag': '@resultsDatabaseSchema', 'value': config['site']['results_database_schema']},
    {'tag': '@cdmDatabaseSchema', 'value': config['site']['cdm_database_schema']},
    {'tag': '@vocabularyDatabaseSchema', 'value': config['site']['cdm_database_schema']},
    {'tag': '@siteAbbrev', 'value': config['site']['site_abbrev']},
    {'tag': '@siteName', 'value': config['site']['site_name']},
    {'tag': '@contactName', 'value': config['site']['contact_name']},
    {'tag': '@contactEmail', 'value': config['site']['contact_email']},
    {'tag': '@cdmName', 'value': config['site']['cdm_name']},
    {'tag': '@cdmVersion', 'value': config['site']['cdm_version']},
    {'tag': '@vocabularyVersion', 'value': config['site']['vocabulary_version']},
    {'tag': '@cgrndcPhenotypeYN', 'value': config['site']['cgrndc_phenotype_yn']},
    {'tag': '@dataLatencyNumDays', 'value': config['site']['data_latency_num_days']},
    {'tag': '@daysBetweenSubmissions', 'value': config['site']['days_between_submissions']},
    {'tag': '@shiftDateYN', 'value': config['site']['shift_date_yn']},
    {'tag': '@maxNumShiftDays', 'value': config['site']['max_num_shift_days']},
    {'tag': '@lookbakStartYear', 'value': config['site']['lookbak_start_year']}
]

# Connect to a database #
db_conn = None
if database == 'oracle':
    import cx_Oracle
    db_conn = oracle_connect(config)
elif database == 'mssql':
    import pyodbc
    db_conn = mssql_connect(config)
elif database != None:
    print("Invalid database type, use mssql or oracle")
    exit()

# CONSENTED PATIENTS LIST #
# create consented patients table, it should be populated before export start
if consented_fname != None:
    if db_conn == None:
        print("Invalid database type, use mssql or oracle")
        exit()
    print("Getting consented patients list")
    run_sql(db_conn, consented_fname, sql_params, debug)

# PHENOTYPE #
# create phenotype table, CGRNDC_COHORT, if option set
if phenotype_fname != None:
    if db_conn == None:
        print("Invalid database type, use mssql or oracle")
        exit()
    print("Creating phenotype")
    run_sql(db_conn, phenotype_fname, sql_params, debug)

# EXPORT #
if sql_fname != None:
    print("Exporting data")
    if db_conn == None:
        print("Invalid database type, use mssql or oracle")
        exit()
    # put domain data in DATAFILES subdir of output directory
    datafiles_dir = output_dir + os.path.sep + 'DATAFILES'
    # put files below in root output directory
    root_files = ('MANIFEST.csv','DATA_COUNTS.csv')
    # test for DATAFILES subdir exists
    if not mkdirs_safe(datafiles_dir):
        # print("ERROR: export path not found {}.  You may need to create a 'DATAFILES' subdirectory under your output directory, also may need to specify --output on command line\n".format(datafiles_dir) )
        print("ERROR: export path is not found {}.  \n".format(datafiles_dir) )
        exit()
    exports = parse_sql(sql_fname,sql_params)
    for exp in exports:
        if 'output_file' in exp:
            output_file = exp['output_file']
        else:
            print("ERROR: output_file is not found in sql block")
            exit()
        print( "processing output file: {}\n".format(output_file) )
        if output_file in root_files:
            outfname = output_dir + os.path.sep + exp['output_file']
        else:
            outfname = datafiles_dir + os.path.sep + exp['output_file']
        outf = open(outfname, 'w', newline='')
        csv_delimiter = config.get('site', 'csv_delimiter')
        if csv_delimiter == None: csv_delimiter = '|'
        csvwriter = csv.writer(outf, delimiter=csv_delimiter, quotechar='"', quoting=csv.QUOTE_ALL)
        if exp['validation'] == True:
            val = db_export_validate(db_conn, exp['sql'], csvwriter, arraysize, debug)
            if val == True:
                print("Validation OK")
            else:
                print("Validation ERROR")
                print("Stopping export")
                print("See file {}".format(outfname))
                exit()
        else:
            db_export(db_conn, exp['sql'], csvwriter, arraysize, debug)
        outf.close()

# ZIP #
zip_prefix = config['site']['site_abbrev'] + '_' + config['site']['cdm_name'].lower() + '_' + datetime.date.today().strftime("%Y%m%d")
if not os.path.exists(zip_dir) and create_zip:
    try:
        os.path.mkdir(zip_dir)
    except Exception as e:
        print(zip_dir + ' is not found. To save the zip archive there, please make sure the path is available.')
zip_prefix = os.path.join(zip_dir, zip_prefix)
zip_fname = zip_prefix + ".zip"

if create_zip == True:
    print('Zipping ' + zip_fname)
    shutil.make_archive(zip_prefix, 'zip', output_dir)

# UPLOAD #
if upload:
    print("Uploading " + zip_fname)
    upload_file(
        source_file_path=zip_fname,
        bucket_name=config.get('bigquery','bucket_name'),
        key_pass=config.get('bigquery','oauthpvtkeypath')
    )

# SFTP #
# if sftp_zip == True:
#     print("sftp zip file {}\n".format(zip_fname))
#     #python -m pip install paramiko
#     import paramiko
#     paramiko.util.log_to_file("sftp.log")
#     # get key
#     sftpkey = paramiko.RSAKey.from_private_key_file(config['sftp']['keyfile'])
#     # open paramiko transport
#     hp = config['sftp']['host'] + ':' + config['sftp']['port']
#     transport = paramiko.Transport(hp)
#     # authenticate
#     transport.connect(username=config['sftp']['user'],pkey=sftpkey)
#     # sftp client
#     sftp = paramiko.SFTPClient.from_transport(transport)
#     sftp.chdir(config['sftp']['remote_dir'])
#     sftp.put(zip_fname,zip_fname)

