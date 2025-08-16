-- select * from units;
-- all records returned 43261 in 0.118s
-- meter_id = 25, returns 6579 , "Sin Amp 1 kWh" in 0.082s
SELECT meter_id, reading_rate, max_rate, min_rate, time_interval, graphic_unit_id
	FROM public.meter_daily_readings_unit_vB
	where meter_id = 25
	order by meter_id, time_interval, graphic_unit_id;

-- to be developed
-- select meter_line_readings_unit_v#B('{25}', 1, '-infinity', 'infinity', 'daily', 200, 200);

-- all records returned 43261 in 0.132s
-- meter_id = 25, returns 6579, "Sin Amp 1 kWh" om 0.075s
SELECT meter_id, reading_rate, min_rate, max_rate, time_interval, graphic_unit_id
	FROM public.meter_daily_readings_unit
	where meter_id = 25
	order by meter_id, time_interval, graphic_unit_id;

-- select meter_line_readings_unit('{25}', 1, '-infinity', 'infinity', 'daily', 200, 200);

-- running full record comparison between both m-views
-- if receiving the following error with varying byte values:
-- "ERROR:  could not resize shared memory segment "/PostgreSQL.4261237022" to 33554432 bytes: No space left on device SQL state: 53100"
-- set max_parallel_workers_per_gather to '0', test, and then reset back to '2'

-- Limit query performance for this session
-- get current values
SHOW max_parallel_workers_per_gather; -- default 2
SHOW work_mem; -- default 4MB

-- note, only need to disable parallelism
SET max_parallel_workers_per_gather = 0; -- Disable parallelism
SET work_mem = '2MB';    				 -- Reduce per-operation memory

-- reset value in current sessions after testing completes
RESET max_parallel_workers_per_gather;
RESET work_mem;

-- compare results 
SELECT
  org.meter_id, org.graphic_unit_id, org.time_interval,
  -- Show values from both views
  org.reading_rate, vB.reading_rate, org.reading_rate - vB.reading_rate AS reading_rate_diff,
  org.min_rate, vB.min_rate, org.min_rate - vB.min_rate AS min_rate_diff,
  org.max_rate, vB.max_rate, org.max_rate - vB.max_rate AS max_rate_diff

FROM meter_daily_readings_unit AS org
FULL OUTER JOIN meter_daily_readings_unit_vB AS vB
  ON org.meter_id = vB.meter_id
  AND org.graphic_unit_id = vB.graphic_unit_id
  AND org.time_interval = vB.time_interval

WHERE
  -- show same rows
  -- returns 19 / 43261
  -- org.reading_rate = vB.reading_rate
  -- AND org.min_rate = vB.min_rate
  -- AND org.max_rate = vB.max_rate
  
  -- show differences
  -- returns 24883 / 43261
  -- current version returns xx records
  -- Ex. difference in reading_rate
-- 		20472.852	20472.85200000001
-- 		36630.03663003663	36630.03663003665
-- 		109890.10989010989	109890.10989010987
  -- org.reading_rate IS DISTINCT FROM vB.reading_rate
  -- OR org.min_rate IS DISTINCT FROM vB.min_rate
  -- OR org.max_rate IS DISTINCT FROM vB.max_rate

  -- reduce precision, account for rounding errors
  -- comparing at 0.0000000001, returns 0 records
  -- comparing at 0.00000000001 returns 15 records
  -- comparing at 0.000000000001 returns 1316 record
  ABS(org.reading_rate - vB.reading_rate) > 0.0000000001
  OR ABS(org.min_rate - vB.min_rate) > 0.0000000001
  OR ABS(org.max_rate - vB.max_rate) > 0.0000000001
  
ORDER BY org.meter_id, org.graphic_unit_id, org.time_interval;

-- -- option to consider that sets/resets parallelism
-- -- Use this block to safely run memory-friendly queries
-- BEGIN;
-- -- Disable parallelism only for this session
-- SET max_parallel_workers_per_gather = 0;
-- -- Your heavy query here
-- SELECT ...
-- FROM matview1
-- JOIN matview2 ON ...;
-- -- Reset to default if needed before closing session
-- RESET max_parallel_workers_per_gather;
-- COMMIT;
