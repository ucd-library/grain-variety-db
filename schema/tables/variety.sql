-- TYPE
DROP TYPE if EXISTS trial_group CASCADE;
CREATE TYPE trial_group AS ENUM ('BARLEY', 'DURUM', 'WHEAT', 'COMMON');

DROP TYPE if EXISTS crop_type CASCADE;
CREATE TYPE crop_type AS ENUM ('BARLEY', 'DURUM', 'WHEAT', 'COMMON', 'SPRINGWHEAT', 'TRITICALE');

DROP TYPE if EXISTS crop_classification CASCADE;
CREATE TYPE crop_classification AS ENUM ('6RSF(H)', 'DURUM', 'SRS', 'HRS', 
'TRITICALE', 'SWW', 'HRW', '2R2M', '2RSF(H)', '6RSF');

-- wrong 
DROP TYPE if EXISTS variety_release_status CASCADE;
CREATE TYPE variety_release_status AS ENUM ('IR', 'NonIR');

-- TABLE
DROP TABLE IF EXISTS variety CASCADE;
CREATE TABLE variety (
  variety_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  trial_group trial_group NOT NULL,
  crop_type crop_type NOT NULL,
  crop_classification crop_classification,
  source TEXT,
  variety_release_status variety_release_status
);

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_variety_id_by_uc(uc_entry_number_in text) RETURNS INTEGER AS $$   
DECLARE
  vid integer;
BEGIN

  select variety_id into vid from variety where uc_entry_number = uc_entry_number_in;

  IF (vid is NULL) then
    RAISE EXCEPTION 'Unknown variety uc_entry_number: %', uc_entry_number_in;
  END IF;

  RETURN vid;
END; 
$$ LANGUAGE plpgsql;