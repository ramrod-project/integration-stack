#!/bin/bash

# This script pulls the latest versions of the ramrodpcp docker
# images based on the tag provided by user input. It then exports
# them to .tar.gz files.
# TODO:
# - clone repos and export them

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

mkdir exports
mkdir repos

for img in "backend-interpreter" "database-brain" "frontend-ui" "interpreter-plugin"; do
    echo "Pulling ramrodpcp/${img}:${selection}..."
    docker pull ramrodpcp/$img:$selection >> /dev/null
    imagesave=$img-$selection
    echo "Saving image to ./exports/ramrodpcp-${imagesave}.tar.gz"
    docker save ramrodpcp/$img:$selection | gzip -c > ./exports/ramrodpcp-$imagesave.tar.gz
done

for repo in "frontend-ui" "backend-interpreter" "database-brain" "integration-stack"; do
    echo "Cloning repository: ${repo} branch: ${selection}"
    git clone -b $selection https://github.com/ramrod-project/$repo ./repos/$repo >> /dev/null
    reposave=$repo-$selection
    echo "Saving repo to ./exports/${repo}-${selection}.tar.gz"
    tar -czvf ./exports/$repo-$selection.tar.gz ./repos/$repo >> /dev/null
done

echo "Exporting repos and images to file ramrodpcp-exports.tar.gz..."
tar -czvf ramrodpcp-exports.tar.gz ./exports
echo "Cleaning up..."
rm -rf {exports,repos}