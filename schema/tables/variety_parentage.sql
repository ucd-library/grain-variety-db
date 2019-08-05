-- TABLE
DROP TABLE IF EXISTS variety_parentage CASCADE;
CREATE TABLE variety_parentage (
  variety_parentage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  variety_id UUID REFERENCES variety NOT NULL,
  parent_variety_id UUID REFERENCES variety NOT NULL
);
CREATE INDEX variety_parentage_source_id_idx ON variety_parentage(source_id);

-- VIEW
CREATE OR REPLACE VIEW variety_parentage_view AS
  SELECT
    v.variety_parentage_id AS variety_parentage_id,
    cv.name as variety_name,
    pv.name as parent_variety_name,
    sc.name AS source_name
  FROM
    variety_parentage v
LEFT JOIN source sc ON v.source_id = sc.source_id
LEFT JOIN variety cv ON v.variety_id = cv.variety_id
LEFT JOIN variety pv ON v.parent_variety_id = pv.variety_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_variety_parentage (
  variety_parentage_id UUID,
  variety_name TEXT,
  parent_variety_name TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  pvid UUID;
  cvid UUID;
BEGIN

  IF( variety_parentage_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO variety_parentage_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  SELECT get_variety_id(variety_name) INTO cvid;
  SELECT get_variety_id(parent_variety_name) INTO pvid;

  INSERT INTO variety_parentage (
    variety_parentage_id, variety_id, parent_variety_id, source_id
  ) VALUES (
    variety_parentage_id, cvid, pvid, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_variety_parentage (
  variety_parentage_id_in UUID,
  variety_name_in TEXT,
  parent_variety_name_in TEXT) RETURNS void AS $$   
DECLARE
  pvid UUID;
  cvid UUID;
BEGIN

  SELECT get_variety_id(variety_name) INTO cvid;
  SELECT get_variety_id(parent_variety_name) INTO pvid;

  UPDATE variety_parentage SET (
    variety_id, parent_variety_id
  ) = (
    cvid, pvid
  ) WHERE
    variety_parentage_id = variety_parentage_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_variety_parentage_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_variety_parentage(
    variety_parentage_id := NEW.variety_parentage_id,
    variety_name := NEW.variety_name,
    parent_variety_name := NEW.parent_variety_name,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_variety_parentage_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_variety_parentage(
    variety_parentage_id_in := NEW.variety_parentage_id,
    variety_name_in := NEW.variety_name,
    parent_variety_name_in := NEW.parent_variety_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER variety_parentage_insert_trig
  INSTEAD OF INSERT ON
  variety_parentage_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_variety_parentage_from_trig();

CREATE TRIGGER variety_parentage_update_trig
  INSTEAD OF UPDATE ON
  variety_parentage_view FOR EACH ROW 
  EXECUTE PROCEDURE update_variety_parentage_from_trig();