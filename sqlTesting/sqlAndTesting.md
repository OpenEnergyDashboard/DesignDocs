# SQL commands and testing information

## Introduction

This is a collect of information on useful SQL commands for looking at the database and for using with testing for correct functioning. It can allow for loading of special data to see how it functions. It also shows SQL commands that my be interesting and useful in other contexts and modifiable.

It is provided for the record and for potential use. Some items may be out of date or have issues as they have not been retested. Some assume the basic test data has been loaded.

This is only the first version with limited information. More should be coming in the future. If you have ideas for additions/changes then please make a pull request.

## Wiping OED DB data

### These should work after time-varying changes

- Remove all readings, groups, meters, conversions, units and the cik data.

```sql
delete from readings;
delete from groups_immediate_meters;
delete from groups_immediate_children;
delete from groups;
delete from meters;
delete from conversion_segments;
delete from conversions;
delete from cik;
delete from cik_vary;
delete from units;
```

- Purge suffix units. Works after time-varying work. This was used during some testing where they seemed to be causing issues.

```sql
DELETE FROM CONVERSION_SEGMENTS WHERE DESTINATION_ID IN ( SELECT ID FROM UNITS WHERE SUFFIX != '' OR TYPE_OF_UNIT = 'suffix' );
DELETE FROM CONVERSION_SEGMENTS WHERE SOURCE_ID IN ( SELECT ID FROM UNITS WHERE SUFFIX != '' OR TYPE_OF_UNIT = 'suffix' );
DELETE FROM CONVERSIONS WHERE DESTINATION_ID IN ( SELECT ID FROM UNITS WHERE SUFFIX != '' OR TYPE_OF_UNIT = 'suffix' );
DELETE FROM CONVERSIONS WHERE SOURCE_ID IN ( SELECT ID FROM UNITS WHERE SUFFIX != '' OR TYPE_OF_UNIT = 'suffix' );
DELETE FROM CIK;
DELETE FROM READINGS WHERE METER_ID IN ( SELECT ID FROM METERS WHERE DEFAULT_GRAPHIC_UNIT IN ( SELECT ID FROM UNITS WHERE SUFFIX != '' OR TYPE_OF_UNIT = 'suffix' ) );
DELETE FROM METERS WHERE DEFAULT_GRAPHIC_UNIT IN ( SELECT ID FROM UNITS WHERE SUFFIX != '' OR TYPE_OF_UNIT = 'suffix' );
DELETE FROM UNITS WHERE SUFFIX != '' OR TYPE_OF_UNIT = 'suffix';
```

- Remove all units, conversions, ... but the Water Gallon/gallon test data. This was done to allow the system to only have one meter and set of conversions to limit the items being worked on. Probably easier to delete them all and just recreate ones wanted.

```sql
DELETE FROM CONVERSION_SEGMENTS WHERE SOURCE_ID NOT IN ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) OR DESTINATION_ID NOT IN ( SELECT ID FROM UNITS WHERE NAME = 'gallon' );
DELETE FROM CONVERSIONS WHERE SOURCE_ID NOT IN ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) OR DESTINATION_ID NOT IN ( SELECT ID FROM UNITS WHERE NAME = 'gallon' );
DELETE FROM READINGS WHERE METER_ID NOT IN ( SELECT ID FROM METERS WHERE NAME = 'Water Gallon');
delete from groups_immediate_meters;
delete from groups_immediate_children;
delete from groups;
DELETE FROM METERS WHERE ID NOT IN ( SELECT ID FROM METERS WHERE NAME = 'Water Gallon');
DELETE FROM CIK WHERE SOURCE_ID NOT IN ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) OR DESTINATION_ID NOT IN ( SELECT ID FROM UNITS WHERE NAME = 'gallon' );
DELETE FROM CIK_VARY WHERE SOURCE_ID NOT IN ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) OR DESTINATION_ID NOT IN ( SELECT ID FROM UNITS WHERE NAME = 'gallon' );
DELETE FROM UNITS WHERE ID NOT IN ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) AND ID NOT IN ( SELECT ID FROM UNITS WHERE NAME = 'gallon' );
```

- Make water (see previous example) have 2 segments (no pattern) where remove all other ones if they exist:

```sql
DELETE FROM CIK;
DELETE FROM CIK_VARY;
DELETE FROM CONVERSION_SEGMENTS;
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ), NULL, 2, 0, '-infinity', '2021-06-03 00:00:00', 'segment 1 Water Gallon -> gallon' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ), NULL, 3, 0, '2021-06-03 00:00:00', 'infinity', 'segment 2 Water Gallon -> gallon' );
```

## Time varying

- Change the end time of the one segment of the test data for Water Gallon/gallon. Assumes such a conversion segment exists.

```sql
UPDATE CONVERSION_SEGMENTS SET END_TIME = '2021-06-06 00:00:00' WHERE SOURCE_ID IN ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) AND DESTINATION_ID IN ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ) AND START_TIME = '-infinity' AND END_TIME = 'infinity';
```

- This uses the standard test data to change Water_Gallon meter to have 3 conversion segments to the gallon graphing unit. The dates are specific to the 5 days used in the test data. This was for an easy test of time-varying code. One can probe the few points in the DB, manually make the DB graphic function call or graph it to see the result.

**Note that as of 260730, when OED is restarted it resets cik/cik_vary based on the actual conversions so you have to reinsert those values if needed. ??Try inserting conversions/conversion_segments to see if that fixes??**

The readings are:

- quantity
  - 24: 2021-06-01 00:00:00 to 2021-06-02 00:00:00
  - 21: 2021-06-02 00:00:00 to 2021-06-02 12:00:00
  - 27: 2021-06-02 12:00:00 to 2021-06-03 00:00:00
  - 72: 2021-06-03 00:00:00 to 2021-06-04 00:00:00
  - 96: 2021-06-04 00:00:00 to 2021-06-05 00:00:00
  - 120: 2021-06-05 00:00:00 to 2021-06-06 00:00:00
