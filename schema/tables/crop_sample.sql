-- TABLE
DROP TABLE IF EXISTS crop_sample CASCADE;
CREATE TABLE crop_sample (
  crop_sample_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  crop_sampling_event_id UUID REFERENCES crop_sampling_event NOT NULL,
  crop_part_measurement_id UUID REFERENCES crop_part_measurement NOT NULL,
  amount float NOT NULL,
  description text
);
CREATE INDEX crop_sample_source_id_idx ON crop_sample(source_id);
CREATE INDEX crop_sample_crop_sampling_event_id_idx ON crop_sample(crop_sampling_event_id);
CREATE INDEX crop_sample_crop_part_measurement_id_idx ON crop_sample(crop_part_measurement_id);

-- VIEW
CREATE OR REPLACE VIEW crop_sample_view AS
  SELECT
    c.crop_sample_id AS crop_sample_id,
    cse.trial as trial,
    cse.site as site,
    cse.field as field,
    cse.plot_number as plot_number,
    cse.crop as crop,
    cpm.plant_part as plant_part,
    cse.year as year,
    cse.date as date,
    cse.growth_stage as growth_stage,
    cpm.measurement_name as measurement_name,
    cpm.measurement_device as measurement_device,
    cpm.measurement_unit as measurement_unit,
    c.amount as amount,
    c.description as description,
    sc.name AS source_name
  FROM
    crop_sample c
LEFT JOIN source sc ON c.source_id = sc.source_id
LEFT JOIN crop_sampling_event_view cse on c.crop_sampling_event_id = cse.crop_sampling_event_id
LEFT JOIN crop_part_measurement_view cpm on c.crop_part_measurement_id = cpm.crop_part_measurement_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_crop_sample (
  crop_sample_id UUID,
  trial TEXT,
  field TEXT,
  plot_number INTEGER,
  crop TEXT,
  plant_part TEXT,
  year INTEGER,
  date DATE,
  growth_stage INTEGER,
  measurement_name TEXT,
  measurement_device TEXT,
  measurement_unit TEXT,
  amount FLOAT,
  description text,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  cid UUID;
  source_id UUID;
  cseid UUID;
  cpmid UUID;
BEGIN

  IF( crop_sample_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO crop_sample_id;
  END IF;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_crop_sampling_event_id(trial, field, plot_number_in, year, growth_stage_in) into cseid;
  SELECT get_crop_part_measurement_id(crop, plant_part, measurement_name, measurement_device, measurement_unit) into cpmid;

  INSERT INTO crop_sample (
    crop_sample_id, crop_sampling_event_id, crop_part_measurement_id, amount, description, source_id
  ) VALUES (
    crop_sample_id, cseid, cpmid, amount, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_sample (
  crop_sample_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_in TEXT,
  crop_in TEXT,
  plant_part_in TEXT,
  year_in INTEGER,
  date_in DATE,
  growth_stage_in INTEGER,
  measurement_name_in TEXT,
  measurement_device_in TEXT,
  measurement_unit_in TEXT,
  amount_in FLOAT,
  description_in TEXT) RETURNS void AS $$   
DECLARE
  cseid UUID;
  cpmid UUID;
BEGIN

  IF date_in IS NOT NULL THEN
    select extract(YEAR FROM date_in) into year_in;
  END IF;
  SELECT get_crop_sampling_event_id(trial, field, plot_number_in, year, growth_stage_in) into cseid;
  SELECT get_crop_part_measurement_id(crop, plant_part, measurement_name, measurement_device, measurement_unit) into cpmid;

  UPDATE crop_sample SET (
    crop_sampling_event_id, crop_part_measurement_id, amount, description
  ) = (
    cseid, cpmid, amount_in, description_in
  ) WHERE
    crop_sample_id = crop_sample_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_crop_sample_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_crop_sample(
    crop_sample_id := NEW.crop_sample_id,
    trial := NEW.trial,
    field := NEW.field,
    plot := NEW.plot,
    crop := NEW.crop,
    plant_part := NEW.plant_part,
    year := NEW.year,
    date := NEW.date,
    growth_stage := NEW.growth_stage,
    measurement_name := NEW.measurement_name,
    measurement_device := NEW.measurement_device,
    measurement_unit := NEW.measurement_unit,
    amount := NEW.amount,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_sample_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_crop_sample(
    crop_sample_id_in := NEW.crop_sample_id,
    trial_in := NEW.trial,
    field_in := NEW.field,
    plot_in := NEW.plot,
    crop_in := NEW.crop,
    plant_part_in := NEW.plant_part,
    year_in := NEW.year,
    date_in := NEW.date,
    growth_stage_in := NEW.growth_stage,
    measurement_name_in := NEW.measurement_name,
    measurement_device_in := NEW.measurement_device,
    measurement_unit_in := NEW.measurement_unit,
    amount_in := NEW.amount,
    description := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER crop_sample_insert_trig
  INSTEAD OF INSERT ON
  crop_sample_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_crop_sample_from_trig();

CREATE TRIGGER crop_sample_update_trig
  INSTEAD OF UPDATE ON
  crop_sample_view FOR EACH ROW 
  EXECUTE PROCEDURE update_crop_sample_from_trig();