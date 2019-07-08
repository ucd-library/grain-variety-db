-- TABLE
DROP TABLE IF EXISTS weed_treatment_event CASCADE;
CREATE TABLE weed_treatment_event (
  weed_treatment_event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  location_id UUID REFERENCES location NOT NULL,
  date DATE,
  year INTEGER NOT NULL,
  weed_treatment_type_id UUID REFERENCES weed_treatment_type NOT NULL,
  amount float NOT NULL
);
CREATE INDEX weed_treatment_event_source_id_idx ON weed_treatment_event(source_id);

-- VIEW
CREATE OR REPLACE VIEW weed_treatment_event_view AS
  SELECT
    w.weed_treatment_event_id AS weed_treatment_event_id,
    l.trial as trial,
    l.site as site,
    l.field as field,
    l.plot_number as plot_number,
    w.year as year,
    w.date as date,
    wtt.name as treatment_name,
    wtt.unit as treatment_unit,
    w.amount as amount,
    sc.name AS source_name
  FROM
    weed_treatment_event w
LEFT JOIN source sc ON w.source_id = sc.source_id
LEFT JOIN location_view l on w.location_id = l.location_id
LEFT JOIN weed_treatment_type wtt ON w.weed_treatment_type_id = wtt.weed_treatment_type_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_weed_treatment_event (
  weed_treatment_event_id UUID,
  trial TEXT,
  site TEXT,
  field TEXT,
  plot_number INTEGER,
  year INTEGER,
  date DATE,
  treatment_name TEXT,
  treatment_unit TEXT,
  amount FLOAT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  wttid UUID;
  lid UUID;
BEGIN

  IF( weed_treatment_event_id IS NULL ) THEN
    SELECT uuid_generate_v4() INTO weed_treatment_event_id;
  END IF;
  IF date IS NOT NULL THEN
    select extract(YEAR FROM date) into year;
  END IF;
  SELECT get_source_id(source_name) INTO source_id;
  SELECT get_weed_treatment_type_id(treatment_name, treatment_unit) INTO wttid;
  SELECT get_location_id(trial, field, plot_number) INTO lid;

  INSERT INTO weed_treatment_event (
    weed_treatment_event_id, location_id, year, date, weed_treatment_type_id, amount, source_id
  ) VALUES (
    weed_treatment_event_id, lid, year, date, wttid, amount, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_weed_treatment_event (
  weed_treatment_event_id_in UUID,
  trial_in TEXT,
  site_in TEXT,
  field_in TEXT,
  plot_number_in INTEGER,
  year_in INTEGER,
  date_in DATE,
  treatment_name_in TEXT,
  treatment_unit_in TEXT,
  amount_in FLOAT) RETURNS void AS $$   
DECLARE
  wttid UUID;
  lid UUID;
BEGIN

  IF date_in IS NOT NULL THEN
    select extract(YEAR FROM date_in) into year_in;
  END IF;
  SELECT get_weed_treatment_type_id(treatment_name_in, treatment_unit_in) INTO wttid;
  SELECT get_location_id(trial_in, field_in, plot_number_in) INTO lid;

  UPDATE weed_treatment_event SET (
    location_id, year, date, weed_treatment_type_id, amount 
  ) = (
    lid, year_in, date_in, wttid, amount_in
  ) WHERE
    weed_treatment_event_id = weed_treatment_event_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_weed_treatment_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_weed_treatment_event(
    weed_treatment_event_id := NEW.weed_treatment_event_id,
    trial := NEW.trial,
    site := NEW.site,
    field := NEW.field,
    plot_number := NEW.plot_number,
    year := NEW.year,
    date := NEW.date,
    treatment_name := NEW.treatment_name,
    treatment_unit := NEW.treatment_unit,
    amount := NEW.amount,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_weed_treatment_event_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_weed_treatment_event(
    weed_treatment_event_id_in := NEW.weed_treatment_event_id,
    trial_in := NEW.trial,
    site_in := NEW.site,
    field_in := NEW.field,
    plot_number_in := NEW.plot_number,
    year_in := NEW.year,
    date_in := NEW.date,
    treatment_name_in := NEW.treatment_name,
    treatment_unit_in := NEW.treatment_unit,
    amount_in := NEW.amount
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER weed_treatment_event_insert_trig
  INSTEAD OF INSERT ON
  weed_treatment_event_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_weed_treatment_event_from_trig();

CREATE TRIGGER weed_treatment_event_update_trig
  INSTEAD OF UPDATE ON
  weed_treatment_event_view FOR EACH ROW 
  EXECUTE PROCEDURE update_weed_treatment_event_from_trig();