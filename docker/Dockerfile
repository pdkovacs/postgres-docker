FROM ubuntu:bionic

RUN apt-get update && apt-get upgrade -y && apt-get install -y gnupg2

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

RUN apt-get install -y net-tools software-properties-common postgresql-10 postgresql-client-10 postgresql-contrib-10

RUN locale-gen en_US.utf8

RUN echo "This is an arg: $PG_CLUSTER_OWNER_GROUPID"

EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

COPY "entrypoint.sh" "/"

ENTRYPOINT ["/entrypoint.sh"]

# Set the default command to run when starting the container
CMD []