- flow: important to note that it is per minute not
  - 1: 2021-06-01 00:00:00 to 2021-06-02 00:00:00
  - 2: 2021-06-02 00:00:00 to 2021-06-03 00:00:00
  - 2.6875: 2021-06-03 00:00:00 to 2021-06-03 09:00:00
  - 3.125: 2021-06-03 09:00:00 to 2021-06-03 21:00:00
  - 3.4375: 2021-06-03 21:00:00 to 2021-06-04 00:00:00
  - 4: 2021-06-04 00:00:00 to 2021-06-05 00:00:00
  - 5: 2021-06-05 00:00:00 to 2021-06-06 00:00:00

At least as of 260728, one needs to manually update the views (hypertables in TSD) after directly adding entries in cik/cik_vary. This is done by: ``npm run rebuildAllReadingViews``.

The expected values for line are:

Since this is only for 5 days, graphing on the web page will show raw data. If you want to see daily, you can set the meter frequency reading below 5 min (5 days x 24 hours/day x 60 min/hour / 1440 max readings = 5 min/reading) such as 00:04:00. ??Unsure why get hourly here since too many points expected (60 min/hour / 4 min/readings x 24 hour/day x 5 day = 1800 readings)???? It is also fine to use the direct DB queries to see the value for these graphing functions.

- quantity
  - hourly
    - June 1
      - 3 (24 reading for day x 3 / 24 hour for reading = 3 reading/hour)
    - June 2
      - 5.25 (21 x (4 / 12) / 4 x 3) to 04:00
        - Explanation: 21 is reading value, 4 / 12 is the prorated amount of this reading that applies to the 6 hours of this conversion, divide by 4 to get the rate and multiply by 3 for the conversion.
      - 8.75 (21 x (8 / 12) / 8 x 5) to 12:00
      - 11.25 (27 x (12 / 12) / 12 x 5) after
    - June 3
      - 15 (72 x (18 / 24) / 18 x 5) to 18:00
      - 21 (72 x (6 / 24) / 6 x 7) after
    - June 4
      - 28 (96 / 24 * 7)
    - June 5
      - 45 (120 / 24 * 9)
  - daily
    - June 1
      - 3 (1 reading for day (quantity/min) x 3 = 3 reading/hour)
    - June 2
      - 9.41666667 ((5.25 x 4 + 8.75 x 8 + 11.25 x 12) / 24) with min of 5.25 and max of 11.25
        - Explanation: It is the sum of the quantities for each segment divided by 24 hours for the day. The hourly items above are a rate so multiply by the time for the segment to get the quantity. This is the same as not doing the division for conversion time above.
    - June 3
      - 16.5 ((15 x 18 + 21 x 6) / 24) with min of 15 and max of 21
    - June 4
      - 28
    - June 5
      - 45
  - raw
    - 2021-06-01 00:00:00 to 2021-06-02 00:00:00
      - 3 (24 / 24 x 3)
    - 2021-06-02 00:00:00 to 2021-06-02 12:00:00
      - 7.58333333 ((21 x (4 / 12) x 3 + 21 (8 / 12) x 5) / 12)
    - 2021-06-02 12:00:00 to 2021-06-03 00:00:00
      - 11.25 ((27 / 12) x 5)
    - 2021-06-03 00:00:00 to 2021-06-04 00:00:00
      - 16.5 ((72 x (18 / 24) x 5 + 72 (6 / 24) x 7) / 24)
    - 96: 2021-06-04 00:00:00 to 2021-06-05 00:00:00
      - 28 (96 / 24 x 7)
    - 120: 2021-06-05 00:00:00 to 2021-06-06 00:00:00
      - 45 (120 / 24 x 9)
- flow
  - hourly
    - June 1
      - 180 ((1 (quantity/min for reading) x 3) x 60 min/hour = 180 quantity/hour)
    - June 2
      - 360 (2 x 3 x 60) to 04:00
        - Explanation: 2 is reading value, multiply by 3 for the conversion & 60 to go from per min of reading to per hour.
      - 600 (2 x 5 x 60) after
    - June 3
      - 806.25 (2.6875 x 5 x 60) to 09:00
      - 937.5 (3.125 x 5 x 60) to 18:00
      - 1,312.5 (3.125 x 7 x 60) to 21:00
      - 1,443.75 (3.4375 x 7 x 60) after
    - June 4
      - 1,680 (4 x 7 x 60)
    - June 5
      - 2700 (5 x 9 x 60)
  - daily
    - June 1
      - 180 (1 x 3 x 60)
    - June 2
      - 560 ((360 x 4 + 600 x 20) / 24) with min of 360 and max of 600
        - Explanation: It is the sum of the quantities for each segment divided by 24 hours for the day. The hourly items above are a rate so multiply by the time for the segment to get the quantity. This is the same as not doing the division for conversion time above.
    - June 3
      - 998.4375 ((806.25 x 9 + 937.5 x 9 + 1,312.5 x 3 + 1,443.75 x 3) / 24) with min of 806.25 and max of 1443.75
    - June 4
      - 1680
    - June 5
      - 2700
  - raw
    - 2021-06-01 00:00:00 to 2021-06-02 00:00:00
      - 180 (1 x 3 x 60)
      - Explanation: Same as hourly/daily since flow and those points spans the full reading.
    - 2021-06-02 00:00:00 to 2021-06-03 00:00:00
      - 560 ((360 x 4 + 600 x 20) / 24)
      - Explanation: Ave of flows for day weighted by hours that it applies.
    - 2021-06-03 00:00:00 to 2021-06-03 09:00:00
      - 806.25
      - Explanation: Same as hourly over same time range since flow and those points spans the full reading.
    - 2021-06-03 09:00:00 to 2021-06-03 21:00:00
      - 1,031.25 ((937.5 x 9 + 1,312.5 x 3) / 12)
    - 2021-06-03 21:00:00 to 2021-06-04 00:00:00
      - 1,443.75
    - 96: 2021-06-04 00:00:00 to 2021-06-05 00:00:00
      - 1680
    - 120: 2021-06-05 00:00:00 to 2021-06-06 00:00:00
      - 2700

