-- NOTE: This file depends on the prism_grid_ca.sql file



-- TABLE
CREATE TABLE prism (
  prism_id SERIAL PRIMARY KEY,
  rast RASTER NOT NULL,
  date DATE NOT NULL,
  measurement TEXT NOT NULL,
  quality prism_quality NOT NULL
);
CREATE INDEX prism_date_idx ON prism(date);
CREATE INDEX prism_measurement_idx ON prism(measurement);

-- GETTER FUNCTION
CREATE OR REPLACE FUNCTION get_prism_xy_from_ll(in lng float, in lat float, out x int, out y int)
AS $$ 

  WITH point AS (
    SELECT (ST_WorldToRasterCoord(rast, lng, lat)).* from prism limit 1
  )
  SELECT 
    point.columnx as x,
    point.rowy as y
  FROM
    point;

$$ LANGUAGE SQL;