-- TYPE
DROP TYPE if EXISTS region CASCADE;
CREATE TYPE region AS ENUM ('IR', 'NonIR');

-- TABLE
DROP TABLE IF EXISTS variety_region CASCADE;
CREATE TABLE variety_region (
  variety_region_id SERIAL PRIMARY KEY,
  uc_entry_number INTEGER UNIQUE NOT NULL,
  region region NOT NULL,
  variety INTEGER REFERENCES variety,
  year_added DATE
);
