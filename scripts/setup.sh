#!/bin/bash

# This script sets up the host environment to run the application
# in a docker stack. Loads the provided images.

if [ $# == 0 ]; then
    echo "Please provide image files to load!"
    echo "Usage: setup.sh <image_directory>"
    exit 1
fi

# Get image file names
images=()

while IFS= read -d $'\0' -r file ; do
     images=("${images[@]}" "$file")
done < <(find "$1" -name "*image-*" -print0)

# Load images
for img in "${images[@]}"; do
    echo "Loading ${img}..."
    docker load --input $img
done