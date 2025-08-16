DROP MATERIALIZED VIEW IF EXISTS meter_hourly_readings_unit_vB;
-- DROP MATERIALIZED VIEW IF EXISTS meter_daily_readings_unit_v2B;
CREATE MATERIALIZED VIEW IF NOT EXISTS
meter_hourly_readings_unit_vB
	-- vB all rates now include meter conversions from CIK table, changes noted with 'sls_B01'
	AS SELECT
		-- This gives the weighted average of the converted reading rates, defined as
		-- sum((reading_rate * slope + intercept) * overlap_duration) / sum(overlap_duration)
		r.meter_id AS meter_id,
		CASE WHEN u.unit_represent = 'quantity'::unit_represent_type THEN
			(sum(
				((r.reading * c.slope + c.intercept) * 3600 / (extract(EPOCH FROM (r.end_timestamp - r.start_timestamp)))) -- Reading rate in kw
				*
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
						-
						greatest(r.start_timestamp, gen.interval_start)
				)
			) / sum(
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
					-
					greatest(r.start_timestamp, gen.interval_start)
				)
			))
		WHEN (u.unit_represent = 'flow'::unit_represent_type OR u.unit_represent = 'raw'::unit_represent_type) THEN
			(sum(
				((r.reading * c.slope + c.intercept)  * 3600 / u.sec_in_rate) -- Reading rate in per hour
				*
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
					-
					greatest(r.start_timestamp, gen.interval_start)
				)
			) / sum(
					extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
						least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
						-
						greatest(r.start_timestamp, gen.interval_start)
					)
			))
		END AS reading_rate,

		-- The following code does the converted min/max for hourly readings
		CASE WHEN u.unit_represent = 'quantity'::unit_represent_type THEN
    		(max(( -- Extract the maximum rate over each day
				((r.reading * c.slope + c.intercept)  * 3600 / (extract(EPOCH FROM (r.end_timestamp - r.start_timestamp)))) -- Reading rate in kw
				*
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
					-
					greatest(r.start_timestamp, gen.interval_start)
				)
			) / (
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
					-
					greatest(r.start_timestamp, gen.interval_start)
				)
			))) 
		WHEN (u.unit_represent = 'flow'::unit_represent_type OR u.unit_represent = 'raw'::unit_represent_type) THEN
			(max(( -- For flow and raw data the max/min is per minute, so we multiply the max/min by 24 hrs * 60 min
				((r.reading * c.slope + c.intercept)  * 3600 / u.sec_in_rate) -- Reading rate in kw
				*
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
					-
					greatest(r.start_timestamp, gen.interval_start)
				)
			) / (
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
					-
					greatest(r.start_timestamp, gen.interval_start)
				)
			)))
		END as max_rate,
			
		CASE WHEN u.unit_represent = 'quantity'::unit_represent_type THEN
			(min(( --Extract the minimum rate over each day
				((r.reading * c.slope + c.intercept) * 3600 / (extract(EPOCH FROM (r.end_timestamp - r.start_timestamp)))) -- Reading rate in kw
				*
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
						least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
						-
						greatest(r.start_timestamp, gen.interval_start)
					) 
			) / (
					extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
						least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
						-
						greatest(r.start_timestamp, gen.interval_start)
					)
			)))
		WHEN (u.unit_represent = 'flow'::unit_represent_type OR u.unit_represent = 'raw'::unit_represent_type) THEN
			(min((
				((r.reading * c.slope + c.intercept) * 3600 / u.sec_in_rate) -- Reading rate in kw
				*
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
					-
					greatest(r.start_timestamp, gen.interval_start)
				) 
			) / (
				extract(EPOCH FROM -- The number of seconds that the reading shares with the interval
					least(r.end_timestamp, gen.interval_start + '1 hour'::INTERVAL)
					-
					greatest(r.start_timestamp, gen.interval_start)
				)
			)))
		END as min_rate,

	tsrange(gen.interval_start, gen.interval_start + '1 hour'::INTERVAL, '()') AS time_interval,
	c.destination_id AS graphic_unit_id -- sls_B01
	
	FROM (((readings r
	-- This sequence of joins takes the meter id to its unit and a unit.
	INNER JOIN meters m ON r.meter_id = m.id)
	INNER JOIN cik c on c.source_id = m.unit_id) -- sls_B01
	INNER JOIN units u ON c.source_id = u.id) -- sls_B03
	-- INNER JOIN units u ON m.unit_id = u.id)
		CROSS JOIN LATERAL generate_series(
			date_trunc('hour', r.start_timestamp),
			-- Subtract 1 interval width because generate_series is end-inclusive
			date_trunc_up('hour', r.end_timestamp) - '1 hour'::INTERVAL,
			'1 hour'::INTERVAL
		) gen(interval_start)
	-- INNER JOIN cik c ON c.source_id = m.unit_id AND tsrange(c.start_time, c.end_time, '()') && tsrange(gen.interval_start, gen.interval_start + INTERVAL '1 hour', '()')) -- sls_B03
	WHERE tsrange(c.start_time, c.end_time, '()') && tsrange(gen.interval_start, gen.interval_start + INTERVAL '1 hour', '()')
	GROUP BY r.meter_id, gen.interval_start, u.unit_represent, graphic_unit_id -- sls_B02
	-- The order by ensures that the materialized view will be clustered in this way.
	-- ORDER BY matches current version of meter_hourly_readings_unit -- sls_B01
	ORDER BY r.meter_id, graphic_unit_id, gen.interval_start; -- sls_B01

ALTER TABLE IF EXISTS public.meter_hourly_readings_unit_vB
    OWNER TO oed;
	
-- Index: idx_meter_hourly_ordering_vB

-- DROP INDEX IF EXISTS public.idx_meter_hourly_ordering_vB;

CREATE INDEX IF NOT EXISTS idx_meter_hourly_ordering_vB
    ON public.meter_hourly_readings_unit_vB USING btree
    (meter_id ASC NULLS LAST, graphic_unit_id ASC NULLS LAST, lower(time_interval) ASC NULLS LAST)
    TABLESPACE pg_default;

