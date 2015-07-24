#!/bin/bash

docker build -t chronam:dev -f Dockerfile-dev .

docker stop chronam-dev || true
docker rm chronam-dev || true

docker run -i -t \
  -p 80:80 \
  --name chronam-dev \
  --link mysql:db \
  --link solr:solr \
  -v $(pwd)/chronam/core:/opt/chronam/core \
  -v $(pwd)/data:/opt/chronam/data \
  chronam:dev
