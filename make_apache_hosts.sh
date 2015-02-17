#!/bin/bash
# Скрипт для автоматического создания хостов на основании
# списка директорий в ~/Sites/*.dev

SITES_DIR=/home/zyuskin_en/Sites/
APACHE_CONFIG_DIR=/etc/apache2/sites-enabled/
DOMAIN_SUFFIX=dev
APACHECTL=`which apachectl`

[ -f ~/.makeapachehosts ] && . ~/.makeapachehosts

NEED_RESTART=0

sites=`find $SITES_DIR -name "*.$DOMAIN_SUFFIX"`

for site in $sites; do
    name=`basename $site`

    # Заплатка для хостов у которых корень вынесен в web
    if [ -f "${site}/web/index.php" ] || [ -f "${site}/web/app.php" ]; then
	path="${site}/web"
    else
	path="$site"
    fi

    [ "`echo $name | cut -c1-4`" == "www." ] && alias=`echo $name | cut -c5-` || alias=""

    cat /etc/hosts | grep "$name" > /dev/null 2>&1
    if [ ! $? -eq 0 ]; then
	echo "127.0.0.1 $name $alias" >> /etc/hosts
    fi;

    ls -la $APACHE_CONFIG_DIR | grep "$name.conf" > /dev/null 2>&1
    if [ ! $? -eq 0 ]; then
	echo "<VirtualHost *:80>" > $APACHE_CONFIG_DIR$name.conf
	echo "DocumentRoot $path/" >> $APACHE_CONFIG_DIR$name.conf
	echo "ServerName $name" >> $APACHE_CONFIG_DIR$name.conf
	if [ "$alias" != "" ]; then
	    echo "ServerAlias $alias" >> $APACHE_CONFIG_DIR$name.conf
	fi
	echo "</VirtualHost>" >> $APACHE_CONFIG_DIR$name.conf
	NEED_RESTART=1
    fi
done;

sites=`find $APACHE_CONFIG_DIR -name "*.$DOMAIN_SUFFIX.conf"`

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
	rm -f $APACHE_CONFIG_DIR$name.conf
	NEED_RESTART=1
    fi
done;


[ $NEED_RESTART -eq 1 ] && $APACHECTL restart
