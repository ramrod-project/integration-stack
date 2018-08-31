#!/bin/bash

# This script sets up the host environment to run the application
# in a docker stack. Loads the provided images.
# TODO:
# - add docker auto install

SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

if [[ $# == 0 ]]; then
    echo "Please provide the export directory!"
    echo "Usage: setup.sh <exports_directory>"
    exit 1
fi

if ! [[ -d $1 ]]; then
    echo "Directory ${1} not found!"
    exit 2
fi

# Get branch
TAG_NAME=$(find ./exports/ -name image-frontend* | grep -o 'dev\|qa\|latest')

# Get image file names
images=()

while IFS= read -d $'\0' -r file ; do
     images+=( "$file" )
done < <(find $1 -name "*image-*" -print0)

# Purge existing images
docker images | grep ramrodpcp | awk '{print $3}' | xargs docker rmi -f
docker images prune

# Load images
for img in "${images[@]}"; do
    echo "Loading ${img}..."
    docker load --input $img
done

# Check if user wants to deploy the stack right away
PS3="Deploy the stack now?"
options=( "Yes" "No" "exit" )
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            break
            ;;
        "No")
            exit
            ;;
        "exit")
            exit
            ;;
        *) echo "invalid option";;
    esac
done

sudo ${SCRIPT_DIR}/deploy.sh --tag ${TAG_NAME} --loglevel DEBUG