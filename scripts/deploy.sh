#!/bin/bash

# This script deploys the docker stack. Only works on Ubuntu 16.04 at the moment.
# TODO:
# - add default arguments

# Arguments
TAG=""
LOGLEVEL=""

# Get directory info
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
BASE_DIR="$( echo $SCRIPT_DIR | sed 's/[^/]*$//g' )"

# Prevent CRTL-C echo
stty -echoctl

# Valid arguments
declare -a VALID_TAGS=( "dev" "qa" "latest" )
declare -a VALID_LOGLEVELS=( "DEBUG" "INFO" "WARN" "ERROR" "CRITICAL" )

# Images
declare -a images=( "database-brain" "backend-controller" "interpreter-plugin" "interpreter-plugin-extra" "frontend-ui" "websocket-server" "auxiliary-services" "auxiliary-wrapper")

if ! [[ $(whoami) == "root" ]]; then
    echo "Please run script as sudo!"
    exit 1
fi

if [[ "$TAG" == "qa" ]]; then
    images+=( "robot-framework-xvfb" )
fi

# Arg parser
function parse_args() {

    ARGS=( "$@" )

    if ! [[ $# == 4 ]] && ! [[ $# == 2 ]]; then
        echo "Usage: deploy.sh --tag <latest|dev|qa> --loglevel <DEBUG|INFO|WARN|ERROR|CRITICAL>"
        exit 1
    fi

    i=1
    if [[ $# == 2 ]]; then
        i=i+1
    fi

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
                elif [[ $# == 2 ]]; then
                    validate_tag $2
                    TAG=$2
                    break
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
                elif [[ $# == 2 ]]; then
                    validate_loglevel $2
                    LOGLEVEL=$2
                    break
                else
                    validate_loglevel $4
                    LOGLEVEL=$4
                    break
                fi
                ;;
            *) continue;;
        esac
    done
}

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

function crtl_c() {
    echo "Tearing down stack..."
    docker stack rm pcp-test 2>&1 >>/dev/null
    echo "Removing leftover services..."
    docker service ls | grep -v ID | awk '{print $1}' | xargs docker service rm 2>&1 1>>/dev/null
    echo "Removing leftover containers..."
    docker ps | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker stop {} 2>&1; fi >>/dev/null'
    docker ps -a | grep -v CONTAINER | awk '{print $1}' | xargs -I {} bash -c 'if [[ {} ]]; then docker rm {} 2>&1; fi >>/dev/null'
    echo "Pruning networks..."
    docker network prune -f >> /dev/null
    echo "Restoring hosts file..."
    sudo cp /etc/hosts.bak /etc/hosts
    exit 0
}

function pull_latest() {
    for image in "${images[@]}"; do
        echo "Attempting to pull ramrodpcp/${image}:${TAG}..."
        docker pull ramrodpcp/$image:$TAG
        if ! [[ $? == 0 ]]; then
            echo "Unable to pull image ${image}:${TAG}!"
        fi
    done
}

function set_hosts() {
    DOCKER_IP=$(docker node inspect -f "{{.Status.Addr}}" `docker node ls | grep Leader | awk '{print $3}'`)

    cp /etc/hosts /etc/hosts.bak 2>&1 1>>/dev/null
    sed -i 's/^.*frontend$//g' /etc/hosts 2>&1 1>>/dev/null
    bash -c "echo \"${DOCKER_IP}     frontend\" >> /etc/hosts" 2>&1 1>>/dev/null
    if ! [[ $? == 0 ]]; then
        echo "Could not add ${DOCKER_IP} to host file! Did you run as sudo?"
        exit 1
    else
        echo "***Added ${DOCKER_IP} to /etc/hosts as 'frontend'"
    fi
}

if ! [[ $(docker --version | grep 18.) ]]; then
    echo "Docker 18.x-ce install not detected! Exiting..."
    exit 2
fi

if [[ $# > 0 ]]; then
    parse_args $@
fi

if [[ "$TAG" == "" ]]; then
    TAG="latest"
fi

if [[ "$LOGLEVEL" == "" ]]; then
    LOGLEVEL="INFO"
fi

# Avoid weird error
docker logout 2>&1 1>>/dev/null

# Pull latest if available
PS3="Attempt to pull latest images?"
options=( "Yes" "No" "exit" )
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            pull_latest
            break
            ;;
        "No")
            break
            ;;
        "exit")
            exit 0
            ;;
        *) echo "invalid option";;
    esac
done

# Check locally for images
for image in "${images[@]}"; do
    docker image inspect ramrodpcp/$image:$TAG >> /dev/null
    if ! [[ $? == 0 ]]; then
        echo "Unable to find image ${image}:${TAG} locally!"
        exit
    fi
done

echo ''

# Check if Harness should be started
START_HARNESS=""
PS3="Start the 'Harness' plugin on stack deployment?"
options=( "Yes" "No" "exit" )
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            START_HARNESS="YES"
            break
            ;;
        "No")
            START_HARNESS="NO"
            break
            ;;
        "exit")
            exit
            ;;
        *) echo "invalid option";;
    esac
done

# Check if Harness should be started
START_AUX=""
PS3="Start the Aux services plugin on stack deployment?"
options=( "Yes" "No" "exit" )
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            START_AUX="YES"
            break
            ;;
        "No")
            START_AUX="NO"
            break
            ;;
        "exit")
            exit
            ;;
        *) echo "invalid option";;
    esac
done

# Initialize swarm
if [[ $(docker node inspect $(hostname) --format='{{.ManagerStatus.Leader}}'  2>&1) == true ]]; then
    if [[ $(ifconfig | grep $(docker node inspect $(hostname) --format='{{.ManagerStatus.Addr}} 2>&1' | sed 's/:.*//g')) ]]; then
        echo "host already part of swarm! Use join token:"
        docker swarm join-token manager -q
    fi
else
    docker swarm leave --force 2>&1 1>>/dev/null
    read -p 'Enter the IP address to listen on: ' STACK_IP
    docker swarm init --listen-addr $STACK_IP:2377 --advertise-addr $STACK_IP
fi

if ! [[ $(docker network ls | grep pcp) ]]; then
    docker network create --driver=overlay --attachable pcp 2>&1 1>>/dev/null
fi

# Trap signals
trap crtl_c SIGINT
trap ctrl_c SIGTSTP

# Deploy stack and watch
set_hosts
echo "Deploying stack..."
rm -rf $BASE_DIR/db_logs
mkdir $BASE_DIR/db_logs
START_AUX=$START_AUX START_HARNESS=$START_HARNESS TAG=$TAG LOGLEVEL=$LOGLEVEL LOGDIR=$BASE_DIR docker stack deploy -c $BASE_DIR/docker/docker-compose.yml pcp-test 2>&1 1>>/dev/null

echo "You can reach the frontend from this machine at 'http://frontend:8080'."
echo "If you need to access from another machine or VM host, \
be sure to add this machine's IP to the hostfile as 'frontend'"
echo "Running stack, press <CRTL-C> to stop..."
watch -d docker service ls
while true; do
    sleep 1
done