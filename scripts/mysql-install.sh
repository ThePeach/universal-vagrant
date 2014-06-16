#!/bin/bash

echo "Installing MySQL"
echo mysql-server mysql-server/root_password select "password" | debconf-set-selections
echo mysql-server mysql-server/root_password_again select "password" | debconf-set-selections
apt-get install -y -qq mysql-server

echo "Configuring MySQL"
cp /universal-vagrant/configs/my.cnf /etc/mysql/my.cnf

echo "Restarting MySQL"
service mysql restart


