-- TABLE
DROP TABLE IF EXISTS variety_parts CASCADE;
CREATE TABLE variety_parts (
  variety_parts_id SERIAL PRIMARY KEY,
  variety_id INTEGER REFERENCES variety,
  plant_part_id INTEGER REFERENCES plant_part
);
