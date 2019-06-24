-- TABLE
DROP TABLE IF EXISTS location CASCADE;
CREATE TABLE location (
  location_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  field_id UUID REFERENCES field NOT NULL,
  plot_id UUID REFERENCES plot,
  source_id UUID REFERENCES source
);
CREATE INDEX location_source_id_idx ON location(source_id);
CREATE INDEX location_plot_id_idx ON location(plot_id);
CREATE INDEX location_field_id_idx ON location(field_id);

-- VIEW
CREATE OR REPLACE VIEW location_view AS
  SELECT
    l.location_id AS location_id,
    t.name as trial,
    s.name as site,
    f.name as field,
    p.plot_number as plot_number,
    cr.name as crop
  FROM
    location l
LEFT JOIN field f on l.field_id = f.field_id
LEFT JOIN plot p on l.plot_id = p.plot_id
LEFT JOIN site s on f.site_id = s.site_id
LEFT JOIN trial t on f.trial_id = t.trial_id
LEFT JOIN crop cr on f.crop_id = cr.crop_id;

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
CREATE OR REPLACE FUNCTION get_location_id(trial_name_in text, field_name_in text, plot_number_in integer) RETURNS UUID AS $$   
DECLARE
  fid UUID;
  pid UUID;
  lid UUID;
BEGIN

  SELECT get_field_id(trial_name_in, field_name_in) INTO fid;
  IF (plot_number_in is not NULL) then
    SELECT get_plot_id(trial_name_in, field_name_in, plot_number_in) INTO pid;
  END IF;

  SELECT 
    location_id INTO lid 
  FROM
    location
  WHERE 
    field_id = fid AND
    plot_id = pid;

  IF (lid is NULL) then
    RAISE EXCEPTION 'Unknown location: % % %', trial_name_in, field_name_in, plot_number_in;
  END IF;

  RETURN lid;
END; 
$$ LANGUAGE plpgsql;