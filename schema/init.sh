#! /bin/bash

export PGSERVICE=localdev
#export PGSERVICE=grain

# types
psql -f ./tables/enums/region.sql
psql -f ./tables/enums/trial_group.sql
psql -f ./tables/enums/release_status.sql
psql -f ./tables/enums/crop_classification.sql

# 3rd Party GIS DATA
# psql -c 'DROP TABLE IF EXISTS ca_counties CASCADE';
# shp2pgsql ../data/CA_Counties/CA_Counties_TIGER2016.shp ca_counties | psql
# psql -c 'UPDATE ca_counties set geom = ST_Transform(ST_SetSRID(geom, 3857),4326);';

# tables
psql -f ./tables/source.sql
psql -f ./tables/tables.sql
psql -f ./tables/trial.sql
psql -f ./tables/site.sql

psql -f ./tables/crop.sql
psql -f ./tables/variety.sql
psql -f ./tables/field.sql
psql -f ./tables/plot.sql
psql -f ./tables/location.sql


# psql -f ./tables/variety_name.sql
# psql -f ./tables/variety_parentage.sql
# psql -f ./tables/variety_region.sql

# PROJECT DATA
pgdm insert --pg-service $PGSERVICE --file ../data/trial.csv --table trial_view 
pgdm insert --pg-service $PGSERVICE --file ../data/site.csv --table site_view_kml 
pgdm insert --pg-service $PGSERVICE --file ../data/crop.csv --table crop_view
pgdm insert --pg-service $PGSERVICE --file ../data/variety.csv --table variety_view
pgdm insert --pg-service $PGSERVICE --file ../data/field.csv --table field_view
pgdm insert --pg-service $PGSERVICE --file ../data/plot.csv --table plot_view