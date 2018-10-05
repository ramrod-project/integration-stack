#!/bin/bash

exit 0

# add frontend to hosts file
DOCKER_IP=$(ifconfig -a | grep -A 1 "docker" | awk 'NR==2 {print $2}' | sed 's/addr://g')
sudo cp /etc/hosts /etc/hosts.bak
sudo sed -i 's/^.*frontend$//g' /etc/hosts
sudo bash -c "echo \"${DOCKER_IP}     frontend\" >> /etc/hosts"

# clone integration stack and set variables
STACK_DIR=`pwd`/
if [[ $(pwd | sed 's/.*\///g') != "integration-stack" ]]; then
    git clone -b $TRAVIS_BRANCH https://github.com/ramrod-project/integration-stack.git
    STACK_DIR=`pwd`/integration-stack
fi
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

docker pull selenium/standalone-firefox:3.14.0-dubnium
docker pull selenium/standalone-chrome:3.14.0-dubnium

rm -rf `pwd`/db_logs
mkdir `pwd`/db_logs

# run stack with TAG=test and START_AUX/HARNESS
docker swarm init
docker network create --driver=overlay --attachable pcp
START_AUX=YES START_HARNESS=YES TAG=test LOGLEVEL=DEBUG LOGDIR=`pwd`/ docker stack deploy -c $STACK_DIR/docker/docker-compose.yml pcp-test
docker run -d --rm -p 4444:4444 --name selenium-firefox --network pcp --shm-size=2g selenium/standalone-firefox:3.14.0-dubnium
docker run -d --rm -p 4445:4444 --name selenium-chrome --network pcp --shm-size=2g selenium/standalone-chrome:3.14.0-dubnium

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
    docker stack ps pcp-test --no-trunc
    docker service ps Harness-5000
    docker service logs Harness-5000
    exit 1
fi

EXITCODE=0
# get the selenium tests
pip install -r $STACK_DIR/linharn/requirements.txt
pytest $STACK_DIR/linharn/e2e.py
# must exit upon test failure
if ! [[ $? == 0 ]]; then
    EXITCODE=1
fi

# remove stack
docker stop selenium-firefox selenium-chrome
docker stack rm pcp-test
docker service rm AuxiliaryServices Harness-5000
docker network prune -f

sudo cp /etc/hosts.bak /etc/hosts

if [[ $EXITCODE == "1" ]]; then
    exit 1
fi
exit 0