-- VARIETY CROP CLASSIFICATION REMOVAL
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

-- CROP SAMPLE UNQIUE
ALTER TABLE crop_sample 
ADD CONSTRAINT crop_sample_location_measurement_data_key 
UNIQUE (location_id, crop_part_measurement_id, date, year);
