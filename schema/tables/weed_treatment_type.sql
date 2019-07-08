-- TABLE
DROP TABLE IF EXISTS weed_treatment_type CASCADE;
CREATE TABLE weed_treatment_type (
  weed_treatment_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name text NOT NULL,
  unit text,
  description text,
  unique(name, unit)
);
CREATE INDEX weed_treatment_type_source_id_idx ON weed_treatment_type(source_id);
CREATE INDEX weed_treatment_type_name_idx ON weed_treatment_type(name);

-- VIEW
CREATE OR REPLACE VIEW weed_treatment_type_view AS
  SELECT
    w.weed_treatment_type_id AS weed_treatment_type_id,
    w.name as name,
    w.unit as unit,
    w.description as description,
    sc.name AS source_name
  FROM
    weed_treatment_type w
LEFT JOIN source sc ON w.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_weed_treatment_type (
  weed_treatment_type_id UUID,
  name TEXT,
  unit TEXT,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
BEGIN

  IF( weed_treatment_type_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO weed_treatment_type_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  INSERT INTO weed_treatment_type (
    weed_treatment_type_id, name, unit, description, source_id
  ) VALUES (
    weed_treatment_type_id, name, unit, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_weed_treatment_type (
  weed_treatment_type_id_in UUID,
  name_in TEXT,
  unit_in TEXT,
  description_in TEXT) RETURNS void AS $$   
BEGIN

  UPDATE weed_treatment_type SET (
    name, unit, description
  ) = (
    name_in, unit_in, description_in
  ) WHERE
    weed_treatment_type_id = weed_treatment_type_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_weed_treatment_type_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_weed_treatment_type(
    weed_treatment_type_id := NEW.weed_treatment_type_id,
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

CREATE OR REPLACE FUNCTION update_weed_treatment_type_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_weed_treatment_type(
    weed_treatment_type_id_in := NEW.weed_treatment_type_id,
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
CREATE OR REPLACE FUNCTION get_weed_treatment_type_id(name_in text, unit_in text) RETURNS UUID AS $$   
DECLARE
  wid UUID;
BEGIN

  SELECT 
    weed_treatment_type_id INTO wid 
  FROM 
    weed_treatment_type w 
  WHERE
    name = name_in AND
    unit = unit_in;

  IF (wid IS NULL) THEN
    RAISE EXCEPTION 'Unknown weed_treatment_type: % %', name_in, unit_in;
  END IF;
  
  RETURN wid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER weed_treatment_type_insert_trig
  INSTEAD OF INSERT ON
  weed_treatment_type_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_weed_treatment_type_from_trig();

CREATE TRIGGER weed_treatment_type_update_trig
  INSTEAD OF UPDATE ON
  weed_treatment_type_view FOR EACH ROW 
  EXECUTE PROCEDURE update_weed_treatment_type_from_trig();