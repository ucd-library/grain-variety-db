-- TABLE
DROP TABLE IF EXISTS note CASCADE;
CREATE TABLE note (
  note_id SERIAL PRIMARY KEY,
  source_id INTEGER REFERENCES source NOT NULL,
  field_location_id INTEGER REFERENCES field_location NOT NULL,
  date DATE NOT NULL,
  growth_stage INTEGER NOT NULL,
  note TEXT NOT NULL
);

-- VIEW
CREATE OR REPLACE VIEW note_view AS 
SELECT 
  fn.note_id as note_id,
  t.name as trial_name,
  s.name as site_name,
  f.name as field_name,
  p.name as plot_name
  fn.date as date,
  fn.growth_stage as growth_stage,
  fn.note as note
FROM
  field_note fn
LEFT JOIN field_location fl ON fl.field_location_id = fn.field_location_id
LEFT JOIN plot p ON p.plot_id = fl.plot_id
LEFT JOIN field f ON f.field_id = fl.field_id
LEFT JOIN site s ON s.site_id = f.site_id
LEFT JOIN trial t ON t.trial_id = s.site_id
LEFT JOIN source sc ON fn.source_id = sc.source_id;

-- FUNCTION INSERT
CREATE OR REPLACE FUNCTION insert_note (
  trial_name text,
  site_name text,
  field_name text,
  plot_name integer,
  date date,
  growth_stage integer,
  note text,
  source_name text) RETURNS void AS $$   
DECLARE
  flid INTEGER;
  scid INTEGER;
BEGIN

  select get_source_id(source_name) into scid;
  select get_field_location_id(trial_name, site_name, field_name, plot_name) into flid;
  
  INSERT INTO note (
    source_id, field_location_id, date, growth_stage, note
  ) VALUES (
    scid, flid, date, growth_stage, not
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;