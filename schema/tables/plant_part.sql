-- TABLE
DROP TABLE IF EXISTS plant_part CASCADE;
CREATE TABLE plant_part (
  plant_part_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name TEXT UNIQUE NOT NULL
);

-- VIEW
CREATE OR REPLACE VIEW plant_part_view AS
  SELECT
    p.plant_part_id AS plant_part_id,
    p.name as name,
    sc.name AS source_name
  FROM
    plant_part p
LEFT JOIN source sc ON p.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_plant_part (
  plant_part_id UUID,
  name TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  pid UUID;
  source_id UUID;
BEGIN

  IF( plant_part_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO plant_part_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  INSERT INTO plant_part (
    plant_part_id, name, source_id
  ) VALUES (
    plant_part_id, name, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_plant_part (
  plant_part_id_in UUID,
  name_in TEXT) RETURNS void AS $$   
BEGIN

  UPDATE plant_part SET
    name 
  = 
    name_in
  WHERE
    plant_part_id = plant_part_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_plant_part_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_plant_part(
    plant_part_id := NEW.plant_part_id,
    name := NEW.name,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_plant_part_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_plant_part(
    plant_part_id_in := NEW.plant_part_id,
    name_in := NEW.name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_plant_part_id(name_in text) RETURNS UUID AS $$   
DECLARE
  pid UUID;
BEGIN

  SELECT 
    plant_part_id INTO pid 
  FROM 
    plant_part p 
  WHERE
    name = name_in;

  IF (pid IS NULL) THEN
    RAISE EXCEPTION 'Unknown plant_part: %', name_in;
  END IF;
  
  RETURN pid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER plant_part_insert_trig
  INSTEAD OF INSERT ON
  plant_part_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_plant_part_from_trig();

CREATE TRIGGER plant_part_update_trig
  INSTEAD OF UPDATE ON
  plant_part_view FOR EACH ROW 
  EXECUTE PROCEDURE update_plant_part_from_trig();