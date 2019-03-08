-- TABLE
DROP TABLE IF EXISTS variety_name CASCADE;
CREATE TABLE variety_name (
  variety_name_id SERIAL PRIMARY KEY,
  varity_id INTEGER REFERENCES variety NOT NULL,
  name TEXT NOT NULL UNIQUE
);
CREATE INDEX variety_name_name_idx ON variety_name(name);

-- VIEW
CREATE OR REPLACE VIEW variety_name_view AS 
SELECT 
  v.uc_entry_number as uc_entry_number,
  nv.name as name
FROM
  variety v,
  variety_name vn
WHERE
  v.variety_id = nv.variety_id;


-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_variety_id_by_name(name_in text) RETURNS INTEGER AS $$   
DECLARE
  vid integer;
BEGIN

  select varity_id into vid from variety_name where name = name_in;

  IF (vid is NULL) then
    RAISE EXCEPTION 'Unknown variety name: %', name_in;
  END IF;

  RETURN vid;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_variety_uc_id_by_name(name_in text) RETURNS INTEGER AS $$   
DECLARE
  vid integer;
  ucid integer;
BEGIN

  select get_variety_id_by_name(name_in) into vid;
  select uc_entry_number into ucid from variety where variety = vid;

  IF (ucid is NULL) then
    RAISE EXCEPTION 'Unknown variety uc_entry_number: %', ucid;
  END IF;

  RETURN ucid;
END; 
$$ LANGUAGE plpgsql;