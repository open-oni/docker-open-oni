#!/bin/bash

source /opt/openoni/ENV/bin/activate

sed -i "s/!DB_HOST!/$DB_PORT_3306_TCP_ADDR/g" /opt/openoni/settings.py
sed -i "s/!SOLR_HOST!/$SOLR_PORT_8983_TCP_ADDR/g" /opt/openoni/settings.py

cd /opt/openoni
django-admin.py syncdb --noinput --migrate
django-admin.py openoni_sync --skip-essays
django-admin.py collectstatic --noinput

source /etc/apache2/envvars
exec apache2 -D FOREGROUND