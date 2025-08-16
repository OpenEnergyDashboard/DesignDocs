-- BEGIN;
-- OEDRawTimeVaryingConversionsTestCases
-- npm run testData

-- *** Test Case 1: Test for varying conversion length ***
-- meter_raw_readings_unit (meter_id = 1)
-- select * from readings where meter_id = 1;

-- meter_id, 	reading, 	start_timestamp, 		end_timestamp
-- 1			24			"2021-06-01 00:00:00"	"2021-06-02 00:00:00"
-- 1			21			"2021-06-02 00:00:00"	"2021-06-02 12:00:00"
-- 1			27			"2021-06-02 12:00:00"	"2021-06-03 00:00:00"
-- 1			72			"2021-06-03 00:00:00"	"2021-06-04 00:00:00"
-- 1			96			"2021-06-04 00:00:00"	"2021-06-05 00:00:00"
-- 1			120			"2021-06-05 00:00:00"	"2021-06-06 00:00:00"

-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: ?

DO $$ BEGIN
  RAISE NOTICE '---[0] Verify meter_id = 3 for Electric_Utility ';
END $$;

select u.id as source_id, u.name, m.id, m.name, m.unit_id as meter_unit_id
from units u inner join meters m on u.id = m.unit_id 
where m.name = 'Electric Utility kWh' order by m.id;
-- 3	"Electric_Utility"

DO $$ BEGIN
  RAISE NOTICE '---[1] Resetting CIK conversions for meter_id = 1';
END $$;

TRUNCATE TABLE cik;

DO $$ BEGIN
  RAISE NOTICE '---[2] Inserting CIK test data';
END $$;

INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (3, 1, 1.0, 0.0, '-infinity', '2021-05-30 00:00:00'),
  (3, 1, 1.0, 0.0, '2021-05-30 00:00:00', '2021-06-01 00:15:00'),
  (3, 1, 2.0, 0.0, '2021-06-01 00:15:00', '2021-06-01 00:30:00'),
  (3, 1, 3.0, 0.0, '2021-06-01 00:30:00', '2021-06-01 00:45:00'),
  (3, 1, 4.0, 0.0, '2021-06-01 00:45:00', '2021-10-01 01:00:00'),
  (3, 1, 1.0, 0.0, '2021-10-01 01:00:00', 'infinity');

DO $$ BEGIN
  RAISE NOTICE '---[3] Refreshing materialized views';
END $$;

REFRESH MATERIALIZED VIEW meter_raw_readings_unit WITH DATA; -- 4.757s
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit_v3 WITH DATA; -- 3.209s
-- meter_raw_readings_unit > refresh with data

DO $$ BEGIN
  RAISE NOTICE '---[4] Checking cik conversions';
END $$;

select * from cik;
-- source_id, 	destination_id, slope, intercept,	start_time, 			end_time
-- 3				1				1	0			"-infinity"				"2021-05-30 00:00:00"
-- 3				1				1	0			"2021-05-30 00:00:00"	"2021-06-01 00:15:00"
-- 3				1				2	0			"2021-06-01 00:15:00"	"2021-06-01 00:30:00"
-- 3				1				3	0			"2021-06-01 00:30:00"	"2021-06-01 00:45:00"
-- 3				1				4	0			"2021-06-01 00:45:00"	"2021-10-01 01:00:00"
-- 3				1				1	0			"2021-10-01 01:00:00"	"infinity"

DO $$ BEGIN
  RAISE NOTICE '---[5] Checking meter_raw_readings_unit output';
END $$;

select * from meter_raw_readings_unit where meter_id = 1; -- 
-- meter_id, 	reading_rate, 	time_interval, 										graphic_unit_id
-- 1			3.9375			["2021-06-01 00:00:00","2021-06-02 00:00:00"]		1
-- 1			7				["2021-06-02 00:00:00","2021-06-02 12:00:00"]		1
-- 1			9				["2021-06-02 12:00:00","2021-06-03 00:00:00"]		1
-- 1			12				["2021-06-03 00:00:00","2021-06-04 00:00:00"]		1
-- 1			16				["2021-06-04 00:00:00","2021-06-05 00:00:00"]		1
-- 1			20				["2021-06-05 00:00:00","2021-06-06 00:00:00"]		1

-- select meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'raw', 200, 200);
-- select meter_line_readings_unit('{1}', 1, '2021-05-30 00:00:00', '2021-10-01 01:00:00', 'raw', 200, 200);

