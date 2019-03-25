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
CREATE OR REPLACE FUNCTION get_site_id(trail_name TEXT, site_name TEXT) RETURNS INTEGER AS $$   
DECLARE
  sid INTEGER;
  tid INTEGER;
BEGIN

  select trail_id into tid from trail where name = trail_name;
  select site_id into sid from site where name = site_name and trail_id = tid;

  IF (sid is NULL) then
    RAISE EXCEPTION 'Unknown trail site: % %', trail_name, site_name;
  END IF;

  RETURN sid;
END; 
$$ LANGUAGE plpgsql;