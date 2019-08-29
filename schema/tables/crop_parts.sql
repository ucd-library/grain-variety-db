-- TABLE
DROP TABLE IF EXISTS crop_parts CASCADE;
CREATE TABLE crop_parts (
  crop_parts_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  plant_part_id UUID REFERENCES plant_part NOT NULL,
  crop_id UUID REFERENCES crop NOT NULL,
  UNIQUE(plant_part_id, crop_id)
);
CREATE INDEX crop_parts_plant_part_id_idx ON crop_parts(plant_part_id);
CREATE INDEX crop_parts_plant_crop_id_idx ON crop_parts(crop_id);

-- VIEW
CREATE OR REPLACE VIEW crop_parts_view AS
  SELECT
    c.crop_parts_id AS crop_parts_id,
    pp.name as plant_part,
    cr.name as crop,
    sc.name AS source_name
  FROM
    crop_parts c
LEFT JOIN source sc ON c.source_id = sc.source_id
LEFT JOIN plant_part pp ON c.plant_part_id = pp.plant_part_Id
LEFT JOIN crop cr ON c.crop_id = cr.crop_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_crop_parts (
  crop_parts_id UUID,
  plant_part TEXT,
  crop TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  cid UUID;
  source_id UUID;
  crop_id UUID;
  plant_part_id UUID;
BEGIN

  IF( crop_parts_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO crop_parts_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_crop_id(crop) INTO crop_id;
  SELECT get_plant_part_id(plant_part) INTO plant_part_id;

  INSERT INTO crop_parts (
    crop_parts_id, plant_part_id, crop_id, source_id
  ) VALUES (
    crop_parts_id, plant_part_id, crop_id, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_parts (
  crop_parts_id_in UUID,
  plant_part_in TEXT,
  crop_in TEXT) RETURNS void AS $$   
DECLARE
  cid UUID;
  ppid UUID;
BEGIN

  SELECT get_crop_id(crop_in) INTO cid;
  SELECT get_plant_part_id(plant_part_in) INTO ppid;

  UPDATE crop_parts SET (
    plant_part_id, crop_id
  ) = (
    ppid, cid
  ) WHERE
    crop_parts_id = crop_parts_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_crop_parts_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_crop_parts(
    crop_parts_id := NEW.crop_parts_id,
    plant_part := NEW.plant_part,
    crop := NEW.crop,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_parts_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_crop_parts(
    crop_parts_id_in := NEW.crop_parts_id,
    plant_part_in := NEW.plant_part,
    crop_in := NEW.crop
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_crop_parts_id(crop_in text, plant_part_in text) RETURNS UUID AS $$   
DECLARE
  cid UUID;
  crid UUID;
  ppid UUID;
BEGIN

  SELECT get_crop_id(crop_in) INTO crid;
  SELECT get_plant_part_id(plant_part_in) INTO ppid;

  SELECT 
    crop_parts_id INTO cid 
  FROM 
    crop_parts c 
  WHERE
    crid = crop_id AND
    ppid = plant_part_id;
  

  IF (cid IS NULL) THEN
    RAISE EXCEPTION 'Unknown crop_parts: % %', crop_in, plant_part_in;
  END IF;
  
  RETURN cid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER crop_parts_insert_trig
  INSTEAD OF INSERT ON
  crop_parts_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_crop_parts_from_trig();

CREATE TRIGGER crop_parts_update_trig
  INSTEAD OF UPDATE ON
  crop_parts_view FOR EACH ROW 
  EXECUTE PROCEDURE update_crop_parts_from_trig();