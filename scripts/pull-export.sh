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
            selection="dev"
            break
            ;;
        "qa")
            selection="qa"
            break
            ;;
        "master")
            selection="latest"
            break
            ;;
        "exit")
            exit
            ;;
        *) echo "invalid option";;
    esac
done

mkdir ./{exports,repos,.scripts}

declare -a images=( "backend-controller" "database-brain" "frontend-ui" "interpreter-plugin" "websocket-server" "auxiliary-services" "auxiliary-wrapper" "robot-framework-xvfb" "devguide-api" )

timestamp=$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )

for img in "${images[@]}"; do
    imagename=ramrodpcp/$img:$selection
    imagesave=image-$img-$selection-$timestamp

    echo "Pulling ramrodpcp/${img}..."
    docker pull $imagename >> /dev/null

    echo "Saving image to ./exports/${imagesave}.tar.gz"
    docker save $imagename -o $BASE_DIR/$imagesave.tar
    gzip $BASE_DIR/$imagesave.tar && mv $BASE_DIR/$imagesave.tar.gz ./exports
done

for repo in "integration-stack" "backend-interpreter" "database-brain" "frontend-ui" "websocket-server" "backend-controller" "devguide-api" "aux-service-service"; do
    echo "Cloning repository: ${repo} branch: ${selection}"
    git clone -b $selection https://github.com/ramrod-project/$repo ./repos/$repo >> /dev/null
    reposave=$repo-$selection-$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )
    echo "Saving repo to ./exports/repo-clone-${reposave}.tar.gz"
    tar -czvf ./exports/repo-clone-$reposave.tar.gz ./repos/$repo >> /dev/null
done

cp -r ./repos/integration-stack/scripts/* ./.scripts/

echo "Exporting repos, images, and scripts to file ramrodpcp-exports-${selection}_${timestamp}.tar.gz..."
tar -czvf ramrodpcp-exports-$selection-$timestamp.tar.gz ./exports ./.scripts ./docker/docker-compose.yml
echo "Cleaning up..."
rm -rf ./{exports,repos,.scripts}