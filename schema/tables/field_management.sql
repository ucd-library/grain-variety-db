-- TABLE
DROP TABLE IF EXISTS field_management CASCADE;
CREATE TABLE field_management (
  field_management_id SERIAL PRIMARY KEY,
  field_id INTEGER REFERENCES field NOT NULL,
  name text NOT NULL UNIQUE,
  season season NOT NULL,
  year INTEGER NOT NULL,
  water_stress BOOLEAN,
  nitrogen_stress BOOLEAN,
  variety_id INTEGER REFERENCES variety NOT NULL,
  previous_varity_id INTEGER REFERENCES variety NOT NULL
  preplant_nitrate INTEGER
);