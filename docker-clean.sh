#!/usr/bin/env bash
#
# Stop and remove the docker containers necessary for open ONI
# except for the persistent data containers

echo "stopping ..."
docker stop openoni-dev
docker stop openoni-dev-mysql
docker stop openoni-dev-solr
docker stop openoni-dev-rais

echo "removing ..."
docker rm openoni-dev
docker rm openoni-dev-mysql
docker rm openoni-dev-solr
docker rm openoni-dev-rais

echo "Run ./dev.sh to set your environment back up"
