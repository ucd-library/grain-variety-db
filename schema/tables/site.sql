-- TABLE
DROP TABLE IF EXISTS site CASCADE;
CREATE TABLE site (
  site_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  source_id UUID REFERENCES source NOT NULL,
  name TEXT NOT NULL UNIQUE,
  common_name TEXT,
  region REGION,
  description TEXT,
  cooperator TEXT,
  season TEXT NOT NULL,
  season_start_year INTEGER NOT NULL,
  season_end_year INTEGER NOT NULL,
  boundary GEOMETRY(POLYGON, 4326)
);

-- VIEW
CREATE OR REPLACE VIEW site_view AS
  SELECT
    s.site_id as site_id,
    s.name as site_name,
    s.common_name as common_name,
    cac.name as county_name,
    s.region as region,
    s.description as description,
    s.cooperator as cooperator,
    s.season as season,
    s.season_start_year as season_start_year,
    s.season_end_year as season_end_year,
    sc.name as source_name
  FROM
    site s
LEFT JOIN ca_counties cac ON ST_Intersects(cac.geom, s.boundary)
LEFT JOIN source sc ON s.source_id = sc.source_id;

CREATE OR REPLACE VIEW site_view_ll as
  SELECT
    sv.*,
    ST_X(ST_Centroid(s.boundary)) as lng,
    ST_Y(ST_Centroid(s.boundary)) as lat
  FROM
    site_view sv,
    site s
  WHERE
    s.site_id = sv.site_id;

CREATE OR REPLACE VIEW site_view_kml as
  SELECT
    sv.*,
    ST_AsKML(s.boundary) as boundary
  FROM
    site_view sv,
    site s
  WHERE
    s.site_id = sv.site_id;

CREATE OR REPLACE VIEW site_weather_view as
  SELECT
    sv.*,
    p.measurement as measurement,
    p.date as date,
    p.quality as quality,
    ST_Value(p.rast, ST_Centroid(s.boundary)) as value
  FROM
    site_view sv,
    site s,
    prism p
  WHERE
    s.site_id = sv.site_id AND
    EXTRACT(YEAR FROM p.date) >= sv.season_start_year AND
    EXTRACT(YEAR FROM p.date) <= sv.season_end_year;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION insert_site_kml (
  site_id UUID,
  name text,
  common_name text,
  region region,
  description text,
  cooperator text,
  season text,
  season_start_year integer,
  season_end_year integer,
  boundary text,
  source_name text) RETURNS void AS $$   
DECLARE
  source_id UUID;
BEGIN

  if( site_id IS NULL ) Then
    select uuid_generate_v4() into site_id;
  END IF;
  select get_source_id(source_name) into source_id;

  if( boundary is not NULL ) then
    select ST_Force2D(ST_GeomFromKML(boundary)) into boundary;
  END IF;

  INSERT INTO site (
    site_id, source_id, name, common_name, region, description, cooperator, season, season_start_year,
    season_end_year, boundary
  ) VALUES (
    site_id, source_id, name, common_name, region, description, cooperator, season, season_start_year,
    season_end_year, boundary
  );

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_site_kml (
  name_in text,
  common_name_in text,
  region_in region,
  description_in text,
  cooperator_in text,
  season_in text,
  season_start_year_in integer,
  season_end_year_in integer,
  boundary_in text,
  site_id_in UUID) RETURNS void AS $$   
DECLARE

BEGIN

  if( boundary_in is not NULL ) then
    select ST_Force2D(ST_GeomFromKML(boundary_in)) into boundary_in;
  END IF;

  UPDATE site SET (
    name, common_name, region, description, cooperator, season, season_start_year,
    season_end_year, boundary
  ) = (
    name_in, common_name_in, region_in, description_in, cooperator_in, season_in, 
    season_start_year_in, season_end_year_in, boundary_in
  ) WHERE
    site_id = site_id_in;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION TRIGGERS
CREATE OR REPLACE FUNCTION insert_site_kml_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM insert_site_kml(
    site_id := NEW.site_id,
    source_name := NEW.source_name,
    name := NEW.site_name,
    common_name := NEW.common_name,
    region := NEW.region,
    description := NEW.description,
    cooperator := NEW.cooperator,
    season := NEW.season,
    season_start_year := NEW.season_start_year,
    season_end_year := NEW.season_end_year,
    boundary := NEW.boundary
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_site_kml_from_trig() 
RETURNS TRIGGER AS $$   
BEGIN
  PERFORM update_site_kml(
    site_id_in := NEW.site_id,
    name_in := NEW.site_name,
    common_name_in := NEW.common_name,
    region_in := NEW.region,
    description_in := NEW.description,
    cooperator_in := NEW.cooperator,
    season_in := NEW.season,
    season_start_year_in := NEW.season_start_year,
    season_end_year_in := NEW.season_end_year,
    boundary_in := NEW.boundary
  );
  RETURN NEW;

EXCEPTION WHEN raise_exception THEN
  RAISE;
END; 
$$ LANGUAGE plpgsql;

-- FUNCTION GETTER
CREATE OR REPLACE FUNCTION get_site_id(name_in text) RETURNS UUID AS $$   
DECLARE
  sid UUID;
BEGIN

  select 
    site_id into sid 
  from 
    site s 
  where  
    name = name_in;

  if (sid is NULL) then
    RAISE EXCEPTION 'Unknown site: %', name_in;
  END IF;
  
  RETURN sid;
END ; 
$$ LANGUAGE plpgsql;

-- RULES
CREATE TRIGGER site_kml_insert_trig
  INSTEAD OF INSERT ON
  site_view_kml FOR EACH ROW 
  EXECUTE PROCEDURE insert_site_kml_from_trig();

CREATE TRIGGER site_kml_update_trig
  INSTEAD OF UPDATE ON
  site_view_kml FOR EACH ROW 
  EXECUTE PROCEDURE update_site_kml_from_trig();