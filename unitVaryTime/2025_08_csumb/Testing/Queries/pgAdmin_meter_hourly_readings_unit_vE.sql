-- View: public.meter_hourly_readings_unit_ve

-- DROP MATERIALIZED VIEW IF EXISTS public.meter_hourly_readings_unit_ve;

CREATE MATERIALIZED VIEW IF NOT EXISTS public.meter_hourly_readings_unit_ve
TABLESPACE pg_default
AS
 SELECT r.meter_id,
    sum(
        CASE
            WHEN u.unit_represent = 'quantity'::unit_represent_type THEN r.reading * 3600::double precision / EXTRACT(epoch FROM r.end_timestamp - r.start_timestamp)::double precision
            WHEN u.unit_represent = ANY (ARRAY['flow'::unit_represent_type, 'raw'::unit_represent_type]) THEN r.reading * 3600::double precision / u.sec_in_rate::double precision
            ELSE NULL::double precision
        END * EXTRACT(epoch FROM LEAST(r.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(r.start_timestamp, gen.interval_start))::double precision * c.slope + c.intercept) / sum(EXTRACT(epoch FROM LEAST(r.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(r.start_timestamp, gen.interval_start)))::double precision AS reading_rate,
    max(
        CASE
            WHEN u.unit_represent = 'quantity'::unit_represent_type THEN r.reading * 3600::double precision / EXTRACT(epoch FROM r.end_timestamp - r.start_timestamp)::double precision
            WHEN u.unit_represent = ANY (ARRAY['flow'::unit_represent_type, 'raw'::unit_represent_type]) THEN r.reading * 3600::double precision / u.sec_in_rate::double precision
            ELSE NULL::double precision
        END * EXTRACT(epoch FROM LEAST(r.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(r.start_timestamp, gen.interval_start))::double precision / EXTRACT(epoch FROM LEAST(r.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(r.start_timestamp, gen.interval_start))::double precision * c.slope + c.intercept) AS max_rate,
    min(
        CASE
            WHEN u.unit_represent = 'quantity'::unit_represent_type THEN r.reading * 3600::double precision / EXTRACT(epoch FROM r.end_timestamp - r.start_timestamp)::double precision
            WHEN u.unit_represent = ANY (ARRAY['flow'::unit_represent_type, 'raw'::unit_represent_type]) THEN r.reading * 3600::double precision / u.sec_in_rate::double precision
            ELSE NULL::double precision
        END * EXTRACT(epoch FROM LEAST(r.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(r.start_timestamp, gen.interval_start))::double precision / EXTRACT(epoch FROM LEAST(r.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(r.start_timestamp, gen.interval_start))::double precision * c.slope + c.intercept) AS min_rate,
    tsrange(gen.interval_start, gen.interval_start + '01:00:00'::interval, '()'::text) AS time_interval,
    c.destination_id AS graphic_unit_id
   FROM readings r
     JOIN meters m ON r.meter_id = m.id
     JOIN units u ON m.unit_id = u.id
     CROSS JOIN LATERAL generate_series(date_trunc('hour'::text, r.start_timestamp), date_trunc_up('hour'::text, r.end_timestamp) - '01:00:00'::interval, '01:00:00'::interval) gen(interval_start)
     JOIN cik c ON c.source_id = m.unit_id AND tsrange(c.start_time, c.end_time, '()'::text) && tsrange(gen.interval_start, gen.interval_start + '01:00:00'::interval, '()'::text)
  GROUP BY r.meter_id, c.destination_id, gen.interval_start
  ORDER BY r.meter_id, c.destination_id, gen.interval_start
WITH DATA;

ALTER TABLE IF EXISTS public.meter_hourly_readings_unit_ve
    OWNER TO oed;