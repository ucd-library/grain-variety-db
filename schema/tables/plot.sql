-- TABLE
DROP TABLE IF EXISTS plot CASCADE;
CREATE TABLE plot (
  plot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  field_id UUID REFERENCES field NOT NULL,
  block INTEGER,
  range INTEGER,
  row INTEGER,
  plot_number INTEGER NOT NULL,
  boundary GEOMETRY(POLYGON, 4326),
  description text,
  variety_id UUID REFERENCES variety NOT NULL,
  UNIQUE(field_id, plot_number)
);
CREATE INDEX plot_source_id_idx ON plot(source_id);
CREATE INDEX plot_field_id_idx ON plot(field_id);
CREATE INDEX plot_variety_id_idx ON plot(variety_id);

-- VIEW
CREATE OR REPLACE VIEW plot_view AS
  SELECT
    p.plot_id as plot_id,
    t.name as trial_name,
    f.name as field_name,
    p.block as block,
    p.range as range,
    p.row as row,
    p.plot_number as plot_number,
    p.description as description,
    v.name as variety_name,
    sc.name as source_name
  FROM
    plot p
LEFT JOIN source sc on p.source_id = sc.source_id
LEFT JOIN field f on p.field_id = f.field_id
LEFT JOIN trial t on f.trial_id = t.trial_id
LEFT JOIN variety v on p.variety_id = v.variety_id;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_plot (
  plot_id UUID,
  trial_name TEXT,
  field_name TEXT,
  block INTEGER,
  range INTEGER,
  "row" INTEGER,
  plot_number INTEGER,
  description TEXT,
  variety_name TEXT,
  source_name TEXT) RETURNS void AS $$   
DECLARE
  source_id UUID;
  field_id UUID;
  variety_id UUID;
BEGIN

  if( plot_id IS NULL ) Then
    select uuid_generate_v4() into plot_id;
  END IF;
  select get_source_id(source_name) into source_id;
  select get_field_id(trial_name, field_name) into field_id;
  select get_variety_id(variety_name) into variety_id;

  INSERT INTO plot (
    plot_id, field_id, block, range, row, plot_number, description, variety_id, source_id
  ) VALUES (
    plot_id, field_id, block, range, row, plot_number, description, variety_id, source_id
  );

  INSERT INTO location (
    field_id, plot_id, source_id
  ) VALUES (
    field_id, plot_id, source_id
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_plot (
  plot_id_in UUID,
  trial_name_in TEXT,
  field_name_in TEXT,
  block_in INTEGER,
  range_in INTEGER,
  row_in INTEGER,
  plot_number_in INTEGER,
  description_in TEXT,
  variety_name_in TEXT) RETURNS void AS $$   
DECLARE
  fid UUID;
  vid UUID;
BEGIN

  select get_variety_id(variety_name_in) into vid;
  select get_field_id(trial_name_in, field_name_in) into fid;

  UPDATE plot SET (
    field_id, block, range, row, plot_number, description, variety_id
  ) = (
    fid, block_in, range_in, row_in, plot_number_in, description_in, vid
  ) WHERE
    plot_id = plot_id_in;

  UPDATE location SET 
    field_id = fid
  WHERE
    plot_id = plot_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_plots (
  plot_id_in UUID) RETURNS void AS $$   
DECLARE
  scid UUID;
BEGIN

  DELETE FROM location where plot_id = plot_id_in;
  DELETE FROM plot where plot_id = plot_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_plot_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_plot(
    plot_id := NEW.plot_id,
    trial_name := NEW.trial_name,
    field_name := NEW.field_name,
    block := NEW.block,
    range := NEW.range,
    "row" := NEW.row,
    plot_number := NEW.plot_number,
    description := NEW.description,
    variety_name := NEW.variety_name,
    source_name := NEW.source_name  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_plot_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_plot(
    plot_id_in := NEW.plot_id,
    trial_name_in := NEW.trial_name,
    field_name_in := NEW.field_name,
    block_in := NEW.block,
    range_in := NEW.range,
    row_in := NEW.row,
    plot_number_in := NEW.plot_number,
    description_in := NEW.description,
    variety_name_in := NEW.variety_name
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_plots_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM delete_plots (
    plot_id_in := OLD.plot_id
  );
  RETURN OLD;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_plot_id(trial_name_in text, field_name_in text, plot_number_in integer) RETURNS UUID AS $$   
DECLARE
  pid UUID;
  fid UUID;
BEGIN

  select get_field_id(trial_name_in, field_name_in) into fid;

  select 
    plot_id into pid 
  from 
    plot p 
  where  
    p.field_id = fid AND
    p.plot_number = plot_number_in;

  if (pid is NULL) then
    RAISE EXCEPTION 'Unknown plot: % % %', trial_name_in, field_name_in, plot_number_in;
  END IF;
  
  RETURN pid;
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

CREATE TRIGGER plot_delete_trig
  INSTEAD OF DELETE ON
  plot_view FOR EACH ROW 
  EXECUTE PROCEDURE delete_plots_from_trig();