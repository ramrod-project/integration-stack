#!/bin.bash

# This script pulls the latest versions of the ramrodpcp docker
# images based on the tag provided by user input. It then exports
# them to .tar.gz files.

PS3="Please select a release to download and export: "
options=("dev" "qa" "latest" "exit")
select opt in "${options[@]}"
do
    case $opt in
        "dev")
            selection="dev"
            break
            ;;
        "qa")
            selection="qa"
            break
            ;;
        "latest")
            selection="latest"
            break
            ;;
        "exit")
            exit
            ;;
        *) echo "invalid option";;
    esac
done

mkdir image_exports

for img in "backend-interpreter:${selection}" "database-brain:${selection}" "frontend-ui:${selection}" "interpreter-plugin:${selection}"; do
    docker pull ramrodpcp/$img
    docker save ramrodpcp/$img | gzip -c > ./image_exports/ramrodpcp-$img.tar.gz
done