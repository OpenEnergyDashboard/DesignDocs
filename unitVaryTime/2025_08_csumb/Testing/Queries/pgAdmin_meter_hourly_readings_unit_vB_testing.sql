-- all records returned 1037578 in 2.357s
-- meter_id = 25, returns 157896 , "Sin Amp 1 kWh" in 1.028s
-- updatet CIK table then refresh m-views to be compared

REFRESH MATERIALIZED VIEW meter_hourly_readings_unit_vB WITH DATA; -- #.##s
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit WITH DATA; -- #.##s

SELECT meter_id, reading_rate, max_rate, min_rate, time_interval, graphic_unit_id
	FROM public.meter_hourly_readings_unit_vB
	where meter_id = 25
	order by meter_id, time_interval, graphic_unit_id;

-- to be developed
-- select meter_line_readings_unit_vB('{25}', 1, '-infinity', 'infinity', 'hourly', 200, 200);

-- all records returned 1037578 in 2.290s
-- meter_id = 25, returns 157896, "Sin Amp 1 kWh" om 1.028s
SELECT meter_id, reading_rate, min_rate, max_rate, time_interval, graphic_unit_id
	FROM public.meter_hourly_readings_unit
	where meter_id = 25
	order by meter_id, time_interval, graphic_unit_id;

-- select meter_line_readings_unit('{25}', 1, '-infinity', 'infinity', 'hourly', 200, 200);


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

FROM meter_hourly_readings_unit AS org
FULL OUTER JOIN meter_hourly_readings_unit_vB AS vB
-- FROM meter_daily_readings_unit_v2 AS org
-- FULL OUTER JOIN meter_daily_readings_unit_v2B AS vB
  ON org.meter_id = vB.meter_id
  AND org.graphic_unit_id = vB.graphic_unit_id
  AND org.time_interval = vB.time_interval

WHERE
  -- show matching rows
  -- org.reading_rate = vB.reading_rate
  -- AND org.min_rate = vB.min_rate
  -- AND org.max_rate = vB.max_rate
  
  -- show differences
  -- org.reading_rate IS DISTINCT FROM vB.reading_rate
  -- OR org.min_rate IS DISTINCT FROM vB.min_rate
  -- OR org.max_rate IS DISTINCT FROM vB.max_rate
  
  -- reduce precision, account for rounding errors
  ABS(org.reading_rate - vB.reading_rate) > 0.0000000001
  OR ABS(org.min_rate - vB.min_rate) > 0.0000000001
  OR ABS(org.max_rate - vB.max_rate) > 0.0000000001
ORDER BY org.meter_id, org.graphic_unit_id, org.time_interval;

-- look at meters, unit and conversion where slope != 0
-- "testData": "node -e 'require(\"./src/server/data/automatedTestingData.js\").insertSpecialUnitsConversionsMetersGroups()'",
select * from readings where meter_id in (13, 14); -- 13 "Temp Fahrenheit 0-212", 14 "Temp Fahrenheit in Celsius"
select id, name from meters order by id;
select * from conversions; -- source_id = 10, destination_id = 6 is only conversion with slope != 0

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
