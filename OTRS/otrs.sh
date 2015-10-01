#!/bin/bash
##################################################
# Name: OTRS Installer
# Description: Instalation of OTRS 4.0.13 on Debian Jessie 8.10
# Script Maintainer: Rafael
#
# Versão: 1.0
# Last Updated: October 1st 2015
##################################################
############ OTRS Instalation Specs ############## 
# 
OTRSVERSAO=otrs-4.0.13
#OTRSVERSAO=otrs-5.0.0.beta5

apt-get update && apt-get upgrade --show-upgraded
apt-get install -y apache2 libapache2-mod-perl2 mysql-server
apt-get install -y libdbd-odbc-perl libarchive-zip-perl libcrypt-eksblowfish-perl libcrypt-ssleay-perl libtimedate-perl libencode-hanextra-perl libgd-gd2-perl libgd-text-perl libgd-graph-perl libio-socket-ssl-perl libjson-xs-perl libmail-imapclient-perl libio-socket-ssl-perl libnet-dns-perl libnet-ldap-perl libpdf-api2-perl libtemplate-perl libtemplate-perl libtext-csv-xs-perl libxml-parser-perl libyaml-libyaml-perl
echo "Baixando a Versão $OTRSVERSAO"
wget ftp://ftp.otrs.org/pub/otrs/$OTRSVERSAO.tar.gz
sleep 10
echo "Descompactando e movendo para a pasta otrs"
tar xf $OTRSVERSAO.tar.gz
mv $OTRSVERSAO /opt/otrs

echo "Inclusao do usuario OTRS"
useradd -d /opt/otrs/ -c 'OTRS user' otrs
usermod -g www-data otrs

echo "Demais Ajustes Necessários"

cp /opt/otrs/Kernel/Config.pm.dist /opt/otrs/Kernel/Config.pm
cp /opt/otrs/Kernel/Config/GenericAgent.pm.dist /opt/otrs/Kernel/Config/GenericAgent.pm

echo "Permissoes para o Apache"
/opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data
cp /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-available/otrs.conf && a2enconf otrs.conf
/etc/init.d/apache2 restart
echo "Ajustes no Mysql"
mysql --user="root" -p --execute="SET GLOBAL innodb_fast_shutdown = 0;"
echo "Desligando o serviço Mysql"
/etc/init.d/mysql stop
echo "Apagando Logs Mysql"
rm -rf /var/lib/mysql/ib_logfile*
echo "Alteração do arquivo my.sql"
sed -i "/max_allowed_packet/{H;x;/^\n/d;g;}" /etc/mysql/my.cnf
sleep 5
sed -i "s/skip-external-locking/&\ninnodb_log_file_size = 256M/;s/thread_stack\t\t= 192K/max_allowed_packet\t= 20M\n&/" /etc/mysql/my.cnf
echo "Reiniciando o Mysql"
/etc/init.d/mysql start

cd /opt/otrs/var/cron
for foo in *.dist; do cp $foo `basename $foo .dist`; done
/opt/otrs/bin/Cron.sh start otrs
crontab -l -u otrs
