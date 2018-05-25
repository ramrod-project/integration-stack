#!/bin/bash

# This script deploys the docker stack. Only works on Ubuntu 16.04 at the moment.
# TODO:
# - change hosts environment variable

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

cp /etc/hosts /etc/hosts.bak
bash -c "echo \"${DOCKER_IP}     frontend\" >> /etc/hosts"
echo "***Added ${DOCKER_IP} to /etc/hosts as 'frontend'"

declare -a images=("ramrodpcp/database-brain" "ramrodpcp/backend-interpreter" "ramrodpcp/interpreter-plugin" "ramrodpcp/frontend-ui")
for image in "${images[@]}"; do
    docker image inspect $image:$TAG >> /dev/null
    if ! [[ $? == 0 ]]; then
        echo "Unable to find image ${image}:${TAG} locally!"
    fi
done

crtl_c() {
    echo "Tearing down stack..."
    docker stack rm pcp-test 2>&1 >>/dev/null
    echo "Removing leftover containers..."
    docker ps | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker stop {} 2>&1; fi >>/dev/null'
    docker ps -a | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker rm {} 2>&1; fi >>/dev/null'
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

echo "Opening ports 8080/5000 on firewall..."
ufw allow 5000
ufw allow 8080

echo "Deploying stack..."
TAG=$TAG LOGLEVEL=$LOGLEVEL docker stack deploy -c $BASE_DIR/docker/docker-compose.yml pcp-test >> /dev/null

echo "You can reach the frontend from this machine at 'http://frontend:8080'."
echo "If you need to access from another machine or VM host, \
be sure to add this machine's IP to the hostfile as 'frontend'"
echo "Running stack, press <CRTL-C> to stop..."
while true; do
    sleep 1
done