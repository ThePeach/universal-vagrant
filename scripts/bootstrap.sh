#!/bin/bash

echo -e "\n--- Updating packages ---\n"
apt-get -qq update

echo -e "\n--- Install base packages ---\n"
apt-get -y install vim curl build-essential python-software-properties git > /dev/null 2>&1
 
#echo -e "\n--- Add some repos to update our distro ---\n"
#add-apt-repository ppa:ondrej/php5 > /dev/null 2>&1
#add-apt-repository ppa:chris-lea/node.js > /dev/null 2>&1
 
echo -e "\n--- Updating packages list ---\n"
apt-get -qq update
 
