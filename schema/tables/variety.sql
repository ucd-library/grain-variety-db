-- TABLE
DROP TABLE IF EXISTS variety CASCADE;
CREATE TABLE variety (
  variety_id SERIAL PRIMARY KEY,
  source_id INTEGER REFERENCES source NOT NULL,
  crop_id INTEGER REFERENCES crop NOT NULL,
  name TEXT UNIQUE NOT NULL,
  crop_classification crop_classification,
  source text,
  release_status release_status
);

-- VIEW
CREATE OR REPLACE VIEW variety_view AS
  SELECT
    v.variety_id as variety_id,
    c.name as crop,
    v.name as name,
    v.crop_classification as crop_classification,
    v.source as source,
    v.release_status as release_status,
    sc.name as source_name
  FROM
    variety v
LEFT JOIN crop c ON v.crop_id = c.crop_id
LEFT JOIN source sc ON v.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_variety (
  crop text,
  name text,
  crop_classification crop_classification,
  source text,
  release_status release_status,
  source_name text) RETURNS void AS $$   
DECLARE
  source_id INTEGER;
  crop_id INTEGER;
BEGIN

  select get_source_id(source_name) into source_id;
  select get_crop_id(crop) into crop_id;

  INSERT INTO variety (
    source_id, crop_id, name, crop_classification, source, release_status
  ) VALUES (
    source_id, crop_id, name, crop_classification, source, release_status
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_variety (
  variety_id_in INTEGER,
  crop_in text,
  name_in text,
  crop_classification_in crop_classification,
  source_in text,
  release_status_in release_status) RETURNS void AS $$   
DECLARE
  cid INTEGER;
BEGIN

  select get_crop_id(crop_in) into cid;

  UPDATE variety SET (
    crop_id, name, crop_classification, source, release_status
  ) = (
    cid, name_in, crop_classification_in, source_in, release_status_in
  ) WHERE
    variety_id = variety_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_variety_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_variety(
    crop := NEW.crop,
    name := NEW.name,
    crop_classification := NEW.crop_classification,
    source := NEW.source,
    release_status := NEW.release_status,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_variety_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_variety(
    variety_id_in := NEW.variety_id,
    crop_in := NEW.crop,
    name_in := NEW.name,
    crop_classification_in := NEW.crop_classification,
    source_in := NEW.source,
    release_status_in := NEW.release_status
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_variety_id(name_in text) RETURNS INTEGER AS $$   
DECLARE
  vid integer;
BEGIN

  select 
    variety_id into vid 
  from 
    variety v 
  where  
    name = name_in;

  if (vid is NULL) then
    RAISE EXCEPTION 'Unknown variety: %', name_in;
  END IF;
  
  RETURN vid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER variety_insert_trig
  INSTEAD OF INSERT ON
  variety_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_variety_from_trig();

CREATE TRIGGER variety_update_trig
  INSTEAD OF UPDATE ON
  variety_view FOR EACH ROW 
  EXECUTE PROCEDURE update_variety_from_trig();