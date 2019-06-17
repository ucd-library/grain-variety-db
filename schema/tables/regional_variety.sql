-- TABLE
DROP TABLE IF EXISTS regional_variety CASCADE;
CREATE TABLE regional_variety (
  regional_variety_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  region REGION NOT NULL,
  variety_id UUID REFERENCES variety NOT NULL,
  uc_entry_number INTEGER,
  trial_group trial_group,
  crop_sub_type crop_sub_type,
  year_added INTEGER,
  crop_classification crop_classification
);

-- VIEW
CREATE OR REPLACE VIEW regional_variety_view AS
  SELECT
    r.regional_variety_id AS regional_variety_id,
    r.region as region,
    v.name as variety_name,
    r.uc_entry_number as uc_entry_number,
    r.trial_group as trial_group,
    r.crop_classification as crop_classification,
    r.crop_sub_type as crop_sub_type,
    r.year_added as year_added,
    sc.name AS source_name
  FROM
    regional_variety r
LEFT JOIN source sc ON r.source_id = sc.source_id
LEFT JOIN variety v on r.variety_id = v.variety_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_regional_variety (
  regional_variety_id UUID,
  region region,
  variety_name TEXT,
  uc_entry_number INTEGER,
  trial_group trial_group,
  crop_classification crop_classification,
  crop_sub_type crop_sub_type,
  year_added INTEGER,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  rid UUID;
  vid UUID;
  source_id UUID;
BEGIN

  IF( regional_variety_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO regional_variety_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_variety_id(variety_name) INTO vid;

  INSERT INTO regional_variety (
    regional_variety_id, region, variety_id, uc_entry_number, trial_group, crop_classification, crop_sub_type, year_added, source_id
  ) VALUES (
    regional_variety_id, region, vid, uc_entry_number, trial_group, crop_classification, crop_sub_type, year_added, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_regional_variety (
  regional_variety_id_in UUID,
  region_in region,
  variety_name_in TEXT,
  uc_entry_number_in INTEGER,
  trial_group_in trial_group,
  crop_classification_in crop_classification,
  crop_sub_type_in crop_sub_type,
  year_added_in INTEGER) RETURNS void AS $$   
DECLARE
  vid UUID;
BEGIN
  SELECT get_variety_id(variety_name_in) INTO vid;

  UPDATE regional_variety SET (
    region, variety_name, uc_entry_number, trial_group, crop_classification, crop_sub_type,  year_added
  ) = (
    region_in, vid, uc_entry_number_in, trial_group_in, crop_classification_in, crop_sub_type_in, year_added_in
  ) WHERE
    regional_variety_id = regional_variety_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_regional_variety_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_regional_variety(
    regional_variety_id := NEW.regional_variety_id,
    region := NEW.region,
    variety_name := NEW.variety_name,
    uc_entry_number := NEW.uc_entry_number,
    trial_group := NEW.trial_group,
    crop_classification := NEW.crop_classification,
    crop_sub_type := NEW.crop_sub_type,
    year_added := NEW.year_added,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_regional_variety_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_regional_variety(
    regional_variety_id_in := NEW.regional_variety_id,
    region_in := NEW.region,
    variety_name_in := NEW.variety_name,
    uc_entry_number_in := NEW.uc_entry_number,
    trial_group_in := NEW.trial_group,
    crop_classification_in := NEW.crop_classification,
    crop_sub_type_in := NEW.crop_sub_type,
    year_added_in := NEW.year_added
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_regional_variety_id(
  region_in REGION, 
  uc_entry_number_in INTEGER) RETURNS UUID AS $$   
DECLARE
  rid UUID;
BEGIN

  SELECT 
    regional_variety_id INTO rid 
  FROM 
    regional_variety r 
  WHERE 
    region = region_in AND
    uc_entry_number = uc_entry_number_in;

  IF (rid IS NULL) THEN
    RAISE EXCEPTION 'Unknown regional_variety: %s %s', region_in, uc_entry_number_in;
  END IF;
  
  RETURN rid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER regional_variety_insert_trig
  INSTEAD OF INSERT ON
  regional_variety_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_regional_variety_from_trig();

CREATE TRIGGER regional_variety_update_trig
  INSTEAD OF UPDATE ON
  regional_variety_view FOR EACH ROW 
  EXECUTE PROCEDURE update_regional_variety_from_trig();