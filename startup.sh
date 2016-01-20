#!/bin/bash

if [ ! -d /opt/openoni/ENV ]; then
  /pip-install.sh
fi

source /opt/openoni/ENV/bin/activate

sed -i "s/!DB_HOST!/$DB_PORT_3306_TCP_ADDR/g" /opt/openoni/settings_local.py
sed -i "s/!SOLR_HOST!/$SOLR_PORT_8983_TCP_ADDR/g" /opt/openoni/settings_local.py
sed -i "s/!SECRET_KEY!/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 80)/g" /opt/openoni/settings_local.py

cd /opt/openoni
django-admin.py syncdb --noinput --migrate
django-admin.py openoni_sync --skip-essays
django-admin.py collectstatic --noinput


# Remove any pre-existing PID file which prevents Apache from starting
#   thus causing the container to close immediately after
#   See: https://github.com/docker-library/php/pull/59
rm -f /var/run/apache2/apache2.pid

source /etc/apache2/envvars
exec apache2 -D FOREGROUND
