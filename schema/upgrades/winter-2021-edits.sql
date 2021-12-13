-- CREATE NEW TABLES
-- permanent_characteristic.sql
-- variety_permanent_characteristic.sql

-- UPDATE TABLE REGISTRATIONS
INSERT INTO tables (table_view, name, uid) VALUES ('permanent_characteristic_view', 'permanent_characteristic', 'permanent_characteristic_id');
INSERT INTO tables (table_view, name, uid) VALUES ('variety_permanent_characteristic_view', 'variety_permanent_characteristic', 'variety_permanent_characteristic_id');

-- VARIETY CROP CLASSIFICATION REMOVAL
DROP VIEW variety_selection_view;
DROP VIEW regional_variety_view;

ALTER TABLE regional_variety drop column crop_classification;

CREATE OR REPLACE VIEW regional_variety_view AS
  SELECT
    r.regional_variety_id AS regional_variety_id,
    r.region as region,
    v.name as variety_name,
    r.uc_entry_number as uc_entry_number,
    r.trial_group as trial_group,
    r.crop_sub_type as crop_sub_type,
    r.year_added as year_added,
    sc.name AS source_name
  FROM
    regional_variety r
LEFT JOIN source sc ON r.source_id = sc.source_id
LEFT JOIN variety v on r.variety_id = v.variety_id;

CREATE OR REPLACE VIEW variety_selection_view AS
SELECT c.season,
  sv.season_end_year,
  lv.field_name,
  round(sv.lat::numeric, 4) AS lat,
  round(sv.lng::numeric, 4) AS lng,
  pv.block,
  sv.common_name,
  rgv.region,
  rgv.crop_sub_type,
  vlv.label,
  c.measurement_name,
  c.amount,
  c.plot_number,
  vv.release_status,
  rgv.trial_group,
  rgv.uc_entry_number,
  vlv.variety_name,
  fv.nitrogen_stress,
  fv.water_stress,
  c.trial_name,
  vlv.current,
  sv.site_name,
  c.crop_sample_id,
  vv.crop_classification,
  vv.source
FROM crop_sample_view c
LEFT JOIN plot_view pv ON c.plot_number = pv.plot_number AND c.field_name = pv.field_name AND c.trial_name = pv.trial_name
LEFT JOIN location_view lv ON c.plot_number = lv.plot_number AND c.field_name = lv.field_name
LEFT JOIN field_view fv ON c.field_name = fv.field_name AND c.site_name = fv.site_name
LEFT JOIN site_view_ll sv ON c.site_name = sv.site_name
LEFT JOIN variety_view vv ON pv.variety_name = vv.variety_name
LEFT JOIN variety_label_view vlv ON vv.variety_name = vlv.variety_name
LEFT JOIN regional_variety_view rgv ON fv.trial_group = rgv.trial_group AND sv.region = rgv.region AND vlv.variety_name = rgv.variety_name;


-- CROP SAMPLE UNQIUE
ALTER TABLE crop_sample 
ADD CONSTRAINT crop_sample_location_measurement_data_key 
UNIQUE (location_id, crop_part_measurement_id, date, year);
