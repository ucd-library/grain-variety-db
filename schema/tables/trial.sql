-- TABLE
DROP TABLE IF EXISTS trial CASCADE;
CREATE TABLE trial (
  trial_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name text NOT NULL UNIQUE,
  description text
);

-- VIEW
CREATE OR REPLACE VIEW trial_view AS
  SELECT
    t.trial_id as trial_id,
    sc.name as source_name,
    t.name as trial_name,
    t.description as description
  FROM
    trial t,
    source sc
  WHERE
    t.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_trial (
  trial_id UUID,
  name text,
  description text,
  source_name text) RETURNS void AS $$   
DECLARE
  source_id UUID;
BEGIN

  if( trial_id IS NULL ) Then
    select uuid_generate_v4() into trial_id;
  END IF;
  select get_source_id(source_name) into source_id;

  INSERT INTO trial (
    trial_id, name, description, source_id
  ) VALUES (
    trial_id, name, description, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_trial (
  name_in text,
  description_in text,
  trial_id_in UUID) RETURNS void AS $$   
DECLARE

BEGIN

  UPDATE trial SET (
    name, description
  ) = (
    name_in, description_in
  ) WHERE
    trial_id = trial_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_trial_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_trial(
    trial_id := NEW.trial_id,
    name := NEW.trial_name,
    description := NEW.description,
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_trial_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_trial(
    trial_id_in := NEW.trial_id,
    name_in := NEW.trial_name,
    description_in := NEW.description
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_trial_id(name_in text) RETURNS UUID AS $$   
DECLARE
  tid UUID;
BEGIN

  select trial_id into tid from trial where name = name_in;

  if (tid is NULL) then
    RAISE EXCEPTION 'Unknown trial: %', name_in;
  END IF;
  
  RETURN tid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER trial_insert_trig
  INSTEAD OF INSERT ON
  trial_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_trial_from_trig();

CREATE TRIGGER trial_update_trig
  INSTEAD OF UPDATE ON
  trial_view FOR EACH ROW 
  EXECUTE PROCEDURE update_trial_from_trig();