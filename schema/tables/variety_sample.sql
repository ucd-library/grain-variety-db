-- TABLE
DROP TABLE IF EXISTS variety_sample CASCADE;
CREATE TABLE variety_sample (
  variety_sample_id SERIAL PRIMARY KEY,
  variety_sampling_event_id INTEGER NOT NULL REFERENCES variety_sampling,
  variety_part_measurement_id INTEGER NOT NULL REFERENCES variety_part_measurement,
  amount FLOAT NOT NULL,
  description TEXT,
  UNIQUE(variety_sampling_event_id, variety_part_measurement_id)
);