-- TABLE
DROP TABLE IF EXISTS fertilization_type CASCADE;
CREATE TABLE fertilization_type (
  fertilization_type_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name TEXT NOT NULL,
  unit TEXT,
  description TEXT,
  UNIQUE(name, unit)
);
CREATE INDEX fertilization_type_source_id_idx ON fertilization_type(source_id);

-- VIEW
CREATE OR REPLACE VIEW fertilization_type_view AS
  SELECT
    f.fertilization_type_id AS fertilization_type_id,
    f.name as name,
    f.unit as unit,
    f.description as description,
    sc.name AS source_name
  FROM
    fertilization_type f
LEFT JOIN source sc ON f.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_fertilization_type (
  fertilization_type_id UUID,
  name TEXT,
  unit TEXT,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
BEGIN

  IF( fertilization_type_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO fertilization_type_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  INSERT INTO fertilization_type (
    fertilization_type_id, name, unit, description, source_id
  ) VALUES (
    fertilization_type_id, name, unit, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_fertilization_type (
  fertilization_type_id_in UUID,
  name_in TEXT,
  unit_in TEXT,
  description_in TEXT) RETURNS void AS $$  
BEGIN

  UPDATE fertilization_type SET (
    name, unit, description
  ) = (
    name_in, unit_in, description_in
  ) WHERE
    fertilization_type_id = fertilization_type_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_fertilization_type_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_fertilization_type(
    fertilization_type_id := NEW.fertilization_type_id,
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

CREATE OR REPLACE FUNCTION update_fertilization_type_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_fertilization_type(
    fertilization_type_id_in := NEW.fertilization_type_id,
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
CREATE OR REPLACE FUNCTION get_fertilization_type_id(name_in TEXT, unit_in TEXT) RETURNS UUID AS $$   
DECLARE
  fid UUID;
BEGIN

  SELECT 
    fertilization_type_id INTO fid 
  FROM 
    fertilization_type f 
  WHERE
    name = name_in AND
    unit = unit_in;

  IF (fid IS NULL) THEN
    RAISE EXCEPTION 'Unknown fertilization_type: % %', name_in, unit_in;
  END IF;
  
  RETURN fid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER fertilization_type_insert_trig
  INSTEAD OF INSERT ON
  fertilization_type_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_fertilization_type_from_trig();

CREATE TRIGGER fertilization_type_update_trig
  INSTEAD OF UPDATE ON
  fertilization_type_view FOR EACH ROW 
  EXECUTE PROCEDURE update_fertilization_type_from_trig();