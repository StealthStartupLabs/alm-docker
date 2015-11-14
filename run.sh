#! /bin/bash

DOCKER_HUB_USER=stealthstartuplabs

usage() {

echo "

 Usage:

    run.sh all             # 

    run.sh <app>           # stop and remove <app> container, create a new one in background
                           # then restart web server 
                           # <app> can be jira, bitbucket or bamboo

    run.sh <app> -i <cmd>  # start <app> container in interactive mode, pass <cmd> to docker

    run.sh  web            # restart web server 

    run.sh  db             # stop and remove db container, then start a new one

    run.sh  dbsh           # launch a shell into db server

    run.sh  datash         # start an interactive container for examine the shared data volumes

    run.sh  backup <dir>   # backup all data inside data container into <dir>/almdata.tar.gz

    run.sh  clean          # remove all untagged images

"

}


is_container_running() {

    if [ "$(docker inspect -f '{{ .State.Running }}' $1 2> /dev/null)" = "true" ]; then
        return 0
    else
        return 1
    fi
}


stop_and_rm_container() {

    is_container_running $1 && docker stop $1
    ( docker ps -a | grep -q $1 ) && docker rm $1
}


start_app() {

    [ "$2" = "-i" ] && RUN_MODE="-it" ||  RUN_MODE="-d"

    stop_and_rm_container $1

    start_data

    echo starting $1
    docker run $RUN_MODE --name $1 --link postgres:db \
        --volumes-from="almdata" -e BASE_URL=$BASE_URL \
        ${DOCKER_HUB_USER}/alm-$1 $3
}


start_db() {

    stop_and_rm_container postgres

    start_data

    docker run -d --name postgres -e POSTGRES_PASSWORD=password \
        --volumes-from="almdata" ${DOCKER_HUB_USER}/alm-postgres
}


start_data() {

    (docker ps -a | grep -q almdata ) || \
        docker run --name almdata \
            -v /opt/atlassian-home \
            -v /var/lib/postgresql/data \
            busybox echo almdata container
}


start_web() {

    BASE_DIR=`dirname $0`
    $($BASE_DIR/parse_base_url.py $BASE_URL)

    if [ -z "$BASE_URL_SCHEME" ]; then
        BASE_URL_SCHEME="http"
        BASE_URL_PORT="80"
    fi
    
    if [ "$BASE_URL_SCHEME" = "http" ]; then
        PORTS="-p $BASE_URL_PORT:80"
    else
        PORTS="-p $BASE_URL_PORT:443"
    fi

    is_container_running jira && LINKS="$LINKS --link jira:jira"
    is_container_running bamboo && LINKS="$LINKS --link bamboo:bamboo"
    is_container_running bitbucket && LINKS="$LINKS --link bitbucket:bitbucket"

    echo starting httpd with links $LINKS
    stop_and_rm_container atlweb
    docker run -d --name atlweb \
       $PORTS \
       $LINKS \
       ${DOCKER_HUB_USER}/alm-web

    [ -z "$LINKS" ] && echo httpd started but no application running.
}


    
ACTION=$1

# when this script is piped into /bin/bash as describe in README.md
# it'll boot up all components
if [ ! -t 0 ]; then

    ACTION=all 
    
    echo
    echo starting all docker containers for Atlassian Jira, bitbucket and Bamboo
    echo all images will be downloaded from docker hub for the first time, this will take a while.
    echo 
    echo hit ctrl-C to abort ...
    echo
    sleep 2

fi


    
case "$ACTION" in

    all)
        start_data
        start_db
        start_app jira
        start_app bamboo
        start_app bitbucket
        sleep 2 && start_web

    ;;

    jira|bitbucket|bamboo)
        
        stop_and_rm_container $1
        start_app $1 $2 $3 $4
        # start web browser if container not launched run.sh <app> -i <cmd>
        [ -z "$2" ] && start_web

    ;;

    web)
        
        start_web        

    ;;

    db)
        
        start_db        

    ;;

    initdb)
        
        init_db        

    ;;

    dbsh)

        docker exec -it postgres /bin/bash

    ;;

    datash)

        docker run -it --rm --volumes-from="almdata" stealthstartuplabs/jre-base /bin/bash

    ;;

    backup)

        BACKUP_DIR=$(readlink -f $2)
        echo backing up all data in almdata to $BACKUP_DIR

        docker run -it --rm --volumes-from almdata -v $BACKUP_DIR:/backup  ${DOCKER_HUB_USER}/java-base  \
              tar czvf /backup/almdata.tar.gz \
                   /opt/atlassian-home /var/lib/postgresql/data 

    ;;

    clean)

        docker rmi $(docker images | grep "^<none>" | awk ' {print $3} ')

    ;;

    *)

        usage

    ;;

esac 


