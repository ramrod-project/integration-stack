#!/bin/bash

# This script deploys the docker stack.
# TODO:
# - add host entry for frontend
# - pull images before deploy

TAG=""
LOGLEVEL=""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$( echo $SCRIPT_DIR | sed 's/[^/]*$//g' )

# Get IPs
# IFCONFIG_OUTPUT=$(ifconfig -a | grep -v "lo\|docker" | grep -A 1 "Ethernet" | awk 'NR%3==2 {print $2}' | sed 's/addr://g')

# function readarray() {
#   local i=0
#   unset -v "$1"
#   while IFS= read -r "$1[i++]"; do :; done
#   eval "[[ \${$1[--i]} ]]" || unset "$1[i]"
# }

# readarray HOST_IPS < <(echo $IFCONFIG_OUTPUT)

DOCKER_IP=$(ifconfig -a | grep -A 1 "docker" | awk 'NR==2 {print $2}' | sed 's/addr://g')
sudo cp /etc/hosts /etc/hosts.bak
sudo bash -c 'echo "${DOCKER_IP}     frontend" >> /etc/hosts'

echo "***Added ${DOCKER_IP} to /etc/hosts as 'frontend'"

if ! [ $# == 4 ]; then
    echo "Please supply --tag and --loglevel arguments"
    echo "Usage: deploy.sh --tag <latest|dev|qa> --loglevel <DEBUG|INFO|WARN|ERROR|CRITICAL>"
    exit 1
fi

if ! [ $(which docker) ]; then
    echo "Docker install not detected!"
    exit 1
fi

ARGS=( $1 $3 )
i=1

for arg in "${ARGS[@]}"; do
    case $arg in
        "--tag")
            if ! [ "${TAG}" == "" ]; then
                echo "--tag already supplied!"
                exit 1
            fi
            if [ $i == 1 ]; then
                TAG=$2
                i=i+1
            else
                TAG=$4
                break
            fi
            ;;
        "--loglevel")
            if ! [ "${LOGLEVEL}" == "" ]; then
                echo "--loglevel already supplied!"
                exit 1
            fi
            if [ $i == 1 ]; then
                LOGLEVEL=$2
                i=i+1
            else
                LOGLEVEL=$4
                break
            fi
            ;;
        *) echo "argument ${arg} not recognized!";;
    esac
done

declare -a images=("ramrodpcp/database-brain" "ramrodpcp/backend-interpreter" "ramrodpcp/interpreter-plugin" "ramrodpcp/frontend-ui")
echo "Checking internet connection..."
if ! [[ $(ping -c 3 8.8.8.8) ]]; then
    echo "No internet connection! checking for local images..."
    for image in "${images[@]}"; do
        docker image inspect $image:$TAG >> /dev/null
        if ! [[ $? == 0 ]]; then
            echo "Unable to find image ${image}:${TAG} locally! Exiting..."
            exit 1
        fi
    done
else
    for image in "${images[@]}"; do
        echo "Pulling ${image}:${TAG}..."
        docker pull $image:$TAG >> /dev/null
        if ! [ $? == 0 ]; then
            echo "Unable to pull image ${image}:${TAG}! Exiting..."
            exit 1
        fi
    done
fi

crtl_c() {
    echo "Tearing down stack..."
    docker stack rm pcp-test >> /dev/null
    echo "Removing leftover containers..."
    docker ps | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker stop {} 2>&1; fi >>/dev/null' && \
    docker ps | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then rm stop {} 2>&1; fi >>/dev/null'
    echo "Pruning networks..."
    docker network prune -f >> /dev/null
    echo "Restoring hosts file..."
    sudo cp /etc/hosts.bak /etc/hosts
    exit 0
}

trap crtl_c SIGINT
trap ctrl_c SIGTSTP

docker swarm init >>/dev/null
docker network create --driver=overlay --attachable pcp >>/dev/null

echo "Deploying stack..."
TAG=$TAG LOGLEVEL=$LOGLEVEL docker stack deploy -c $BASE_DIR/docker/docker-compose.yml pcp-test >> /dev/null

echo "You can reach the frontend from this machine at 'http://frontend:8080'."
echo "If you need to access from another machine or VM host, \
be sure to add this machine's IP to the hostfile as 'frontend'"
echo "Running stack, press <CRTL-C> to stop..."
while true; do
    sleep 1
done