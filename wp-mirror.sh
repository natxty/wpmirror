#!/bin/bash


# ============================================================
# AUTO VARIABLES
# ============================================================
 TIME=`date +"%Y_%m_%d"`

#pull in the config file from the CLI argument:
config_file=$1

#test file:
if [ ! -f $config_file ]; then
	echo "ERROR: config file $config_file doesn't seem to exist"
	exit $?
fi

#source config .. not secure but it works:
. $config_file


# ============================================================
# DOUBLE CHECK!!
# ============================================================
echo "WARNING!!"
echo 
echo "READ THIS FIRST!!"
echo
echo "Using config file $config_file" >&2
echo 
echo "This script will remove files and data from the target folder and database."
echo "Explicitly, this means that we will delete the following before proceeding:"
echo
echo "Target Destination: ${DESTINATION_FOLDER}"
echo "Target Datbase: ${DESTINATION_DATABASE}"
echo "..."
echo "Are you OK with this [y/n]?"

read answer

echo "You entered ${answer}"

if [ $answer != 'y' ]; then
	echo "OK. Err on the side of caution."
	echo "Quitting..."
	exit 0
fi

# you may want to lock .htaccess down with "DENY FROM ALL"
# you can add an easy exception - such as ALLOW FROM my.own.hostname.net
ADD_TO_HTACCESS='
deny from all
allow from my.intranet.connection
';
 
# ============================================================
# END CONFIGURATION - DON'T TOUCH BELOW THIS LINE
# ============================================================
 
IFS=$'\n';
 
# ============================================================
# step 1: clear destination folder and database
# ============================================================
echo "removing / recreating ${DESTINATION_FOLDER}";
rm -rf ${DESTINATION_FOLDER}
mkdir ${DESTINATION_FOLDER}
 
tables=\
`echo "show tables from ${DESTINATION_DATABASE}" | \
mysql -u${DESTINATION_DATABASE_USER} -p${DESTINATION_DATABASE_PASS} | \
grep -v "Tables_in_${DESTINATION_DATABASE}"`
 
IFS=$' ';
count_tables=`echo ${tables} | cat -n | tail -n 1 | cut -f1`;
IFS=$'\n';
 
echo "removing ${count_tables} tables from destination database ${DESTINATION_DATABASE}";
for table in $tables
do
	echo \
		"drop table ${DESTINATION_DATABASE}.${table}" | \
		mysql -u${DESTINATION_DATABASE_USER} -p${DESTINATION_DATABASE_PASS};
done
 
 
# ============================================================
# step 2: import database and files
# ============================================================
 
echo "grabbing snapshot of source database from ${SOURCE_DATABASE}";
/usr/bin/mysqldump \
	${SOURCE_DATABASE} \
	-u${SOURCE_DATABASE_USER} \
	-p${SOURCE_DATABASE_PASS} \
	> ${TEMP_FILE}
 
 
echo `stat ${TEMP_FILE} -c "%n %s"` " bytes";


#echo "down and dirty sed to replace the old domain with the new domain:"
# use underscore (_) as delimiter, since the slash (/) is rough 
#sed -i "s_http://${SOURCE_SITE}_http://${DESTINATION_SITE}_g" ${TEMP_FILE}
 
echo "importing snapshot into destination database ${DESTINATION_DATABASE}"
mysql -D \
	${DESTINATION_DATABASE} \
	-u${DESTINATION_DATABASE_USER} \
	-p${DESTINATION_DATABASE_PASS} \
	< ${TEMP_FILE}
 
echo "updating siteurl in options":

 echo "update ${DESTINATION_DATABASE}.${table} set option_value=replace(option_value, 'http://${SOURCE_SITE}/', 'http://${DESTINATION_SITE}/') where option_name = 'siteurl'" \
	| mysql \
		-u${DESTINATION_DATABASE_USER} \
		-p${DESTINATION_DATABASE_PASS};

 
echo "copying files from ${SOURCE_FOLDER}* to ${DESTINATION_FOLDER}";
cp -R -p ${SOURCE_FOLDER}* ${DESTINATION_FOLDER}
 
echo "chown'ing ${DESTINATION_FOLDER} as ${DESTINATION_CHOWN_USER_GROUP}";
chown -R ${DESTINATION_CHOWN_USER_GROUP} ${DESTINATION_FOLDER}*
 
echo "copying .htaccess manually";
cp ${SOURCE_FOLDER}.htaccess ${DESTINATION_FOLDER}.htaccess
echo "   not adding to .htaccess: ${ADD_TO_HTACCESS}";
#echo "${ADD_TO_HTACCESS}" >> ${DESTINATION_FOLDER}.htaccess
 
 
# ============================================================
# step 3: disable caching plugins, if any
# ============================================================
if [ -d ${DESTINATION_FOLDER}wp-content/plugins/wp-super-cache/ ]; then
	echo "removing caching plugin ${DESTINATION_FOLDER}wp-content/plugins/wp-super-cache/";
	rm -rf ${DESTINATION_FOLDER}wp-content/plugins/wp-super-cache/
fi
 
# ============================================================
# step 4: rewrite wp-config.php
# ============================================================
 
echo "rewriting wp-config.php with new information";
 
sed \
	"s/'DB_NAME', '${SOURCE_DATABASE}'/'DB_NAME', '${DESTINATION_DATABASE}'/g" \
		${SOURCE_FOLDER}wp-config.php | \
sed \
	"s/'DB_USER', '${SOURCE_DATABASE_USER}'/'DB_USER', '${DESTINATION_DATABASE_USER}'/g" | \
sed \
	"s/'DB_PASSWORD', '${SOURCE_DATABASE_PASS}'/'DB_PASSWORD', '${DESTINATION_DATABASE_PASS}'/g" | \
sed \
	"s/'DOMAIN_CURRENT_SITE', '${SOURCE_SITE}'/'DOMAIN_CURRENT_SITE', '${DESTINATION_SITE}'/g" \
	> ${DESTINATION_FOLDER}wp-config.php
 

