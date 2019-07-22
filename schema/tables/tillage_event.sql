-- TABLE
DROP TABLE IF EXISTS tillage_event CASCADE;
CREATE TABLE tillage_event (
  tillage_event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  location_id UUID REFERENCES location NOT NULL,
  date DATE,
  year INTEGER NOT NULL,
  description TEXT
);
CREATE INDEX tillage_event_source_id_idx ON tillage_event(source_id);

-- VIEW
CREATE OR REPLACE VIEW tillage_event_view AS
  SELECT
    t.tillage_event_id AS tillage_event_id,
    l.trial_name as trial_name,
    l.site_name as site_name,
    l.field_name as field_name,
    l.plot_number as plot_number,
    t.year as year,
    t.date as date,
    t.description as description,
    sc.name AS source_name
  FROM
    tillage_event t
LEFT JOIN source sc ON t.source_id = sc.source_id
LEFT JOIN location_view l on t.location_id = l.location_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_tillage_event (
  tillage_event_id UUID,
  trial TEXT,
  field TEXT,
  plot_number INTEGER,
  year INTEGER,
  date DATE,
  description TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  lid UUID;
BEGIN

  IF( tillage_event_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO tillage_event_id;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_location_id(trial, field, plot_number) INTO lid;

  INSERT INTO tillage_event (
    tillage_event_id, location_id, year, date, description, source_id
  ) VALUES (
    tillage_event_id, lid, year, date, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_tillage_event (
  tillage_event_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  year_in INTEGER,
  date_in DATE,
  description_in TEXT) RETURNS void AS $$   
DECLARE
  lid UUID;
BEGIN

  SELECT get_location_id(trial_in, field_in, plot_number_in) INTO lid;

  UPDATE tillage_event SET (
    location_id, year, date, description
  ) = (
    lid, year_in, date_in, description_in
  ) WHERE
    tillage_event_id = tillage_event_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_tillage_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_tillage_event(
    tillage_event_id := NEW.tillage_event_id,
    trial := NEW.trial_name,
    field := NEW.field_name,
    plot_number := NEW.plot_number,
    year := NEW.year,
    date := NEW.date,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_tillage_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_tillage_event(
    tillage_event_id_in := NEW.tillage_event_id,
    trial_in := NEW.trial_name,
    field_in := NEW.field_name,
    plot_number_in := NEW.plot_number,
    year_in := NEW.year,
    date_in := NEW.date,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER tillage_event_insert_trig
  INSTEAD OF INSERT ON
  tillage_event_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_tillage_event_from_trig();

CREATE TRIGGER tillage_event_update_trig
  INSTEAD OF UPDATE ON
  tillage_event_view FOR EACH ROW 
  EXECUTE PROCEDURE update_tillage_event_from_trig();