The expected values for 1 day bars are (tested by looking at graphic). All values are the average rate/day (from daily) for the day x 24 hours/day.

- quantity
  - June 1: 3 x 24 = 72
  - June 2: 9.41666667 x 24 = 226
  - June 3: 16.5 x 24 = 396
  - June 4: 28 x 24 = 672
  - June 5: 45 x 24 = 1,080
- flow
  - June 1: 180 x 24 = 4,320
  - June 2: 560 x 24 = 13,440
  - June 3: 998.4375 x 24 = 23,962.5
  - June 4: 1680 x 24 = 40,320
  - June 5: 2700 x 24 = 64,800

To test map, create the Happy Place map per the directions on the developer docs for test data. Set the gps of these meters to 20,20. On the map set it to the desired number of days (<=5). Expect results (it is per day):

- quantity
  - 1 day (June 5): 1080
    - Explanation: Same as 6/5 bar
  - 2 day (June 4-5): (1080 + 672) / 2 = 876
    - Explanation: Sum of 6/4 & 6/5 bar divided by 2 days
  - 3 day  (June 3-5): (1080 + 672 + 396) / 3 = 716
  - 4 day  (June 2-5): (1080 + 672 + 396 + 226) / 4 = 593.5
  - 5 day  (June 1-5): (1080 + 672 + 396 + 226 + 72) / 5 = 489.2
- flow
  - 1 day (June 5): 64,800
    - Explanation: Same as 6/5 bar
  - 2 day (June 4-5): (64,800 + 40,320) / 2 = 52,560
    - Explanation: Sum of 6/4 & 6/5 bar divided by 2 days
  - 3 day  (June 3-5): (64,800 + 40,320 + 23,962.5) / 3 = 43,027.5
  - 4 day  (June 2-5): (64,800 + 40,320 + 23,962.5 + 13,440) / 4 = 35,630.625
  - 5 day  (June 1-5): (64,800 + 40,320 + 23,962.5 + 13,440 + 4,320) / 5 = 29,368.5

To teat 3D, you need to set the date range on the graphic to 2021-06-01 to 2021-06-06. The values should follow the line hourly. Make sure the meter reading freq. is less than 1 hour so it will allow it to graph (00:15:00 is fine).

```sql
-- Quantity
-- Remove current values.
DELETE FROM CIK WHERE SOURCE_ID = ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) and DESTINATION_ID = ( SELECT ID FROM UNITS WHERE NAME = 'gallon' );
DELETE FROM CIK_VARY WHERE SOURCE_ID = ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) and DESTINATION_ID = ( SELECT ID FROM UNITS WHERE NAME = 'gallon' );
-- Insert the desired conversion segments directly in cik, cik_vary
INSERT INTO cik VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ) );
INSERT INTO cik_vary VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ), '-infinity', '2021-06-02 04:00:00', 3, 0 );
INSERT INTO cik_vary VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ), '2021-06-02 04:00:00', '2021-06-03 18:00:00', 5, 0 );
INSERT INTO cik_vary VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ), '2021-06-03 18:00:00', '2021-06-05 00:00:00', 7, 0 );
INSERT INTO cik_vary VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ), '2021-06-05 00:00:00', 'infinity', 9, 0 );
-- flow: same as quantity but different meter/graphic unit
-- Remove current values.
DELETE FROM CIK WHERE SOURCE_ID = ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ) and DESTINATION_ID = ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' );
DELETE FROM CIK_VARY WHERE SOURCE_ID = ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ) and DESTINATION_ID = ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' );
-- Insert the 3 desired conversion segments directly in cik, cik_vary
INSERT INTO cik VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' ) );
INSERT INTO cik_vary VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' ), '-infinity', '2021-06-02 04:00:00', 3, 0 );
INSERT INTO cik_vary VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' ), '2021-06-02 04:00:00', '2021-06-03 18:00:00', 5, 0 );
INSERT INTO cik_vary VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' ), '2021-06-03 18:00:00', '2021-06-05 00:00:00', 7, 0 );
INSERT INTO cik_vary VALUES ( ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ), ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' ), '2021-06-05 00:00:00', 'infinity', 9, 0 );

-- View readings, cik_vary, hourly cagg and daily cagg. It is for a specific meter in that test system. or cagg, daily and group are similar. Last is to directly call the DB function to return the meter line graphic points. By changing the point_accuracy one can get the raw, hourly or daily level result.
-- quantity
SELECT * FROM readings where meter_id = ( SELECT ID FROM METERS WHERE NAME = 'Water Gallon' );
select * FROM CIK_VARY WHERE SOURCE_ID = ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon' ) and DESTINATION_ID = ( SELECT ID FROM UNITS WHERE NAME = 'gallon' );
SELECT * FROM meter_hourly_readings_unit_cagg where meter_id = ( SELECT ID FROM METERS WHERE NAME = 'Water Gallon' ) and graphic_unit_id = ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ) order by bucket;
SELECT * FROM meter_daily_readings_unit_cagg where meter_id = ( SELECT ID FROM METERS WHERE NAME = 'Water Gallon' ) and graphic_unit_id = ( SELECT ID FROM UNITS WHERE NAME = 'gallon' ) order by bucket;
-- Because cannot yet get the ids automatically, these get them to use next.
SELECT array_agg(ID) FROM METERS WHERE NAME = 'Water Gallon';
SELECT ID FROM UNITS WHERE NAME = 'gallon';
SELECT * FROM meter_line_readings_unit (
    -- If you want by a meter_id value use {#}
    meter_ids => '{11}',
    passed_graphic_unit_id => 9,
    -- ???why don't these work????
    -- meter_ids => 'SELECT array_agg(ID) FROM METERS WHERE NAME = ''Water Gallon'';',
    -- passed_graphic_unit_id => 'SELECT ID FROM UNITS WHERE NAME = ''gallon''',
    start_stamp => '2021-06-01 00:00:00'::timestamp,
    end_stamp => '2021-06-06 00:00:00'::timestamp,
    point_accuracy => 'daily',
    max_raw_points =>  1440,
    max_hour_points =>  1440
);
-- flow
SELECT * FROM readings where meter_id = ( SELECT ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' );
select * FROM CIK_VARY WHERE SOURCE_ID = ( SELECT UNIT_ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ) and DESTINATION_ID = ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' );
SELECT * FROM meter_hourly_readings_unit_cagg where meter_id = ( SELECT ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ) and graphic_unit_id = ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' ) order by bucket;
SELECT * FROM meter_daily_readings_unit_cagg where meter_id = ( SELECT ID FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute' ) and graphic_unit_id = ( SELECT ID FROM UNITS WHERE NAME = 'gallon per minute' ) order by bucket;
-- Because cannot yet get the ids automatically, these get them to use next.
SELECT array_agg(ID) FROM METERS WHERE NAME = 'Water Gallon flow 1-5 per minute';
SELECT ID FROM UNITS WHERE NAME = 'gallon per minute';
SELECT * FROM meter_line_readings_unit (
    -- If you want by a meter_id value use {#}
    meter_ids => '{17}',
    passed_graphic_unit_id => 24,
    start_stamp => '2021-06-01 00:00:00'::timestamp,
    end_stamp => '2021-06-06 00:00:00'::timestamp,
    point_accuracy => 'raw',
    max_raw_points =>  1440,
    max_hour_points =>  1440
);
```

