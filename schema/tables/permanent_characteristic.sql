-- TABLE
DROP TABLE IF EXISTS permanent_characteristic CASCADE;
CREATE TABLE permanent_characteristic (
  permanent_characteristic_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name TEXT UNIQUE NOT NULL,
  description TEXT
);
CREATE INDEX permanent_characteristic_source_id_idx ON permanent_characteristic(source_id);

-- VIEW
CREATE OR REPLACE VIEW permanent_characteristic_view AS
  SELECT
    p.permanent_characteristic_id AS permanent_characteristic_id,
    p.name as name,
    p.description as description,
    sc.name AS source_name
  FROM
    permanent_characteristic p
LEFT JOIN source sc ON p.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_permanent_characteristic (
  permanent_characteristic_id UUID,
  name TEXT,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
BEGIN

  IF( permanent_characteristic_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO permanent_characteristic_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  INSERT INTO permanent_characteristic (
    permanent_characteristic_id, name, description, source_id
  ) VALUES (
    permanent_characteristic_id, name, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_permanent_characteristic (
  permanent_characteristic_id_in UUID,
  name_in TEXT,
  description_in TEXT) RETURNS void AS $$   
DECLARE

BEGIN

  UPDATE permanent_characteristic SET (
    name, description, 
  ) = (
    name_in, description_in
  ) WHERE
    permanent_characteristic_id = permanent_characteristic_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_permanent_characteristic_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_permanent_characteristic(
    permanent_characteristic_id := NEW.permanent_characteristic_id,
    name := NEW.name,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_permanent_characteristic_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_permanent_characteristic(
    permanent_characteristic_id_in := NEW.permanent_characteristic_id,
    name_in := NEW.name,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_permanent_characteristic_id(name_in) RETURNS UUID AS $$   
DECLARE
  pid UUID;
BEGIN

  SELECT 
    permanent_characteristic_id INTO pid 
  FROM 
    permanent_characteristic p 
  WHERE  
    name = name_in;

  IF (pid IS NULL) THEN
    RAISE EXCEPTION 'Unknown permanent_characteristic: name="%"', name_in;
  END IF;
  
  RETURN pid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER permanent_characteristic_insert_trig
  INSTEAD OF INSERT ON
  permanent_characteristic_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_permanent_characteristic_from_trig();

CREATE TRIGGER permanent_characteristic_update_trig
  INSTEAD OF UPDATE ON
  permanent_characteristic_view FOR EACH ROW 
  EXECUTE PROCEDURE update_permanent_characteristic_from_trig();