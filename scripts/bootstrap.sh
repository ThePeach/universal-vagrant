#!/bin/bash

echo -e "\n--- Updating packages ---\n"
apt-get -qq update

echo -e "\n--- Install base packages ---\n"
apt-get -y install vim curl build-essential python-software-properties git > /dev/null 2>&1

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update
 