- This is a reasonable test case with patterns (weeks) and slope/intercept that overlap. Here is a description:

### Units

- um1: meter unit
- ug2: first graphic unit
- ug3: second graphic unit
- ug4: third graphic unit

### Conversions

um1 -> ug2 <-> ug3 <-> ug4

### days with day segments

- d1 (1 hour segment at end)

| Hours | slope (intercept 0) |
| :---: | :---: |
| 0-7 | 2 |
| 7-23 | 3 |
| 23-24 | 5 |

- d2 (span the whole day)

| Hours | slope (intercept 0) |
| :---: | :---: |
| 0-24 | 7 |

- d3 (split day evenly)

| Hours | slope (intercept 0) |
| :---: | :---: |
| 0-12 | 13 |
| 12-24 | 17 |

### weeks

- w1

| Week | Sunday | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| w1 | d2 | d1 | d2 | d2 | d2 | d1 | d2 |

- w2 (all days the same)

| Week | Sunday | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| w1 | d3 | d3 | d3 | d3 | d3 | d3 | d3 |

### Overall conversions

```pre
-inf     6/3  6/4  6/6  6/7    6/10    6/16  6/17    inf
  |  10   | w1           | 20           | 30          |    um1 -> ug2
  |  40        | 50             | 60          | 70    |    ug2 <-> ug3
  |  80             | w2                      | 90    |    ug3 <-> ug4
```

When cik_vary is redone, it should show the values shown here:

### um1 -> ug2

| end of segment hour | expected value | Note |
| :---------: | :-: | :-------: |
| 6/3/2020 00 | 10 | many days |
| 6/4/2020 00 | 7 | W, d2 |
| 6/5/2020 00 | 7 | R, d2 |
| 6/5/2020 07 | 2 | F, d1 |
| 6/5/2020 23 | 3 | F, d1 |
| 6/6/2020 00 | 7 | F, d1 |
| 6/7/2020 00 | 5 | S, d2 |
| 6/16/2020 07 | 20 | |
| infinity | 30 | |

### um1 -> ug3

| end of segment hour | expected value | Note |
| :---------: | :-: | :-------: |
| 6/3/2020 00 | 400 | many days |
| 6/4/2020 00 | 280 | W, d2 |
| 6/5/2020 00 | 350 | R, d2 |
| 6/5/2020 07 | 100 | F, d1 |
| 6/5/2020 23 | 150 | F, d1 |
| 6/6/2020 00 | 250 | F, d1 |
| 6/7/2020 00 | 350 | S, d2 |
| 6/10/2020 00 | 1000 | |
| 6/16/2020 07 | 1200 | |
| 6/17/2020 23 | 1800 | |
| infinity | 2100 | |

### um1 -> ug4

| end of segment hour | expected value | Note |
| :---------: | :-: | :-------: |
| 6/3/2020 00 | 32,000 | many days |
| 6/4/2020 00 | 22,400 | W, d2 |
| 6/5/2020 00 | 28,000 | R, d2 |
| 6/5/2020 07 | 8000 | F, d1 |
| 6/5/2020 23 | 12,000 | F, d1 |
| 6/6/2020 00 | 20,000 | F, d1 |
| 6/6/2020 12 | 4,550 | d3 |
| 6/7/2020 00 | 5,950 | d3 |
| 6/7/2020 12 | 13,000 | d3, repeats until 6/9 |
| 6/8/2020 00 | 17,000 | d3, repeats until 6/10 |
| 6/10/2020 12 | 15,600 | d3, repeats until 6/16 |
| 6/11/2020 00 | 20,400 | d3, repeats until 6/17 |
| 6/16/2020 12 | 23,400 | d3 |
| 6/17/2020 00 | 30,600 | d3 |
| infinity | 189,000 | |

### SQL including seeing results

