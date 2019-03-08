#! /bin/bash

export PGSERVICE=localdev

psql -f ./tables/trial.sql
