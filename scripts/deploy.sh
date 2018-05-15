#!/bin/bash

# This script deploys the docker stack.

TAG=""
LOGLEVEL=""
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$( echo $SCRIPT_DIR | sed 's/[^/]*$//g' )

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

crtl_c() {
    docker stack rm pcp-test
    docker network prune -f
    exit 0
}

trap crtl_c SIGINT
trap ctrl_c SIGTSTP

docker swarm init 2>/dev/null
docker network create --driver=overlay --attachable pcp

TAG=$TAG LOGLEVEL=$LOGLEVEL docker stack deploy -c $BASE_DIR/docker/docker-compose.yml pcp-test

echo "Running stack, press <CRTL-C> to stop..."
while true; do
    sleep 1
done