```sql
-- see data
select * from meters;
select * from units;
select * from week_patterns;
select * from day_patterns;
select * from day_segments;
select * from conversions order by  source_id, destination_id;
select * from conversion_segments order by  source_id, destination_id;
select * from cik order by source_id, destination_id;
-- Also show name of source & destination units
select (select name from units where id = source_id), (select name from units where id = destination_id), * from cik order by source_id, destination_id;
select * from cik_vary order by source_id, destination_id;
select * from cik_vary order by destination_id, start_time;
-- Also show name of source & destination units
select (select name from units where id = source_id), (select name from units where id = destination_id), * from cik_vary order by source_id, destination_id;

-- Remove data
delete from meters;
delete from conversion_segments;
delete from conversions;
delete from week_patterns;
delete from day_patterns;
delete from day_segments;
delete from cik;
delete from cik_vary;
delete from units;

-- Week 1
-- day pattern
insert into day_patterns values (DEFAULT, 'dp1', 'for ds2, ds3, ds5');
insert into day_patterns values (DEFAULT, 'dp2', 'for ds7');
-- day segments
insert into day_segments values (DEFAULT, ( SELECT id FROM day_patterns WHERE NAME = 'dp1' ), 0, 7, 2, 0, 'd2 for dp1 0-7 slope 2');
insert into day_segments values (DEFAULT, ( SELECT id FROM day_patterns WHERE NAME = 'dp1' ), 7, 23, 3, 0, 'd3 for dp1 7-23 slope 3');
insert into day_segments values (DEFAULT, ( SELECT id FROM day_patterns WHERE NAME = 'dp1' ), 23, 24, 5, 0, 'd5 for dp1 23-24 slope 5');
insert into day_segments values (DEFAULT, ( SELECT id FROM day_patterns WHERE NAME = 'dp2' ), 0, 24, 7, 0, 'd7 for dp2 0-24 slope 7');
--- week pattern
insert into week_patterns values (DEFAULT, 'w1', 'dp1: M, F; dp2: N, T, W, R, S', ( SELECT id FROM day_patterns WHERE NAME = 'dp2' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp1' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp2' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp2' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp2' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp1' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp2' ) );
-- units
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('um1', 'um1', 'quantity', 3600, 'meter', '', 'none', false, 'um1 meter unit', -999999999, 999999999, 'reject_all');
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('ug2', 'ug2', 'quantity', 3600, 'unit', '', 'all', false, 'ug2 graphic unit', -999999999, 999999999, 'reject_all');
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('ug3', 'ug3', 'quantity', 3600, 'unit', '', 'all', false, 'ug3 graphic unit', -999999999, 999999999, 'reject_all');
-- conversions
INSERT INTO CONVERSIONS VALUES ( ( SELECT id FROM units WHERE NAME = 'um1' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug2' ), false, 'um1 -> ug2' );
INSERT INTO CONVERSIONS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug2' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug3' ), true, 'ug2 <-> ug3' );
-- conversion segments
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'um1' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug2' ), NULL, 10, 0, '-infinity', '2020-06-03', 'segment 1 slope 10 um1 -> ug2' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'um1' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug2' ), (select id from week_patterns where name = 'w1'), 0, 0, '2020-06-03', '2020-06-07', 'segment 2 week 1 um1 <-> ug2' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'um1' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug2' ), null, 20, 0, '2020-06-07', '2020-06-16', 'segment 3 slope 20 um1 -> ug2' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'um1' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug2' ), null, 30, 0, '2020-06-16', 'infinity', 'segment 4 slope 30 um1 -> ug2' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug2' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug3' ), NULL, 40, 0, '-infinity', '2020-06-04', 'segment 1 slope 40 ug2 <-> ug3' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug2' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug3' ), NULL, 50, 0, '2020-06-04', '2020-06-10', 'segment 2 slope 50 ug2 <-> ug3' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug2' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug3' ), null, 60, 0, '2020-06-10', '2020-06-17', 'segment 3 slope 60 ug2 <-> ug3' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug2' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug3' ), null, 70, 0, '2020-06-17', 'infinity', 'segment 4 slope 70 ug2 <-> ug3' );

-- Week 2: need to do week 1 first
-- day pattern
insert into day_patterns values (DEFAULT, 'dp3', 'for ds13, ds17');
-- day segments
insert into day_segments values (DEFAULT, ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ), 0, 12, 13, 0, 'd13 for dp3 0-12 slope 13');
insert into day_segments values (DEFAULT, ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ), 12, 24, 17, 0, 'd17 for dp3 12-24 slope 17');
--- week pattern
insert into week_patterns values (DEFAULT, 'w2', 'dp3: all days', ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ), ( SELECT id FROM day_patterns WHERE NAME = 'dp3' ) );
-- units
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('ug4', 'ug4', 'quantity', 3600, 'unit', '', 'all', false, 'ug4 graphic unit', -999999999, 999999999, 'reject_all');
-- conversions
INSERT INTO CONVERSIONS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug3' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug4' ), true, 'ug3 <-> ug4' );
-- conversion segments
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug3' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug4' ), NULL, 80, 0, '-infinity', '2020-06-06', 'segment 1 slope 80 ug3 <-> ug4' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug3' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug4' ), (select id from week_patterns where name = 'w2'), 0, 0, '2020-06-06', '2020-06-17', 'segment 2 week 2 ug3 <-> ug4' );
INSERT INTO CONVERSION_SEGMENTS VALUES ( ( SELECT id FROM units WHERE NAME = 'ug3' ), ( SELECT ID FROM UNITS WHERE NAME = 'ug4' ), null, 90, 0, '2020-06-17', 'infinity', 'segment 3 slope 90 ug3 <-> ug4' );
```

```sql
-- meter: Not be formally needed but then can add readings when want.
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('m1', null, false, true, 'other', DEFAULT, DEFAULT, 'm1', 'meter 1', DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'um1' ), null, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
```

### Info

- This SQL was used to do the overall conversions.
- It is okay to only do w1 without w2 or just w2 if you add in unit ug3. Obviously the results will differ.
- It was also used without any patterns by using the conversion web page to set a conversion segment to no pattern and set the slope/intercept. In this case the days & weeks are not needed but they don't cause an issue being in the DB.
- Another variant was to remove some conversion segments from a week but this makes changes the result. The first test was only one non-pattern segment, then with a pattern, then two segments, then simple cases with chaining of conversion, etc.

## Direct Time-vary into cik

- This was for short-term testing of newer time-vary work where patterns not there so manually inserting into conversions/cik/cik_vary so can see results.

These have "a" at the front of names so they show up early in the OED menus.

**If you update cik_vary (and maybe cik) then the values inserted will be lost and you will not see what is desired.**

Note that flow are the same where you simply replace quantity -> flow everywhere.

### Units

- Quantity
  - aumReadingsQuantity1: meter unit used for the test readings
  - aumExpectQuantity1: meter unit for holding the expected values
  - augQuantityTest1: the graphic unit to test TV conversions

### Conversions

