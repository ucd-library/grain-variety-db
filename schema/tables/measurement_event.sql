-- TABLE
DROP TABLE IF EXISTS variety_sampling_event CASCADE;
CREATE TABLE variety_sampling_event (
  variety_sampling_event_id SERIAL PRIMARY KEY,
  year INTEGER NOT NULL,
  date DATE,
  season season NOT NULL,
  growth_stage growth_stage NOT NULL,
  UNIQUE(field_id, year, season, growth_stage)
);

-- VIEW
-- CREATE OR REPLACE VIEW variety_sampling_event_view AS 
-- SELECT 
--   me.year as year,
--   me.date as date,
--   me.season as season,
--   me.growth_state as growth_stage
-- FROM
--   variety_sampling_event me,
--   field f
-- WHERE
--   me.field_id = f.field_id;

-- INSERT
CREATE OR REPLACE FUNCTION insert_variety_sampling_event (
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

  INSERT INTO variety_sampling_event (
    field_id, year, date, season, growth_stage
  ) VALUES (
    fid, year, date, season, growth_stage
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_variety_sampling_event_id(field_name_in text, year_in integer, season_in season, growth_stage_in growth_state) RETURNS INTEGER AS $$   
DECLARE
  meid integer;
  fid integer;
BEGIN

  select get_field_id(field_name_in) into fid; 

  select 
    variety_sampling_event_id into meid 
  from  
    variety_sampling_event
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