#!/bin/bash

# This script pulls the latest versions of the ramrodpcp docker
# images based on the tag provided by user input. It then exports
# them to .tar.gz files.
# TODO:

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

declare -a images=( "backend-interpreter" "database-brain" "frontend-ui" "interpreter-plugin" )

if [[ "$selection" == "qa" ]]; then
    images+=( "robot-framework-xvfb" )
fi

for img in "${images[@]}"; do
    imagename=ramrodpcp/$img:$selection
    imagesave=image-$img-$selection_$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )

    echo "Pulling ramrodpcp/${img}..."
    docker pull $imagename >> /dev/null

    echo "Saving image to ./exports/${imagesave}.tar.gz"
    docker inspect --format='{{index .RepoDigests 0}}' $imagename | sed 's/^[^:]*://g' >> $imagesave.sha
    docker save $imagename
    tar -rf $imagename.tar $imagesave.sha
    gzip $imagename.tar && mv $imagename.tar.gz ./exports
done

for repo in "frontend-ui" "backend-interpreter" "database-brain" "integration-stack"; do
    echo "Cloning repository: ${repo} branch: ${selection}"
    git clone -b $selection https://github.com/ramrod-project/$repo ./repos/$repo >> /dev/null
    reposave=$repo-$selection_$( date +%T-%D-%Z | sed 's/\//-/g' | sed 's/://g' )
    echo "Saving repo to ./exports/repo-clone-${reposave}.tar.gz"
    tar -czvf ./exports/repo-clone-$reposave.tar.gz ./repos/$repo >> /dev/null
done

echo "Exporting repos and images to file ramrodpcp-exports.tar.gz..."
tar -czvf ramrodpcp-exports.tar.gz ./exports
echo "Cleaning up..."
rm -rf {exports,repos}