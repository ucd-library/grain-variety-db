FROM postgres:14
MAINTAINER Justin Merz <jrmerz@ucdavis.edu>

RUN apt-get update \
      && apt-get install -y --no-install-recommends \
        postgis \
        postgresql-14-postgis-3 \
        postgresql-14-postgis-3-scripts \
      && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sql /docker-entrypoint-initdb.d/postgis.sql

# COPY postgresql.conf /etc/postgresql/postgresql.conf
# COPY pg_hba.conf /etc/postgresql/pg_hba.conf
# RUN chown postgres:postgres /etc/postgresql/postgresql.conf
# RUN chown postgres:postgres /etc/postgresql/pg_hba.conf

# CMD docker-entrypoint.sh -c 'config_file=/etc/postgresql/postgresql.conf'