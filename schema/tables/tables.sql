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
INSERT INTO tables (table_view, delete_view, name, uid) VALUES ('plot_view', TRUE, 'plot', 'plot_id');
INSERT INTO tables (table_view, name, uid) VALUES ('regional_variety_view', 'regional_variety', 'regional_variety_id');
INSERT INTO tables (table_view, name, uid) VALUES ('variety_label_view', 'variety_label', 'variety_label_id');
INSERT INTO tables (table_view, name, uid) VALUES ('crop_parts_view', 'crop_parts', 'crop_parts_id');
INSERT INTO tables (table_view, name, uid) VALUES ('plant_part_view', 'plant_part', 'plant_part_id');
INSERT INTO tables (table_view, name, uid) VALUES ('crop_part_measurement_view', 'crop_part_measurement', 'crop_part_measurement_id');
INSERT INTO tables (table_view, name, uid) VALUES ('measurement_device_view', 'measurement_device', 'measurement_device_id');
INSERT INTO tables (table_view, name, uid) VALUES ('measurement_view', 'measurement', 'measurement_id');
INSERT INTO tables (table_view, name, uid) VALUES ('crop_sample_view', 'crop_sample', 'crop_sample_id');
INSERT INTO tables (table_view, name, uid) VALUES ('crop_sampling_event_view', 'crop_sampling_event', 'crop_sampling_event_id');