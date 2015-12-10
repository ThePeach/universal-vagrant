#!/bin/bash

# defaults
DEFAULT_PROJECT_ROOT='/vagrant'
DEFAULT_WEBROOT='/var/www'
WEBROOT=$DEFAULT_WEBROOT/public_html
MYSQL_ROOT_USER='root'
MYSQL_ROOT_PASS='password'
APACHE_DEFAULT_VHOST='/etc/apache2/sites-available/default'

# application variables
#PROJECT_ROOT=''

# application related variables
VERSION="0.2"
NO_ARGS=0
E_OPTERROR=85
E_GENERROR=25
OLD_IFS="$IFS"
IFS=','

function usage() {
    echo -e "Syntax: `basename $0` [-h|-v] [-r <PROJECT_ROOT>] [-n <PHP_VERSION>]
\t-h: shows this help
\t-v: be verbose
\t-r <PROJECT_ROOT>: absolute path of the projcet root in the vagrant VM (no trailing slash)
\t\tWill default to ${DEFAULT_PROJECT_ROOT} if not specified
\t-n <PHP_VERSION>: [php5.4|php5.5|php5.6] if not passed it will install the default version
\t\tavailable from the official repo
\n"
}

function version() {
    echo -e "`basename $0` - LAMP Provisionin Script - version $VERSION\n"
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

# The expected flags
while getopts ":hvn:r:" Option
do
    case $Option in
        h ) version
            usage
            quit 0
            ;;
        v ) BE_VERBOSE=true
            ;;
        r ) [ ! -e $OPTARG ] && error "'$OPTARG' not accessible" && quit $E_OPTERROR
            PROJECT_ROOT=$OPTARG
            ;;
        n ) PHP_VERSION=$OPTARG
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

[[ -n $BE_VERBOSE ]] && echo -e "\n>>> PROJECT_ROOT: $PROJECT_ROOT"
[[ -n $BE_VERBOSE ]] && echo -e ">>> WEBROOT: $WEBROOT"
[[ -n $BE_VERBOSE ]] && echo -e ">>> PHP_VERSION: $PHP_VERSION"
[[ -n $BE_VERBOSE ]] && echo -e ">>> MYSQL_ROOT_PASS: $MYSQL_ROOT_PASS"
[[ -n $BE_VERBOSE ]] && echo -e ">>> APACHE_DEFAULT_VHOST: $APACHE_DEFAULT_VHOST\n"

[[ -n $BE_VERBOSE ]] && echo -e "\n--- Install MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASS" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASS" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/app-password-confirm password $MYSQL_ROOT_PASS" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASS" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQL_ROOT_PASS" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
#apt-get -y install mysql-server-5.5 phpmyadmin > /dev/null 2>&1
apt-get -y install mysql-server-5.5 > /dev/null 2>&1

mysql -uroot -p$MYSQL_ROOT_PASS -e "show databases;" > /dev/null 2>&1
if [[ $? -gt 0 ]]
then
    [[ -n $BE_VERBOSE ]] && echo -e "\n!!! Root pass not set, setting it via mysqladmin !!!\n"
    # let's try to set the root password the good ol' way
    mysqladmin -uroot password $MYSQL_ROOT_PASS
fi

#echo "Configuring MySQL"
#cp /universal-vagrant/configs/my.cnf /etc/mysql/my.cnf

if [[ -n $PHP_VERSION ]]
then
    if [[ $PHP_VERSION = 'php5.6' ]]
    then
        [[ -n $BE_VERBOSE ]] && echo -e "\n--- Adding PHP 5.6 repo ---\n"
        add-apt-repository ppa:ondrej/php5-5.6 > /dev/null 2>&1
        APACHE_DEFAULT_VHOST="/etc/apache2/sites-available/000-default.conf"
    elif [[ $PHP_VERSION = 'php5.5' ]]
    then
        [[ -n $BE_VERBOSE ]] && echo -e "\n--- Adding PHP 5.5 repo ---\n"
        add-apt-repository ppa:ondrej/php5 > /dev/null 2>&1
        APACHE_DEFAULT_VHOST="/etc/apache2/sites-available/000-default.conf"
    elif [[ $PHP_VERSION = 'php5.4' ]]
    then
        [[ -n $BE_VERBOSE ]] && echo -e "\n--- Adding PHP 5.4 repo ---\n"
        add-apt-repository ppa:ondrej/php5-oldstable > /dev/null 2>&1
    else
        version
        usage
        echo -e "\n!!! Parameter not understood. !!!"
        [[ -n $BE_VERBOSE ]] && echo -e "\n!!! Got $PHP_VERSION, it should be either php5.4, php5.5 or php5.6 !!! "
        quit $E_GENERROR
    fi

    [[ -n $BE_VERBOSE ]] && echo -e "\n--- Updating packages list ---\n"
    apt-get -qq update
