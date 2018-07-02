#!/bin/bash

print_accepted_args() {
    cat <<EOF

Accepted arguments:
   --pg-cluster-owner-userid <string>
   --pg-cluster-owner-groupid <string>
   --pg-db-owner-name <string>
   --pg-db-name <string>
   --pg-log-statements

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]];
    do
        case $1 in
            --pg-cluster-owner-userid)
                shift
                pg_cluster_owner_userid=$1
                ;;
            --pg-cluster-owner-groupid)
                shift
                pg_cluster_owner_groupid=$1
                ;;
            --pg-db-owner-name)
                shift
                pg_db_owner_name=$1
                ;;
            --pg-db-name)
                shift
                pg_db_name=$1
                ;;
            --pg-log-statements)
                pg_log_statements="yes"
                ;;
            *)
                echo "Unexecpted argument $1"
                print_accepted_args
                exit 1
                ;;
        esac;
        shift
    done
}

check_arguments() {
    if [ -z "$pg_cluster_owner_userid" ];
    then
        echo "--pg-cluster-owner-userid must be set"
        exit 1;
    fi

    if [ -z "$pg_cluster_owner_groupid" ];
    then
        echo "--pg-cluster-owner-groupid must be set"
        exit 1;
    fi

    if [ -z "$pg_db_owner_name" ];
    then
        echo "--pg-db-owner-name must be set"
        exit 1;
    fi

    if [ -z "$pg_db_name" ];
    then
        echo "--pg-db-name must be set"
        exit 1;
    fi
}

setup_variables() {
    check_arguments
    docker_image_name=postgres-${pg_db_owner_name}-${pg_cluster_owner_userid}-${pg_cluster_owner_groupid}
    docker_container_name=pg-$pg_db_owner_name
}

print_help() {
    cat <<EOF

You can create a docker container by executing (e.g.) this:
    sudo docker run --user $pg_cluster_owner_userid:$pg_cluster_owner_groupid -P -d --name $DOCKER_CONTAINER_NAME $docker_image_name

You can connect to the container with "psql" by executing (e.g.) this:
    sudo docker run -it --rm --link $DOCKER_CONTAINER_NAME:postgres-server $docker_image_name psql -h postgres-server -U $pg_db_owner_name $pg_db_name

EOF
}

setup_cluster_and_db() {
    groupadd -g $pg_cluster_owner_groupid pgc-owner
    useradd -u $pg_cluster_owner_userid -g $pg_cluster_owner_groupid pgc-owner

    chown -R $pg_cluster_owner_userid:$pg_cluster_owner_groupid /var/run/postgresql
    pg_lsclusters && pg_dropcluster 10 main
    pg_createcluster -u $pg_cluster_owner_userid --locale en_US.utf8 10 main

    echo "start_init_db_cmd: $start_init_db_cmd"
    set -xe
    su pgc-owner -c "/etc/init.d/postgresql start"
    pg_db_owner_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};)
    echo "pg_db_owner_password: $pg_db_owner_password"
    su pgc-owner -c "psql --command \"CREATE USER $pg_db_owner_name WITH SUPERUSER PASSWORD '$pg_db_owner_password';\" postgres"
    su pgc-owner -c "createdb -O $pg_db_owner_name $pg_db_name"
    su pgc-owner -c "/etc/init.d/postgresql stop"
    su pgc-owner -c "echo \"local all all            md5\" > /etc/postgresql/10/main/pg_hba.conf"
    su pgc-owner -c "echo \"host  all all 0.0.0.0/0  md5\" >> /etc/postgresql/10/main/pg_hba.conf"
    su pgc-owner -c "echo \"listen_addresses='*'\" >> /etc/postgresql/10/main/postgresql.conf"
    test "$pg_log_statements" = "yes" \
            && \
                su pgc-owner -c "echo \"log_statement=all\" >> /etc/postgresql/10/main/postgresql.conf" \
            || \
                echo "statements not logged"
    start_server
    set +xe
}

start_server() {
    su pgc-owner -c "/usr/lib/postgresql/10/bin/postgres -D /var/lib/postgresql/10/main -c config_file=/etc/postgresql/10/main/postgresql.conf"
}

parse_arguments $@
setup_variables
set -x
id pgc-owner && start_server || setup_cluster_and_db
set +x
start_server
