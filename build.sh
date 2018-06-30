#!/bin/bash -e

##############################################################################
# Environment variables:
#   PG_CLUSTER_OWNER
#   PG_DB_OWNER_NAME
#   PG_DB_NAME
#   PG_LOG_STATEMENTS ("yes")
##############################################################################

set_variables() {

    test -f $(dirname $0)/config.sh && . config.sh 

    if [ -z "$PG_CLUSTER_OWNER" ];
    then
        echo "PG_CLUSTER_OWNER must be set"
        exit 1;
    fi

    if [ -z "$PG_DB_OWNER_NAME" ];
    then
        echo "PG_DB_OWNER_NAME must be set"
        exit 1;
    fi

    if [ -z "$PG_DB_NAME" ];
    then
        echo "PG_DB_NAME must be set"
        exit 1;
    fi

    PG_CLUSTER_OWNER_USERID=$(id -u $PG_CLUSTER_OWNER)
    PG_CLUSTER_OWNER_GROUPID=$(id -g $PG_CLUSTER_OWNER)

    DOCKER_IMAGE_NAME=postgres-${PG_DB_OWNER_NAME}-${PG_CLUSTER_OWNER_USERID}-${PG_CLUSTER_OWNER_GROUPID}
    DOCKER_CONTAINER_NAME=pg-$PG_DB_OWNER_NAME
}

print_help() {
    cat <<EOF

You can create a docker container by executing (e.g.) this:
    sudo docker run --user $PG_CLUSTER_OWNER_USERID:$PG_CLUSTER_OWNER_GROUPID -P -d --name $DOCKER_CONTAINER_NAME $DOCKER_IMAGE_NAME

You can connect to the container with "psql" by executing (e.g.) this:
    sudo docker run -it --rm --link $DOCKER_CONTAINER_NAME:postgres-server $DOCKER_IMAGE_NAME psql -h postgres-server -U $PG_DB_OWNER_NAME $PG_DB_NAME

EOF
}

do_build() {
    set -x
    docker build \
        --build-arg PG_CLUSTER_OWNER_USERID=$PG_CLUSTER_OWNER_USERID \
        --build-arg PG_CLUSTER_OWNER_GROUPID=$PG_CLUSTER_OWNER_GROUPID \
        --build-arg PG_DB_OWNER_NAME=$PG_DB_OWNER_NAME \
        --build-arg PG_DB_OWNER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};) \
        --build-arg PG_DB_NAME=$PG_DB_NAME \
        --build-arg PG_LOG_STATEMENTS=$PG_LOG_STATEMENTS \
        -t $DOCKER_IMAGE_NAME .
    set +x
    print_help
}
set -x
set_variables
set +x
case $1 in
    --help)
        print_help
    ;;
    *)
        do_build
    ;;
esac
