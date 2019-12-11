-- NOTE: This file depends on the prism_grid_ca.sql file



-- TABLE
CREATE TABLE prism (
  prism_id SERIAL PRIMARY KEY,
  rast RASTER NOT NULL,
  date DATE NOT NULL,
  measurement TEXT NOT NULL,
  quality prism_quality NOT NULL
);

-- GETTER FUNCTION
CREATE FUNCTION get_prism_xy_from_ll(in lat float, in lng float, out x int, out y int)
AS $$ 
  SELECT 
    x, y 
  FROM 
    prism_grid_ca 
  WHERE 
    ST_Contains(
        pixel, 
        ST_PointFromText('POINT(' || lng || ' ' ||  lat || ' )', 4326)
    );
$$ LANGUAGE SQL;