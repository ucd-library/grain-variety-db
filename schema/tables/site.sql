-- TABLE
DROP TABLE IF EXISTS site CASCADE;
CREATE TABLE site (
  site_id SERIAL PRIMARY KEY,
  trial_id INTEGER REFERENCES trail NOT NULL,
  name text NOT NULL UNIQUE,
  cooperator text NOT NULL,
  boundry GEOMETRY(POLYGON, 4326)
);

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_site_id(name_in text) RETURNS INTEGER AS $$   
DECLARE
  sid integer;
BEGIN

  select site_id into sid from site where name = name_in;

  IF (sid is NULL) then
    RAISE EXCEPTION 'Unknown site: %', name_in;
  END IF;

  RETURN side;
END; 
$$ LANGUAGE plpgsql;