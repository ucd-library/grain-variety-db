-- TABLE
DROP TABLE IF EXISTS crop CASCADE;
CREATE TABLE crop (
  crop_id SERIAL PRIMARY KEY,
  source_id INTEGER REFERENCES source NOT NULL,
  name TEXT UNIQUE NOT NULL
);

-- VIEW
CREATE OR REPLACE VIEW crop_view AS
  SELECT
    c.crop_id as crop_id,
    sc.name as source_name,
    c.name as name
  FROM
    crop c,
    source sc
  WHERE
    c.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_crop (
  name text,
  source_name text) RETURNS void AS $$   
DECLARE
  source_id INTEGER;
BEGIN

  select get_source_id(source_name) into source_id;

  INSERT INTO crop (
    source_id, name
  ) VALUES (
    source_id, name
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop (
  name_in TEXT,
  crop_id_in INTEGER) RETURNS void AS $$   
DECLARE

BEGIN

  UPDATE crop SET (
    name
  ) = (
    name_in
  ) WHERE
    crop_id = crop_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_crop_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_crop(
    name := NEW.name,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_crop(
    name_in := NEW.name,
    crop_id := NEW.crop_id
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_crop_id(name_in text) RETURNS INTEGER AS $$   
DECLARE
  cid integer;
BEGIN

  select 
    crop_id into cid 
  from 
    crop c 
  where  
    name = name_in;

  if (cid is NULL) then
    RAISE EXCEPTION 'Unknown crop: %', name_in;
  END IF;
  
  RETURN cid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER crop_insert_trig
  INSTEAD OF INSERT ON
  crop_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_crop_from_trig();

CREATE TRIGGER crop_update_trig
  INSTEAD OF UPDATE ON
  crop_view FOR EACH ROW 
  EXECUTE PROCEDURE update_crop_from_trig();