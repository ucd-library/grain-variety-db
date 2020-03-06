#! /bin/bash

SCHEMA=grain_growth_stage;
psql -c "CREATE SCHEMA IF NOT EXISTS $SCHEMA;"
psql -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
# psql -c "alter extension \"uuid-ossp\" set schema public;"
export PGOPTIONS=--search_path=$SCHEMA,public

# types
psql -f ./tables/enums/region.sql
psql -f ./tables/enums/trial_group.sql
psql -f ./tables/enums/release_status.sql
psql -f ./tables/enums/crop_classification.sql
psql -f ./tables/enums/crop_sub_type.sql

# 3rd Party GIS DATA
psql -c "DROP TABLE IF EXISTS $SCHEMA.ca_counties CASCADE";
shp2pgsql ../data/CA_Counties/CA_Counties_TIGER2016.shp "$SCHEMA.ca_counties" | psql
psql -c "UPDATE $SCHEMA.ca_counties set geom = ST_Transform(ST_SetSRID(geom, 3857),4326);";

# tables
psql -f ./tables/tables.sql
psql -f ./tables/source.sql
psql -f ./tables/trial.sql
psql -f ./tables/site.sql

psql -f ./tables/crop.sql
psql -f ./tables/variety.sql
psql -f ./tables/regional_variety.sql
psql -f ./tables/variety_label.sql
psql -f ./tables/variety_parentage.sql

psql -f ./tables/field.sql
psql -f ./tables/plot.sql
psql -f ./tables/location.sql

psql -f ./tables/plant_part.sql;
psql -f ./tables/crop_parts.sql;
psql -f ./tables/measurement_device.sql;
psql -f ./tables/measurement.sql;
psql -f ./tables/crop_part_measurement.sql;

psql -f ./tables/crop_sample.sql;
psql -f ./tables/soil_sample.sql

psql -f ./tables/weed_treatment_type.sql
psql -f ./tables/weed_treatment_event.sql

psql -f ./tables/planting.sql
psql -f ./tables/tillage_event.sql
psql -f ./tables/note.sql

psql -f ./tables/fertilization_type.sql
psql -f ./tables/fertilization_event.sql

psql -f ./tables/irrigation_method.sql
psql -f ./tables/irrigation_event.sql


# Add permissions
psql -c "grant usage on schema $SCHEMA to public;"
psql -c "grant all on all tables in schema $SCHEMA to public;"
psql -c "grant execute on all functions in schema $SCHEMA to public;"
psql -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA $SCHEMA TO public;"

grant usage on schema grain to public;
grant all on all tables in schema grain to public;
grant execute on all functions in schema grain to public;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA grain TO public;