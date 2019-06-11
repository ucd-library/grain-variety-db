-- TABLE
DROP TABLE IF EXISTS location CASCADE;
CREATE TABLE location (
  location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  field_id UUID REFERENCES field NOT NULL,
  plot_id UUID REFERENCES plot,
  source_id UUID REFERENCES source
);

-- FUNCTION INSERT
CREATE OR REPLACE FUNCTION insert_location (
  location_id UUID,
  site_name text,
  field_name text,
  plot_name text) RETURNS void AS $$   
DECLARE
  fid UUID;
  pid UUID;
BEGIN

  if( location_id IS NULL ) Then
    select uuid_generate_v4() into location_id;
  END IF;
  SELECT get_field_id(site_name) INTO fid;
  IF (plot_name is not NULL) then
    SELECT get_plot_id(site_name, field_name, plot_name) INTO pid;
  END IF;

  INSERT INTO location (
    location_id, field_id, plot_id 
  ) VALUES (
    location_id, fid, pid
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_location_id(site_name text, field_name text, plot_name text) RETURNS UUID AS $$   
DECLARE
  fid UUID;
  pid UUID;
  lid UUID;
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