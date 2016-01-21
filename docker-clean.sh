#!/usr/bin/env bash
#
# Cleans everything docker can leave behind.  NOT to be used in a production
# environment.  You should probably be a little less brute-force with your
# cleaning if you're not just developing stuff.
docker rm $(docker ps -qa)
docker rmi $(docker images | grep "<none>" | awk '{print $3}')
