-- TABLE
DROP TABLE IF EXISTS trial CASCADE;
CREATE TABLE trial (
  trial_id SERIAL PRIMARY KEY,
  name text NOT NULL
);

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_trial_id(name_in text) RETURNS INTEGER AS $$   
DECLARE
  tid integer;
BEGIN

  select trial_id into tid from trial where name = name_in;

  IF (tid is NULL) then
    RAISE EXCEPTION 'Unknown trail: %', name_in;
  END IF;

  RETURN tid;
END; 
$$ LANGUAGE plpgsql;