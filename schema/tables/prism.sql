CREATE TABLE prism (
  prism_id SERIAL PRIMARY KEY,
  rast RASTER NOT NULL,
  date DATE NOT NULL,
  measurement TEXT NOT NULL
);