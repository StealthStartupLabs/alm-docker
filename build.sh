#!/bin/bash

set -o errexit

# build all the images

(
    cd java-base
    docker build --rm --tag stealthstartuplabs/java-base .
)

(
    cd alm-web
    docker build --rm --tag stealthstartuplabs/alm-web .
)

(
    cd alm-postgres
    docker build --rm --tag stealthstartuplabs/alm-postgres .
)

for MODULE in $(ls -d alm-*)
do
(
    echo building $MODULE
    cd $MODULE
    TAG="stealthstartuplabs/$MODULE"

    docker build --rm --tag ${TAG}:latest .

    case "$MODULE" in

        alm-jira|alm-bitbucket|alm-bamboo)

            ENV_STRING="$(docker inspect  -f '{{ index .ContainerConfig.Env 5 }}' ${TAG}:latest )" 
            VERSION="$(echo $ENV_STRING | cut -d '=' -f 2 )"

            if [ ! -z "$VERSION" ]; then
                docker tag -f ${TAG}:latest ${TAG}:${VERSION}
            fi
        ;;

        *)

        ;;
     esac
)
done
