-- The following script will give the meters and groups for the website data fixed values so the color should never change.

-- To run the script, open a terminal, cd to the main OED directory, and type:
-- cat <location of this script>/websiteData.sql | docker compose exec database psql -U oed
-- The output should be the following set of lines where one set per meter so 8 in total where the UPDATE before the final DELETE
-- will be followed by the number of readings for that meter. The other UPDATES may not be zero if that meter is used for groups.
-- INSERT 0 1
-- UPDATE 0
-- UPDATE 0
-- UPDATE 0
-- UPDATE 0
-- UPDATE 5
-- DELETE 1
-- and groups will have this ouput for each one (3 sets in total where values may differ):
-- INSERT 0 1
-- UPDATE 1
-- UPDATE 0
-- UPDATE 2
-- DELETE 1


-- To be safe, they numbering starts at 10000.
-- This script must be updated if the columns in the meters and/or groups table is changed.

-- This fixes each meter number to start at 10012 and increase by 1 for the next meter. The code in
-- /Users/steve/OED/OED/src/client/app/utils/getGraphColor.ts subtracts 1 from the id and then does a modulo
-- 47 to get the color. 10012 gives 0 so starts in first index of the color array. Note groups start at the other
-- end of the array so they use the same values.
-- The names do not have the starting M from the script that puts in the meters so add that in.
-- To avoid foreign key constraint issues, the current meter is duplicated where the id is set to the desired value.
-- After creating the new meter, it then updates all the foreign keys to use the new meter id. The final step is to
-- delete the old meter.
--  There should not be any baselines but do it to be complete. Most foreign keys are not present but process them all.

-- Meter 1
insert into meters (id, name, ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp) (select 10012, concat('M', name), ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, concat('M', identifier), note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp from meters where name in ('eter 1'));
update baseline set meter_id = 10012 where meter_id in (select id from meters where name in ('eter 1'));
update groups_immediate_meters set meter_id = 10012 where meter_id in (select id from meters where name in ('eter 1'));
update meters_immediate_children set child_id = 10012 where child_id in (select id from meters where name in ('eter 1'));
update meters_immediate_children set parent_id = 10012 where parent_id in (select id from meters where name in ('eter 1'));
update readings set meter_id = 10012 where meter_id in (select id from meters where name in ('eter 1'));
delete from meters where id in (select id from meters where name in ('eter 1'));
-- Meter 2
insert into meters (id, name, ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp) (select 10013, concat('M', name), ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, concat('M', identifier), note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp from meters where name in ('eter 2'));
update baseline set meter_id = 10013 where meter_id in (select id from meters where name in ('eter 2'));
update groups_immediate_meters set meter_id = 10013 where meter_id in (select id from meters where name in ('eter 2'));
update meters_immediate_children set child_id = 10013 where child_id in (select id from meters where name in ('eter 2'));
update meters_immediate_children set parent_id = 10013 where parent_id in (select id from meters where name in ('eter 2'));
update readings set meter_id = 10013 where meter_id in (select id from meters where name in ('eter 2'));
delete from meters where id in (select id from meters where name in ('eter 2'));
-- Meter A
insert into meters (id, name, ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp) (select 10014, concat('M', name), ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, concat('M', identifier), note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp from meters where name in ('eter A'));
update baseline set meter_id = 10014 where meter_id in (select id from meters where name in ('eter A'));
update groups_immediate_meters set meter_id = 10014 where meter_id in (select id from meters where name in ('eter A'));
update meters_immediate_children set child_id = 10014 where child_id in (select id from meters where name in ('eter A'));
update meters_immediate_children set parent_id = 10014 where parent_id in (select id from meters where name in ('eter A'));
update readings set meter_id = 10014 where meter_id in (select id from meters where name in ('eter A'));
delete from meters where id in (select id from meters where name in ('eter A'));
-- Meter B
insert into meters (id, name, ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp) (select 10015, concat('M', name), ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, concat('M', identifier), note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp from meters where name in ('eter B'));
update baseline set meter_id = 10015 where meter_id in (select id from meters where name in ('eter B'));
update groups_immediate_meters set meter_id = 10015 where meter_id in (select id from meters where name in ('eter B'));
update meters_immediate_children set child_id = 10015 where child_id in (select id from meters where name in ('eter B'));
update meters_immediate_children set parent_id = 10015 where parent_id in (select id from meters where name in ('eter B'));
update readings set meter_id = 10015 where meter_id in (select id from meters where name in ('eter B'));
delete from meters where id in (select id from meters where name in ('eter B'));
-- Meter C
insert into meters (id, name, ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp) (select 10016, concat('M', name), ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, concat('M', identifier), note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp from meters where name in ('eter C'));
update baseline set meter_id = 10016 where meter_id in (select id from meters where name in ('eter C'));
update groups_immediate_meters set meter_id = 10016 where meter_id in (select id from meters where name in ('eter C'));
update meters_immediate_children set child_id = 10016 where child_id in (select id from meters where name in ('eter C'));
update meters_immediate_children set parent_id = 10016 where parent_id in (select id from meters where name in ('eter C'));
update readings set meter_id = 10016 where meter_id in (select id from meters where name in ('eter C'));
delete from meters where id in (select id from meters where name in ('eter C'));
-- Meter D
insert into meters (id, name, ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp) (select 10017, concat('M', name), ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, concat('M', identifier), note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp from meters where name in ('eter D'));
update baseline set meter_id = 10017 where meter_id in (select id from meters where name in ('eter D'));
update groups_immediate_meters set meter_id = 10017 where meter_id in (select id from meters where name in ('eter D'));
update meters_immediate_children set child_id = 10017 where child_id in (select id from meters where name in ('eter D'));
update meters_immediate_children set parent_id = 10017 where parent_id in (select id from meters where name in ('eter D'));
update readings set meter_id = 10017 where meter_id in (select id from meters where name in ('eter D'));
delete from meters where id in (select id from meters where name in ('eter D'));
-- Meter 7
insert into meters (id, name, ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp) (select 10018, concat('M', name), ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, concat('M', identifier), note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp from meters where name in ('eter 7'));
update baseline set meter_id = 10018 where meter_id in (select id from meters where name in ('eter 7'));
update groups_immediate_meters set meter_id = 10018 where meter_id in (select id from meters where name in ('eter 7'));
update meters_immediate_children set child_id = 10018 where child_id in (select id from meters where name in ('eter 7'));
update meters_immediate_children set parent_id = 10018 where parent_id in (select id from meters where name in ('eter 7'));
update readings set meter_id = 10006 where meter_id in (select id from meters where name in ('eter 7'));
delete from meters where id in (select id from meters where name in ('eter 7'));
-- Meter 8
insert into meters (id, name, ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp) (select 10019, concat('M', name), ipaddress, enabled, displayable, meter_type, default_timezone_meter, gps, concat('M', identifier), note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort , end_only_time, reading, start_timestamp, end_timestamp from meters where name in ('eter 8'));
update baseline set meter_id = 10019 where meter_id in (select id from meters where name in ('eter 8'));
update groups_immediate_meters set meter_id = 10019 where meter_id in (select id from meters where name in ('eter 8'));
update meters_immediate_children set child_id = 10019 where child_id in (select id from meters where name in ('eter 8'));
update meters_immediate_children set parent_id = 10019 where parent_id in (select id from meters where name in ('eter 8'));
update readings set meter_id = 10019 where meter_id in (select id from meters where name in ('eter 8'));
delete from meters where id in (select id from meters where name in ('eter 8'));