-- Expected Result:
 -- 24/24 * (0.25 * 1 + 0.25 * 2 + 0.25 * 3 + 23.25 * 4) / 24 = 3.9375 -- 1st row
 -- 23.25 * 4 -> 23.25 hours remaing in the day
 -- 21/12 * 4 -- 2nd row
 -- 
 -- quanity reading of 24 spanedd across a day giving it an hourly reading of 24/24 = 1

DO $$ BEGIN
  RAISE NOTICE '---[6] Checking expected rates';
END $$;

SELECT 
    r.meter_id, r.reading, r.start_timestamp AS reading_start, r.end_timestamp AS reading_end,
    c.source_id, c.destination_id, c.slope, c.intercept, c.start_time AS cik_start, c.end_time AS cik_end,
    tsrange(m.start_timestamp, m.end_timestamp, '[)') as m_time_interval,m.reading_rate,
	  (r.reading * c.slope + c.intercept) / 
        (EXTRACT(EPOCH FROM r.end_timestamp - r.start_timestamp) / 3600) AS expected_reading_rate
FROM 
    readings r
LEFT JOIN cik c
    ON c.destination_id = r.meter_id AND tsrange(r.start_timestamp, r.end_timestamp, '[)') && tsrange(c.start_time, c.end_time, '[)')
LEFT JOIN meter_raw_readings_unit m
    ON m.meter_id = r.meter_id AND tsrange(r.start_timestamp, r.end_timestamp, '[)') && tsrange(m.start_timestamp, m.end_timestamp, '[)')--m.time_interval
where r.meter_id = 1
ORDER BY r.start_timestamp, c.start_time, tsrange(m.start_timestamp, m.end_timestamp, '[)')--m.time_interval;

-- meter_hourly_readings_unit_v3 needs where clause similar to tsrange(r.start_timestamp, r.end_timestamp, '[)') && tsrange(m.start_timestamp, m.end_timestamp, '[)')
--    to capture overlap

-- COMMIT;

-- *** Test Case 2: Test for varying conversion length ***
-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: 3, quantity

-- CIK:
TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (3, 1, 1.0, 0.0, '-infinity', '2021-06-01 00:00:00'),
  (3, 1, 2.0, 0.0, '2021-06-01 00:00:00', '2021-06-01 03:00:00'),
  (3, 1, 1.0, 0.0, '2021-06-01 03:00:00', 'infinity');

REFRESH MATERIALIZED VIEW meter_raw_readings_unit WITH DATA; -- 4.757s
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit_v3 WITH DATA; -- 3.209s

-- Results:
select * from meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'raw', 200, 200);

-- *** Test Case 3: Test for varying conversion length ***
-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: 3, quantity

-- CIK:
TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (3, 1, 1.0, 0.0, '-infinity', '2021-06-01 00:00:00'),
  (3, 1, 2.0, 0.0, '2021-06-01 00:00:00', '2021-06-01 03:00:00'),
  (3, 1, 10.0, 0.0, '2021-06-01 03:00:00', '2021-06-02 00:00:00'),
  (3, 1, 1.0, 0.0, '2021-06-02 00:00:00', 'infinity');

select * from cik;

REFRESH MATERIALIZED VIEW meter_raw_readings_unit WITH DATA; -- 4.757s
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit_v3 WITH DATA; -- 3.209s

select * from meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'raw', 200, 200);

--Expected results for 1st row: reading_rate = 9

-- *** Test Case 3.5: Test for varying conversion length ***
-- Meter:
-- Id: 1, Electric Utility kWh, unit_id: 3, quantity

-- CIK:
TRUNCATE TABLE cik;
INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
VALUES 
  (3, 1, 1.0, 0.0, '-infinity', '2021-06-01 00:00:00'),
  (3, 1, 2.0, 5.0, '2021-06-01 00:00:00', '2021-06-01 03:00:00'),
  (3, 1, 10.0, 20.0, '2021-06-01 03:00:00', '2021-06-02 00:00:00'),
  (3, 1, 1.0, 0.0, '2021-06-02 00:00:00', 'infinity');

select * from cik;

REFRESH MATERIALIZED VIEW meter_raw_readings_unit WITH DATA; -- 4.757s
REFRESH MATERIALIZED VIEW meter_hourly_readings_unit_v3 WITH DATA; -- 3.209s

select * from meter_line_readings_unit('{1}', 1, '-infinity', 'infinity', 'raw', 200, 200);

