#! /bin/bash

export PGSERVICE=localdev

psql -f ./tables/trial.sql

psql -f ./tables/variety.sql
psql -f ./tables/variety_name.sql
psql -f ./tables/variety_parentage.sql
psql -f ./tables/variety_region.sql