#!/bin/bash

export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data
mkdir -p /var/tmp/django_cache && chown -R www-data:www-data /var/tmp/django_cache

source /opt/chronam/ENV/bin/activate

sed -i "s/!DB_HOST!/$DB_PORT_3306_TCP_ADDR/g" /opt/chronam/settings.py
sed -i "s/!SOLR_HOST!/$SOLR_PORT_8983_TCP_ADDR/g" /opt/chronam/settings.py

cd /opt/chronam
django-admin.py syncdb --noinput
django-admin.py chronam_sync --skip-essays
django-admin.py collectstatic --noinput

source /etc/apache2/envvars
exec apache2 -D FOREGROUND