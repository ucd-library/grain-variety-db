# download the shapfile folder from box and place this folder as ./ssurgo_soils

shp2pgsql -s 4326 ./ssurgo_soils/ssurgo_ca_soils.shp grain.ssurgo_test | psql

# review data
# if all looks good we need to
#   - drop the site_soil_view
#   - drop grain.ssurgo
#   - rename grain.ssurgo_test to grain.ssurgo
#   - recreate the site_soil_view

psql -c 'drop view grain.site_soil_view;'
psql -c 'drop table grain.ssurgo;'
psql -c 'ALTER TABLE grain.ssurgo_test RENAME TO grain.ssurgo;'

# now create the site soil view; see site.sql