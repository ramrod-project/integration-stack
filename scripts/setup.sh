#!/bin/bash

# This script sets up the host environment to run the application
# in a docker stack. Loads the provided images.

if [ $# == 0 ]; then
    echo "Please provide at least one tar.gz image file to load!"
    exit 1
fi

# Validate arguments
for img in "$@"; do
    if ! [ -f $img ]; then
        echo "File ${img} not found!"
        exit 1
    elif ! [[ $( tar -t -f $img ) ]]; then
        echo "File ${img} is not a valid tar.gz archive!"
        exit 1
    fi
done

# Load images
for img in "$@"; do
    echo "Loading ${img}..."
    docker load --input $img
done