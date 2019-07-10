-- TABLE
DROP TABLE IF EXISTS irrigation_method CASCADE;
CREATE TABLE irrigation_method (
  irrigation_method_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name TEXT NOT NULL,
  unit TEXT,
  description TEXT,
  UNIQUE(name, unit)
);
CREATE INDEX irrigation_method_source_id_idx ON irrigation_method(source_id);

-- VIEW
CREATE OR REPLACE VIEW irrigation_method_view AS
  SELECT
    i.irrigation_method_id AS irrigation_method_id,
    i.name as name,
    i.unit as unit,
    i.description as description,
    sc.name AS source_name
  FROM
    irrigation_method i
LEFT JOIN source sc ON i.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_irrigation_method (
  irrigation_method_id UUID,
  name TEXT,
  unit TEXT,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
BEGIN

  IF( irrigation_method_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO irrigation_method_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  INSERT INTO irrigation_method (
    irrigation_method_id, name, unit, description, source_id
  ) VALUES (
    irrigation_method_id, name, unit, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_irrigation_method (
  irrigation_method_id_in UUID,
  name_in TEXT,
  unit_in TEXT,
  description_in TEXT) RETURNS void AS $$
BEGIN

  UPDATE irrigation_method SET (
    name, unit, description
  ) = (
    name_in, unit_in, description_in
  ) WHERE
    irrigation_method_id = irrigation_method_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_irrigation_method_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_irrigation_method(
    irrigation_method_id := NEW.irrigation_method_id,
    name := NEW.name,
    unit := NEW.unit,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_irrigation_method_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_irrigation_method(
    irrigation_method_id_in := NEW.irrigation_method_id,
    name_in := NEW.name,
    unit_in := NEW.unit,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_irrigation_method_id(name_in text, unit_in text) RETURNS UUID AS $$   
DECLARE
  iid UUID;
BEGIN

  SELECT 
    irrigation_method_id INTO iid 
  FROM 
    irrigation_method i 
  WHERE  
    name = name_in,
    unit = unit_in;

  IF (iid IS NULL) THEN
    RAISE EXCEPTION 'Unknown irrigation_method: % %', name_in, unit_in;
  END IF;
  
  RETURN iid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER irrigation_method_insert_trig
  INSTEAD OF INSERT ON
  irrigation_method_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_irrigation_method_from_trig();

CREATE TRIGGER irrigation_method_update_trig
  INSTEAD OF UPDATE ON
  irrigation_method_view FOR EACH ROW 
  EXECUTE PROCEDURE update_irrigation_method_from_trig();