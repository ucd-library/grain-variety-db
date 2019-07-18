-- TABLE
DROP TABLE IF EXISTS note CASCADE;
CREATE TABLE note (
  note_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  trial_id UUID REFERENCES trial NOT NULL,
  location_id UUID REFERENCES location,
  growth_stage INTEGER,
  date DATE,
  year INTEGER,
  note TEXT NOT NULL
);
CREATE INDEX note_source_id_idx ON note(source_id);

-- VIEW
CREATE OR REPLACE VIEW note_view AS
  SELECT
    n.note_id AS note_id,
    t.name as trial,
    l.site as site,
    l.field as field,
    l.plot_number as plot_number,
    n.growth_stage as growth_stage,
    n.date as date,
    n.year as year,
    n.note as note,
    sc.name AS source_name
  FROM
    note n
LEFT JOIN source sc ON n.source_id = sc.source_id
LEFT JOIN trial t ON n.trial_id = t.trial_id
LEFT JOIN location_view l ON n.location_id = l.location_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_note (
  note_id UUID,
  trial TEXT,
  field TEXT,
  plot_number INTEGER,
  growth_stage INTEGER,
  date DATE,
  year INTEGER,
  note TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  lid UUID;
  tid UUID;
BEGIN

  IF( note_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO note_id;
  END IF;
  SELECT get_trial_id(trial) INTO tid;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  IF field IS NOT NULL THEN
    SELECT get_location_id(trial, field, plot_number) INTO lid;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;

  INSERT INTO note (
    note_id, trial_id, location_id, growth_stage, date, year, note, source_id
  ) VALUES (
    note_id, tid, lid, growth_stage, date, year, note, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_note (
  note_id_in UUID,
  trial_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  growth_stage_in INTEGER,
  date_in DATE,
  year_in INTEGER,
  note_in TEXT) RETURNS void AS $$   
DECLARE
  lid UUID;
  tid UUID;
BEGIN

  IF date_in IS NOT NULL THEN
    select extract(YEAR FROM date_in) into year_in;
  END IF;
  SELECT get_trial_id(trial_in) INTO tid;
  IF field IS NOT NULL THEN
    SELECT get_location_id(trial_in, field_in, plot_number_in) INTO lid;
  END IF;

  UPDATE note SET (
    trial_id, location_id, growth_stage, date, year, note
  ) = (
    tid, lid, growth_stage_in, date_in, year_in, note_in
  ) WHERE
    note_id = note_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_note_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_note(
    note_id := NEW.note_id,
    trial := NEW.trial,
    field := NEW.field,
    plot_number := NEW.plot_number,
    growth_stage := NEW.growth_stage,
    date := NEW.date,
    year := NEW.year,
    note := NEW.note,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_note_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_note(
    note_id_in := NEW.note_id,
    trial_in := NEW.trial,
    field_in := NEW.field,
    plot_number_in := NEW.plot_number,
    growth_stage_in := NEW.growth_stage,
    date_in := NEW.date,
    year_in := NEW.year,
    note_in := NEW.note
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER note_insert_trig
  INSTEAD OF INSERT ON
  note_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_note_from_trig();

CREATE TRIGGER note_update_trig
  INSTEAD OF UPDATE ON
  note_view FOR EACH ROW 
  EXECUTE PROCEDURE update_note_from_trig();