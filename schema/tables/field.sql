-- TABLE
DROP TABLE IF EXISTS field CASCADE;
CREATE TABLE field (
  field_id SERIAL PRIMARY KEY,
  source_id INTEGER REFERENCES source NOT NULL,
  site_id INTEGER REFERENCES site NOT NULL,
  name text NOT NULL UNIQUE
);

-- VIEW
CREATE OR REPLACE VIEW field_view AS 
SELECT 
  f.field_id as field_id,
  t.name as trial_name,
  s.name as site_name,
  f.name as field_name,
  sc.name as source_name
FROM
  field f
LEFT JOIN site s ON s.site_id = f.site_id
LEFT JOIN trail t ON t.trail_id = s.site_id
LEFT JOIN source sc ON f.source_id = sc.source_id;


-- FUNCTION INSERT
CREATE OR REPLACE FUNCTION insert_field (
  trail_name text,
  site_name text,
  field_name text,
  source_name text) RETURNS void AS $$   
DECLARE
  sid INTEGER;
  scid INTEGER;
  fid INTEGER;
BEGIN

  select get_source_id(source_name) into scid;
  select get_site_id(trial_name, site_name) into sid;
  
  BEGIN;
  INSERT INTO field (
    source_id, site_id, name
  ) VALUES (
    scid, sid, field_name
  ) RETURNING field_id into fid;

  INSERT INTO field_location (
    scid, fid, NULL
  ) VALUES (
    source_id, field_id, plot_id 
  )
  COMMIT;

EXCEPTION WHEN raise_exception THEN
  ROLLBACK;
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_field_id(trail_name text, site_name text, field_name text) RETURNS INTEGER AS $$   
DECLARE
  fid integer;
  sid integer;
BEGIN

  SELECT get_site_id(trail_name, site_name) INTO sid;

  SELECT 
    field_id INTO fid 
  FROM
    field
  WHERE 
    name = field_name AND
    site_id = sid;

  IF (fid is NULL) then
    RAISE EXCEPTION 'Unknown field: % % %', trail_name, site_name, field_name;
  END IF;

  RETURN fid;
END; 
$$ LANGUAGE plpgsql;