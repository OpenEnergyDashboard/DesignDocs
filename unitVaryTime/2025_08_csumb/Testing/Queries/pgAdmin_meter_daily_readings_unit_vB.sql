-- View: public.daily_readings_unit

-- DROP MATERIALIZED VIEW IF EXISTS public.meter_daily_readings_unit_vB;

CREATE MATERIALIZED VIEW IF NOT EXISTS public.meter_daily_readings_unit_vB
TABLESPACE pg_default
AS
 SELECT h.meter_id,
    avg(h.reading_rate) AS reading_rate,
    max(h.max_rate) AS max_rate,
    min(h.min_rate) AS min_rate,
    tsrange(gen.interval_start, gen.interval_start + '1 day'::interval, '()'::text) AS time_interval
   FROM meter_hourly_readings_unit_vB h
     JOIN meters m ON h.meter_id = m.id
     JOIN units u ON m.unit_id = u.id
     CROSS JOIN LATERAL generate_series(date_trunc('day'::text, lower(h.time_interval)), date_trunc_up('day'::text, upper(h.time_interval)) - '01:00:00'::interval, '1 day'::interval) gen(interval_start)
  GROUP BY h.meter_id, gen.interval_start, u.unit_represent
  ORDER BY gen.interval_start, h.meter_id
WITH DATA;

ALTER TABLE IF EXISTS public.meter_daily_readings_unit_vB
    OWNER TO oed;


CREATE INDEX idx_meter_daily_readings_unit_vB
    ON public.meter_daily_readings_unit_vB USING gist
    (time_interval, meter_id)
    TABLESPACE pg_default;