-- TABLE
DROP TABLE IF EXISTS location CASCADE;
CREATE TABLE location (
  location_id SERIAL PRIMARY KEY,
  field_id INTEGER REFERENCES field NOT NULL,
  plot_id INTEGER REFERENCES plot,
  source_id INTEGER REFERENCES source
);

-- FUNCTION INSERT
CREATE OR REPLACE FUNCTION insert_location (
  site_name text,
  field_name text,
  plot_name text) RETURNS void AS $$   
DECLARE
  fid integer;
  pid integer;
BEGIN

  SELECT get_field_id(site_name) INTO fid;
  IF (plot_name is not NULL) then
    SELECT get_plot_id(site_name, field_name, plot_name) INTO pid;
  END IF;

  INSERT INTO location (
    field_id, plot_id 
  ) VALUES (
    fid, pid
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_location_id(site_name text, field_name text, plot_name text) RETURNS INTEGER AS $$   
DECLARE
  fid integer;
  pid integer;
  lid integer;
BEGIN

  SELECT get_field_id(site_name) INTO fid;
  IF (plot_name is not NULL) then
    SELECT get_plot_id(site_name, field_name, plot_name) INTO pid;
  END IF;

  SELECT 
    location_id INTO lid 
  FROM
    location
  WHERE 
    field_id = fid AND
    plot_id = pid;

  IF (lid is NULL) then
    RAISE EXCEPTION 'Unknown location: % % %', site_name, field_name, plot_name;
  END IF;

  RETURN lid;
END; 
$$ LANGUAGE plpgsql;