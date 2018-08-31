#!/bin/bash

# TODO:
# - add selenium tests

# clone integration stack and set variables
git clone -b $TRAVIS_BRANCH https://github.com/ramrod-project/integration-stack.git
declare -a images=( "backend-controller" "interpreter-plugin" "database-brain" "frontend-ui" "websocket-server" "auxiliary-services" "auxiliary-wrapper" )
testImage=$(docker images | grep -v IMAGE |  awk '$2 == "test" {print $1}')

# initialize images array
# check images against built test image to see which one
# to not pull/tag.
pullImages=()
for img in "${images[@]}"; do
    if ! [[ $testImage == "ramrodpcp/$img" ]]; then
        pullImages+=( "ramrodpcp/${img}" )
    fi
done

# pull TAG images for full stack. 
# tag all of those as :test (make sure that built container is also tagged as :test)
for img in "${pullImages[@]}"; do
    docker pull $img:$TAG
    docker tag $img:$TAG $img:test
done

# get the docker-compose file
curl https://raw.githubusercontent.com/ramrod-project/integration-stack/$TRAVIS_BRANCH/docker/docker-compose.yml > docker-compose.yml

# run stack with TAG=test and START_AUX/HARNESS
docker swarm init
docker network create --driver=overlay --attachable pcp
rm -rf db_logs
mkdir db_logs
START_AUX=YES START_HARNESS=YES TAG=test LOGLEVEL=DEBUG LOGDIR=./ docker stack deploy -c ./docker-compose.yml pcp-test

# wait until all services start
counter=0
while (( counter < 45 )); do
    if ! [[ $(docker service ls | grep 0/1) ]]; then
        if [[ $(docker ps | grep Harness | grep healthy) ]]; then
            break
        fi
    fi
    sleep 1
    counter=$(( counter+1 ))
done

if (( counter > 44 )); then
    echo "Harness not healthy within timeout: ${counter}s"
    exit 1
fi

# get the selenium tests
# pip install pytest
# run selenium tests "pytest ..."

# remove stack
docker stack rm pcp-test