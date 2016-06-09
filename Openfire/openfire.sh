#!/bin/bash
##################################################
# Name: openfire.sh
# Description: Openfire installer
# Script Maintainer: Rafael
#
# Versão: 0.1
# Last Updated: June 8th 2016
##################################################
# 
: << 'Description'
	This is the installer of the openfire server on debian jessie 8.
Description
##################################################
#Include source file with text functions
#
echo "Verifying Dependencies"
echo ""
sleep 2
if [ ! -f textfuncs.fnc ]; then
echo "Downloading configuration file"
echo ""
sleep 2
wget goo.gl/4ATfHz -O textfuncs.fnc
fi
sleep 3
source textfuncs.fnc

##Fist things to do
##Set Fixed IP on the server and choose the version

ipAddress=135
openFireVersion="openfire_4.0.2_all.deb"

SuggestParameters $ipAddress

Colorize 3 "You will be asked to create a password for the mysql database"
echo ""
sleep 4
##Install essencial packets
echo "Updating apt base"
	apt-get update &> /dev/null
echo "Installing essencial programs"
aptitude install -y mysql-server apache2 php5 php5-mysql libmysql-java libapache2-mod-auth-mysql openjdk-7-jre 

Colorize 2  "Please insert the Mysql Password here: "
echo ""
echo "Creating database openfire"
mysql -ubackup -u root -p $mysqlPswd -e 'create database openfire'
echo "Creating directory to store the openfire files"
mkdir -p /root/openfire/
cd /root/openfire
echo "Downloading $openFireVersion"
wget https://www.igniterealtime.org/downloadServlet?filename=openfire/$openFireVersion -O $openFireVersion

echo "Now we are going to start the instalation of openfire on your system"
chmod +x $openFireVersion
dpkg -i $openFireVersion

echo "We finish here now open a browser on your desktop on the address http://$R_IP:9090 and continue from there"



