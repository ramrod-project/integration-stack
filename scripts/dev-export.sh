#!/bin/bash

# This exports only the files needed for deployment to 'production'
# TODO:

# Get directory info
SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
BASE_DIR="$( echo $SCRIPT_DIR | sed 's/[^/]*$//g' )"

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

mkdir $BASE_DIR/.scripts/docker/plugin_interpreter/plugins
PLUGINS_DIR=$BASE_DIR/.scripts/docker/plugin_interpreter/plugins
cp -r $2/* $PLUGINS_DIR

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

declare -a images=( "database-brain" "frontend-ui" "websocket-server" "auxiliary-services" )

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

# Create manifest of plugins
python3 $SCRIPT_DIR/manifest.py $PLUGINS_DIR
mv ./manifest.json $SCRIPT_DIR/docker/plugin_controller

# Build new controller image
echo "Building new ramrodpcp/backend-interpreter:${TAG} image..."
echo "Context: ${SCRIPT_DIR}/docker/plugin_controller"
docker build -t ramrodpcp/backend-interpreter:$TAG --build-arg TAG=$TAG --build-arg MANIFEST=./manifest.json $SCRIPT_DIR/docker/plugin_controller

# Build new interpreter image
echo "Building new ramrodpcp/interpreter-plugin:${TAG} image..."
echo "Context: ${SCRIPT_DIR}/docker/plugin_interpreter"
docker build -t ramrodpcp/interpreter-plugin:$TAG --build-arg TAG=$TAG --build-arg PORTS="${PORTS}" $SCRIPT_DIR/docker/plugin_interpreter

timestamp=$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )
imagesave_interpreter=image-ramrodpcp-interpreter-plugin-$TAG-$timestamp
imagesave_controller=image-ramrodpcp-backend-interpreter-$TAG-$timestamp

echo "Saving new image to ./${imagesave_interpreter}.tar.gz"
docker save ramrodpcp/interpreter-plugin:$TAG -o $imagesave_interpreter.tar
gzip $imagesave_interpreter.tar && mv $imagesave_interpreter.tar.gz $EXPORTS_DIR

echo "Saving new image to ./${imagesave_controller}.tar.gz"
docker save ramrodpcp/backend-interpreter:$TAG -o $imagesave_controller.tar
gzip $imagesave_controller.tar && mv $imagesave_controller.tar.gz $EXPORTS_DIR

tar -cvf ramrod-deployment-package-$TAG-$timestamp.tar $EXPORTS_DIR/$imagesave_interpreter.tar.gz $EXPORTS_DIR/$imagesave_controller.tar.gz ./.scripts/setup.sh ./.scripts/deploy.sh ./docker/docker-compose.yml

for file in "${exportimages[@]}"; do
    tar -rvf ramrod-deployment-package-$TAG-$timestamp.tar $file
done

gzip ramrod-deployment-package-$TAG-$timestamp.tar
rm -rf ramrod-deployment-package-$TAG-$timestamp.tar