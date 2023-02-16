# Conversions that vary with time

This is a preliminary draft to start discussions on this idea. It is being pushed out for a meeting and has not been reviewed at this time.

## Introduction

The current resourceGeneralization designed conversions between units that did not vary. This document discusses how OED can extend this idea so conversions will vary with time.

There are conversions that sites want to vary by time including:

- Baselines (which may be doable by units) which can change if a building is changed.
- Area normalization (see [design document](../areaNormalization/areaNormalization.md)) where values can vary with building changes.
- Cost. This one may differ from the others in that costs can vary by time of day and even the day of the week. Thus, the general solution would allow repeating costs over time that can be also changed periodically. This means lots of time variations which is unlike most other uses.

## Potential solution

During a discussion with Simon Tomlinson, he felt OED could efficiently implement this by creating conversions that had time ranges in a way similar to readings. He outlined potential SQL as (done quickly and does not exactly match what OED has now):

...
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
...

The basic idea to apply the time varying conversion in a similar way that readings area averaged by determining the overlap in time and properly applying. Note that an actual solution would do a slope (rate above) and an intercept (not above).

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
2. There are already conversion for this unit pair. In this case OED will need to get the start time for the new conversion. The detail need to be decided. The start time will be used to split the current conversion that includes that time. An example may help:

- If this is the second conversion for this unit pair, the first will have time of -inf, inf with a value of 10 (for example). If a start time for the new conversion is 1/1/2022 with a value of 20 then there will now be two conversions:

1. -inf, 1/1/2022 with value 10
2. 1/1/2022, inf with value 20

This idea can be applied to any existing conversion. Note the admin should be able to enter -inf as the start time to split from the beginning of time.

A special case is if the start time is on the end time of a current conversion. This will not be allowed as it is effectively an edit of the conversion. Note the description is the end time. This means it does not exclude -inf which can only be a start time. For all other values (except inf which the admin is not allowed to enter), there will be an end time of one conversion and the start time of another conversion that matches because gaps are not allowed. One question is whether the edit should just be done here rather than on a separate page.

To facilitate entering conversions, it may be useful for OED to display the current conversion with the entered source/destination. This could be a table and/or a graph of them.

For conversion editing, OED needs to list all the current conversions (see comment above). The admin can then select a conversion (decide how) and the values can be edited. The values for the start/end time must be controlled by these rules:

- -inf/inf cannot be changed so the conversions continue to span all time.
- If the start/end time is changed then the conversion that has the matching end/start time must be modified to have the same value so the conversions continue to abut and span all time. Think about if this is the best way to do this.

### Repeating values

Needs to be worked out.
