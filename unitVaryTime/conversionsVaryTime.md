# Conversions that vary with time

Unlike some of the design documents, this one proposes avenue to try so the final solution can be determined.

## Introduction

The current resourceGeneralization designed conversions between units that did not vary. This document discusses how OED can extend this idea so conversions will vary with time.

There are conversions that sites want to vary by time including:

- Area normalization (see [design document](../areaNormalization/areaNormalization.md)) where values can vary with building changes. If variation is allowed then changes will be needed to how it is implemented since it assumes fixed areas and is done on the client rather than the server side. This is a completed feature.
- Cost. This one may differ from the others in that costs can vary by time of day and even the day of the week. Thus, the general solution would allow repeating costs over time that can be also changed periodically. This means lots of time variations which is unlike the first two uses. Fixed costs are part of the units work for v1.0.
- Baselines (which may be doable by units) which can change if a building is changed.
- Weather. Normalize usage by the weather. In a common way, the degree heating/cooling for each day is determined from local weather and then used to normalize the usage. Other ways are possible. This usage has similarities to cost in the frequency of variation but there is no regular pattern. This is a planned feature that is not yet done in OED.

## Potential solution

During a discussion with Simon Tomlinson, he felt OED could efficiently implement this by creating conversions that had time ranges in a way similar to readings. He outlined potential SQL as (done quickly and does not exactly match what OED has now):

```sql
create table conversions (
    id serial,
    rate real,
    valid_for tsrange
)

    -- for example, for conversions valid forever
    insert into conversions(rate, valid_for)
    values ('1000 watts / kw', tsrange(-inf, inf));
    
create table hourly_readings (
    reading real,
    duration tsrange,
    conversion_id integer references conversions(id)
);
    
select
    hourly_readings.reading,
    hourly_readings.duration,
    sum( -- Calculate adjusted rate = reading * (conversion_rate * % of reading that conversion applies for)
        hourly_readings.reading * conversions.rate
        * (
            conversions.valid_for * hourly_readings.duration)
            / (hourly_readings.duration)
            ) as converted_reading
from hourly_readings
inner join conversions on conversions.id = hourly_readings.conversion_id
                    conversions.valid_for && hourly_readings.duration -- they overlap
group by hourly_readings.duration -- unique per reading, need more with meters
```

The basic idea to apply the time varying conversion in a similar way that readings area averaged by determining the overlap in time and properly applying. Note that an actual solution would do a slope (rate above) and an intercept (not above).

Note OED has an hourly and daily table so both will need changes. If these work then the raw/meter readings also need to be incorporated into the system. See src/server/sql/reading/create_reading_views.sql for the DB functions. It may be valuable to see the description in the devDocs for resource generalization that describes how the older functions worked (see section other-database-considerations, note this is only available to OED developers at this time).

The design of the new conversion storage in the DB needs to be worked out. It may be the case that there will be a new conversion table that uses holds the conversions by time with a foreign key into the modified current table that holds the rest of the information on the conversion that does not vary with time. If the conversion does not vary then there would only be one entry in the new table for that conversion. If it varies then there would be one entry per range (see below).

How efficient this will be, esp. when the conversion varies with time, needs to be tested. If necessary, limitations on the variation can be imposed.

## Conversion ideas

