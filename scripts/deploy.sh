#!/bin/bash

# This script deploys the docker stack. Only works on Ubuntu 16.04 at the moment.
# TODO:
# - add default arguments


TAG=""
LOGLEVEL=""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$( echo $SCRIPT_DIR | sed 's/[^/]*$//g' )
DOCKER_IP=$(ifconfig -a | grep -A 1 "docker" | awk 'NR==2 {print $2}' | sed 's/addr://g')

stty -echoctl

declare -a VALID_TAGS=( "dev" "qa" "latest" )
declare -a VALID_LOGLEVELS=( "DEBUG" "INFO" "WARN" "ERROR" "CRITICAL" )

if ! [[ $# == 4 ]] && ! [[ $# == 2 ]]; then
    echo "Usage: deploy.sh --tag <latest|dev|qa> --loglevel <DEBUG|INFO|WARN|ERROR|CRITICAL>"
    exit 1
fi

if ! [[ $(docker --version | grep 18.) ]]; then
    echo "Docker 18.x-ce install not detected! Exiting..."
    exit 2
fi

function contains_element() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function validate_tag() {
    contains_element $1 "${VALID_TAGS[@]}"
    if ! [[ $? == 0 ]]; then
        echo "Please select one of: dev|qa|latest for tag"
        exit 3
    fi
}

function validate_loglevel() {
    contains_element $1 "${VALID_LOGLEVELS[@]}"
    if ! [[ $? == 0 ]]; then
        echo "Please select one of: DEBUG|INFO|WARN|ERROR|CRITICAL for loglevel"
        exit 3
    fi
}

ARGS=( $1 $3 )
i=1

for arg in "${ARGS[@]}"; do
    case $arg in
        "--tag")
            if ! [ "${TAG}" == "" ]; then
                echo "--tag already supplied!"
                exit 4
            fi
            if [[ $i == 1 ]]; then
                validate_tag $2
                TAG=$2
                i=i+1
            else
                validate_tag $4
                TAG=$4
                break
            fi
            ;;
        "--loglevel")
            if ! [[ "${LOGLEVEL}" == "" ]]; then
                echo "--loglevel already supplied!"
                exit 4
            fi
            if [[ $i == 1 ]]; then
                validate_loglevel $2
                LOGLEVEL=$2
                i=i+1
            else
                validate_loglevel $4
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

declare -a images=( "database-brain" "backend-interpreter" "interpreter-plugin" "frontend-ui" )

if [[ "$TAG" == "qa" ]]; then
    images+=( "robot-framework-xvfb" )
fi

for image in "${images[@]}"; do
    docker image inspect ramrodpcp/$image:$TAG >> /dev/null
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

echo "Deploying stack..."
TAG=$TAG LOGLEVEL=$LOGLEVEL docker stack deploy -c $BASE_DIR/docker/docker-compose.yml pcp-test >> /dev/null

echo "You can reach the frontend from this machine at 'http://frontend:8080'."
echo "If you need to access from another machine or VM host, \
be sure to add this machine's IP to the hostfile as 'frontend'"
echo "Running stack, press <CRTL-C> to stop..."
sleep 2
watch -d docker stack ps pcp-test
while true; do
    sleep 1
done