These may not be strictly needed but nice to have. They should match the cik/cik_vary conversions to have them align.

- Quantity
  - aumReadingsQuantity1 -> augQuantityTest1: holds the conversion for graphing the test readings in the graphic unit. This will be time_varying.
  - aumExpectQuantity1 -> augQuantityTest1: holds the conversion for graphing the expected values in a graphic unit. This is a simple unit conversion across all time.

### Meters

- Quantity
  - aReadingsQuantity 1: meter used for the test readings
  - aExpectHourlyQuantity 1: meter used for holding the expected Hourly values
  - aExpectDailyQuantity 1: meter used for holding the expected Daily values

### SQL including seeing results

```sql
-- see data: see above/other examples for doing this.
select * from readings where meter_id = ( select id from meters where name = 'aReadingsQuantity 1' );
select * from readings where meter_id = ( select id from meters where name = 'aExpectHourlyQuantity 1' );
select * from readings where meter_id = ( select id from meters where name = 'aExpectDailyQuantity 1' );

select * from meter_daily_readings_unit where meter_id = ( select id from meters where name = 'aReadingsQuantity 1' );
select * from meter_hourly_readings_unit where meter_id = ( select id from meters where name = 'aExpectHourlyQuantity 1' );
select * from meter_hourly_readings_unit where meter_id = ( select id from meters where name = 'aExpectDailyQuantity 1' );

select * from meter_daily_readings_unit_cagg where meter_id = ( select id from meters where name = 'aReadingsQuantity 1' );
select * from meter_hourly_readings_unit_cagg where meter_id = ( select id from meters where name = 'aExpectHourlyQuantity 1' ) order by bucket;
select * from meter_hourly_readings_unit_cagg where meter_id = ( select id from meters where name = 'aExpectDailyQuantity 1' ) order by bucket;

-- Remove data
delete from readings where meter_id in ( select id from meters where name like 'aReadings%' or name like 'aExpect%' and default_graphic_unit in ( select id from units where name like 'aug%' ) );
delete from meters where name like 'aReadings%' or name like 'aExpect%' and default_graphic_unit in ( select id from units where name like 'aug%' );
delete from conversions where source_id in ( select id from units where name like 'aum%' ) and  destination_id in ( select id from units where name like 'aug%' );
delete from cik where source_id in ( select id from units where name like 'aum%' ) and  destination_id in ( select id from units where name like 'aug%' );
delete from cik_vary where source_id in ( select id from units where name like 'aum%' ) and  destination_id in ( select id from units where name like 'aug%' );
delete from units where name like 'aug%' or name like 'aum%';

-- Insert test data
-- units
-- Quantity
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('aumReadingsQuantity1', 'aumReadingsQuantity1', 'quantity', 3600, 'meter', '', 'none', false, '', -999999999, 999999999, 'reject_all');
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('aumExpectQuantity1', 'aumExpectQuantity1', 'quantity', 3600, 'meter', '', 'none', false, '', -999999999, 999999999, 'reject_all');
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('augQuantityTest1', 'augQuantityTest1', 'quantity', 3600, 'unit', '', 'all', false, '', -999999999, 999999999, 'reject_all');
-- Flow
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('aumReadingsFlow1', 'aumReadingsFlow1', 'flow', 3600, 'meter', '', 'none', false, '', -999999999, 999999999, 'reject_all');
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('aumExpectFlow1', 'aumExpectFlow1', 'flow', 3600, 'meter', '', 'none', false, '', -999999999, 999999999, 'reject_all');
INSERT INTO units(name, identifier, unit_represent, sec_in_rate, type_of_unit, suffix, displayable, preferred_display, note, min_val, max_val, disable_checks) VALUES ('augFlowTest1', 'augFlowTest1', 'flow', 3600, 'unit', '', 'all', false, '', -999999999, 999999999, 'reject_all');

-- conversions: not formally needed but adding so can see in UI since easy & does not normally change with different tests.
-- Quantity
INSERT INTO CONVERSIONS VALUES ( ( SELECT id FROM units WHERE NAME = 'aumReadingsQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), false, '' );
INSERT INTO CONVERSIONS VALUES ( ( SELECT id FROM units WHERE NAME = 'aumExpectQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), false, '' );
-- Flow
INSERT INTO CONVERSIONS VALUES ( ( SELECT id FROM units WHERE NAME = 'aumReadingsFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), false, '' );
INSERT INTO CONVERSIONS VALUES ( ( SELECT id FROM units WHERE NAME = 'aumExpectFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), false, '' );

-- conversion segments: not formally needed since ci_vary is set so not doing

-- cik
-- Quantity
INSERT INTO cik VALUES ( ( SELECT id FROM units WHERE NAME = 'aumReadingsQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ) );
INSERT INTO cik VALUES ( ( SELECT id FROM units WHERE NAME = 'aumExpectQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ) );
-- Flow
INSERT INTO cik VALUES ( ( SELECT id FROM units WHERE NAME = 'aumReadingsFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ) );
INSERT INTO cik VALUES ( ( SELECT id FROM units WHERE NAME = 'aumExpectFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ) );

-- cik_vary
-- For the test readings to graph
-- Quantity
-- Should be before data so use weird slope
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ),  ( select id from units where name = 'augQuantityTest1' ), '-infinity', '2022-08-18 00:00:00', -99, 0);
-- time-varying for segments desired
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ),  ( select id from units where name = 'augQuantityTest1' ), '2022-08-18 00:00:00', '2022-08-20 00:00:00', 1, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ),  ( select id from units where name = 'augQuantityTest1' ), '2022-08-20 00:00:00', '2022-09-01 00:00:00', 2, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ),  ( select id from units where name = 'augQuantityTest1' ), '2022-09-01 00:00:00', '2022-09-01 09:00:00', 3, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ),  ( select id from units where name = 'augQuantityTest1' ), '2022-09-01 09:00:00', '2022-09-15 00:00:00', 4, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ),  ( select id from units where name = 'augQuantityTest1' ), '2022-09-15 00:00:00', '2022-10-01 00:00:00', 5, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ),  ( select id from units where name = 'augQuantityTest1' ), '2022-10-01 00:00:00', '2022-10-15 00:00:00', 6, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ),  ( select id from units where name = 'augQuantityTest1' ), '2022-10-15 00:00:00', '2022-11-01 00:00:00', 7, 0);
-- Should be after data so use weird slope
insert into cik_vary values( ( select id from units where name = 'aumReadingsQuantity1' ), ( select id from units where name = 'augQuantityTest1' ), '2022-11-01 00:00:00', 'infinity', -999, 0);
-- For the expected to graph. The is a unit conversion since it is already the desired value.
insert into cik_vary values( ( select id from units where name = 'aumExpectQuantity1' ), ( select id from units where name = 'augQuantityTest1' ), '-infinity', 'infinity', 1, 0);
-- Flow
-- Should be before data so use weird slope
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ),  ( select id from units where name = 'augFlowTest1' ), '-infinity', '2022-08-18 00:00:00', -99, 0);
-- time-varying for segments desired
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ),  ( select id from units where name = 'augFlowTest1' ), '2022-08-18 00:00:00', '2022-08-20 00:00:00', 1, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ),  ( select id from units where name = 'augFlowTest1' ), '2022-08-20 00:00:00', '2022-09-01 00:00:00', 2, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ),  ( select id from units where name = 'augFlowTest1' ), '2022-09-01 00:00:00', '2022-09-01 09:00:00', 3, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ),  ( select id from units where name = 'augFlowTest1' ), '2022-09-01 09:00:00', '2022-09-15 00:00:00', 4, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ),  ( select id from units where name = 'augFlowTest1' ), '2022-09-15 00:00:00', '2022-10-01 00:00:00', 5, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ),  ( select id from units where name = 'augFlowTest1' ), '2022-10-01 00:00:00', '2022-10-15 00:00:00', 6, 0);
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ),  ( select id from units where name = 'augFlowTest1' ), '2022-10-15 00:00:00', '2022-11-01 00:00:00', 7, 0);
-- Should be after data so use weird slope
insert into cik_vary values( ( select id from units where name = 'aumReadingsFlow1' ), ( select id from units where name = 'augFlowTest1' ), '2022-11-01 00:00:00', 'infinity', -999, 0);
-- For the expected to graph. The is a unit conversion since it is already the desired value.
insert into cik_vary values( ( select id from units where name = 'aumExpectFlow1' ), ( select id from units where name = 'augFlowTest1' ), '-infinity', 'infinity', 1, 0);

-- Meters: only need to do once
-- Quantity
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aReadingsQuantity 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aReadingsQuantity 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumReadingsQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectHourlyQuantity 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectHourlyQuantity 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectHourlyQuantityMin 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectHourlyQuantityMin 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectHourlyQuantityMax 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectHourlyQuantityMax 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectDailyQuantity 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectDailyQuantity 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectDailyQuantityMin 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectDailyQuantityMin 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectDailyQuantityMax 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectDailyQuantityMax 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectQuantity1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augQuantityTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
-- Flow
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aReadingsFlow 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aReadingsFlow 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumReadingsFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectHourlyFlow 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectHourlyFlow 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectHourlyFlowMin 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectHourlyFlowMin 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectHourlyFlowMax 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectHourlyFlowMax 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectDailyFlow 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectDailyFlow 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectDailyFlowMin 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectDailyFlowMin 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
INSERT INTO meters(name, url, enabled, displayable, meter_type, default_timezone_meter, gps, identifier, note, area, cumulative, cumulative_reset, cumulative_reset_start, cumulative_reset_end, reading_gap, reading_variation, reading_duplication, time_sort, end_only_time, reading, start_timestamp, end_timestamp, previous_end, unit_id, default_graphic_unit, area_unit, reading_frequency, min_val, max_val, min_date, max_date, max_error, disable_checks) VALUES ('aExpectDailyFlowMax 1', null, false, true, 'other', DEFAULT, DEFAULT, 'aExpectDailyFlowMax 1', DEFAULT, DEFAULT, false, false, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, ( SELECT ID FROM UNITS WHERE NAME = 'aumExpectFlow1' ), ( SELECT ID FROM UNITS WHERE NAME = 'augFlowTest1' ), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
```

