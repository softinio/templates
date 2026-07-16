CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE notes (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    author     text NOT NULL,
    body       text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX notes_created_at_idx ON notes (created_at DESC);
