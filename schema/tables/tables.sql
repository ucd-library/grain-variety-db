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
INSERT INTO tables (table_view, name, uid) VALUES ('variety_parentage_view', 'variety_parentage', 'variety_parentage_id');
INSERT INTO tables (table_view, name, uid) VALUES ('variety_label_view', 'variety_label', 'variety_label_id');
INSERT INTO tables (table_view, name, uid) VALUES ('crop_parts_view', 'crop_parts', 'crop_parts_id');
INSERT INTO tables (table_view, name, uid) VALUES ('plant_part_view', 'plant_part', 'plant_part_id');
INSERT INTO tables (table_view, name, uid) VALUES ('crop_part_measurement_view', 'crop_part_measurement', 'crop_part_measurement_id');
INSERT INTO tables (table_view, name, uid) VALUES ('measurement_device_view', 'measurement_device', 'measurement_device_id');
INSERT INTO tables (table_view, name, uid) VALUES ('measurement_view', 'measurement', 'measurement_id');

INSERT INTO tables (table_view, name, uid) VALUES ('crop_sample_view', 'crop_sample', 'crop_sample_id');
INSERT INTO tables (table_view, name, uid) VALUES ('soil_sample_view', 'soil_sample', 'soil_sample_id');
INSERT INTO tables (table_view, name, uid) VALUES ('weed_treatment_type_view', 'weed_treatment_type', 'weed_treatment_type_id');
INSERT INTO tables (table_view, name, uid) VALUES ('weed_treatment_event_view', 'weed_treatment_event', 'weed_treatment_event_id');

INSERT INTO tables (table_view, name, uid) VALUES ('tillage_event_view', 'tillage_event', 'tillage_event_id');
INSERT INTO tables (table_view, name, uid) VALUES ('planting_view', 'planting', 'planting_id');

INSERT INTO tables (table_view, name, uid) VALUES ('fertilization_type_view', 'fertilization_type', 'fertilization_type_id');
INSERT INTO tables (table_view, name, uid) VALUES ('fertilization_event_view', 'fertilization_event', 'fertilization_event_id');

INSERT INTO tables (table_view, name, uid) VALUES ('irrigation_type_view', 'irrigation_type', 'irrigation_type_id');
INSERT INTO tables (table_view, name, uid) VALUES ('irrigation_event_view', 'irrigation_event', 'irrigation_event_id');

INSERT INTO tables (table_view, name, uid) VALUES ('note_view', 'note', 'note_id');
