#!/bin/bash

DELAY=10 # interval to wait for dependent docker services to initialize

docker stop chronam-dev || true
docker rm chronam-dev || true

echo "Building chronam for development"
docker build -t chronam:dev -f Dockerfile-dev .

echo "Starting mysql ..."
docker run -d \
  -p 3306:3306 \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -e MYSQL_DATABASE=chronam \
  -e MYSQL_USER=chronam \
  -e MYSQL_PASSWORD=chronam \
  mysql || true

sleep $DELAY
mysql -h 127.0.0.1 -u root --password=123456 -e 'ALTER DATABASE chronam charset=utf8;'

echo "Starting solr ..."
export SOLR=4.10.4
docker run -d \
  -p 8983:8983 \
  --name solr \
  -v /$(pwd)/solr/schema.xml:/opt/solr/example/solr/collection1/conf/schema.xml \
  -v /$(pwd)/solr/solrconfig.xml:/opt/solr/example/solr/collection1/conf/solrconfig.xml \
  makuk66/docker-solr:$SOLR || true

sleep $DELAY

echo "Starting chronam for development ..."
docker run -i -t \
  -p 80:80 \
  --name chronam-dev \
  --link mysql:db \
  --link solr:solr \
  -v $(pwd)/chronam/core:/opt/chronam/core \
  -v $(pwd)/data:/opt/chronam/data \
  chronam:dev
