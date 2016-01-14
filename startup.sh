#!/bin/bash

source /opt/chronam/ENV/bin/activate

sed -i "s/!DB_HOST!/$DB_PORT_3306_TCP_ADDR/g" /opt/chronam/settings.py
sed -i "s/!SOLR_HOST!/$SOLR_PORT_8983_TCP_ADDR/g" /opt/chronam/settings.py

cd /opt/chronam
django-admin.py syncdb --noinput --migrate
django-admin.py chronam_sync --skip-essays
django-admin.py collectstatic --noinput


# Remove any pre-existing PID file which prevents Apache from starting
#   thus causing the container to close immediately after
#   See: https://github.com/docker-library/php/pull/59
rm -f /var/run/apache2/apache2.pid

source /etc/apache2/envvars
exec apache2 -D FOREGROUND