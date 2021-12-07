-- TABLE
DROP TABLE IF EXISTS crop_sample CASCADE;
CREATE TABLE crop_sample (
  crop_sample_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  crop_part_measurement_id UUID REFERENCES crop_part_measurement NOT NULL,
  location_id UUID REFERENCES location,
  date DATE,
  year INTEGER,
  growth_stage_min INTEGER,
  growth_stage_max INTEGER,
  amount float NOT NULL,
  description text,
  UNIQUE(crop_part_measurement_id, location_id, date, year)
);
CREATE INDEX crop_sample_source_id_idx ON crop_sample(source_id);
CREATE INDEX location_id_idx ON crop_sample(location_id);
CREATE INDEX crop_sample_crop_part_measurement_id_idx ON crop_sample(crop_part_measurement_id);

-- VIEW
CREATE OR REPLACE VIEW crop_sample_view AS
  SELECT
    c.crop_sample_id AS crop_sample_id,
    l.trial_name as trial_name,
    l.site_name as site_name,
    l.season as season,
    l.field_name as field_name,
    l.plot_number as plot_number,
    cpm.crop as crop,
    cpm.plant_part as plant_part,
    c.year as year,
    c.date as date,
    c.growth_stage_min as growth_stage_min,
    c.growth_stage_max as growth_stage_max,
    cpm.measurement_name as measurement_name,
    cpm.measurement_device as measurement_device,
    cpm.measurement_unit as measurement_unit,
    c.amount as amount,
    c.description as description,
    sc.name AS source_name
  FROM
    crop_sample c
LEFT JOIN source sc ON c.source_id = sc.source_id
LEFT JOIN location_view l ON c.location_id = l.location_id
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
  growth_stage_min INTEGER,
  growth_stage_max INTEGER,
  measurement_name TEXT,
  measurement_device TEXT,
  measurement_unit TEXT,
  amount FLOAT,
  description text,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  cid UUID;
  source_id UUID;
  lid UUID;
  cpmid UUID;
BEGIN

  IF( crop_sample_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO crop_sample_id;
  END IF;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_location_id(trial, field, plot_number) INTO lid;
  SELECT get_crop_part_measurement_id(crop, plant_part, measurement_name, measurement_device, measurement_unit) into cpmid;

  INSERT INTO crop_sample (
    crop_sample_id, location_id, crop_part_measurement_id, year, date, growth_stage_min, growth_stage_max,
    amount, description, source_id
  ) VALUES (
    crop_sample_id, lid, cpmid, year, date, growth_stage_min, growth_stage_max,
    amount, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_sample (
  crop_sample_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  crop_in TEXT,
  plant_part_in TEXT,
  year_in INTEGER,
  date_in DATE,
  growth_stage_min_in INTEGER,
  growth_stage_max_in INTEGER,
  measurement_name_in TEXT,
  measurement_device_in TEXT,
  measurement_unit_in TEXT,
  amount_in FLOAT,
  description_in TEXT) RETURNS void AS $$   
DECLARE
  lid UUID;
  cpmid UUID;
BEGIN

  IF date_in IS NOT NULL THEN
    select extract(YEAR FROM date_in) into year_in;
  END IF;
  SELECT get_location_id(trial_in, field_in, plot_number_in) INTO lid;
  SELECT get_crop_part_measurement_id(crop_in, plant_part_in, measurement_name_in, measurement_device_in, measurement_unit_in) into cpmid;

  UPDATE crop_sample SET (
    location_id, crop_part_measurement_id, year, date, growth_stage_min, growth_stage_max,
    amount, description
  ) = (
    lid, cpmid, year_in, date_in, growth_stage_min_in, growth_stage_max_in,
    amount_in, description_in
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
    trial := NEW.trial_name,
    field := NEW.field_name,
    plot_number := NEW.plot_number,
    crop := NEW.crop,
    plant_part := NEW.plant_part,
    year := NEW.year,
    date := NEW.date,
    growth_stage_min := NEW.growth_stage_min,
    growth_stage_max := NEW.growth_stage_max,
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
    trial_in := NEW.trial_name,
    field_in := NEW.field_name,
    plot_number_in := NEW.plot_number,
    crop_in := NEW.crop,
    plant_part_in := NEW.plant_part,
    year_in := NEW.year,
    date_in := NEW.date,
    growth_stage_min_in := NEW.growth_stage_min,
    growth_stage_max_in := NEW.growth_stage_max,
    measurement_name_in := NEW.measurement_name,
    measurement_device_in := NEW.measurement_device,
    measurement_unit_in := NEW.measurement_unit,
    amount_in := NEW.amount,
    description_in := NEW.description
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