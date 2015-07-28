#!/bin/bash

IP_ADDRESS=${1:-127.0.0.1}
DELAY=${2:-20} # interval to wait for dependent docker services to initialize

docker stop open-oni-dev || true
docker rm open-oni-dev || true

echo "Building open-oni for development"
docker build -t open-oni:dev -f Dockerfile-dev .

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
mysql -h $IP_ADDRESS -u root --password=123456 -e 'ALTER DATABASE chronam charset=utf8;'

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
  --name open-oni-dev \
  --link mysql:db \
  --link solr:solr \
  -v $(pwd)/open-oni/core:/opt/chronam/core \
  -v $(pwd)/data:/opt/chronam/data \
  open-oni:dev
