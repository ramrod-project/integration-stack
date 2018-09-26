#!/bin/bash

# This script pulls the latest versions of the ramrodpcp docker
# images based on the tag provided by user input. It then exports
# them to .tar.gz files.
# TODO:

SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
BASE_DIR="$( echo $SCRIPT_DIR | sed 's/[^/]*$//g' )"

PS3="Please select a release to download and export: "
options=( "dev" "qa" "master" "exit" )
select opt in "${options[@]}"
do
    case $opt in
        "dev")
            selectionTag="dev"
            selectionRepo="dev"
            break
            ;;
        "qa")
            selectionTag="qa"
            selectionRepo="qa"
            break
            ;;
        "master")
            selectionTag="latest"
            selectionRepo="master"
            break
            ;;
        "exit")
            exit
            ;;
        *) echo "invalid option";;
    esac
done

mkdir ./{exports,repos,.scripts}

declare -a images=( "backend-controller" "database-brain" "frontend-ui" "interpreter-plugin" "interpreter-plugin-extra" "websocket-server" "auxiliary-services" "auxiliary-wrapper" "devguide-api" )

timestamp=$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )

for img in "${images[@]}"; do
    imagename=ramrodpcp/$img:$selectionTag
    imagesave=image-$img-$selectionTag-$timestamp

    echo "Pulling ramrodpcp/${img}..."
    docker pull $imagename >> /dev/null

    echo "Saving image to ./exports/${imagesave}.tar.gz"
    docker save $imagename -o $BASE_DIR/$imagesave.tar
    gzip $BASE_DIR/$imagesave.tar && mv $BASE_DIR/$imagesave.tar.gz ./exports
done

for repo in "integration-stack" "backend-interpreter" "database-brain" "frontend-ui" "websocket-server" "backend-controller" "devguide-api" "aux-services-service"; do
    echo "Cloning repository: ${repo} branch: ${selectionRepo}"
    git clone -b $selectionRepo https://github.com/ramrod-project/$repo ./repos/$repo >> /dev/null
    reposave=$repo-$selectionRepo-$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )
    echo "Saving repo to ./exports/repo-clone-${reposave}.tar.gz"
    tar -czvf ./exports/repo-clone-$reposave.tar.gz ./repos/$repo >> /dev/null
done

cp -r ./repos/integration-stack/scripts/* ./.scripts/

echo "Exporting repos, images, and scripts to file ramrodpcp-exports-${selectionRepo}_${timestamp}.tar.gz..."
tar -czvf ramrodpcp-exports-$selectionRepo-$timestamp.tar.gz ./exports ./.scripts ./docker/docker-compose.yml
echo "Cleaning up..."
rm -rf ./{exports,repos,.scripts}