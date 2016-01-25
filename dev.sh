#!/bin/bash

IP_ADDRESS=${1:-127.0.0.1}
SOLRDELAY=${SOLRDELAY:-10} # interval to wait for dependent docker services to initialize
MYSQL_ROOT_PASSWORD=123456
PORT=${DOCKERPORT:-80}
DB_READY=0
TRIES=0
MAX_TRIES=12
export SOLR=4.10.4

docker stop open-oni-dev || true
docker rm open-oni-dev || true

# start_container $1 = name of container, $2 = container running status
start_container () {
  echo "Existing $1 container found"
  if [ "$2" == "false" ]; then
    docker start $1
  fi
}  

# Make sure settings_local.py exists so the app doesn't crash
if [ ! -f open-oni/settings_local.py ]; then
  touch open-oni/settings_local.py
fi

# Make persistent data containers
# If these containers are removed, you will lose all mysql and solr data
DATA_MYSQL_STATUS=$(docker inspect --type=container --format="{{ .State.Running }}" data_mysql 2> /dev/null)
if [ -z "$DATA_MYSQL_STATUS" ]; then
  echo "Creating a data container for mysql ..."
  docker create -v /var/lib/mysql --name data_mysql mysql
fi
DATA_SOLR_STATUS=$(docker inspect --type=container --format="{{ .State.Running }}" data_solr 2> /dev/null)
if [ -z "$DATA_SOLR_STATUS" ]; then
  echo "Creating a data container for solr ..."
  docker create -v /opt/solr --name data_solr makuk66/docker-solr:$SOLR
fi

# Make containers for mysql and solr
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
    --volumes-from data_mysql \
    mysql

  while [ $DB_READY == 0 ]
  do
   if
     ! docker exec mysql mysql -uroot -p$MYSQL_ROOT_PASSWORD \
       -e 'ALTER DATABASE openoni charset=utf8' > /dev/null 2>/dev/null
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
  start_container "mysql" $MYSQL_STATUS
fi

SOLR_STATUS=$(docker inspect --type=container --format="{{ .State.Running }}" solr 2> /dev/null)
if [ -z "$SOLR_STATUS" ]; then
  echo "Starting solr ..."
  docker run -d \
    -p 8983:8983 \
    --name solr \
    -v /$(pwd)/solr/schema.xml:/opt/solr/example/solr/collection1/conf/schema.xml \
    -v /$(pwd)/solr/solrconfig.xml:/opt/solr/example/solr/collection1/conf/solrconfig.xml \
    --volumes-from data_solr \
    makuk66/docker-solr:$SOLR && sleep $SOLRDELAY
else
  start_container "solr" $SOLR_STATUS
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
