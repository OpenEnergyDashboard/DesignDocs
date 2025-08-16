-- OEDDailyTimeVaryingConversionsTestCases
-- npm run testData
-- *** Test Case 1: Test for varying conversion length ***
-- daily_readings_unit(meter_id = 1)
select * from daily_readings_unit where meter_id = 1 limit 5;

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
  (5, 1, 2.0, 0.0, '2021-06-01 00:00:00', '2021-06-01 06:00:00'),
  (5, 1, 4.0, 0.0, '2021-06-01 06:00:00', '2021-06-01 12:00:00'),
  (5, 1, 8.0, 0.0, '2021-06-01 12:00:00', '2021-06-02 00:00:00');

INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (5, 1, 1.0, 0.0, '-infinity', '2021-06-01 00:00:00'),
  (5, 1, 2.0, 0.0, '2021-06-01 00:00:00', '2021-06-01 06:00:00'),
  (5, 1, 4.0, 0.0, '2021-06-01 06:00:00', '2021-06-01 12:00:00'),
  (5, 1, 8.0, 0.0, '2021-06-01 12:00:00', '2021-06-02 00:00:00'),
  (5, 1, 1.0, 0.0, '2021-06-02 00:00:00', 'infinity');
  
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit WITH DATA; --7.384s
REFRESH MATERIALIZED VIEW meter_daily_readings_unit WITH DATA; --0.044s
-- meter_hourly_readings_unit > refresh with data
-- daily_readings_unit > refresh with data
-- select * from cik;

select meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'daily', 200, 200); --0.051s
select meter_line_readings_unit('{1}', 1, '2021-06-01 00:00:00', '2021-06-02 00:00:00', 'daily', 200, 200); --
-- Expected Result:
-- 1 * (((.25*2) + (.25*4) + (.50*8))) = 5.5

-- *** Test Case 2: Test for varying conversion length ***
-- *Similar to first test but the reading_rate is not 3
-- daily_readings_unit(meter_id = 1)
select * from daily_readings_unit where meter_id = 1;

-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: 5

TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time) --0.045s
VALUES 
  (5, 1, 2.0, 0.0, '2021-06-03 00:00:00', '2021-06-03 06:00:00'),
  (5, 1, 4.0, 0.0, '2021-06-03 06:00:00', '2021-06-03 12:00:00'),
  (5, 1, 8.0, 0.0, '2021-06-03 12:00:00', '2021-06-04 00:00:00');

INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time) -- 
VALUES 
  (5, 1, 1.0, 0.0, '-infinity', '2021-06-03 00:00:00'),
  (5, 1, 2.0, 0.0, '2021-06-03 00:00:00', '2021-06-03 06:00:00'),
  (5, 1, 4.0, 0.0, '2021-06-03 06:00:00', '2021-06-03 12:00:00'),
  (5, 1, 8.0, 0.0, '2021-06-03 12:00:00', '2021-06-04 00:00:00'),
  (5, 1, 1.0, 0.0, '2021-06-04 00:00:00', 'infinity');

REFRESH MATERIALIZED VIEW meter_hourly_readings_unit WITH DATA; --7.225s
REFRESH MATERIALIZED VIEW meter_daily_readings_unit WITH DATA; --0.041s
-- meter_hourly_readings_unit > refresh with data
-- daily_readings_unit > refresh with data
-- select * from cik;

-- Results:
select meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'daily', 200, 200); -- 0.046s
select meter_line_readings_unit('{1}', 1, '2021-06-03 00:00:00', '2021-06-04 00:00:00', 'daily', 200, 200); --
-- select * from cik;

-- Expected Result:
-- 3 * (((.25*2) + (.25*4) + (.50*8))) = 16.5

-- *** Test Case 3: Test conversion that overlap reading *** 
-- daily_readings_unit(meter_id = 1)
select * from daily_readings_unit where meter_id = 1;

-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: 5

TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (5, 1, 2.0, 0.0, '2021-06-03 00:00:00', '2021-06-04 08:00:00'),
  (5, 1, 4.0, 0.0, '2021-06-04 08:00:00', '2021-06-06 00:00:00');
  -- (5, 1, 4.0, 0.0, '2021-06-04 06:08:00', '2021-06-06 00:00:00');

INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (5, 1, 1.0, 0.0, '-infinity', '2021-06-03 00:00:00'),
  (5, 1, 2.0, 0.0, '2021-06-03 00:00:00', '2021-06-04 08:00:00'),
  (5, 1, 4.0, 0.0, '2021-06-04 08:00:00', '2021-06-06 00:00:00'),
  (5, 1, 1.0, 0.0, '2021-06-06 00:00:00', 'infinity');

REFRESH MATERIALIZED VIEW meter_hourly_readings_unit WITH DATA; --7.159s
REFRESH MATERIALIZED VIEW meter_daily_readings_unit WITH DATA; --0.039s
-- meter_hourly_readings_unit > refresh with data
-- daily_readings_unit > refresh with data
-- select * from cik;

select meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'daily', 200, 200); -- 0.053, 0.072
select meter_line_readings_unit('{1}', 1, '2021-06-03 00:00:00', '2021-06-06 00:00:00', 'daily', 200, 200); -- 0.074, 0.058
-- Expected Result:
-- 4 * ((.33333*2) + (.66666*4)) = 13.333  *for middle row

-- --record
-- "["1","6","6","6","2021-06-03 00:00:00","2021-06-04 00:00:00"]"
-- "["1","13.333333333333334","8","16","2021-06-04 00:00:00","2021-06-05 00:00:00"]"
-- "["1","20","20","20","2021-06-05 00:00:00","2021-06-06 00:00:00"]"

-- *** Test Case 4: Test conversion that overlap reading ***
-- daily_readings_unit(meter_id = 1)
select * from daily_readings_unit where meter_id = 1;

-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: 5

TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (5, 1, 2.0, 0.0, '2021-06-03 12:00:00', '2021-06-04 06:00:00'),
  (5, 1, 4.0, 0.0, '2021-06-04 06:00:00', '2021-06-05 12:00:00');

INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (5, 1, 1.0, 0.0, '-infinity', '2021-06-03 12:00:00'),
  (5, 1, 2.0, 0.0, '2021-06-03 12:00:00', '2021-06-04 06:00:00'),
  (5, 1, 4.0, 0.0, '2021-06-04 06:00:00', '2021-06-05 12:00:00'),
  (5, 1, 1.0, 0.0, '2021-06-05 12:00:00', 'infinity');
  
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit WITH DATA; --8.373s
REFRESH MATERIALIZED VIEW meter_daily_readings_unit WITH DATA; --0.787s
-- meter_hourly_readings_unit > refresh with data
-- daily_readings_unit > refresh with data
-- 
-- select * from cik;

select meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'daily', 200, 200); -- 0.058
select meter_line_readings_unit('{1}', 1, '2021-06-03 00:00:00', '2021-06-06 00:00:00', 'daily', 200, 200); -- 0.074, 0.060
-- Expected Result:
-- 4 * ((.25*2) + (.75*4)) =  14  *middle row
-- 5 * ((.5*4) + (.5*1)) =  12.5  *last row 

-- -- record using cik without -inifinty/+infinity 
-- "["1","6","6","6","2021-06-03 00:00:00","2021-06-04 00:00:00"]"
-- "["1","14","8","16","2021-06-04 00:00:00","2021-06-05 00:00:00"]"
-- "["1","20","20","20","2021-06-05 00:00:00","2021-06-06 00:00:00"]"

-- -- record with cik delimied by -inifinty/+infinity
-- "["1","4.5","3","6","2021-06-03 00:00:00","2021-06-04 00:00:00"]"
-- "["1","14","8","16","2021-06-04 00:00:00","2021-06-05 00:00:00"]"
-- "["1","12.5","5","20","2021-06-05 00:00:00","2021-06-06 00:00:00"]"  <-- this days value changes

-- -- record
-- "["1","1","1","1","2021-06-01 00:00:00","2021-06-02 00:00:00"]"
-- "["1","2","1.75","2.25","2021-06-02 00:00:00","2021-06-03 00:00:00"]"
-- "["1","4.5","3","6","2021-06-03 00:00:00","2021-06-04 00:00:00"]"
-- "["1","14","8","16","2021-06-04 00:00:00","2021-06-05 00:00:00"]"
-- "["1","12.5","5","20","2021-06-05 00:00:00","2021-06-06 00:00:00"]"