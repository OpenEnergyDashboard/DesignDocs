-- OEDHourlyTimeVaryingConversionsTestCases
-- npm run testData
-- *** Test Case 1: Test for varying conversion length ***
-- hourly_readings_unit(meter_id = 1)
select * from hourly_readings_unit where meter_id = 1 limit 5;

-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: ?

select u.id as source_id, u.name, m.id, m.name, m.unit_id as meter_unit_id
from units u inner join meters m on u.id = m.unit_id 
where m.name = 'Electric Utility kWh' order by m.id;
-- select * from meters order by id;
-- select * from units order by id;
-- 5	"Electric_Utility"

TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (5, 1, 2.0, 0.0, '2021-06-01 00:00:00', '2021-06-01 00:15:00'),
  (5, 1, 4.0, 0.0, '2021-06-01 00:15:00', '2021-06-01 00:30:00'),
  (5, 1, 8.0, 0.0, '2021-06-01 00:30:00', '2021-06-01 01:00:00');
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit WITH DATA;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY meter_hourly_readings_unit WITH DATA;
-- ERROR:  cannot refresh materialized view "public.meter_hourly_readings_unit" concurrently
-- HINT:  Create a unique index with no WHERE clause on one or more columns of the materialized view.
-- meter_hourly_readings_unit > refresh with data
-- select * from cik;

select meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'hourly', 200, 200);

-- Expected Result:
-- 1 * (((.25*2) + (.25*4) + (.50*8))) = 5.5

-- *** Test Case 2: Test for varying conversion length ***
-- *Similar to first test but the reading_rate is not 3
-- hourly_readings_unit(meter_id = 1)
select * from hourly_readings_unit where meter_id = 1 and lower(time_interval) >= '2021-06-03'::timestamp limit 6;
-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: 5

-- TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (5, 1, 2.0, 0.0, '2021-06-03 00:00:00', '2021-06-03 00:15:00'),
  (5, 1, 4.0, 0.0, '2021-06-03 00:15:00', '2021-06-03 00:30:00'),
  (5, 1, 8.0, 0.0, '2021-06-03 00:30:00', '2021-06-03 01:00:00');
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit WITH DATA;
-- meter_hourly_readings_unit > refresh with data

-- Results:
select meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'hourly', 200, 200);
-- select * from cik;

-- Expected Result:
-- 3 * (((.25*2) + (.25*4) + (.50*8))) = 16.5

-- *** Test Case 3: Test conversion that overlap reading *** 
-- hourly_readings_unit(meter_id = 1)
select * from hourly_readings_unit where meter_id = 1 and lower(time_interval) >= '2021-06-03'::timestamp limit 6;

-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: 5

TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (5, 1, 3.0, 0.0, '2021-06-03 00:00:00', '2021-06-03 01:20:00'),
  (5, 1, 7.0, 0.0, '2021-06-03 01:20:00', '2021-06-03 03:00:00');
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit WITH DATA;
-- meter_hourly_readings_unit > refresh with data
select meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'hourly', 200, 200);

-- Expected Result:
-- 3 * ((.33333*3) + (.66666*7)) = ~17
-- * For middle reading

-- --record
-- "["1","9","9","9","2021-06-03 00:00:00","2021-06-03 01:00:00"]"
-- "["1","17","17","17","2021-06-03 01:00:00","2021-06-03 02:00:00"]"
-- "["1","21","21","21","2021-06-03 02:00:00","2021-06-03 03:00:00"]"