-- The next step is to fix up the group ids in a similar way to the meters.
-- Group 1 & 2
insert into groups (id, name, displayable, gps, note, area) (select 10012, concat('G', name), displayable, gps, note, area from groups where name in ('roup 1 & 2'));
update groups_immediate_children set child_id = 10012 where child_id in (select id from groups where name in ('roup 1 & 2'));
update groups_immediate_children set parent_id = 10012 where parent_id in (select id from groups where name in ('roup 1 & 2'));
update groups_immediate_meters set group_id = 10012 where group_id in (select id from groups where name in ('roup 1 & 2'));
delete from groups where id in (select id from groups where name in ('roup 1 & 2'));
-- Group 7 & 8
insert into groups (id, name, displayable, gps, note, area) (select 10013, concat('G', name), displayable, gps, note, area from groups where name in ('roup 7 & 8'));
update groups_immediate_children set child_id = 10013 where child_id in (select id from groups where name in ('roup 7 & 8'));
update groups_immediate_children set parent_id = 10013 where parent_id in (select id from groups where name in ('roup 7 & 8'));
update groups_immediate_meters set group_id = 10013 where group_id in (select id from groups where name in ('roup 7 & 8'));
delete from groups where id in (select id from groups where name in ('roup 7 & 8'));
-- Group 1 & 2 & 7 & 8
insert into groups (id, name, displayable, gps, note, area) (select 10014, concat('G', name), displayable, gps, note, area from groups where name in ('roup 1 & 2 & 7 & 8'));
update groups_immediate_children set child_id = 10014 where child_id in (select id from groups where name in ('roup 1 & 2 & 7 & 8'));
update groups_immediate_children set parent_id = 10014 where parent_id in (select id from groups where name in ('roup 1 & 2 & 7 & 8'));
update groups_immediate_meters set group_id = 10014 where group_id in (select id from groups where name in ('roup 1 & 2 & 7 & 8'));
delete from groups where id in (select id from groups where name in ('roup 1 & 2 & 7 & 8'));
