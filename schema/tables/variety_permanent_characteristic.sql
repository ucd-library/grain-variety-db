-- TABLE
DROP TABLE IF EXISTS variety_permanent_characteristic CASCADE;
CREATE TABLE variety_permanent_characteristic (
  variety_permanent_characteristic_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  variety_id UUID REFERENCES variety NOT NULL,
  permanent_characteristic_id UUID REFERENCES permanent_characteristic NOT NULL,
  value INTEGER
);
CREATE INDEX variety_permanent_characteristic_source_id_idx ON variety_permanent_characteristic(source_id);

-- VIEW
CREATE OR REPLACE VIEW variety_permanent_characteristic_view AS
  SELECT
    vpc.variety_permanent_characteristic_id AS variety_permanent_characteristic_id,
    v.name as variety_name,
    pc.name as permanent_characteristic_name,
    vpc.value as value,
    sc.name AS source_name
  FROM
    variety_permanent_characteristic vpc
LEFT JOIN variety v ON vpc.variety_id = v.variety_id
LEFT JOIN permanent_characteristic pc ON vpc.permanent_characteristic_id = pc.permanent_characteristic_id
LEFT JOIN source sc ON vpc.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_variety_permanent_characteristic (
  variety_permanent_characteristic_id UUID,
  variety_name TEXT,
  permanent_characteristic_name TEXT,
  value INTEGER,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  variety_id UUID;
  permanent_characteristic_id UUID;
BEGIN

  IF( variety_permanent_characteristic_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO variety_permanent_characteristic_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  SELECT get_variety_id(variety_name) INTO variety_id;
  SELECT get_permanent_characteristic_id(permanent_characteristic_name) INTO permanent_characteristic_id;

  INSERT INTO variety_permanent_characteristic (
    variety_permanent_characteristic_id, variety_id, permanent_characteristic_id, value, source_id
  ) VALUES (
    variety_permanent_characteristic_id, variety_id, permanent_characteristic_id, value, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_variety_permanent_characteristic (
  variety_permanent_characteristic_id_in UUID,
  variety_name_in TEXT,
  permanent_characteristic_name_in TEXT,
  value_in INTEGER) RETURNS void AS $$   
DECLARE
  vid UUID;
  pcid UUID;
BEGIN

  SELECT get_variety_id(variety_name_in) INTO vid;
  SELECT get_permanent_characteristic_id(permanent_characteristic_name_in) INTO pcid;

  UPDATE variety_permanent_characteristic SET (
    variety_id, permanent_characteristic_id, value
  ) = (
    vid, pcid, value_in
  ) WHERE
    variety_permanent_characteristic_id = variety_permanent_characteristic_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_variety_permanent_characteristic_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_variety_permanent_characteristic(
    variety_permanent_characteristic_id := NEW.variety_permanent_characteristic_id,
    variety_name := NEW.variety_name,
    permanent_characteristic_name := NEW.permanent_characteristic_name,
    value := NEW.value,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_variety_permanent_characteristic_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_variety_permanent_characteristic(
    variety_permanent_characteristic_id_in := NEW.variety_permanent_characteristic_id,
    variety_name_in := NEW.variety_name,
    permanent_characteristic_name_in := NEW.permanent_characteristic_name,
    value_in := NEW.value
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER variety_permanent_characteristic_insert_trig
  INSTEAD OF INSERT ON
  variety_permanent_characteristic_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_variety_permanent_characteristic_from_trig();

CREATE TRIGGER variety_permanent_characteristic_update_trig
  INSTEAD OF UPDATE ON
  variety_permanent_characteristic_view FOR EACH ROW 
  EXECUTE PROCEDURE update_variety_permanent_characteristic_from_trig();