#!/bin/bash

# This script sets up the host environment to run the application
# in a docker stack. Loads the provided images.
# TODO:
# - add docker auto install

if [[ $# == 0 ]]; then
    echo "Please provide directory to export archive!"
    echo "Usage: setup.sh <archive_directory>"
    exit 1
fi

if ! [[ -f $1/ramrodpcp-exports.tar.gz ]]; then
    echo "${1}/ramrodpcp-exports.tar.gz not found!"
    exit 2
fi

tar -xzvf $1/ramrodpcp-exports.tar.gz -C $1

# Get image file names
images=()

while IFS= read -d $'\0' -r file ; do
     images+=( "$file" )
done < <(find ./exports/ -name "*image-*" -print0)

# Load images
for img in "${images[@]}"; do
    echo "Loading ${img}..."
    docker load --input $img
done