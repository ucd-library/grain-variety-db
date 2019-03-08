-- TABLE
DROP TABLE IF EXISTS measurement_event CASCADE;
CREATE TABLE measurement_event (
  measurement_event_id SERIAL PRIMARY KEY,
  field_id INTEGER REFERENCES field NOT NULL,
  year INTEGER NOT NULL,
  date DATE,
  season season NOT NULL,
  growth_stage growth_stage NOT NULL,
  UNIQUE(field_id, year, season, growth_stage)
);

-- VIEW
CREATE OR REPLACE VIEW measurement_event_view AS 
SELECT 
  f.name as field_name,
  me.year as year,
  me.date as date,
  me.season as season,
  me.growth_state as growth_stage
FROM
  measurement_event me,
  field f
WHERE
  me.field_id = f.field_id;

-- INSERT
CREATE OR REPLACE FUNCTION insert_measurement_event (
  field_name text,
  year integer,
  date date,
  season season,
  growth_stage growth_stage) RETURNS void AS $$   
DECLARE
  fid INTEGER;
BEGIN

  select get_field_id(field_name) into fid;
  
  IF date IS NOT null THEN
    select extract(YEAR FROM date) into year;
  END IF;

  INSERT INTO measurement_event (
    field_id, year, date, season, growth_stage
  ) VALUES (
    fid, year, date, season, growth_stage
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_measurement_event_id(field_name_in text, year_in integer, season_in season, growth_stage_in growth_state) RETURNS INTEGER AS $$   
DECLARE
  meid integer;
  fid integer;
BEGIN

  select get_field_id(field_name_in) into fid; 

  select 
    measurement_event_id into meid 
  from  
    measurement_event
  where 
    field_id = fid AND
    year = year_in AND
    seson = season_in AND
    growth_stage = growth_state_in;


  IF (meid is NULL) then
    RAISE EXCEPTION 'Unknown measurement event: % % % %', field_name_in, year_in, season_in, growth_stage_in;
  END IF;

  RETURN fid;
END; 
$$ LANGUAGE plpgsql;