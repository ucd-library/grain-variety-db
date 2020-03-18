-- NOTE: This file depends on the prism_grid_ca.sql file



-- TABLE
CREATE TABLE prism (
  prism_id SERIAL PRIMARY KEY,
  rast RASTER NOT NULL,
  date DATE NOT NULL,
  measurement TEXT NOT NULL,
  quality prism_quality NOT NULL
);
CREATE INDEX prism_date_idx ON prism(date);
CREATE INDEX prism_measurement_idx ON prism(measurement);

-- GETTER FUNCTION
CREATE OR REPLACE FUNCTION get_prism_xy_from_ll(in lng float, in lat float, out x int, out y int)
AS $$ 

  WITH point AS (
    SELECT (ST_WorldToRasterCoord(rast, lng, lat)).* from prism limit 1
  )
  SELECT 
    point.columnx as x,
    point.rowy as y
  FROM
    point;

$$ LANGUAGE SQL;

select ST_Union(ggd, 'SUM') from growing_degree_days_view where date >= '2019-03-01' and date < '2019-06-01';

-- GROWING DEGREE DAYS
CREATE OR REPLACE VIEW growing_degree_days_view AS
  with tmin as (
    select date, rast from prism where measurement = 'tmin'
  ),
  tmax as (
    select date, rast from prism where measurement = 'tmax'
  )
  select 
    tmin.date as date, 
    rast_growing_degree_days(tmax.rast, tmin.rast) as gdd,
    tmax.rast as tmax,
    tmin.rast as tmin
  from 
    tmin
  left join 
    tmax on tmin.date = tmax.date;

CREATE OR REPLACE FUNCTION rast_growing_degree_days(date_in date) RETURNS RASTER
AS $$
DECLARE
  result RASTER;
  tmax RASTER;
  tmin RASTER;
BEGIN

  SELECT rast FROM prism WHERE date_in = date AND measurement = 'tmax' INTO tmax;
  SELECT rast FROM prism WHERE date_in = date AND measurement = 'tmin' INTO tmin;

  SELECT
    ST_MapAlgebra(
      ARRAY[
        ROW(tmax, 1),
        ROW(tmin, 1)
      ]::rastbandarg[],
      'growing_degree_days_rastalg_callback(double precision[][][], integer[][], text[])'::regprocedure
    ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION rast_growing_degree_days(date_in date) RETURNS RASTER
AS $$
DECLARE
  result RASTER;
  tmax RASTER;
  tmin RASTER;
BEGIN

  SELECT rast FROM prism WHERE date_in = date AND measurement = 'tmax' INTO tmax;
  SELECT rast FROM prism WHERE date_in = date AND measurement = 'tmin' INTO tmin;

  SELECT
    ST_MapAlgebra(
      ARRAY[
        ROW(tmax, 1),
        ROW(tmin, 1)
      ]::rastbandarg[],
      'growing_degree_days_rastalg_callback(double precision[][][], integer[][], text[])'::regprocedure
    ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION rast_growing_degree_days(tmax RASTER, tmin RASTER) RETURNS RASTER
AS $$
DECLARE
  result RASTER;
BEGIN

  SELECT
    ST_MapAlgebra(
      ARRAY[
        ROW(tmax, 1),
        ROW(tmin, 1)
      ]::rastbandarg[],
      'growing_degree_days_rastalg_callback(double precision[][][], integer[][], text[])'::regprocedure
    ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION growing_degree_days(tmax float, tmin float) RETURNS FLOAT 
AS $$
BEGIN
  select (tmax * 9/5) + 32 INTO tmax;
  select (tmin * 9/5) + 32 INTO tmin;

  IF tmax < 45 THEN
    RETURN 0;
  ELSIF tmin > 86 THEN
    RETURN tmax-tmin;
  ELSIF tmax < 86 THEN
    IF tmin < 45 THEN
      RETURN (6*(tmax-45)^2)/(tmax-tmin)/12;
    ELSE
      RETURN ((tmax+tmin-2*45) * 6/12);
    END IF;
  ELSE
    RETURN (6 * (tmax+tmin-2*45) / 12) - (((6*(tmax-86)^2)/(tmax-tmin)) / 12);
  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
growing_degree_days_rastalg_callback(pixel double precision[][][], pos integer[][], VARIADIC userargs text[])
RETURNS FLOAT
AS $$
  DECLARE
    tmax FLOAT;
    tmin FLOAT;
    result FLOAT;
  BEGIN
    tmax := pixel[1][1][1]::float;
    tmin := pixel[2][1][1]::float;
    SELECT growing_degree_days(tmax, tmin) INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;