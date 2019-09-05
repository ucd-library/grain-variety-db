-- TABLE
DROP TABLE IF EXISTS fertilization_event CASCADE;
CREATE TABLE fertilization_event (
  fertilization_event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  location_id UUID REFERENCES location NOT NULL,
  growth_stage_min INTEGER,
  growth_stage_max INTEGER,
  date DATE,
  year INTEGER NOT NULL,
  fertilization_type_id UUID REFERENCES fertilization_type NOT NULL,
  amount float NOT NULL,
  description text,
  UNIQUE(location_id, year, growth_stage)
);
CREATE INDEX fertilization_event_source_id_idx ON fertilization_event(source_id);

-- VIEW
CREATE OR REPLACE VIEW fertilization_event_view AS
  SELECT
    f.fertilization_event_id AS fertilization_event_id,
    l.trial_name as trial_name,
    l.site_name as site_name,
    l.field_name as field_name,
    l.plot_number as plot_number,
    f.growth_stage_min as growth_stage_min,
    f.growth_stage_max as growth_stage_max,
    f.year as year,
    f.date as date,
    ft.name as fertilization_name,
    ft.unit as fertilization_unit,
    f.amount as amount,
    f.description as description,
    sc.name AS source_name
  FROM
    fertilization_event f
LEFT JOIN source sc ON f.source_id = sc.source_id
LEFT JOIN location_view l on f.location_id = l.location_id
LEFT JOIN fertilization_type ft on f.fertilization_type_id = ft.fertilization_type_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_fertilization_event (
  fertilization_event_id UUID,
  trial TEXT,
  field TEXT,
  plot_number INTEGER,
  growth_stage_min INTEGER,
  growth_stage_max INTEGER,
  year INTEGER,
  date DATE,
  fertilization_name TEXT,
  fertilization_unit TEXT,
  amount FLOAT,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  lid UUID;
  ftid UUID;
BEGIN

  IF( fertilization_event_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO fertilization_event_id;
  END IF;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_location_id(trial, field, plot_number) INTO lid;
  SELECT get_fertilization_type_id(fertilization_name, fertilization_unit) INTO ftid;

  INSERT INTO fertilization_event (
    fertilization_event_id, location_id, growth_stage_min, growth_stage_max, year, date, fertilization_type_id, amount, description, source_id
  ) VALUES (
    fertilization_event_id, lid, growth_stage_min, growth_stage_max, year, date, ftid, amount, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_fertilization_event (
  fertilization_event_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  growth_stage_min_in INTEGER,
  growth_stage_max_in INTEGER,
  year_in INTEGER,
  date_in DATE,
  fertilization_name_in TEXT,
  fertilization_unit_in TEXT,
  amount_in FLOAT,
  description_in TEXT) RETURNS void AS $$   
DECLARE
  lid UUID;
  ftid UUID;
BEGIN

  IF date_in IS NOT NULL THEN
    select extract(YEAR FROM date_in) into year_in;
  END IF;
  SELECT get_location_id(trial, field, plot_number) INTO lid;
  SELECT get_fertilization_type_id(fertilization_name_in, fertilization_unit_in) INTO ftid;

  UPDATE fertilization_event SET (
    location_id, growth_stage_min, growth_stage_max, year, date, fertilization_type_id, amount, description
  ) = (
    lid, growth_stage_min_in, growth_stage_max_in, year_in, date_in, ftid, amount_in, description_in
  ) WHERE
    fertilization_event_id = fertilization_event_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_fertilization_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_fertilization_event(
    fertilization_event_id := NEW.fertilization_event_id,
    trial := NEW.trial_name,
    field := NEW.field_name,
    plot_number := NEW.plot_number,
    growth_stage_min := NEW.growth_stage_min,
    growth_stage_max := NEW.growth_stage_max,
    year := NEW.year,
    date := NEW.date,
    fertilization_name := NEW.fertilization_name,
    fertilization_unit := NEW.fertilization_unit,
    amount := NEW.amount,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_fertilization_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_fertilization_event(
    fertilization_event_id_in := NEW.fertilization_event_id,
    trial_in := NEW.trial_name,
    field_in := NEW.field_name,
    plot_number_in := NEW.plot_number,
    growth_stage_min_in := NEW.growth_stage_min,
    growth_stage_max_in := NEW.growth_stage_max,
    year_in := NEW.year,
    date_in := NEW.date,
    fertilization_name_in := NEW.fertilization_name,
    fertilization_unit_in := NEW.fertilization_unit,
    amount_in := NEW.amount,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER fertilization_event_insert_trig
  INSTEAD OF INSERT ON
  fertilization_event_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_fertilization_event_from_trig();

CREATE TRIGGER fertilization_event_update_trig
  INSTEAD OF UPDATE ON
  fertilization_event_view FOR EACH ROW 
  EXECUTE PROCEDURE update_fertilization_event_from_trig();