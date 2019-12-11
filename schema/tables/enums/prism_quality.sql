DROP TYPE if EXISTS prism_quality CASCADE;
CREATE TYPE prism_quality AS ENUM ('stable', 'provisional', 'early');