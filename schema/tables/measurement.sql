-- TABLE
DROP TABLE IF EXISTS measurement CASCADE;
CREATE TABLE measurement (
  measurement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name TEXT NOT NULL,
  unit TEXT,
  measurement_device_id UUID REFERENCES measurement_device,
  description TEXT,
  UNIQUE(name, unit, measurement_device_id)
);
CREATE INDEX measurement_source_id_idx ON measurement(source_id);

-- VIEW
CREATE OR REPLACE VIEW measurement_view AS
  SELECT
    m.measurement_id AS measurement_id,
    m.name as name,
    md.name as device,
    m.unit as unit,
    m.description as description,
    sc.name AS source_name
  FROM
    measurement m
LEFT JOIN source sc ON m.source_id = sc.source_id
LEFT JOIN measurement_device md on m.measurement_device_id = md.measurement_device_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_measurement (
  measurement_id UUID,
  name TEXT,
  device TEXT,
  unit TEXT,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  mid UUID;
  source_id UUID;
  mdid UUID;
BEGIN

  IF( measurement_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO measurement_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  IF device IS NOT NULL THEN
    SELECT get_measurement_device_id(device) INTO mdid;
  END IF;

  INSERT INTO measurement (
    measurement_id, name, measurement_device_id, unit, description, source_id
  ) VALUES (
    measurement_id, name, mdid, unit, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_measurement (
  measurement_id_in UUID,
  name_in TEXT,
  device_in TEXT,
  unit_in TEXT,
  description_in TEXT) RETURNS void AS $$   
DECLARE
  mdid UUID;
BEGIN

  IF device_in IS NOT NULL THEN
    SELECT get_measurement_device_id(device_in) INTO mdid;
  END IF;

  UPDATE measurement SET (
    name, measurement_device_id, unit, description
  ) = (
    name_in, mdid, unit_in, description_in
  ) WHERE
    measurement_id = measurement_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_measurement_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_measurement(
    measurement_id := NEW.measurement_id,
    name := NEW.name,
    device := NEW.device,
    unit := NEW.unit,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_measurement_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_measurement(
    measurement_id_in := NEW.measurement_id,
    name_in := NEW.name,
    device_in := NEW.device,
    unit_in := NEW.unit,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_measurement_id(name_in text, device_in text, unit_in text) RETURNS UUID AS $$   
DECLARE
  mid UUID;
  mdid UUID;
BEGIN

  IF device_in IS NOT NULL THEN
    SELECT get_measurement_device_id(device_in) INTO mdid;

    IF unit_in IS NULL THEN
      SELECT 
        measurement_id INTO mid 
      FROM 
        measurement m 
      WHERE  
        name = name_in AND
        unit IS NULL AND
        measurement_device_id = mdid;
    ELSE
      SELECT 
        measurement_id INTO mid 
      FROM 
        measurement m 
      WHERE  
        name = name_in AND
        unit = unit_in AND
        measurement_device_id = mdid;
    END IF;

  ELSE

    IF unit_in IS NULL THEN

      SELECT 
        measurement_id INTO mid 
      FROM 
        measurement m 
      WHERE  
        name = name_in AND
        unit IS NULL AND
        measurement_device_id IS NULL;

    ELSE 

      SELECT 
        measurement_id INTO mid 
      FROM 
        measurement m 
      WHERE  
        name = name_in AND
        unit = unit_in AND
        measurement_device_id IS NULL;

    END IF;

  END IF;

  IF (mid IS NULL) THEN
    RAISE EXCEPTION 'Unknown measurement: name="%" device="%" unit="%"', name_in, device_in, unit_in;
  END IF;
  
  RETURN mid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER measurement_insert_trig
  INSTEAD OF INSERT ON
  measurement_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_measurement_from_trig();

CREATE TRIGGER measurement_update_trig
  INSTEAD OF UPDATE ON
  measurement_view FOR EACH ROW 
  EXECUTE PROCEDURE update_measurement_from_trig();