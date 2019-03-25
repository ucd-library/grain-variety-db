-- TABLE
DROP TABLE IF EXISTS field_location CASCADE;
CREATE TABLE field_location (
  field_location_id SERIAL PRIMARY KEY,
  source_id INTEGER REFERENCES source NOT NULL,
  field_id INTEGER REFERENCES field NOT NULL,
  plot_id INTEGER REFERENCES plot,
  UNIQUE(plot_id, field_id)
);

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_field_location_id(trail_name text, site_name text, field_name text, plot_name integer) RETURNS INTEGER AS $$   
DECLARE
  pid INTEGER;
  fid INTEGER;
  flid INTEGER;
BEGIN

  SELECT get_field_id(trail_name, site_name, field_name) INTO fid; 
  -- This can be null, so don't use getter function.
  -- null means location is entire field
  SELECT plot_id INTO pid FROM plot WHERE name = plot_name; 

  SELECT 
    field_location_id INTO flid 
  FROM  
    field_location
  WHERE 
    field_id = fid AND
    plot_id = pid;

  IF (flid is NULL) then
    RAISE EXCEPTION 'Unknown field location: % % % %', trail_name, site_name, field_name, plot_name;
  END IF;

  RETURN flid;
END; 
$$ LANGUAGE plpgsql;