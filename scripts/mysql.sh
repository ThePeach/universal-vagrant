#!/bin/bash
# this file will load all migrations into the database up to a certain point
# The script is expecting the filename to be in the format:
#   XY_databasename_description.sql
# where:
#   - XY is the order to use to load the migration
#   - databasename is the name of the database to create and use [A-Za-z0-9-]
#   - description is a generic short dash-separated description [A-Za-z0-9-]
# the script is also expecting to have at least a 00_databasename_description.sql file
# that it can use to extract the name of the database from.
#
# - author: Anwar Ishmar
# - refactored by: Matteo Pescarin <matteo.pescarin[AT]steellondon.com>
#
#
# This code is provided 'as-is'
# and released under the GPLv2

# defaults
DEFAULT_DB_SNAPSHOT_DIR="/vagrant/_database/"

# application variables
DB_NAME=""
DB_SNAPSHOT=""
PROJECT_ROOT=""

# application related variables
VERSION="0.1"
NO_ARGS=0
E_OPTERROR=85
E_GENERROR=25
OLD_IFS="$IFS"
IFS=','

function usage() {
    echo -e "Syntax: `basename $0` [-h|-v] [-d <DB_NAME>] [-s <DB_SNAPSHOT>] [-p <PROJECT_ROOT>]
\t-h: shows this help
\t-v: be verbose
\t-d <DB_NAME>: Name of the database to create
\t-s <DB_SNAPSHOT>: absolute path to the sql file to be used to fill the database
\t-p <PROJECT_ROOT>: absolute path of the projcet root in the vagrant VM
\n"
}

function version() {
    echo -e "`basename $0` - Mysql Provisionin Script - version $VERSION\n"
}

function error() {
    version
    echo -e "Error: $1\n"
    usage
}

function quit {
    IFS=$OLD_IFS
    exit $1
}

# no problems if there are no arguments passed, we'll use the default arguments
#if [ $# -eq "$NO_ARGS" ]; then
#    version
#    usage
#    quit $E_OPTERROR
#fi

# The expected flags are
#  h v r
while getopts ":hnve:b:u:" Option
do
    case $Option in
        h ) version
            usage
            quit 0
            ;;
        v ) BE_VERBOSE=true
            VERBOSE_OPT=("-v")
            ;;
        d ) [ ! -e $OPTARG ] && error "'$OPTARG' not accessible" && quit $E_OPTERROR
            DB_NAME=$OPTARG
			;;
        s ) [ ! -e $OPTARG ] && error "'$OPTARG' not accessible" && quit $E_OPTERROR
            DB_SNAPSHOT=$OPTARG
            ;;
        p ) [ ! -e $OPTARG ] && error "'$OPTARG' not accessible" && quit $E_OPTERROR
            PROJECT_ROOT=$OPTARG
            ;;
    esac
done

# Decrements the argument pointer so it points to next argument.
# $1 now references the first non-option item supplied on the command-line
# if one exists.
shift $(($OPTIND - 1))

[[ -n $BE_VERBOSE ]] && echo ">> PROJECT_ROOT: ${PROJECT_ROOT}"
[[ -n $BE_VERBOSE ]] && echo ">> DB_NAME     : ${DB_NAME}"
[[ -n $BE_VERBOSE ]] && echo ">> DB_SNAPSHOT : ${DB_SNAPSHOT}"


# FIXME
DB_DIR="/vagrant/_database/"

echo "Installing MySQL"
echo mysql-server mysql-server/root_password select "password" | debconf-set-selections
echo mysql-server mysql-server/root_password_again select "password" | debconf-set-selections
apt-get install -y -qq mysql-server

echo "Configuring MySQL"
cp /universal-vagrant/configs/my.cnf /etc/mysql/my.cnf

echo "Restarting MySQL"
service mysql restart

# running migrations, see top of the file for details
if [ -d ${DB_DIR} ]
then
    echo "Setting up project database(s)"
    if [ -e ${DB_DIR}00*.sql ]
    then
        dbname=`basename ${DB_DIR}00.*sql | cut -d2 -f_`
        # create the db
        # create the user without password
        echo 'Creating the database and the user'
        mysql -u'root' -p'password' <<<EOF
CREATE DATABASE $dbname CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER "${dbname}"@'%' IDENTIFIED BY PASSWORD '';
GRANT ALL ON $dbname.* TO "${dbname}"@'%';
EOF
        # import all the SQL files into $dbname
        echo 'running all migrations'
        sql_files="/vagrant/_database/*.sql"
        for file in $sql_files
        do
            if [ -f $file ]
            then
                mysql -u'root' -p'password' "$db_name" < $file
            else
                echo "No project database(s) to import"
            fi
        done;
    else
        echo "Initial migration file not found (00_dbname.sql)"
    fi
else
  echo "Database directory not found"
  # we don't return this as an error otherwise Vagrant will pester us about it
  exit 0
fi
