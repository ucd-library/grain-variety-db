-- TABLE
DROP TABLE IF EXISTS soil_sample CASCADE;
CREATE TABLE soil_sample (
  soil_sample_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  measurement_id UUID REFERENCES measurement NOT NULL,
  amount float NOT NULL,
  location_id UUID REFERENCES location,
  date DATE,
  year INTEGER,
  growth_stage_min INTEGER,
  growth_stage_max INTEGER,
  start_depth float NOT NULL,
  end_depth float NOT NULL,
  description text
);
CREATE INDEX soil_sample_source_id_idx ON soil_sample(source_id);
CREATE INDEX location_id_idx ON soil_sample(location_id);
CREATE INDEX soil_sample_measurement_id_idx ON soil_sample(measurement_id);

-- VIEW
CREATE OR REPLACE VIEW soil_sample_view AS
  SELECT
    s.soil_sample_id AS soil_sample_id,
    l.trial_name as trial_name,
    l.site_name as site_name,
    l.field_name as field_name,
    l.plot_number as plot_number,
    s.year as year,
    s.date as date,
    s.growth_stage_min as growth_stage_min,
    s.growth_stage_max as growth_stage_max,
    m.name as measurement_name,
    m.device as measurement_device,
    m.unit as measurement_unit,
    s.amount as amount,
    s.start_depth as start_depth,
    s.end_depth as end_depth,
    s.description as description,
    sc.name AS source_name
  FROM
    soil_sample s
LEFT JOIN source sc ON s.source_id = sc.source_id
LEFT JOIN location_view l ON s.location_id = l.location_id
LEFT JOIN measurement_view m on s.measurement_id = m.measurement_id;


-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_soil_sample (
  soil_sample_id UUID,
  trial TEXT,
  field TEXT,
  plot_number INTEGER,
  year INTEGER,
  date DATE,
  growth_stage_min INTEGER,
  growth_stage_max INTEGER,
  measurement_name TEXT,
  measurement_device TEXT,
  measurement_unit TEXT,
  amount FLOAT,
  start_depth FLOAT,
  end_depth FLOAT,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  mid UUID;
  lid UUID;
BEGIN

  IF( soil_sample_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO soil_sample_id;
  END IF;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_location_id(trial, field, plot_number) INTO lid;
  SELECT get_measurement_id(measurement_name, measurement_device, measurement_unit) into mid;

  INSERT INTO soil_sample (
    soil_sample_id, location_id, measurement_id, year, date, growth_stage_min, growth_stage_max,
    amount, start_depth, end_depth, description, source_id
  ) VALUES (
    soil_sample_id, lid, mid, year, date, growth_stage_min, growth_stage_max,
    amount, start_depth, end_depth, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_soil_sample (
  soil_sample_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  year_in INTEGER,
  date_in DATE,
  growth_stage_min_in INTEGER,
  growth_stage_max_in INTEGER,
  measurement_name_in TEXT,
  measurement_device_in TEXT,
  measurement_unit_in TEXT,
  amount_in FLOAT,
  start_depth_in FLOAT,
  end_depth_in FLOAT,
  description_in TEXT) RETURNS void AS $$   
DECLARE
  sseid UUID;
  mid UUID;
  lid UUID;
BEGIN

  SELECT get_location_id(trial_in, field_in, plot_number_in) INTO lid;
  SELECT get_measurement_id(measurement_name_in, measurement_device_in, measurement_unit_in) into mid;

  UPDATE soil_sample SET (
    location_id, measurement_id, year, date, growth_stage_min, growth_stage_max,
    amount, start_depth, end_depth, description
  ) = (
    lid, mid, year_in, date_in, growth_stage_min_in, growth_stage_max_in,
    amount_in, start_depth_in, end_depth_in, description_in
  ) WHERE
    soil_sample_id = soil_sample_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_soil_sample_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_soil_sample(
    soil_sample_id := NEW.soil_sample_id,
    trial := NEW.trial_name,
    field := NEW.field_name,
    plot_number := NEW.plot_number,
    year := NEW.year,
    date := NEW.date,
    growth_stage_min := NEW.growth_stage_min,
    growth_stage_max := NEW.growth_stage_max,
    measurement_name := NEW.measurement_name,
    measurement_device := NEW.measurement_device,
    measurement_unit := NEW.measurement_unit,
    amount := NEW.amount,
    start_depth := NEW.start_depth,
    end_depth := NEW.end_depth,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_soil_sample_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_soil_sample(
    soil_sample_id_in := NEW.soil_sample_id,
    trial_in := NEW.trial_name,
    field_in := NEW.field_name,
    plot_number_in := NEW.plot_number,
    year_in := NEW.year,
    date_in := NEW.date,
    growth_stage_min_in := NEW.growth_stage_min,
    growth_stage_max_in := NEW.growth_stage_max,
    measurement_name_in := NEW.measurement_name,
    measurement_device_in := NEW.measurement_device,
    measurement_unit_in := NEW.measurement_unit,
    amount_in := NEW.amount,
    start_depth_in := NEW.start_depth,
    end_depth_in := NEW.end_depth,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;


-- RULES
CREATE TRIGGER soil_sample_insert_trig
  INSTEAD OF INSERT ON
  soil_sample_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_soil_sample_from_trig();

CREATE TRIGGER soil_sample_update_trig
  INSTEAD OF UPDATE ON
  soil_sample_view FOR EACH ROW 
  EXECUTE PROCEDURE update_soil_sample_from_trig();