The above segments match what was put into the spreadsheet "expect TV.ods". Then do:

- Run above SQL to create DB items.
- create CVS files to test the data. They come from "expect TV.ods".
  - readingsTest1.csv: The values from the Input section for min or reading or max, start time, end time were placed into a CSV (in that order for first three columns) for the readings CSV.
  - For Hourly (60 min/reading), the readings are in K11:K1810. For Daily (1440 min/reading), the readings are in K11:K85. These are put in column A of the CSV. The start/end times are the same ranges but in columns M,N, i.e., M11:N1810 for hourly. The min/max values are also in the same range but column J/L.
  - Make sure For graphing? is true in spreadsheet.
    - Create as many of these expected files as you want. Note you must set graphing to true in the spreadsheet to get the same values.
      - readingsTest1.csv: has the 75 days of 15 minute readings for all tests. It will be loaded into multiple meters.
      - expectedDailyQuantityTest1.csv: for daily data of a quantity.
      - expectedDailyQuantityMinTest1.csv: for daily data of a quantity.
      - ... Also Hourly instead of Daily, Max instead of Min, Flow for Quantity.
  - For flow, change Quantity data? in spreadsheet to false but the rest is the same where change naming to flow.
- Then these curl commands were run in a standard terminal (not the OED Docker container) where it is in the directory with the CSV files just created to upload the readings:
  - Only need one Result meter since can change the range to see either Hourly or Daily. An alternative is to change the meter frequency so it thinks there are fewer points so returns hourly not daily for longer ranges of time.
    - Quantity
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aReadingsQuantity 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@readingsTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectHourlyQuantity 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectHourlyQuantityTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectHourlyQuantityMin 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectHourlyQuantityMinTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectHourlyQuantityMax 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectHourlyQuantityMaxTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectDailyQuantity 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectDailyQuantityTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectDailyQuantityMin 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectDailyQuantityMinTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectDailyQuantityMax 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectDailyQuantityMaxTest1.csv'
    - Flow
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aReadingsFlow 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@readingsTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectHourlyFlow 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectHourlyFlowTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectHourlyFlowMin 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectHourlyFlowMinTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectHourlyFlowMax 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectHourlyFlowMaxTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectDailyFlow 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectDailyFlowTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectDailyFlowMin 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectDailyFlowMinTest1.csv'
curl http://localhost:3000/api/csv/readings -X POST -F 'meterName=aExpectDailyFlowMax 1' -F 'gzip=no' -F 'email=test' -F 'password=password' -F 'csvfile=@expectDailyFlowMaxTest1.csv'
- If things go well then graphing those two meters with the augQuantityTest1 unit will be the same.

