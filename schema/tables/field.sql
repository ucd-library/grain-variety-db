-- TABLE
DROP TABLE IF EXISTS field CASCADE;
CREATE TABLE field (
  field_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  site_id UUID REFERENCES site NOT NULL,
  trial_id UUID REFERENCES trial NOT NULL,
  name text NOT NULL UNIQUE,
  water_stress BOOLEAN NOT NULL,
  nitrogen_stress BOOLEAN NOT NULL,
  bedded INTEGER,
  trial_group trial_group,
  crop_id UUID REFERENCES CROP NOT NULL,
  crop_description TEXT,
  previous_crop_id UUID REFERENCES CROP,
  previous_crop_description TEXT
);
CREATE INDEX location_source_id_idx ON location(source_id);

-- VIEW
CREATE OR REPLACE VIEW field_view AS 
SELECT 
  f.field_id as field_id,
  t.name as trial_name,
  s.name as site_name,
  f.name as name,
  f.water_stress as water_stress,
  f.nitrogen_stress as nitrogen_stress,
  f.bedded as bedded,
  f.trial_group as trial_group,
  c.name as crop,
  f.crop_description as crop_description,
  pc.name as previous_crop,
  f.previous_crop_description as previous_crop_description,
  sc.name as source_name
FROM
  field f
LEFT JOIN site s ON s.site_id = f.site_id
LEFT JOIN trial t ON t.trial_id = f.trial_id
LEFT JOIN crop c on c.crop_id = f.crop_id
LEFT JOIN crop pc on pc.crop_id = f.previous_crop_id
LEFT JOIN source sc ON sc.source_id = f.source_id;


-- FUNCTION INSERT
CREATE OR REPLACE FUNCTION insert_field (
  field_id UUID,
  trial_name text,
  site_name text,
  name text,
  water_stress boolean,
  nitrogen_stress boolean,
  bedded integer,
  trial_group trial_group,
  crop text,
  crop_description text,
  previous_crop text,
  previous_crop_description text,
  source_name text) RETURNS void AS $$   
DECLARE
  sid UUID;
  scid UUID;
  fid UUID;
  tid UUID;
  cid UUID;
  pcid UUID;
BEGIN

  if( field_id IS NULL ) Then
    select uuid_generate_v4() into field_id;
  END IF;
  select get_source_id(source_name) into scid;
  select get_site_id(site_name) into sid;
  select get_trial_id(trial_name) into tid;
  select get_crop_id(crop) into cid;

  IF (previous_crop IS NOT NULL) THEN
    select get_crop_id(previous_crop) into pcid;
  END IF;
  
  INSERT INTO field (
    field_id, trial_id, site_id, name, water_stress, nitrogen_stress, bedded,
    trial_group, crop_id, crop_description, previous_crop_id, previous_crop_description, 
    source_id
  ) VALUES (
    field_id, tid, sid, name, water_stress, nitrogen_stress, bedded,
    trial_group, cid, crop_description, pcid, previous_crop_description,
    scid
  );

  INSERT INTO location (
    field_id, plot_id, source_id
  ) VALUES (
    field_id, NULL, scid
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_field (
  field_id_in UUID,
  trial_name_in text, 
  site_name_in text, 
  name_in text, 
  water_stress_in boolean,
  nitrogen_stress_in boolean, 
  bedded_in integer, 
  trial_group_in trial_group, 
  crop_in text, 
  crop_description_in text,
  previous_crop_in text, 
  previous_crop_description_in text) RETURNS void AS $$   
DECLARE
  sid UUID;
  fid UUID;
  tid UUID;
  cid UUID;
  pcid UUID;
BEGIN

  select get_site_id(site_name_in) into sid;
  select get_trial_id(trial_name_in) into tid;
  select get_crop_id(crop_in) into cid;

  IF (previous_crop_in IS NOT NULL) THEN
    select get_crop_id(previous_crop_in) into pcid;
  END IF;

  UPDATE field SET (
    trial_id, site_id, name, water_stress, nitrogen_stress, bedded,
    trial_group, crop_id, crop_description, previous_crop_id, previous_crop_description
  ) = (
    tid, sid, name_in, water_stress_in, nitrogen_stress_in, bedded_in,
    trial_group_in, cid, crop_description_in, pcid, previous_crop_description_in
  ) WHERE
    field_id = field_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_fields (
  field_id_in UUID,
  source_name_in text) RETURNS void AS $$   
DECLARE
  scid UUID;
BEGIN

  IF( source_name_in IS NOT NULL ) THEN
    SELECT get_source_id(source_name_in) into scid;
    DELETE FROM location WHERE source_id = scid;
  END IF;

  IF( field_id_in IS NOT NULL ) THEN
    DELETE FROM field where field_id = field_id_in;
  END IF;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_field_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_field(
    field_id := NEW.field_id,
    trial_name := NEW.trial_name,
    site_name := NEW.site_name,
    name := NEW.name,
    water_stress := NEW.water_stress,
    nitrogen_stress := NEW.nitrogen_stress,
    bedded := NEW.bedded,
    trial_group := NEW.trial_group,
    crop := NEW.crop,
    crop_description := NEW.crop_description,
    previous_crop := NEW.previous_crop,
    previous_crop_description := NEW.previous_crop_description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_field_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_field (
    field_id_in := NEW.field_id,
    trial_name_in := NEW.trial_name,
    site_name_in := NEW.site_name,
    name_in := NEW.name,
    water_stress_in := NEW.water_stress,
    nitrogen_stress_in := NEW.nitrogen_stress,
    bedded_in := NEW.bedded,
    trial_group_in := NEW.trial_group,
    crop_in := NEW.crop,
    crop_description_in := NEW.crop_description,
    previous_crop_in := NEW.previous_crop,
    previous_crop_description_in := NEW.previous_crop_description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_fields_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM delete_fields (
    field_id_in := OLD.field_id,
    source_name_in := OLD.source_name
  );
  RETURN OLD;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;


-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_field_id(trial_name_in text, field_name_in text) RETURNS UUID AS $$   
DECLARE
  fid UUID;
  tid UUID;
BEGIN

  SELECT get_trial_id(trial_name_in) INTO tid;

  SELECT 
    field_id INTO fid 
  FROM
    field
  WHERE 
    name = field_name_in AND
    trial_id = tid;

  IF (fid is NULL) then
    RAISE EXCEPTION 'Unknown field: % %', trial_name_in, field_name_in;
  END IF;

  RETURN fid;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER field_insert_trig
  INSTEAD OF INSERT ON
  field_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_field_from_trig();

CREATE TRIGGER field_update_trig
  INSTEAD OF UPDATE ON
  field_view FOR EACH ROW 
  EXECUTE PROCEDURE update_field_from_trig();

CREATE TRIGGER field_delete_trig
  INSTEAD OF DELETE ON
  field_view FOR EACH ROW 
  EXECUTE PROCEDURE delete_fields_from_trig();