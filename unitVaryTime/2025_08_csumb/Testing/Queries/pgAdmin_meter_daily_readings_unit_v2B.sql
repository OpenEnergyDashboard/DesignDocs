-- View: public.meter_daily_readings_unit_v2

-- DROP MATERIALIZED VIEW IF EXISTS public.meter_daily_readings_unit_v2B;

CREATE MATERIALIZED VIEW IF NOT EXISTS public.meter_daily_readings_unit_v2B
TABLESPACE pg_default
AS
 SELECT h.meter_id,
    avg(h.reading_rate) AS reading_rate,
    min(h.min_rate) AS min_rate,
    max(h.max_rate) AS max_rate,
    tsrange(date_trunc('day'::text, lower(h.time_interval)), date_trunc('day'::text, lower(h.time_interval)) + '1 day'::interval, '()'::text) AS time_interval,
    h.graphic_unit_id
   FROM meter_hourly_readings_unit_vB h
  GROUP BY h.meter_id, h.graphic_unit_id, (date_trunc('day'::text, lower(h.time_interval)))
  ORDER BY h.meter_id, (tsrange(date_trunc('day'::text, lower(h.time_interval)), date_trunc('day'::text, lower(h.time_interval)) + '1 day'::interval, '()'::text))
WITH DATA;

ALTER TABLE IF EXISTS public.meter_daily_readings_unit_v2B
    OWNER TO oed;

-- DROP MATERIALIZED VIEW IF EXISTS idx_meter_daily_ordering_v2B;

CREATE INDEX idx_meter_daily_ordering_v2B
    ON public.meter_daily_readings_unit_v2B USING btree
    (meter_id, graphic_unit_id, lower(time_interval))
    TABLESPACE pg_default;