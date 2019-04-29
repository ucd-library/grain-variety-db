-- TABLE
DROP TABLE IF EXISTS plot CASCADE;
CREATE TABLE plot (
  plot_id SERIAL PRIMARY KEY,
  source_id INTEGER REFERENCES source NOT NULL,
  field INTEGER REFERENCES field NOT NULL,
  block INTEGER NOT NULL,
  range INTEGER NOT NULL,
  row INTEGER NOT NULL,
  plot_number INTEGER NOT NULL,
  planting_order INTEGER NOT NULL,
  variety_id INTEGER REFERENCES variety NOT NULL
);

-- VIEW
CREATE OR REPLACE VIEW plot_view AS
  SELECT
    p.plot_id as plot_id,
    sc.name as source_name
  FROM
    plot p,
    source sc
  WHERE
    p.source_id = sc.source_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_plot (
  field INTEGER,
  block INTEGER,
  range INTEGER,
  row INTEGER,
  plot_number INTEGER,
  planting_order INTEGER,
  variety_name text,
  source_name text) RETURNS void AS $$   
DECLARE
  source_id INTEGER;
BEGIN

  select get_source_id(source_name) into source_id;

  INSERT INTO plot (
    source_id
  ) VALUES (
    source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_plot (
  plot_id_in INTEGER) RETURNS void AS $$   
DECLARE

BEGIN

  UPDATE plot SET (
    
  ) = (
    
  ) WHERE
    plot_id = plot_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_plot_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_plot(
    source_name := NEW.source_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_plot_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_plot(
    plot_id := NEW.plot_id,
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_plot_id() RETURNS INTEGER AS $$   
DECLARE
  pid integer;
BEGIN

  select 
    plot_id into pid 
  from 
    plot p 
  where  

  if (pid is NULL) then
    RAISE EXCEPTION 'Unknown plot: ', ;
  END IF;
  
  RETURN hid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER plot_insert_trig
  INSTEAD OF INSERT ON
  plot_view FOR EACH ROW 
  EXECUTE PROCEDURE insert_plot_from_trig();

CREATE TRIGGER plot_update_trig
  INSTEAD OF UPDATE ON
  plot_view FOR EACH ROW 
  EXECUTE PROCEDURE update_plot_from_trig();