-- TABLE
DROP TABLE IF EXISTS planting CASCADE;
CREATE TABLE planting (
  planting_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  location_id UUID REFERENCES location NOT NULL,
  date DATE,
  year INTEGER NOT NULL,
  planter TEXT NOT NULL,
  seed_rate TEXT NOT NULL,
  description TEXT
);
CREATE INDEX planting_source_id_idx ON planting(source_id);

-- VIEW
CREATE OR REPLACE VIEW planting_view AS
  SELECT
    p.planting_id AS planting_id,
    l.trial_name as trial_name,
    l.site_name as site_name,
    l.field_name as field_name,
    l.plot_number as plot_number,
    p.year as year,
    p.date as date,
    p.planter as planter,
    p.seed_rate as seed_rate,
    p.description as description,
    sc.name AS source_name
  FROM
    planting p
LEFT JOIN source sc ON p.source_id = sc.source_id
LEFT JOIN location_view l on p.location_id = l.location_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_planting (
  planting_id UUID,
  trial TEXT,
  field TEXT,
  plot_number INTEGER,
  year INTEGER,
  date DATE,
  planter TEXT,
  seed_rate INTEGER,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  lid UUID;
BEGIN

  IF( planting_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO planting_id;
  END IF;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_location_id(trial, field, plot_number) INTO lid;

  INSERT INTO planting (
    planting_id, location_id, year, date, planter, seed_rate, description, source_id
  ) VALUES (
    planting_id, lid, year, date, planter, seed_rate, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_planting (
  planting_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  year_in INTEGER,
  date_in DATE,
  planter_in TEXT,
  seed_rate_in INTEGER,
  description_in TEXT) RETURNS void AS $$   
DECLARE
  lid UUID;
BEGIN

  IF date_in IS NOT NULL THEN
    select extract(YEAR FROM date_in) into year_in;
  END IF;
  SELECT get_location_id(trial_in, field_in, plot_number_in) INTO lid;

  UPDATE planting SET (
    location_id, year, date, planter, seed_rate, description
  ) = (
    lid, year_in, date_in, planter_in, seed_rate_in, description_in
  ) WHERE
    planting_id = planting_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_planting_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_planting(
    planting_id := NEW.planting_id,
    trial := NEW.trial_name,
    field := NEW.field_name,
    plot_number := NEW.plot_number,
    year := NEW.year,
    date := NEW.date,
    planter := NEW.planter,
    seed_rate := NEW.seed_rate,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_planting_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_planting(
    planting_id_in := NEW.planting_id,
    trial_in := NEW.trial_name,
    field_in := NEW.field_name,
    plot_number_in := NEW.plot_number,
    year_in := NEW.year,
    date_in := NEW.date,
    planter_in := NEW.planter,
    seed_rate_in := NEW.seed_rate,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER planting_insert_trig
  INSTEAD OF INSERT ON
  planting_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_planting_from_trig();

CREATE TRIGGER planting_update_trig
  INSTEAD OF UPDATE ON
  planting_view FOR EACH ROW 
  EXECUTE PROCEDURE update_planting_from_trig();