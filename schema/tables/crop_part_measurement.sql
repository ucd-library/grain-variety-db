-- TABLE
DROP TABLE IF EXISTS crop_part_measurement CASCADE;
CREATE TABLE crop_part_measurement (
  crop_part_measurement_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  measurement_id UUID REFERENCES measurement NOT NULL,
  crop_parts_id UUID REFERENCES crop_parts NOT NULL,
  UNIQUE(measurement_id, crop_parts_id)
);
CREATE INDEX crop_part_measurement_source_id_idx ON crop_part_measurement(source_id);
CREATE INDEX crop_part_measurement_measurement_id_idx ON crop_part_measurement(measurement_id);
CREATE INDEX crop_part_measurement_crop_parts_id_idx ON crop_part_measurement(crop_parts_id);

-- VIEW
CREATE OR REPLACE VIEW crop_part_measurement_view AS
  SELECT
    c.crop_part_measurement_id AS crop_part_measurement_id,
    cr.name as crop,
    pp.name as plant_part,
    m.name as measurement_name,
    md.name as measurement_device,
    m.unit as measurement_unit,
    sc.name AS source_name
  FROM
    crop_part_measurement c
LEFT JOIN source sc ON c.source_id = sc.source_id
LEFT JOIN crop_parts cp ON c.crop_parts_id = cp.crop_parts_id
LEFT JOIN crop cr ON cp.crop_id = cr.crop_id
LEFT JOIN plant_part pp ON pp.plant_part_id = cp.plant_part_id
LEFT JOIN measurement m ON c.measurement_id = m.measurement_id
LEFT JOIN measurement_device md on m.measurement_device_id = md.measurement_device_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_crop_part_measurement (
  crop_part_measurement_id UUID,
  crop TEXT,
  plant_part TEXT,
  measurement_name TEXT,
  measurement_device TEXT,
  measurement_unit TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  cid UUID;
  source_id UUID;
  cpid UUID;
  mid UUID;
BEGIN

  IF( crop_part_measurement_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO crop_part_measurement_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_crop_parts_id(crop, plant_part) INTO cpid;
  SELECT get_measurement_id(measurement_name, measurement_device, measurement_unit) INTO mid;

  INSERT INTO crop_part_measurement (
    crop_part_measurement_id, measurement_id, crop_parts_id, source_id
  ) VALUES (
    crop_part_measurement_id, mid, cpid, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_part_measurement (
  crop_part_measurement_id_in UUID,
  crop_in TEXT,
  plant_part_in TEXT,
  measurement_name_in TEXT,
  measurement_device_in TEXT,
  measurement_unit_in TEXT) RETURNS void AS $$   
DECLARE
  cpid UUID;
  mid UUID;
BEGIN

  SELECT get_crop_parts_id(crop_in, plant_part_in) INTO cpid;
  SELECT get_measurement_id(measurement_name_in, measurement_device_in, measurement_unit_in) INTO mid;

  UPDATE crop_part_measurement SET (
    measurement_id, crop_parts_id 
  ) = (
    mid, cpid
  ) WHERE
    crop_part_measurement_id = crop_part_measurement_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_crop_part_measurement_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_crop_part_measurement(
    crop_part_measurement_id := NEW.crop_part_measurement_id,
    crop := NEW.crop,
    plant_part := NEW.plant_part,
    measurement_name := NEW.measurement_name,
    measurement_device := NEW.measurement_device,
    measurement_unit := NEW.measurement_unit,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_part_measurement_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_crop_part_measurement(
    crop_part_measurement_id_in := NEW.crop_part_measurement_id,
    crop_in := NEW.crop,
    plant_part_in := NEW.plant_part,
    measurement_name_in := NEW.measurement_name,
    measurement_device_in := NEW.measurement_device,
    measurement_unit_in := NEW.measurement_unit
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_crop_part_measurement_id(
  crop text, plant_part text,
  measurement_name text, measurement_device text, measurement_unit text ) RETURNS UUID AS $$   
DECLARE
  cid UUID;
  cpid UUID;
  mid UUID;
BEGIN

  SELECT get_crop_parts_id(crop, plant_part) INTO cpid;
  SELECT get_measurement_id(measurement_name, measurement_device, measurement_unit) INTO mid;
  SELECT 
    crop_part_measurement_id INTO cid 
  FROM 
    crop_part_measurement c 
  WHERE
    crop_parts_id = cpid AND
    measurement_id = mid;

  IF (cid IS NULL) THEN
    RAISE EXCEPTION 'Unknown crop_part_measurement: crop="%" plant_part="%" measurement_name="%" measurement_device="%" measurement_unit="%"',  crop, plant_part, measurement_name, measurement_device, measurement_unit;
  END IF;
  
  RETURN cid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER crop_part_measurement_insert_trig
  INSTEAD OF INSERT ON
  crop_part_measurement_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_crop_part_measurement_from_trig();

CREATE TRIGGER crop_part_measurement_update_trig
  INSTEAD OF UPDATE ON
  crop_part_measurement_view FOR EACH ROW 
  EXECUTE PROCEDURE update_crop_part_measurement_from_trig();