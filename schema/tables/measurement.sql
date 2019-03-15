-- TABLE
DROP TABLE IF EXISTS measurement CASCADE;
CREATE TABLE measurement (
  measurement_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  unit TEXT NOT NULL,
  description TEXT,
  UNIQUE(name, unit)
);