fi

[[ -n $BE_VERBOSE ]] && echo -e "\n--- Installing PHP-specific packages ---\n"
apt-get -y install php5 apache2 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt php5-mysql php-apc > /dev/null 2>&1

[[ -n $BE_VERBOSE ]] && echo -e "\n--- Updating ownership of Apache ---\n"
APACHEUSR=`grep -c 'APACHE_RUN_USER=www-data' /etc/apache2/envvars`
APACHEGRP=`grep -c 'APACHE_RUN_GROUP=www-data' /etc/apache2/envvars`
if [ APACHEUSR ];
then
    sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/' /etc/apache2/envvars
fi
if [ APACHEGRP ];
then
    sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/' /etc/apache2/envvars
fi
sudo chown -R vagrant:www-data /var/lock/apache2

[[ -n $BE_VERBOSE ]] && echo -e "\n--- Enabling mod-rewrite ---\n"
a2enmod rewrite > /dev/null 2>&1

if [[ -n $PHP_VERSION ]] && [[ $PHP_VERSION = 'php5.5' || $PHP_VERSION = 'php5.6' ]]
then
    [[ -n $BE_VERBOSE ]] && echo -e "\n--- Replacing the default vhost file ---\n"
    cat > $APACHE_DEFAULT_VHOST << EOF
<VirtualHost *:80>
  DocumentRoot /var/www/public_html
  <Directory />
    Options +FollowSymLinks
    AllowOverride None
  </Directory>
  <Directory /var/www/public_html>
    Options -Indexes +FollowSymLinks +MultiViews
    AllowOverride all
    Order allow,deny
    allow from all
  </Directory>
</VirtualHost>
EOF
else
    [[ -n $BE_VERBOSE ]] && echo -e "\n--- Allowing Apache override to all ---\n"
    sed -i "s/AllowOverride None/AllowOverride All/g" $APACHE_DEFAULT_VHOST

    [[ -n $BE_VERBOSE ]] && echo -e "\n--- Setting document root to webroot directory ---\n"
    sed -i 's|DocumentRoot '$DEFAULT_WEBROOT'$|DocumentRoot '$WEBROOT'|g' $APACHE_DEFAULT_VHOST
    sed -i 's|'$DEFAULT_WEBROOT'/>$|'$WEBROOT'/>|g' $APACHE_DEFAULT_VHOST
fi

[[ -n $BE_VERBOSE ]] && echo -e "\n--- Linking the document root to webroot directory ---\n"
ln -sfn $PROJECT_ROOT $WEBROOT

[[ -n $BE_VERBOSE ]] && echo -e "\n--- We definitly need to see the PHP errors, turning them on ---\n"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini

[[ -n $BE_VERBOSE ]] && echo -e "\n--- Setting timezone to UTC ---\n"
sed -i "s/;date.timezone =.*/date.timezone = \"UTC\"/" /etc/php5/apache2/php.ini

#echo -e "\n--- Turn off disabled pcntl functions so we can use Boris ---\n"
#sed -i "s/disable_functions = .*//" /etc/php5/cli/php.ini

#echo -e "\n--- Configure Apache to use phpmyadmin ---\n"
#echo -e "\n\nListen 81\n" >> /etc/apache2/ports.conf
#cat > /etc/apache2/conf-available/phpmyadmin.conf << "EOF"
#<VirtualHost *:81>
#    ServerAdmin webmaster@localhost
#    DocumentRoot /usr/share/phpmyadmin
#    DirectoryIndex index.php
#    ErrorLog ${APACHE_LOG_DIR}/phpmyadmin-error.log
#    CustomLog ${APACHE_LOG_DIR}/phpmyadmin-access.log combined
#</VirtualHost>
#EOF
#a2enconf phpmyadmin > /dev/null 2>&1

[[ -n $BE_VERBOSE ]] && echo -e "\n--- Restarting Apache ---\n"
service apache2 restart > /dev/null 2>&1

[[ -n $BE_VERBOSE ]] && echo -e "\n--- Installing Composer for PHP package management ---\n"
curl --silent https://getcomposer.org/installer | php > /dev/null 2>&1
mv composer.phar /usr/local/bin/composer

#echo -e "\n--- Updating project components and pulling latest versions ---\n"
#cd /vagrant
#sudo -u vagrant -H sh -c "composer install" > /dev/null 2>&1
