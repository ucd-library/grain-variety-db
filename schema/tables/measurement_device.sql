-- TABLE
DROP TABLE IF EXISTS measurement_device CASCADE;
CREATE TABLE measurement_device (
  measurement_device_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name TEXT UNIQUE NOT NULL
);

-- VIEW
CREATE OR REPLACE VIEW measurement_device_view AS
  SELECT
    m.measurement_device_id AS measurement_device_id,
    m.name as name,
    sc.name AS source_name
  FROM
    measurement_device m
LEFT JOIN source sc ON m.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_measurement_device (
  measurement_device_id UUID,
  name TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  mid UUID;
  source_id UUID;
BEGIN

  IF( measurement_device_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO measurement_device_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  INSERT INTO measurement_device (
    measurement_device_id, name, source_id
  ) VALUES (
    measurement_device_id, name, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_measurement_device (
  measurement_device_id_in UUID,
  name_in TEXT) RETURNS void AS $$   
BEGIN

  UPDATE measurement_device SET
    name
   = 
    name_in
  WHERE
    measurement_device_id = measurement_device_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_measurement_device_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_measurement_device(
    measurement_device_id := NEW.measurement_device_id,
    name := NEW.name,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_measurement_device_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_measurement_device(
    measurement_device_id_in := NEW.measurement_device_id,
    name_in := NEW.name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_measurement_device_id(name_in text) RETURNS UUID AS $$   
DECLARE
  mid UUID;
BEGIN

  SELECT 
    measurement_device_id INTO mid 
  FROM 
    measurement_device m 
  WHERE
    name = name_in;

  IF (mid IS NULL) THEN
    RAISE EXCEPTION 'Unknown measurement_device: %', name_in;
  END IF;
  
  RETURN mid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER measurement_device_insert_trig
  INSTEAD OF INSERT ON
  measurement_device_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_measurement_device_from_trig();

CREATE TRIGGER measurement_device_update_trig
  INSTEAD OF UPDATE ON
  measurement_device_view FOR EACH ROW 
  EXECUTE PROCEDURE update_measurement_device_from_trig();