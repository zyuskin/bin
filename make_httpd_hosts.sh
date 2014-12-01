#!/bin/bash
# Скрипт для автоматического создания хостов на основании
# списка директорий в ~/Sites/*.dev

SITES_DIR=/Users/zyuskin_en/Sites/
HTTPD_CONFIG_DIR=/etc/apache2/other/
DOMAIN_SUFFIX=dev

NEED_RESTART=0

sites=`find $SITES_DIR -name "*.$DOMAIN_SUFFIX"`

for site in $sites; do
    name=`basename $site`
    cat /etc/hosts | grep "$name" > /dev/null 2>&1
    if [ ! $? -eq 0 ]; then
	echo "127.0.0.1 $name" >> /etc/hosts
    fi;
    ls -la $HTTPD_CONFIG_DIR | grep "$name.conf" > /dev/null 2>&1
    if [ ! $? -eq 0 ]; then
	echo "<VirtualHost *:80>" > $HTTPD_CONFIG_DIR$name.conf
	echo "DocumentRoot $SITES_DIR$name/" >> $HTTPD_CONFIG_DIR$name.conf
	echo "ServerName $name" >> $HTTPD_CONFIG_DIR$name.conf
	echo "</VirtualHost>" >> $HTTPD_CONFIG_DIR$name.conf
	NEED_RESTART=1
    fi
done;

sites=`find $HTTPD_CONFIG_DIR -name "*.$DOMAIN_SUFFIX.conf"`

for site in $sites; do
    name=`basename $site | cut -d. -f1`
    name=$name.dev

    ls -la $SITES_DIR | grep "$name" > /dev/null 2>&1
    if [ ! $? -eq 0 ]; then
	cat /etc/hosts | grep "$name" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
	    cat /etc/hosts | grep -v "$name" > /etc/hosts2
	    mv /etc/hosts2 /etc/hosts
	fi;
	rm -f $HTTPD_CONFIG_DIR$name.conf
	NEED_RESTART=1
    fi
done;


if [ $NEED_RESTART -eq 1 ]; then
    apachectl restart
fi