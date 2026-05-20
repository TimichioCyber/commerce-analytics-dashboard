-- Create the raw events table used throughout the analysis.
-- Load the October 2019 e-commerce events CSV into this table before running
-- the analytical scripts.

CREATE TABLE IF NOT EXISTS ecommerce_events (
    event_time TIMESTAMP,
    event_type TEXT,
    product_id BIGINT,
    category_id BIGINT,
    category_code TEXT,
    brand TEXT,
    price NUMERIC,
    user_id BIGINT,
    user_session UUID
);

CREATE INDEX IF NOT EXISTS idx_ecommerce_events_event_time
    ON ecommerce_events(event_time);

CREATE INDEX IF NOT EXISTS idx_ecommerce_events_user_id
    ON ecommerce_events(user_id);

CREATE INDEX IF NOT EXISTS idx_ecommerce_events_event_type
    ON ecommerce_events(event_type);

CREATE INDEX IF NOT EXISTS idx_ecommerce_events_user_session
    ON ecommerce_events(user_session);
