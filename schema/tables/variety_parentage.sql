-- TABLE
DROP TABLE IF EXISTS variety_parentage CASCADE;
CREATE TABLE variety_parentage (
  variety_parentage_id SERIAL PRIMARY KEY,
  variety_id INTEGER REFERENCES variety,
  parent_variety_id INTEGER REFERENCES variety
);

-- VIEW
CREATE OR REPLACE VIEW variety_parentage_view AS 
SELECT 
  v.name as variety_name,
  p.name as parent_name
FROM
  variety_parentage vp,
  variety v,
  variety p
WHERE
  vp.variety_id = v.variety_id AND
  vp.parent_variety_id = p.variety_id;

