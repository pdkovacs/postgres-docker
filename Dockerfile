FROM ubuntu:bionic

ARG PG_CLUSTER_OWNER_USERID
ARG PG_CLUSTER_OWNER_GROUPID
ARG PG_DB_OWNER_NAME
ARG PG_DB_OWNER_PASSWORD
ARG PG_DB_NAME
ARG PG_LOG_STATEMENTS

RUN apt-get update && apt-get install -y gnupg2

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            pgp.mit.edu) ; do \
        apt-key adv --keyserver "$server" --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && break || : ;\
    done
#RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get install -y software-properties-common postgresql-10 postgresql-client-10 postgresql-contrib-10

RUN locale-gen en_US.utf8

RUN echo "This is an arg: $PG_CLUSTER_OWNER_GROUPID"

RUN groupadd -g $PG_CLUSTER_OWNER_GROUPID pgc-runner
run useradd -u $PG_CLUSTER_OWNER_USERID -g $PG_CLUSTER_OWNER_GROUPID pgc-runner

RUN chown -R $PG_CLUSTER_OWNER_USERID:$PG_CLUSTER_OWNER_GROUPID /var/run/postgresql
RUN pg_lsclusters && pg_dropcluster 10 main
RUN pg_createcluster -u $PG_CLUSTER_OWNER_USERID --locale en_US.utf8 10 main

###############################################################################
# Run the rest of the commands as the ``pgc-runner`` user
###############################################################################
USER pgc-runner

RUN echo "PG_DB_OWNER_PASSWORD: $PG_DB_OWNER_PASSWORD"

RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER $PG_DB_OWNER_NAME WITH SUPERUSER PASSWORD '"$PG_DB_OWNER_PASSWORD"';" postgres &&\
    createdb -O $PG_DB_OWNER_NAME $PG_DB_NAME

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/10/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/10/main/postgresql.conf
RUN test "$PG_LOG_STATEMENTS" = "yes" && \
            echo "log_statement=all" >> /etc/postgresql/10/main/postgresql.conf || \
            echo "statements not logged"
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/10/bin/postgres", "-D", "/var/lib/postgresql/10/main", "-c", "config_file=/etc/postgresql/10/main/postgresql.conf"]