The current ideas in resource generalization are mapped to the new system by setting the start/end timestamp (valid_for in Simon's code) to -inf and inf (or some appropriate value) to indicate they apply to all time. These effectively create conversions that do not vary with time.

For ones that vary with time, there would be multiple conversions (OED uses the source/destination as the primary key and not the id as in Simon's code) where the primary key would not include the start timestamp as does readings.

To simplify the system and to make it (probably) better, OED will not allow gaps in time for conversions for a given source/destination. This means that all the conversions for a given source/destination must span -inf to inf without any gaps. Clearly the ones that don't vary, as described just above, meet this criterion. The rationale for this is if there are gaps then the conversion will not be applied and the values would probably be misleading. With readings gaps are allowed because the values are generally coming via meters where failures can occur. This is somewhat beyond the control of the admin of the OED system so we deal with them. In this case the reading value show by OED will be impacted but there is not much we can do. OED does account for the missing time to make the average reflect the time for actual points if they partly overlap the reading point being shown. If there is not overlap then no point is shown. While something similar could be done for conversions, it is unclear we should. The main argument is that the conversions are set by the admin so they can enter a value for all times. If it is unknown they can set the slope/intercept to 0 so the value will be forced to the x-axis in the graphic. However, it is unclear why a value would not be known for a part of time and you still want to apply this conversion. This decision needs review and finalization.

## Entering conversions

Given you can have lots of conversions that vary with time, a new interface will be needed for the admin to enter these values.

### Non-repeating values

Here the admin will enter all the conversion values for various time ranges.

For conversion creation, the admin will set the source/destination units (and the other information currently needed). Once OED has the source/destination, it will need to check if there is any other conversion involving these two units. There are two cases:

1. This is the first conversion for this pair of units. OED will automatically set the start/end timestamp to be -inf and inf (or whatever value is decided). This means that the page is not substantively changed and it is easy for an admin to do the case where conversions do not vary with time.
2. There are already conversion for this unit pair. In this case OED will need to get the start time for the new conversion. The details need to be decided. The start time will be used to split the current conversion that includes that time. An example may help:

    - If this is the second conversion for this unit pair, the first will have time of -inf, inf with a value of 10 for the slope and 0 for the intercept (for example). If a start time for the new conversion is 1/1/2022 with a value of 20 (ignoring slope that is usually 0) then there will now be two conversions:

      1. -inf, 1/1/2022 with value 10
      2. 1/1/2022, inf with value 20

This idea can be applied to any existing conversion. Note the admin should be able to enter -inf as the start time to split from the beginning of time.

A special case is if the start time is on the end time of a current conversion. This will not be allowed as it is effectively an edit of the conversion. Note the description is the end time. This means it does not exclude -inf which can only be a start time. For all other values (except inf which the admin is not allowed to enter), there will be an end time of one conversion and the start time of another conversion that matches because gaps are not allowed. One question is whether the edit should just be done here rather than on a separate page.

To facilitate entering conversions, it may be useful for OED to display the current conversion with the entered source/destination. This could be a table and/or a graph of them. Another option that may make sense is to have a card for each one that is similar to the look of other admin pages. The cards would be sorted by start time so the next time follows the first.

For conversion editing, OED needs to list all the current conversions (see comment above). The admin can then select a conversion (decide how) and the values can be edited. The values for the start/end time must be controlled by these rules:

- -inf/inf cannot be changed so the conversions continue to span all time.
- If the start/end time is changed then the conversion that has the matching end/start time must be modified to have the same value so the conversions continue to abut and span all time. We need to consider if this is the best way to do this.

### Repeating values

Needs to be worked out. First lets see if how the other cases pan out.

## Implementation plan

There are a number of open questions so this will be done step-by-step where the result is used to decide the best way to continue. **As such, regular contact with the OED project is anticipated.**

### 1. Database

As described in the "Potential solution" section, the database functions need to be modified to handle conversions that vary with time. The envisioned steps are:

1. Modify the DB tables and functions to work with conversions that vary with time. This will not necessarily do all needed changes but the ones needed for testing.
2. The validity of the changes will be tested via a moderate level of testing. It is envisioned that this will be done via a Postgres command line to allow for each changes and quick tests during this phase.
3. The speed of the DB queries will be tested for conversions that mimic the two types described in "Introduction" section. Thus, conversions that vary infrequently (a handful of conversions over time) and ones that vary frequently (trying every day and then every hour). Doing line graph data will be good for these tests.

   As a special case, the new code with only one value (so it does not really vary with time) will be compared with the current conversion code to see the impact of treating non-varying conversions as a special case of varying. This will indicate if all the conversions can use the new system.

   The timings will also indicate if the new system is viable for deploying. The OED project can help with tool recommendations to perform this analysis. This may be an iterative process until the performance is deemed acceptable.
4. Once the performance is acceptable, test code will be written to try a range of cases that can be incorporated into the standard OED testing set to be certain that now and in the future the functions work as expected. This testing will be more systematic and careful than in step 2.
5. Any additional DB functions to deal with other graphics will be created. It is hoped this is minimal. New test code is needed for any changes or the current tests need to be modified for conversions that vary with time.

### Routing

The current graphics route back data from the server to the client and into Redux state. It is hoped that the new system will have conversions that are similar to the current system (with an id for each conversion even if it varies with time) so there are not many changes in this area.

### Graphics

Unless there are performance differences that are of concern, the plan is to treat all conversions similarly so they will show on the same user graphics as they currently do. The fact that a conversion varies with time does not change any of the calculations concerning its compatibility for menus/graphics. Thus, the hope is for minimal changes in this area.

### Admin conversion page

If all goes well, then the new UI for the conversion page needs to be created. The "Entering conversions" section has ideas on this. It may be most practical to start with the non-repeating case and then do repeating after that. This is going to be significant work that will be settled once the underlying system is well understood.

## Update May 2024

This part of the design document describes a potential solution attempt for issue #896, it involves implementing the needed database function to efficiently allow for a time conversion feature.

As of now, any changes we have made exist in new files with similar names to the current existing files for testing purposes. After testing has been done the current files should be updated.
We have updated the current conversion table to include a *start_time* and *end_time*, this would replace the *valid_for* in the original table.
The new *conversions_time* table is found in ``create_conversions_time_table.sql``

The source and destination id's reference units that already exist in the ``create_units_table.sql`` By adding a CHECK, the database will prevent duplicate conversions. The slope factor represents the proportional change applied to the original reading.

Bidirectional refers to if the conversion can be done forwards and backwards between the two units. Not all conversions can be bidirectional.
conversions_time.reading is a placeholder parameter for our testing purposes that may need to be removed after implementation.

We have found that using a '-infinity' and 'infinity' are acceptable timestamp values for start_time and end_time, for conversions that can exist across all time.

```sql
CREATE TABLE IF NOT EXISTS conversions_time(
    conversion_id SERIAL PRIMARY KEY,
    source_id INTEGER NOT NULL REFERENCES units(id),
    destination_id INTEGER NOT NULL REFERENCES units(id),
    reading FLOAT NOT NULL, 
    bidirectional BOOLEAN NOT NULL,
    start_timestamp TIMESTAMP, --  TIMESTAMP ‘-infinity’
    end_timestamp TIMESTAMP, --  TIMESTAMP ‘infinity’
    slope FLOAT, --this is the rate
    intercept FLOAT,
    note TEXT,
    CHECK (source_id != destination_id)
);
```

Currently, the dashboard still does not have the front-end functionality for admins to insert the actual conversion information. This is a front-end feature that should be handled by a front-end team.
For example, the admin would insert a conversion whose time ranges are -infinity to infinity, this front-end functionality should be implemented using ``insert_new_time_conversion.sql`` and ``ConversionsTime.js``

```sql
INSERT INTO conversions_time (source_id, destination_id, reading, bidirectional, start_timestamp, end_timestamp, slope, intercept, note)
VALUES (1, 2, 10, true, '-infinity', 'infinity', 0.5, 2.0, 'Example conversion');
```

The unit selected by a user can then be converted into another unit, if the time selected by the user exists in a conversion.

The updated readings table in ``create_readings_time.sql`` that now includes a conversion id

```sql
CREATE TABLE IF NOT EXISTS readings_time (
    meter_id INT NOT NULL REFERENCES meters(id),
    reading FLOAT NOT NULL,
    start_timestamp TIMESTAMP NOT NULL,
    end_timestamp TIMESTAMP NOT NULL,
    CHECK (start_timestamp < readings_time.end_timestamp),
    conversion_id integer references conversions_time(conversion_id),
    CHECK (start_timestamp < readings_time.end_timestamp),
    PRIMARY KEY (meter_id, start_timestamp)
);
```

This is more example test data we plan to use

```sql
INSERT INTO conversions_time (source_id, destination_id, reading, bidirectional, start_timestamp, end_timestamp, slope, intercept, note)
VALUES 
(1, 2, 5, true, '2024-04-01 00:00:00', '2024-04-02 00:00:00', 0.5, 2.0, 'Example conversion 1'),
(2, 3, 10, false, '2024-04-01 00:00:00', '2024-04-03 00:00:00', 1.0, 0.0, 'Example conversion 2');


INSERT INTO readings_time (meter_id, reading, start_timestamp, end_timestamp, conversion_id)
VALUES
(1, 50, '2024-04-01 06:00:00', '2024-04-01 12:00:00', 1),
(2, 75, '2024-04-01 12:00:00', '2024-04-02 06:00:00', 1),
(3, 100, '2024-04-01 06:00:00', '2024-04-02 06:00:00', 2);
```

We have built upon the proposed solution and adjusted it to reflect the new tables. However in the provided SELECT query, there is still no involvement of the intercept column from the conversions_time table in the calculation of the converted readings. The calculation only utilizes the slope column. The result set itself is not stored permanently in the database; it's just used temporarily as part of the query execution process.

```sql
select
    readings_time.reading,
    readings_time.start_timestamp,
    readings_time.end_timestamp,
    conversions_time.start_timestamp,
    conversions_time.end_timestamp,
    sum( -- Calculate adjusted rate = readings_time.reading * (conversions_time.rate * % of reading that conversion applies for)
        readings_time.reading * conversions_time.slope
        * (
        (readings_time.end_timestamp - readings_time.start_timestamp) * (conversions_time.end_timestamp - conversions_time.start_timestamp))
        / (conversions_time.end_timestamp - conversions_time.start_timestamp)
    ) as converted_reading
    from conversions_time
    inner join readings_time on readings_time.conversion_id = conversions_time.conversion_id AND (readings_time.end_timestamp - readings_time.start_timestamp) && (conversions_time.end_timestamp - conversions_time.start_timestamp) -- they overlap
    group by (conversions_time.end_timestamp - conversions_time.start_timestamp) -- unique per reading, need more with meters
```

We have tested the creation and insertion of the tables and have seen expected results. We have not tested the select query against the tables. We expect that when testing a reading that does not vary with time, it should maintain its same reading value.

### Notes

These notes were added during review but may not be complete:

- The readings table will not include the conversion. Readings are stored in the meter unit and converted for graphing.
- It is suspected that the final select for readings needs to be modified for multiple conversions that change over time.
