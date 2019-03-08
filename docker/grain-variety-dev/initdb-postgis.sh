psql -h localhost -U postgres -c 'CREATE EXTENSION IF NOT EXISTS postgis';
psql -h localhost -U postgres -c 'CREATE EXTENSION IF NOT EXISTS postgis_topology;';