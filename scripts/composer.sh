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
# - author: Matteo Pescarin <matteo.pescarin[AT]steellondon.com>
#
#
# This code is provided 'as-is'
# and released under the GPLv2

# defaults
DEFAULT_PROJECT_ROOT="/vagrant/webroot"

# application variables
#PROJECT_ROOT=""

# application related variables
VERSION="0.1"
NO_ARGS=0
E_OPTERROR=85
E_GENERROR=25
OLD_IFS="$IFS"
IFS=','

function usage() {
    echo -e "Syntax: `basename $0` [-h|-v] [-l] [-r <PROJECT_ROOT>]
\t-h: shows this help
\t-v: be verbose
\t-l: Will avoid installing development (require-dev) dependencies
\t-r <PROJECT_ROOT>: absolute path of the projcet root in the vagrant VM (no trailing slash)
\n"
}

function version() {
    echo -e "`basename $0` - Composer dependencies update script - version $VERSION\n"
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
while getopts ":hvd:u:p:s:" Option
do
    case $Option in
        h ) version
            usage
            quit 0
            ;;
        v ) BE_VERBOSE=true
            ;;
        e ) NO_DEV_OPT=("--no-dev")
            ;;
        r ) [ ! -e $OPTARG ] && error "'$OPTARG' not accessible" && quit $E_OPTERROR
            PROJECT_ROOT=$OPTARG
            ;;
    esac
done

# Decrements the argument pointer so it points to next argument.
# $1 now references the first non-option item supplied on the command-line
# if one exists.
shift $(($OPTIND - 1))

# initialise the missing variables
if [[ ! -n $PROJECT_ROOT ]]
then
    PROJECT_ROOT=${DEFAULT_PROJECT_ROOT}
fi

[[ -n $BE_VERBOSE ]] && echo ">> PROJECT_ROOT: ${PROJECT_ROOT}"

cd "${PROJECT_ROOT}"

if [[ -d "vendor" ]]
then
    [[ -n $BE_VERBOSE ]] && echo ">> Cleaning the installed packages for the project"
    rm -rf vendor/*
fi

[[ -n $BE_VERBOSE ]] && echo ">> Installing the project requirements"
composer install ${NO_DEV_OPT[@]} --prefer-dist
