-- TABLE
DROP TABLE IF EXISTS crop_sampling_event CASCADE;
CREATE TABLE crop_sampling_event (
  crop_sampling_event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  location_id UUID REFERENCES location NOT NULL,
  year INTEGER NOT NULL,
  date DATE,
  growth_stage INTEGER,
  UNIQUE(location_id, year, growth_stage)
);
CREATE INDEX crop_sampling_event_source_id_idx ON crop_sampling_event(source_id);
CREATE INDEX crop_sampling_event_location_id_idx ON crop_sampling_event(location_id);

-- VIEW
CREATE OR REPLACE VIEW crop_sampling_event_view AS
  SELECT
    c.crop_sampling_event_id AS crop_sampling_event_id,
    l.trial_name as trial_name,
    l.site_name as site_name,
    l.season as season,
    l.field_name as field_name,
    l.plot_number as plot_number,
    l.crop as crop,
    c.year as year,
    c.date as date,
    c.growth_stage as growth_stage,
    sc.name AS source_name
  FROM
    crop_sampling_event c
LEFT JOIN source sc ON c.source_id = sc.source_id
LEFT JOIN location_view l on c.location_id = l.location_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_crop_sampling_event (
  crop_sampling_event_id UUID,
  trial TEXT,
  field TEXT,
  plot_number INTEGER,
  year INTEGER,
  date DATE,
  growth_stage INTEGER,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  lid UUID;
BEGIN

  IF( crop_sampling_event_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO crop_sampling_event_id;
  END IF;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_location_id(trial, field, plot_number) INTO lid;

  INSERT INTO crop_sampling_event (
    crop_sampling_event_id, location_id, year, date, growth_stage, source_id
  ) VALUES (
    crop_sampling_event_id, lid, year, date, growth_stage, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_sampling_event (
  crop_sampling_event_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  year_in INTEGER,
  date_in DATE,
  growth_stage_in INTEGER) RETURNS void AS $$   
DECLARE
  lid UUID;
BEGIN

  SELECT get_location_id(trial_in, field_in, plot_number_in) INTO lid;
  IF date_in IS NOT NULL THEN
    select extract(YEAR FROM date_in) into year_in;
  END IF;

  UPDATE crop_sampling_event SET (
    location_id, year, date, growth_stage
  ) = (
    lid, year_in, date_in, growth_stage_in
  ) WHERE
    crop_sampling_event_id = crop_sampling_event_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_crop_sampling_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_crop_sampling_event(
    crop_sampling_event_id := NEW.crop_sampling_event_id,
    trial := NEW.trial_name,
    field := NEW.field_name,
    plot_number := NEW.plot_number,
    year := NEW.year,
    date := NEW.date,
    growth_stage := NEW.growth_stage,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_crop_sampling_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_crop_sampling_event(
    crop_sampling_event_id_in := NEW.crop_sampling_event_id,
    trial_in := NEW.trial_name,
    field_in := NEW.field_name,
    plot_number_in := NEW.plot_number,
    year_in := NEW.year,
    date_in := NEW.date,
    growth_stage_in := NEW.growth_stage
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_crop_sampling_event_id(trial_name_in text, field_name_in text, plot_number_in integer, year_in integer, growth_stage_in integer) RETURNS UUID AS $$   
DECLARE
  cid UUID;
  lid UUID;
BEGIN

  SELECT get_location_id(trial_name_in, field_name_in, plot_number_in) INTO lid; 

  IF growth_stage_in IS NULL THEN
    SELECT 
      crop_sampling_event_id INTO cid 
    FROM 
      crop_sampling_event c 
    WHERE
      lid = location_id AND
      year_in = year AND
      growth_stage IS NULL;
  ELSE
    SELECT 
      crop_sampling_event_id INTO cid 
    FROM 
      crop_sampling_event c 
    WHERE
      lid = location_id AND
      year_in = year AND
      growth_stage_in = growth_stage;
  END IF;


  IF (cid IS NULL) THEN
    RAISE EXCEPTION 'Unknown crop_sampling_event: trial %, field %, plot_number %, year %, growth_stage %', trial_name_in, field_name_in, plot_number_in, year_in, growth_stage_in;
  END IF;
  
  RETURN cid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER crop_sampling_event_insert_trig
  INSTEAD OF INSERT ON
  crop_sampling_event_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_crop_sampling_event_from_trig();

CREATE TRIGGER crop_sampling_event_update_trig
  INSTEAD OF UPDATE ON
  crop_sampling_event_view FOR EACH ROW 
  EXECUTE PROCEDURE update_crop_sampling_event_from_trig();