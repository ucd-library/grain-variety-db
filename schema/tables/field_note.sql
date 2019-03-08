-- TABLE
DROP TABLE IF EXISTS field_note CASCADE;
CREATE TABLE field_note (
  field_note_id SERIAL PRIMARY KEY,
  field_id INTEGER REFERENCES field NOT NULL,
  date DATE NOT NULL,
  note TEXT NOT NULL
);

-- VIEW
CREATE OR REPLACE VIEW field_note_view AS 
SELECT 
  f.name as field_name,
  fn.date as date,
  fn.note as note
FROM
  field f,
  field_note fn
WHERE
  f.field_id = fn.field_id;
