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

# Clean pyc and pycache files out of plugins dir
find $2/ -regextype sed -regex "\(.*__pycache__.*\|.*\.pyc$\)" | xargs rm -rf

PLUGINS_SOURCE=$2
PLUGINS_DIR=$BASE_DIR/.scripts/docker/plugin_interpreter/plugins
PLUGINS_EXTRA_DIR=$BASE_DIR/.scripts/docker/plugin_interpreter_extra/plugins

mkdir $PLUGINS_DIR > /dev/null 2>&1

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

declare -a images=( "database-brain" "frontend-ui" "websocket-server" "auxiliary-services" "auxiliary-wrapper" )

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
python3 $SCRIPT_DIR/manifest.py $PLUGINS_SOURCE
if ! [[ $? == 0 ]]; then
    rm -rf ./manifest.json
    exit 1
fi
mv ./manifest.json $SCRIPT_DIR/docker/plugin_controller

# Move plugin files based on manifest entries
if [[ -d ./extra_plugins ]]; then
    mkdir $PLUGINS_EXTRA_DIR > /dev/null 2>&1
    cp -r ./extra_plugins/* $PLUGINS_EXTRA_DIR
fi
cp -r $PLUGINS_SOURCE/* $PLUGINS_DIR

timestamp=$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )
# Build new controller image
echo "Building new ramrodpcp/backend-controller:${TAG} image..."
echo "Context: ${SCRIPT_DIR}/docker/plugin_controller"
docker build -t ramrodpcp/backend-controller:$TAG --build-arg TAG=$TAG --build-arg MANIFEST=./manifest.json $SCRIPT_DIR/docker/plugin_controller
imagesave_controller=image-ramrodpcp-backend-controller-$TAG-$timestamp
echo "Saving new image to ./${imagesave_controller}.tar.gz"
docker save ramrodpcp/backend-controller:$TAG -o $imagesave_controller.tar
gzip $imagesave_controller.tar
mv $imagesave_controller.tar.gz $EXPORTS_DIR

# Check if the plugins directory is empty
# (only happens in the case that there are no 'standard' plugins - all moved to 'extra')
imagesave_interpreter=image-ramrodpcp-interpreter-plugin-$TAG-$timestamp
if [[ $(find ${PLUGINS_DIR} -name "*.py" | grep -v __init__.py) ]]; then
    # Build new interpreter image
    echo "Building new ramrodpcp/interpreter-plugin:${TAG} image..."
    echo "Context: ${SCRIPT_DIR}/docker/plugin_interpreter"
    docker build -t ramrodpcp/interpreter-plugin:$TAG --build-arg TAG=$TAG $SCRIPT_DIR/docker/plugin_interpreter
    echo "Saving new image to ./${imagesave_interpreter}.tar.gz"
    docker save ramrodpcp/interpreter-plugin:$TAG -o $imagesave_interpreter.tar
    gzip $imagesave_interpreter.tar
    mv $imagesave_interpreter.tar.gz $EXPORTS_DIR
fi

# Check if manifest.py created a folder for the extra plugins
imagesave_interpreter_extra=image-ramrodpcp-interpreter-plugin-extra-$TAG-$timestamp
if [[ -d "./extra_plugins" ]]; then
    cp -r ./extra_plugins/* $PLUGINS_EXTRA_DIR/
    # Build new 'extra' interpreter image
    echo "Building new ramrodpcp/interpreter-plugin-extra:${TAG} image..."
    echo "Context: ${SCRIPT_DIR}/docker/plugin_interpreter_extra"
    docker build -t ramrodpcp/interpreter-plugin-extra:$TAG --build-arg TAG=$TAG $SCRIPT_DIR/docker/plugin_interpreter_extra
    echo "Saving new image to ./${imagesave_interpreter_extra}.tar.gz"
    docker save ramrodpcp/interpreter-plugin-extra:$TAG -o $imagesave_interpreter_extra.tar
    gzip $imagesave_interpreter_extra.tar
    mv $imagesave_interpreter_extra.tar.gz $EXPORTS_DIR
fi

# Add controller and required files to the deployment package
tar -cvf ramrod-deployment-package-$TAG-$timestamp.tar ${EXPORTS_DIR}/${imagesave_controller}.tar.gz ./.scripts/setup.sh ./.scripts/deploy.sh ./docker/docker-compose.yml
rm -rf ${EXPORTS_DIR}/${imagesave_controller}.tar.gz

# If we built a new interpreter image, save it
if [[ -f ${EXPORTS_DIR}/${imagesave_interpreter}.tar.gz ]]; then
    tar -rvf ramrod-deployment-package-$TAG-$timestamp.tar ${EXPORTS_DIR}/${imagesave_interpreter}.tar.gz
    rm -rf ${EXPORTS_DIR}/${imagesave_interpreter}.tar.gz
fi

# If we built a new interpreter 'extra' image, save it
if [[ -f ${EXPORTS_DIR}/${imagesave_interpreter_extra}.tar.gz ]]; then
    tar -rvf ramrod-deployment-package-$TAG-$timestamp.tar ${EXPORTS_DIR}/${imagesave_interpreter_extra}.tar.gz
    rm -rf ${EXPORTS_DIR}/${imagesave_interpreter_extra}.tar.gz
fi

# Extra images
for file in "${exportimages[@]}"; do
    tar -rvf ramrod-deployment-package-$TAG-$timestamp.tar $file
done

# Clean up
if [[ -d ./extra_plugins ]]; then
    mv ./extra_plugins/* $PLUGINS_SOURCE
    rm -rf ./extra_plugins
fi

gzip ramrod-deployment-package-$TAG-$timestamp.tar
rm -rf ramrod-deployment-package-$TAG-$timestamp.tar