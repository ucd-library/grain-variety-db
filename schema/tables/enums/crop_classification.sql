DROP TYPE if EXISTS crop_classification CASCADE;
CREATE TYPE crop_classification AS ENUM ('6RSF(H)', 'DURUM', 'SRS', 'HRS', 'HWS', 'HRW',
'TRITICALE', 'SWW', 'SWS', '2R2M', '2RSM', '2RSF', '2RSF(H)', '6RSF', '6RSM',
'6RSN', 'HWW');