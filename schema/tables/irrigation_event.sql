-- TABLE
DROP TABLE IF EXISTS irrigation_event CASCADE;
CREATE TABLE irrigation_event (
  irrigation_event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  location_id UUID REFERENCES location NOT NULL,
  growth_stage_min INTEGER,
  growth_stage_max INTEGER,
  date DATE,
  year INTEGER NOT NULL,
  irrigation_method_id UUID REFERENCES irrigation_method NOT NULL,
  amount FLOAT NOT NULL,
  description TEXT,
  UNIQUE(location_id, year, growth_stage)
);
CREATE INDEX irrigation_event_source_id_idx ON irrigation_event(source_id);

-- VIEW
CREATE OR REPLACE VIEW irrigation_event_view AS
  SELECT
    i.irrigation_event_id AS irrigation_event_id,
    l.trial_name as trial_name,
    l.site_name as site_name,
    l.field_name as field_name,
    l.plot_number as plot_number,
    i.growth_stage_min as growth_stage_min,
    i.growth_stage_max as growth_stage_max,
    i.year as year,
    i.date as date,
    im.name as irrigation_name,
    im.unit as irrigation_unit,
    i.amount as amount,
    i.description as description,
    sc.name AS source_name
  FROM
    irrigation_event i
LEFT JOIN source sc ON i.source_id = sc.source_id
LEFT JOIN location_view l ON i.location_id = l.location_id
LEFT JOIN irrigation_method im on i.irrigation_method_id = im.irrigation_method_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_irrigation_event (
  irrigation_event_id UUID,
  trial TEXT,
  field TEXT,
  plot_number INTEGER,
  growth_stage_min INTEGER,
  growth_stage_max INTEGER,
  year INTEGER,
  date DATE,
  irrigation_name TEXT,
  irrigation_unit TEXT,
  amount FLOAT,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  lid UUID;
  imid UUID;
BEGIN

  IF( irrigation_event_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO irrigation_event_id;
  END IF;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_fertilization_method_id(irrigation_name, irrigation_unit) INTO imid;

  INSERT INTO irrigation_event (
    irrigation_event_id, location_id, growth_stage_min, growth_stage_max, year, date, irrigation_method_id, amount, description, source_id
  ) VALUES (
    irrigation_event_id, lid, growth_stage_min, growth_stage_max, year, date, imid, amount, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_irrigation_event (
  irrigation_event_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  growth_stage_min_in INTEGER,
  growth_stage_max_in INTEGER,
  year_in INTEGER,
  date_in DATE,
  irrigation_name_in TEXT,
  irrigation_unit_in TEXT,
  amount_in FLOAT,
  description_in TEXT) RETURNS void AS $$   
DECLARE
  lid UUID;
  imid UUID;
BEGIN

  IF date_in IS NOT NULL THEN
    select extract(YEAR FROM date_in) into year_in;
  END IF;
  SELECT get_fertilization_method_id(irrigation_name, irrigation_unit) INTO imid;

  UPDATE irrigation_event SET (
    location_id, growth_stage_min, growth_stage_max, year, date, irrigation_method_id, amount, description
  ) = (
    lid, growth_stage_min_in, growth_stage_max_in, year_in, date_in, imid, amount_in, description_in
  ) WHERE
    irrigation_event_id = irrigation_event_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_irrigation_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_irrigation_event(
    irrigation_event_id := NEW.irrigation_event_id,
    trial := NEW.trial_name,
    field := NEW.field_name,
    plot_number := NEW.plot_number,
    growth_stage_min := NEW.growth_stage_min,
    growth_stage_max := NEW.growth_stage_max,
    year := NEW.year,
    date := NEW.date,
    irrigation_name := NEW.irrigation_name,
    irrigation_unit := NEW.irrigation_unit,
    amount := NEW.amount,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_irrigation_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_irrigation_event(
    irrigation_event_id_in := NEW.irrigation_event_id,
    trial_in := NEW.trial_name,
    field_in := NEW.field_name,
    plot_number_in := NEW.plot_number,
    growth_stage_min_in := NEW.growth_stage_min,
    growth_stage_max_in := NEW.growth_stage_max,
    year_in := NEW.year,
    date_in := NEW.date,
    irrigation_name_in := NEW.irrigation_name,
    irrigation_unit_in := NEW.irrigation_unit,
    amount_in := NEW.amount,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER irrigation_event_insert_trig
  INSTEAD OF INSERT ON
  irrigation_event_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_irrigation_event_from_trig();

CREATE TRIGGER irrigation_event_update_trig
  INSTEAD OF UPDATE ON
  irrigation_event_view FOR EACH ROW 
  EXECUTE PROCEDURE update_irrigation_event_from_trig();