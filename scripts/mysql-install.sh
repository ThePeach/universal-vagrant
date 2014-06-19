#!/bin/bash

DB_USER=root
DB_PASS=password

echo -e "\n--- Install MySQL specific packages and settings ---\n"
echo "mysql-server mysql-server/root_password password $DB_PASS" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DB_PASS" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/app-password-confirm password $DB_PASS" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DB_PASS" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/mysql/app-pass password $DB_PASS" | debconf-set-selections
#echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
#apt-get -y install mysql-server-5.5 phpmyadmin > /dev/null 2>&1
apt-get -y install mysql-server-5.5 > /dev/null 2>&1
 
#echo "Configuring MySQL"
#cp /universal-vagrant/configs/my.cnf /etc/mysql/my.cnf

echo -e "\n--- Installing PHP-specific packages ---\n"
apt-get -y install php5 apache2 libapache2-mod-php5 php5-curl php5-gd php5-mcrypt php5-mysql php-apc > /dev/null 2>&1

echo -e "\n--- Updating ownership of Apache ---\n"
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

echo -e "\n--- Enabling mod-rewrite ---\n"
a2enmod rewrite > /dev/null 2>&1
 
echo -e "\n--- Allowing Apache override to all ---\n"
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/sites-available/default
 
echo -e "\n--- Setting document root to webroot directory ---\n"
#rm -rf /var/www/default/public_html
ln -sf /vagrant/webroot /var/www/public_html
sed -i "s/DocumentRoot\ \/var\/www$/DocumentRoot\ \/var\/www\/public_html/g" /etc/apache2/sites-available/default
sed -i "s/\/var\/www\/>$/\/var\/www\/public_html\/>/g" /etc/apache2/sites-available/default
 
echo -e "\n--- We definitly need to see the PHP errors, turning them on ---\n"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/apache2/php.ini
 
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

#echo -e "\n--- Add environment variables to Apache ---\n"
#cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
#<VirtualHost *:80>
#    DocumentRoot /var/www/default/public_html
#    ErrorLog \${APACHE_LOG_DIR}/error.log
#    CustomLog \${APACHE_LOG_DIR}/access.log combined
#</VirtualHost>
#EOF

echo -e "\n--- Restarting Apache ---\n"
service apache2 restart > /dev/null 2>&1
                                 
echo -e "\n--- Installing Composer for PHP package management ---\n"
curl --silent https://getcomposer.org/installer | php > /dev/null 2>&1
mv composer.phar /usr/local/bin/composer
 
#echo -e "\n--- Updating project components and pulling latest versions ---\n"
#cd /vagrant
#sudo -u vagrant -H sh -c "composer install" > /dev/null 2>&1