#### PSQL triggers (these for new Hypertable ones)

```sql
-- disable trigger: can see if PGAdmin if look at properties of the trigger.
ALTER TABLE readings DISABLE TRIGGER trg_readings_update_hourly_hypertable;
-- enable trigger
ALTER TABLE readings ENABLE TRIGGER trg_readings_update_hourly_hypertable;
```

#### Force an update of a TSD split table. This might not work any more

SELECT rebuild_hourly_hypertable_split();

## Standard developer test data with time-varying

If you insert the standard test data and don't have other items in the DB that you manually added then you should get this when you look at cik_vary (``select (select name from units where id = source_id), (select name from units where id = destination_id), * from cik_vary order by source_id, destination_id;
``):

| source | destination | source_id | destination_id | start_time | end_time | slope | intercept |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Electric_Utility | BTU | 211 | 206 | -infinity | infinity | 3412.142 | 0 |
| Electric_Utility | m³ gas | 211 | 207 | -infinity | infinity | 0.09315147659999999 | 0 |
| Electric_Utility | kWh | 211 | 209 | -infinity | infinity | 1 | 0 |
| Electric_Utility | US dollar | 211 | 217 | -infinity | infinity | 0.115 | 0 |
| Electric_Utility | MJ | 211 | 222 | -infinity | infinity | 3.6 | 0 |
| Electric_Utility | 100 w bulb | 211 | 224 | -infinity | infinity | 1 | 0 |
| Electric_Utility | euro | 211 | 226 | -infinity | infinity | 0.1012 | 0 |
| Electric_Utility | kg of CO₂ | 329 | 349 | -infinity | infinity | 0.709 | 0 |
| Electric_Utility | metric ton of CO₂ | 329 | 350 | -infinity | infinity | 0.000709 | 0 |
| Natural_Gas_M3 | BTU | 215 | 206 | -infinity | infinity | 36630.03663003663 | 0 |
| Natural_Gas_M3 | m³ gas | 215 | 207 | -infinity | infinity | 1 | 0 |
| Natural_Gas_M3 | kWh | 215 | 209 | -infinity | infinity | 10.73520288136796 | 0 |
| Natural_Gas_M3 | US dollar | 215 | 217 | -infinity | infinity | 0.25 | 0 |
| Natural_Gas_M3 | MJ | 215 | 222 | -infinity | infinity | 38.64673037292465 | 0 |
| Natural_Gas_M3 | 100 w bulb | 215 | 224 | -infinity | infinity | 10.73520288136796 | 0 |
| Natural_Gas_M3 | euro | 215 | 226 | -infinity | infinity | 0.22 | 0 |
| Water_Gallon | liter | 216 | 205 | -infinity | infinity | 3.7853996378886707 | 0 |
| Water_Gallon | gallon | 216 | 212 | -infinity | infinity | 1 | 0 |
| Temperature_Fahrenheit | Fahrenheit | 219 | 208 | -infinity | infinity | 1 | 0 |
| Temperature_Fahrenheit | Celsius | 219 | 214 | -infinity | infinity | 0.5555555555555556 | -17.77777777777778 |
| Electric_kW | kW | 221 | 220 | -infinity | infinity | 1 | 0 |
| Natural_Gas_BTU | BTU | 223 | 206 | -infinity | infinity | 1 | 0 |
| Natural_Gas_BTU | m³ gas | 223 | 207 | -infinity | infinity | 2.73e-05 | 0 |
| Natural_Gas_BTU | kWh | 223 | 209 | -infinity | infinity | 0.0002930710386613453 | 0 |
| Natural_Gas_BTU | US dollar | 223 | 217 | -infinity | infinity | 2.954545454545455e-06 | 0 |
| Natural_Gas_BTU | MJ | 223 | 222 | -infinity | infinity | 0.0010550557391808431 | 0 |
| Natural_Gas_BTU | 100 w bulb | 223 | 224 | -infinity | infinity | 0.0002930710386613453 | 0 |
| Natural_Gas_BTU | euro | 223 | 226 | -infinity | infinity | 2.6e-06 | 0 |
| Natural_Gas_BTU | kg of CO₂ | 339 | 349 | -infinity | infinity | 5.29e-05 | 0 |
| Natural_Gas_BTU | metric ton of CO₂ | 339 | 350 | -infinity | infinity | 5.29e-08 | 0
| Natural_Gas_Dollar | US dollar | 225 | 217 | -infinity | infinity | 1 | 0 |
| Natural_Gas_Dollar | euro | 225 | 226 | -infinity | infinity | 0.88 | 0 |
| Trash | kg | 229 | 210 | -infinity | infinity | 1 | 0 |
| Trash | metric ton | 229 | 213 | -infinity | infinity | 0.001 | 0 |
| Trash | kg of CO₂ | 345 | 349 | -infinity | infinity | 3.24e-06 | 0 |
| Trash | metric ton of CO₂ | 345 | 350 | -infinity | infinity | 3.24e-09 | 0 |
| Water_Gallon_Per_Minute | gallon per minute | 230 | 227 | -infinity | infinity | 1 | 0 |
| Water_Gallon_Per_Minute | liter per hour | 230 | 228 | -infinity | infinity | 227.12398 | 0 |
