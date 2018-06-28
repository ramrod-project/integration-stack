#!/bin/bash

# This exports only the files needed for deployment to 'production'
# TODO:

# Get directory info
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$( echo $SCRIPT_DIR | sed 's/[^/]*$//g' )

if ! [[ $# == 2 ]]; then
    echo "Please provide the export and plugin directories!"
    echo "Usage: dev-export.sh <exports_directory> <plugin_directory>"
    exit 1
fi

if ! [[ -d $1 ]]; then
    echo "Exports directory ${1} not found!"
    exit 2
fi

EXPORTS_DIR=$1

if ! [[ -d $2 ]]; then
    echo "Plugins directory ${2} not found!"
    exit 2
fi

PLUGINS_DIR=$2

PS3="Please select a release to export: "
options=( "dev" "qa" "latest" "exit" )
select opt in "${options[@]}"
do
    case $opt in
        "dev")
            TAG="dev"
            break
            ;;
        "qa")
            TAG="qa"
            break
            ;;
        "latest")
            TAG="latest"
            break
            ;;
        "exit")
            exit
            ;;
        *) echo "invalid option";;
    esac
done

read -p 'Please the ports needed by your plugin(s) separated by a space: ' PORTS

declare -a images=( "backend-interpreter" "database-brain" "frontend-ui" "websocket-server" )

exportimages=()

# Check saved images except interpreter-plugin
for img in "${images[@]}"; do
    foundfile=$( find $EXPORTS_DIR -name "*image*$img*" )
    if ! [[ foundfile ]]; then
        echo "image ${img} not found in ${1}"
        exit 3
    fi
    exportimages+=( "${foundfile}" )
done

echo "Building new ramrodpcp/interpreter-plugin:${TAG} image..."
docker build -t ramrodpcp/interpreter-plugin:$TAG --build-arg TAG=$TAG --build-arg PLUGINS=$PLUGINS_DIR --build-arg PORTS=$PORTS $SCRIPT_DIR

timestamp=$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )
imagesave=image-ramrodpcp-interpreter-plugin-$TAG_$timestamp

echo "Saving new image to ./${imagesave}.tar.gz"
docker save ramrodpcp/interpreter-plugin:$TAG -o $imagesave.tar
gzip $imagesave.tar && mv $imagesave.tar.gz $EXPORTS_DIR

tar -cvf ramrod-deployment-package-$timestamp.tar $EXPORTS_DIR/$imagesave.tar.gz ./.scripts/setup.sh ./.scripts/deploy.sh ./docker/docker-compose.yml

for file in "${exportimages[@]}"; do
    tar -rvf ramrod-deployment-package-$timestamp.tar $file
done

gzip ramrod-deployment-package-$timestamp.tar
rm -rf 