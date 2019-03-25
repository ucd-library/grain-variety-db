-- TABLE
DROP TABLE IF EXISTS plot CASCADE;
CREATE TABLE plot (
  plot_id SERIAL PRIMARY KEY,
  source_id INTEGER REFERENCES source NOT NULL,
  name INTEGER NOT NULL,
  field_id REFERENCES field NOT NULL,
  block INTEGER NOT NULL,
  range INTEGER NOT NULL,
  row INTEGER NOT NULL,
  planting_order INTEGER NOT NULL
  UNIQUE(name, field_id)
);

-- VIEW
CREATE OR REPLACE VIEW plot AS 
SELECT 
  p.plot_id as plot_id,
  t.name as trial_name,
  s.name as site_name,
  f.name as field_name,
  p.name as plot_name,
  sc.name as source_name
FROM
  plot p
LEFT JOIN field f ON f.field_id = p.field_id
LEFT JOIN site s ON s.site_id = f.site_id
LEFT JOIN trail t ON t.trail_id = s.site_id
LEFT JOIN source sc ON f.source_id = sc.source_id;