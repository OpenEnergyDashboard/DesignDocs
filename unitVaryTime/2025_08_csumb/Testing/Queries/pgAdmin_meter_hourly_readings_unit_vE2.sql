-- View: public.meter_hourly_readings_unit_ve2

-- DROP MATERIALIZED VIEW IF EXISTS public.meter_hourly_readings_unit_ve2;

CREATE MATERIALIZED VIEW IF NOT EXISTS public.meter_hourly_readings_unit_ve2
TABLESPACE pg_default
AS
 WITH readings_with_cik_match AS (
         SELECT r.meter_id,
            r.reading,
            r.start_timestamp,
            r.end_timestamp,
            m.unit_id,
            c.destination_id AS graphic_unit_id,
            c.slope,
            c.intercept,
            u.unit_represent,
            u.sec_in_rate
           FROM readings r
             JOIN meters m ON r.meter_id = m.id
             JOIN cik c ON c.source_id = m.unit_id
             JOIN units u ON m.unit_id = u.id
          WHERE tsrange(r.start_timestamp, r.end_timestamp, '()'::text) && tsrange(c.start_time, c.end_time, '()'::text)
        )
 SELECT j.meter_id,
        CASE
            WHEN j.unit_represent = 'quantity'::unit_represent_type THEN sum(j.reading * 3600::double precision / EXTRACT(epoch FROM j.end_timestamp - j.start_timestamp)::double precision * EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision * j.slope + j.intercept) / sum(EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start)))::double precision
            WHEN j.unit_represent = ANY (ARRAY['flow'::unit_represent_type, 'raw'::unit_represent_type]) THEN sum(j.reading * 3600::double precision / j.sec_in_rate::double precision * EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision * j.slope + j.intercept) / sum(EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start)))::double precision
            ELSE NULL::double precision
        END AS reading_rate,
        CASE
            WHEN j.unit_represent = 'quantity'::unit_represent_type THEN max(j.reading * 3600::double precision / EXTRACT(epoch FROM j.end_timestamp - j.start_timestamp)::double precision * EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision / EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision * j.slope + j.intercept)
            WHEN j.unit_represent = ANY (ARRAY['flow'::unit_represent_type, 'raw'::unit_represent_type]) THEN max(j.reading * 3600::double precision / j.sec_in_rate::double precision * EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision / EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision * j.slope + j.intercept)
            ELSE NULL::double precision
        END AS max_rate,
        CASE
            WHEN j.unit_represent = 'quantity'::unit_represent_type THEN min(j.reading * 3600::double precision / EXTRACT(epoch FROM j.end_timestamp - j.start_timestamp)::double precision * EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision / EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision * j.slope + j.intercept)
            WHEN j.unit_represent = ANY (ARRAY['flow'::unit_represent_type, 'raw'::unit_represent_type]) THEN min(j.reading * 3600::double precision / j.sec_in_rate::double precision * EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision / EXTRACT(epoch FROM LEAST(j.end_timestamp, gen.interval_start + '01:00:00'::interval) - GREATEST(j.start_timestamp, gen.interval_start))::double precision * j.slope + j.intercept)
            ELSE NULL::double precision
        END AS min_rate,
    tsrange(gen.interval_start, gen.interval_start + '01:00:00'::interval, '()'::text) AS time_interval,
    j.graphic_unit_id
   FROM readings_with_cik_match j
     CROSS JOIN LATERAL generate_series(date_trunc('hour'::text, j.start_timestamp), date_trunc_up('hour'::text, j.end_timestamp) - '01:00:00'::interval, '01:00:00'::interval) gen(interval_start)
  WHERE tsrange(j.start_timestamp, j.end_timestamp, '()'::text) && tsrange(gen.interval_start, gen.interval_start + '01:00:00'::interval, '()'::text)
  GROUP BY j.meter_id, j.graphic_unit_id, gen.interval_start, j.unit_represent
  ORDER BY j.meter_id, j.graphic_unit_id, gen.interval_start
WITH DATA;

ALTER TABLE IF EXISTS public.meter_hourly_readings_unit_ve2
    OWNER TO oed;