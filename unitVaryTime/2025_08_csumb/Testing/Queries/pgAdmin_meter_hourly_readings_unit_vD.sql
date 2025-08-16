DROP MATERIALIZED VIEW IF EXISTS meter_hourly_readings_unit_vD;
-- DROP MATERIALIZED VIEW IF EXISTS meter_daily_readings_unit_v2D;
CREATE MATERIALIZED VIEW IF NOT EXISTS meter_hourly_readings_unit_vD AS
SELECT
  r.meter_id,

  -- Weighted average reading rate (converted)
  CASE WHEN u.unit_represent = 'quantity'::unit_represent_type THEN
    (
      SUM(
        ((r.reading * c.slope + c.intercept) * 3600 / EXTRACT(EPOCH FROM (r.end_timestamp - r.start_timestamp))) *
        EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start))
      ) / SUM(
        EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start))
      )
    )
  WHEN (u.unit_represent = 'flow'::unit_represent_type OR u.unit_represent = 'raw'::unit_represent_type) THEN
    (
      SUM(
        ((r.reading * c.slope + c.intercept) * 3600 / u.sec_in_rate) *
        EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start))
      ) / SUM(
        EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start))
      )
    )
  END AS reading_rate,

  -- Max rate
  CASE WHEN u.unit_represent = 'quantity'::unit_represent_type THEN
    MAX(
      ((r.reading * c.slope + c.intercept) * 3600 / EXTRACT(EPOCH FROM (r.end_timestamp - r.start_timestamp))) *
      EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start)) /
      EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start))
    )
  WHEN (u.unit_represent = 'flow'::unit_represent_type OR u.unit_represent = 'raw'::unit_represent_type) THEN
    MAX(
      ((r.reading * c.slope + c.intercept) * 3600 / u.sec_in_rate) *
      EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start)) /
      EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start))
    )
  END AS max_rate,

  -- Min rate
  CASE WHEN u.unit_represent = 'quantity'::unit_represent_type THEN
    MIN(
      ((r.reading * c.slope + c.intercept) * 3600 / EXTRACT(EPOCH FROM (r.end_timestamp - r.start_timestamp))) *
      EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start)) /
      EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start))
    )
  WHEN (u.unit_represent = 'flow'::unit_represent_type OR u.unit_represent = 'raw'::unit_represent_type) THEN
    MIN(
      ((r.reading * c.slope + c.intercept) * 3600 / u.sec_in_rate) *
      EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start)) /
      EXTRACT(EPOCH FROM LEAST(r.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(r.start_timestamp, gen.interval_start))
    )
  END AS min_rate,

  tsrange(gen.interval_start, gen.interval_start + INTERVAL '1 hour', '()') AS time_interval,
  c.destination_id AS graphic_unit_id

FROM readings r
INNER JOIN meters m ON r.meter_id = m.id
INNER JOIN units u ON m.unit_id = u.id

-- Generate intervals per reading
CROSS JOIN LATERAL generate_series(
  date_trunc('hour', r.start_timestamp),
  date_trunc_up('hour', r.end_timestamp) - INTERVAL '1 hour',
  INTERVAL '1 hour'
) gen(interval_start)

-- LATERAL subquery: find matching conversion row for this interval
INNER JOIN LATERAL (
  SELECT c.*
  FROM cik c
  WHERE c.source_id = m.unit_id
    AND tsrange(c.start_time, c.end_time, '()') &&
        tsrange(gen.interval_start, gen.interval_start + INTERVAL '1 hour', '()')
  -- LIMIT 1
  -- A given hourly reading interval overlaps multiple valid CIK entries, only taking one of them via LIMIT 1,
) c ON TRUE

GROUP BY r.meter_id, c.destination_id, gen.interval_start, u.unit_represent
ORDER BY r.meter_id, c.destination_id, gen.interval_start;

ALTER TABLE IF EXISTS public.meter_hourly_readings_unit_vD
    OWNER TO oed;
	
-- Index: idx_meter_hourly_ordering_vD

-- DROP INDEX IF EXISTS public.idx_meter_hourly_ordering_vD;

CREATE INDEX IF NOT EXISTS idx_meter_hourly_ordering_vD
    ON public.meter_hourly_readings_unit_vD USING btree
    (meter_id ASC NULLS LAST, graphic_unit_id ASC NULLS LAST, lower(time_interval) ASC NULLS LAST)
    TABLESPACE pg_default;