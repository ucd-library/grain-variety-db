-- TABLE
DROP TABLE IF EXISTS variety_label CASCADE;
CREATE TABLE variety_label (
  variety_label_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  variety_id UUID REFERENCES variety NOT NULL,
  label TEXT NOT NULL,
  current BOOLEAN,
  UNIQUE(variety_id, label)
);

-- VIEW
CREATE OR REPLACE VIEW variety_label_view AS
  SELECT
    v.variety_label_id AS variety_label_id,
    vy.name as variety_name,
    v.label as label,
    v.current as current,
    sc.name AS source_name
  FROM
    variety_label v
LEFT JOIN source sc ON v.source_id = sc.source_id
LEFT JOIN variety vy on v.variety_id = vy.variety_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION grain.insert_variety_label (
  variety_label_id UUID,
  variety_name TEXT,
  label TEXT,
  current BOOLEAN,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  vid UUID;
  source_id UUID;
BEGIN

  IF( variety_label_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO variety_label_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_variety_id(variety_name) INTO vid;

  INSERT INTO variety_label (
    variety_label_id, variety_id, label, current, source_id
  ) VALUES (
    variety_label_id, vid, label, current, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_variety_label (
  variety_label_id_in UUID,
  variety_name_in TEXT,
  label_in TEXT,
  current_in BOOLEAN) RETURNS void AS $$   
DECLARE
  vid UUID;
BEGIN

  SELECT get_variety_id(variety_name_in) INTO vid;

  UPDATE variety_label SET (
    variety_id, label, current
  ) = (
    vid, label_in, current_in
  ) WHERE
    variety_label_id = variety_label_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_variety_label_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_variety_label(
    variety_label_id := NEW.variety_label_id,
    variety_name := NEW.variety_name,
    label := NEW.label,
    current := NEW.current,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_variety_label_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_variety_label(
    variety_label_id_in := NEW.variety_label_id,
    variety_name_in := NEW.variety_name,
    label_in := NEW.label,
    current_in := NEW.current
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_variety_label_id(label_in TEXT) RETURNS UUID AS $$   
DECLARE
  vid UUID;
BEGIN

  SELECT 
    variety_label_id INTO vid 
  FROM 
    variety_label v 
  WHERE 
    label_in = label;

  IF (vid IS NULL) THEN
    RAISE EXCEPTION 'Unknown variety_label: %s', label_in;
  END IF;
  
  RETURN vid;
END ; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_variety_id_by_label(label_in TEXT) RETURNS UUID AS $$   
DECLARE
  vid UUID;
BEGIN

  SELECT 
    variety_id INTO vid 
  FROM 
    variety_label v 
  WHERE 
    label_in = label;

  IF (vid IS NULL) THEN
    RAISE EXCEPTION 'Unknown variety: %s', label_in;
  END IF;
  
  RETURN vid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER variety_label_insert_trig
  INSTEAD OF INSERT ON
  variety_label_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_variety_label_from_trig();

CREATE TRIGGER variety_label_update_trig
  INSTEAD OF UPDATE ON
  variety_label_view FOR EACH ROW 
  EXECUTE PROCEDURE update_variety_label_from_trig();