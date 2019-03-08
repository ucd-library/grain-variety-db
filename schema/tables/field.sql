-- TABLE
DROP TABLE IF EXISTS field CASCADE;
CREATE TABLE field (
  field_id SERIAL PRIMARY KEY,
  site_id INTEGER REFERENCES site NOT NULL,
  name text NOT NULL UNIQUE
);

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_field_id(name_in text) RETURNS INTEGER AS $$   
DECLARE
  fid integer;
BEGIN

  select field_id into fid from  where name = name_in;

  IF (fid is NULL) then
    RAISE EXCEPTION 'Unknown field: %', name_in;
  END IF;

  RETURN fid;
END; 
$$ LANGUAGE plpgsql;