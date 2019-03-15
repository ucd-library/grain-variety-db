-- TABLE
DROP TABLE IF EXISTS variety_part_measurement CASCADE;
CREATE TABLE variety_part_measurement (
  variety_part_measurement_id SERIAL PRIMARY KEY,
  measurement_id INTEGER NOT NULL REFERENCES measurement,
  variety_parts_id INTEGER NOT NULL REFERENCES variety_parts,
  UNIQUE(measurement_id, variety_parts_id)
);
