#!/bin/bash

set -ex
source settings

#apt-get update
#apt-get upgrade

apt-get install -y python-mysqldb mysql-client curl
apt-get install -y python-keystone python-keystoneclient
apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms

sed -i 's/false/true/g' /etc/default/iscsitarget
service iscsitarget start
service open-iscsi start

# cinder Setup
mysql -h$MYSQL_HOST -uroot -p$MYSQL_ROOT_PASS -e 'DROP DATABASE IF EXISTS cinder;'
mysql -h$MYSQL_HOST -uroot -p$MYSQL_ROOT_PASS -e 'CREATE DATABASE cinder;'
echo "GRANT ALL ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '$MYSQL_SERVICE_PASS'; FLUSH PRIVILEGES;" | mysql -h$MYSQL_HOST -uroot -p$MYSQL_ROOT_PASS

# cinder-api-paste.init.tmpl
sed -e "s,%KEYSTONE_IP%,$KEYSTONE_IP,g" -e "s,%SERVICE_TENANT_NAME%,$SERVICE_TENANT_NAME,g" -e "s,%SERVICE_PASSWORD%,$SERVICE_PASSWORD,g" ./conf/cinder/api-paste.ini.tmpl > ./conf/cinder/api-paste.ini

# cinder.conf.tmpl
sed -e "s,%MYSQL_HOST%,$MYSQL_HOST,g" -e "s,%MYSQL_CINDER_PASS%,$MYSQL_SERVICE_PASS,g" ./conf/cinder/cinder.conf.tmpl > ./conf/cinder/cinder.conf

cp ./conf/cinder/api-paste.ini ./conf/cinder/cinder.conf /etc/cinder/
rm -f ./conf/cinder/api-paste.ini ./conf/cinder/cinder.conf 

chown cinder:cinder /etc/cinder/api-paste.ini
chown cinder:cinder /etc/cinder/cinder.conf

cinder-manage db sync

# create pyshical volume and volume group
#pvcreate ${CINDER_VOLUME} # CINDER_VOLUME = '/dev/sda6'
#vgcreate cinder-volumes ${CINDER_VOLUME}

# restart processes
service cinder-volume restart
service cinder-api restart

echo "cinder install over!"
sleep 1

