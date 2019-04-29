DROP TYPE if EXISTS release_status CASCADE;
CREATE TYPE release_status AS ENUM ('Released', 'Advanced');