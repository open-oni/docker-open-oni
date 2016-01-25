#!/bin/bash

IP_ADDRESS=${1:-127.0.0.1}
SOLRDELAY=${SOLRDELAY:-10} # interval to wait for dependent docker services to initialize
MYSQL_ROOT_PASSWORD=123456
PORT=${DOCKERPORT:-80}
DB_READY=0
TRIES=0
MAX_TRIES=12

docker stop open-oni-dev || true
docker rm open-oni-dev || true

# Make sure settings_local.py exists so the app doesn't crash
if [ ! -f open-oni/settings_local.py ]; then
  touch open-oni/settings_local.py
fi

echo "Building open-oni for development"
docker build -t open-oni:dev -f Dockerfile-dev .

MYSQL_STATUS=$(docker inspect --type=container --format="{{ .State.Running }}" mysql 2> /dev/null)
if [ -z "$MYSQL_STATUS" ]; then
  echo "Starting mysql ..."
  docker run -d \
    -p 3306:3306 \
    --name mysql \
    -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
    -e MYSQL_DATABASE=openoni \
    -e MYSQL_USER=openoni \
    -e MYSQL_PASSWORD=openoni \
    -v /$(pwd)/open-oni/conf/openoni.cnf:/etc/mysql/conf.d/openoni.cnf \
    mysql

  while [ $DB_READY == 0 ]
  do
   if
     ! docker exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD \
       -e 'SHOW DATABASES' > /dev/null 2>/dev/null
   then
     sleep 5
     let TRIES++
     echo "Looks like we're still waiting for MySQL ... 5 more seconds ... retry $TRIES of $MAX_TRIES"
     if [ "$TRIES" = "$MAX_TRIES" ]
     then
      echo "Looks like we couldn't get MySQL running. Could you check settings and try again?"
      exit 2
     fi
   else
     DB_READY=1
   fi
  done

  # set up access to a test database, for masochists
  echo "setting up a test database ..."
  docker exec mysql mysql -u root --password=$MYSQL_ROOT_PASSWORD -e 'USE mysql;
  GRANT ALL on test_openoni.* TO "openoni"@"%" IDENTIFIED BY "openoni";';
else
  echo "Existing mysql container found"
  if [ "$MYSQL_STATUS" == "false" ]; then
    docker start mysql
  fi
fi

SOLR_STATUS=$(docker inspect --type=container --format="{{ .State.Running }}" solr 2> /dev/null)
if [ -z "$SOLR_STATUS" ]; then
  echo "Starting solr ..."
  export SOLR=4.10.4
  docker run -d \
    -p 8983:8983 \
    --name solr \
    -v /$(pwd)/solr/schema.xml:/opt/solr/example/solr/collection1/conf/schema.xml \
    -v /$(pwd)/solr/solrconfig.xml:/opt/solr/example/solr/collection1/conf/solrconfig.xml \
    makuk66/docker-solr:$SOLR && sleep $SOLRDELAY
else
  echo "Existing solr container found"
    if [ "$SOLR_STATUS" == "false" ]; then
      docker start solr
    fi
 fi
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
