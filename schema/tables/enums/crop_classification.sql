DROP TYPE if EXISTS crop_classification CASCADE;
CREATE TYPE crop_classification AS ENUM ('6RSF(H)', 'DURUM', 'SRS', 'HRS', 
'TRITICALE', 'SWW', 'HRW', '2R2M', '2RSF(H)', '6RSF');