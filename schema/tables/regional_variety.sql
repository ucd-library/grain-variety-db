-- TYPE
DROP TYPE if EXISTS region CASCADE;
CREATE TYPE region AS ENUM ('IR', 'NonIR');

-- TABLE
DROP TABLE IF EXISTS regional_variety CASCADE;
CREATE TABLE regional_variety (
  regional_variety_id SERIAL PRIMARY KEY,
  uc_entry_number INTEGER UNIQUE NOT NULL,
  region region NOT NULL,
  variety_id INTEGER REFERENCES variety,
  year_added INTEGER
);
