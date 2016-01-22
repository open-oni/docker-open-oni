#!/bin/bash

IP_ADDRESS=${1:-127.0.0.1}
DELAY=${2:-10} # interval to wait for dependent docker services to initialize
MYSQL_ROOT_PASSWORD=123456
PORT=${DOCKERPORT:-80}

docker stop open-oni-dev || true
docker rm open-oni-dev || true

# Make sure settings_local.py exists so the app doesn't crash
if [ ! -f open-oni/settings_local.py ]; then
  touch open-oni/settings_local.py
fi

echo "Building open-oni for development"
docker build -t open-oni:dev -f Dockerfile-dev .

echo "Starting mysql ..."
docker run -d \
  -p 3307:3306 \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -e MYSQL_DATABASE=openoni \
  -e MYSQL_USER=openoni \
  -e MYSQL_PASSWORD=openoni \
  mysql

docker exec mysql mysqladmin -uroot -p$MYSQL_ROOT_PASSWORD --silent --wait=$DELAY ping || exit 1

docker exec mysql mysql -u root --password=$MYSQL_ROOT_PASSWORD -e 'ALTER DATABASE openoni charset=utf8';

# set up access to a test database, for masochists
docker exec mysql mysql -u root --password=$MYSQL_ROOT_PASSWORD -e 'USE mysql;
GRANT ALL on test_openoni.* TO "openoni"@"%" IDENTIFIED BY "openoni";';

echo "Starting solr ..."
export SOLR=4.10.4
docker run -d \
  -p 8983:8983 \
  --name solr \
  -v /$(pwd)/solr/schema.xml:/opt/solr/example/solr/collection1/conf/schema.xml \
  -v /$(pwd)/solr/solrconfig.xml:/opt/solr/example/solr/collection1/conf/solrconfig.xml \
  makuk66/docker-solr:$SOLR && sleep $DELAY

echo "Starting open-oni for development ..."

# Make sure subdirs are built
mkdir -p data/batches data/cache data/bib
docker run -i -t \
  -p $PORT:80 \
  --name open-oni-dev \
  --link mysql:db \
  --link solr:solr \
  -v $(pwd)/open-oni:/opt/openoni \
  -v $(pwd)/data:/opt/openoni/data \
  open-oni:dev
