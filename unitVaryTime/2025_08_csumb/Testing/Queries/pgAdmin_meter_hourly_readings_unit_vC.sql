DROP MATERIALIZED VIEW IF EXISTS meter_hourly_readings_unit_vC;
-- DROP MATERIALIZED VIEW IF EXISTS meter_daily_readings_unit_vC;
CREATE MATERIALIZED VIEW IF NOT EXISTS meter_hourly_readings_unit_vC AS
WITH joined_readings_with_conversion AS (
  SELECT
    r.meter_id,
    r.reading,
    r.start_timestamp,
    r.end_timestamp,
    c.destination_id AS graphic_unit_id,
    c.slope,
    c.intercept,
    u.unit_represent,
    u.sec_in_rate
  FROM readings r
  INNER JOIN meters m ON r.meter_id = m.id
  INNER JOIN cik c ON c.source_id = m.unit_id
  INNER JOIN units u ON c.source_id = u.id
  WHERE tsrange(r.start_timestamp, r.end_timestamp, '()') &&
        tsrange(c.start_time, c.end_time, '()')
)
SELECT
  j.meter_id,

  -- Weighted average reading rate (converted)
  CASE WHEN j.unit_represent = 'quantity'::unit_represent_type THEN
    (
      SUM(
        ((j.reading * j.slope + j.intercept) * 3600 / EXTRACT(EPOCH FROM (j.end_timestamp - j.start_timestamp))) *
        EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start))
      ) / SUM(
        EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start))
      )
    )
  WHEN (j.unit_represent = 'flow'::unit_represent_type OR j.unit_represent = 'raw'::unit_represent_type) THEN
    (
      SUM(
        ((j.reading * j.slope + j.intercept) * 3600 / j.sec_in_rate) *
        EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start))
      ) / SUM(
        EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start))
      )
    )
  END AS reading_rate,

  -- Max rate (converted)
  CASE WHEN j.unit_represent = 'quantity'::unit_represent_type THEN
    MAX(
      ((j.reading * j.slope + j.intercept) * 3600 / EXTRACT(EPOCH FROM (j.end_timestamp - j.start_timestamp))) *
      EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start)) /
      EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start))
    )
  WHEN (j.unit_represent = 'flow'::unit_represent_type OR j.unit_represent = 'raw'::unit_represent_type) THEN
    MAX(
      ((j.reading * j.slope + j.intercept) * 3600 / j.sec_in_rate) *
      EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start)) /
      EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start))
    )
  END AS max_rate,

  -- Min rate (converted)
  CASE WHEN j.unit_represent = 'quantity'::unit_represent_type THEN
    MIN(
      ((j.reading * j.slope + j.intercept) * 3600 / EXTRACT(EPOCH FROM (j.end_timestamp - j.start_timestamp))) *
      EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start)) /
      EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start))
    )
  WHEN (j.unit_represent = 'flow'::unit_represent_type OR j.unit_represent = 'raw'::unit_represent_type) THEN
    MIN(
      ((j.reading * j.slope + j.intercept) * 3600 / j.sec_in_rate) *
      EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start)) /
      EXTRACT(EPOCH FROM LEAST(j.end_timestamp, gen.interval_start + INTERVAL '1 hour') - GREATEST(j.start_timestamp, gen.interval_start))
    )
  END AS min_rate,

  tsrange(gen.interval_start, gen.interval_start + INTERVAL '1 hour', '()') AS time_interval,
  j.graphic_unit_id

FROM joined_readings_with_conversion j
CROSS JOIN LATERAL generate_series(
  date_trunc('hour', j.start_timestamp),
  date_trunc_up('hour', j.end_timestamp) - INTERVAL '1 hour',
  INTERVAL '1 hour'
) gen(interval_start)

WHERE tsrange(j.start_timestamp, j.end_timestamp, '()') &&
      tsrange(gen.interval_start, gen.interval_start + INTERVAL '1 hour', '()')

GROUP BY j.meter_id, j.graphic_unit_id, gen.interval_start, j.unit_represent
ORDER BY j.meter_id, j.graphic_unit_id, gen.interval_start;

ALTER TABLE IF EXISTS public.meter_hourly_readings_unit_vC
    OWNER TO oed;
	
-- Index: idx_meter_hourly_ordering_vC

-- DROP INDEX IF EXISTS public.idx_meter_hourly_ordering_vC;

CREATE INDEX IF NOT EXISTS idx_meter_hourly_ordering_vC
    ON public.meter_hourly_readings_unit_vC USING btree
    (meter_id ASC NULLS LAST, graphic_unit_id ASC NULLS LAST, lower(time_interval) ASC NULLS LAST)
    TABLESPACE pg_default;
