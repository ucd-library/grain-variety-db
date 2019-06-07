-- TABLES
DROP TABLE IF EXISTS tables CASCADE;
CREATE TABLE tables (
  table_view TEXT PRIMARY KEY,
  uid TEXT NOT NULL,
  name TEXT NOT NULL UNIQUE,
  delete_view BOOLEAN
);

-- DATA
INSERT INTO tables (table_view, name, uid) VALUES ('trial_view', 'trial', 'trial_id');
INSERT INTO tables (table_view, name, uid) VALUES ('site_view_kml', 'site', 'site_id');
INSERT INTO tables (table_view, name, uid) VALUES ('crop_view', 'crop', 'crop_id');
INSERT INTO tables (table_view, name, uid) VALUES ('variety_view', 'variety', 'variety_id');
INSERT INTO tables (table_view, delete_view, name, uid) VALUES ('field_view', TRUE, 'field', 'field_id');
INSERT INTO tables (table_view, name, uid) VALUES ('plot_view', 'plot', 'plot_id');