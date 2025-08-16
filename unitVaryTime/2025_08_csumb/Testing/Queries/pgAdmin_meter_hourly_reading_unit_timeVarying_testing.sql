-- testing meter_hourly_readings_unit and meter_hourly_readings_unit_vb
-- ScratchPad
-- https://docs.google.com/spreadsheets/d/18LYIIo5OrNHqXtRhGUy2amLpx_XdXKBHxL24dzr0n_M/edit?gid=0#gid=0
-- using PG&E bill as test data


INSERT INTO public.readings(
	meter_id, reading, start_timestamp, end_timestamp)
	VALUES (?, ?, ?, ?);
-- Step 0
-- create meter from GUI (localhost:3000) using Electric Utility kWh as template
--   Using the GUI to create a meter enforces data validation via checks
-- There are other methods for creating a meter but these methods bypass checks:
--   cloning a meter record from meters table
--   exporting a meter from GUI to CSV, modifying CSV and then uploading CSV
-- new meter Electric Utility kWh 30 (30 minute), id = 28

-- Step 1
-- insert entries for new meter in readings
INSERT INTO public.readings(meter_id, reading, start_timestamp, end_timestamp)
VALUES (28, 1, '2020-01-01 00:00:00', '2020-01-01 00:30:00');

INSERT INTO public.readings(meter_id, reading, start_timestamp, end_timestamp)
VALUES (28, 2, '2020-01-01 00:30:00', '2020-01-01 01:00:00');

INSERT INTO public.readings(meter_id, reading, start_timestamp, end_timestamp)
VALUES (28, 3, '2020-01-01 01:00:00', '2020-01-01 01:30:00');

INSERT INTO public.readings(meter_id, reading, start_timestamp, end_timestamp)
VALUES (28, 4, '2020-01-01 01:30:00', '2020-01-01 02:00:00');

INSERT INTO public.readings(meter_id, reading, start_timestamp, end_timestamp)
VALUES (28, 5, '2020-01-01 02:00:00', '2020-01-01 02:30:00');

INSERT INTO public.readings(meter_id, reading, start_timestamp, end_timestamp)
VALUES (28, 6, '2020-01-01 02:30:00', '2020-01-01 03:00:00');

-- Step 3 
-- create entries in CIK
-- clear CIK, insert entries
-- refresh hourly_readings_unit, meter_hourly_readings_unit, meter_hourly_readings_unit_vB
TRUNCATE TABLE cik; -- faster than DELETE when you do not want old rows; remind Steve about changing to this instead of wiping/creating database

-- CIK table rules
-- all conversions go from -inifity to +infity
-- slices do not overlap 

-- single conversion per reading with cik overlapping readings
-- (reading are inside the cik)
INSERT INTO public.cik(
	source_id, destination_id, slope, intercept, start_time, end_time)
	VALUES (4, 1, 1, 0, '2020-01-01 00:00:00', '2020-01-01 01:00:00');
INSERT INTO public.cik(
	source_id, destination_id, slope, intercept, start_time, end_time)
	VALUES (4, 1, 2, 0, '2020-01-01 01:00:00', '2020-01-01 02:00:00');
INSERT INTO public.cik(
	source_id, destination_id, slope, intercept, start_time, end_time)
	VALUES (4, 1, 1, 0, '2020-01-01 02:00:00', '2020-01-01 03:00:00');

-- multiple conversions per reading with cik overlapping readings
-- (reading are inside the cik)
-- CIK cannot overlap
-- INSERT INTO public.cik(
-- 	source_id, destination_id, slope, intercept, start_time, end_time)
-- 	VALUES (4, 1, 1, 0, '2020-01-01 00:00:00', '2020-01-01 03:00:00');
-- INSERT INTO public.cik(
-- 	source_id, destination_id, slope, intercept, start_time, end_time)
-- 	VALUES (4, 1, 2, 0, '2020-01-01 01:00:00', '2020-01-01 02:00:00');

-- multiple conversions per reading with readings overlapping cik
-- (cik is inside the reading)
INSERT INTO public.cik(
	source_id, destination_id, slope, intercept, start_time, end_time)
	VALUES (4, 1, 1, 0, '2020-01-01 00:00:00', '2020-01-01 00:15:00');
	
INSERT INTO public.cik(
	source_id, destination_id, slope, intercept, start_time, end_time)
	VALUES (4, 1, 2, 0, '2020-01-01 00:15:00', '2020-01-01 00:45:00');
	
INSERT INTO public.cik(
	source_id, destination_id, slope, intercept, start_time, end_time)
	VALUES (4, 1, 1, 0, '2020-01-01 00:45:00', '2020-01-01 01:00:00');

INSERT INTO public.cik(
	source_id, destination_id, slope, intercept, start_time, end_time)
	VALUES (4, 1, 1, 0, '2020-01-01 01:00:00', '2020-01-01 03:00:00');

-- Step 4
-- verify results
select meter_id, (reading * 1 - 0) as reading, start_timestamp, end_timestamp from readings where meter_id = 28;
select * from cik limit 5;

select * from hourly_readings_unit where meter_id = 28;
select * from meter_hourly_readings_unit where meter_id = 28;
select * from meter_hourly_readings_unit_vb where meter_id = 28;


-- misc. stuff
select * from readings where meter_id = 22 and reading = '0.6533140607923507';
select * from conversions order by source_id;
select * from cik;
select * from units order by id;