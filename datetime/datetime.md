# How does OED deal with dates & times

This document describes how OED treats dates & times, esp. around readings. It also discusses some nuances in their use concerning momentjs. It also discusses work done on OED in April 2022 that addressed:

- Making reading dates consistent in how they are handled.
- How OED handles daylight savings.

See [https://momentjs.com/docs/#/i18n/](https://momentjs.com/docs/#/i18n/) and other sections for information on moment. See [https://momentjs.com/timezone/docs/](https://momentjs.com/timezone/docs/) for information on moment timezone.

## Making OED handle reading dates consistently

As discussed in [OED time help page](https://openenergydashboard.github.io/help/v0.8.0/time.html), OED displays readings at the time/date from the meter and does not shift meters in different timezones. This means that a meter reading at noon in New York and Tokyo will both display at noon even though they happened at different times in different timezones since they happened at the same time of the day.

To make this work, OED stores all readings in UTC time in the database. Some meters do not send timezone information including MAMAC and (we think) Obvius. eGauge, on the other hand, sends Unix timestamps that need to be interpreted in the timezone of the meter. To deal with these difference, OED takes care of putting the reading into the correct date/time when it is processed at the meter level. This means:

- For meters that do not deal with timezones, OED takes the date/time given and adds the UTC timezone to it without and shift of time.
- For meter that do deal with timezones, OED takes the date/time given, puts it into the correct timezone that will generally require a shift of time and then changes the timezone to UTC without a shift of time.

The recent changes has the code follow these rules. The test code was also modified to account for this. A meter timezone if found as follows:

1. If the meter has a timezone, it is used.
2. If the meter does not have a timezone then the default OED timezone is used if it is set.
3. If neither had a timezone then the timezone of the OED web server is used. The docker-compose.yml file now has an environment variable for to set the web server timezone. This is set to UTC by default but it is good to change it to local time so that log messages have the correct local time.

As a rule, OED takes the readings from the database and keeps them in UTC for doing any graphics with them. One way the code does this is to take the date/time and format without a timezone and then add the UTC timezone to it. Another is to set the timezone to UTC when the moment object is created.

Note that in what follows, only meters that deal with timezones need to consider daylight savings. See next.

Another change made was to eliminate the use of JS Date and only use moment.js. Along with this, the client side no longer uses moment-timezone.js but the server side does. This means that moment-timezone.js is no longer needed on the client side and not part of the payload.

## OED and daylight savings

This was a known issue that became more important as we began accepting eGauge meter data. Before that, no meter had reported its dates/times with timezones. Both MAMAC and Aquisuite/Obvius sent a date/time as a string without a timezone, e.g., "2022-04-18 14:45:00". OED accepted this date/time and used it. Note that MAMAC (unsure about Aquisuite) sends a reading each hour that is always one hour later than the last reading independent of daylight savings. Thus, when daylight savings began in 2022, MAMAC meters have "2022-03-13 1:00:00", "2022-03-13 2:00:00", "2022-03-13 3:00:00", etc. on U.S. meters even though there is no 2:00 on that day. OED was okay with this since it treated the times as coming from UTC (which has no daylight savings so all hours of every day exist) and only cares about the date/time. With eGauge, it sends a Unix timestamp that represents how long it has been since the epoch (1970-01-01 00:00:00) at UTC. (That is using the format we chose when we pull eGauge readings.) The actual time the reading occurred is found by converting this Unix timestamp to a date/time using the timezone of the meter. Since many timezones have daylight savings, we might get this series of readings (when gathered every 15 minutes in the U.S.): "2022-03-13 1:45:00", "2022-03-13 3:00:00", "2022-03-13 3:15:00", etc. (all date/times are the end time of the reading). When OED processed the 3:00 reading using momentjs, it stored a reading of 1:45:00:00-3:00:00. This means the reading appears to span 1.25 hours rather than 0.25 hours and the reading rate was 1/5 the correct value. Issues will also occur in the fall when the clock goes the other way but has a different impact.

## Prerequisites

### Detecting crossing DST

In moment, each reading has an offset from UTC. Because OED generally uses UTC time, this offset is always 00:00 and there is no daylight savings. However, if you are working in a timezone with DST (such as eGauge meters) then there is an offset from UTC that is different from 00:00 (assuming you are not in UTC). For example, in America/Chicago, the offset is -06:00 in standard time and -05:00 in daylight savings time. if you take the startTimestamp offset - endTimstamp offset you get:

- When crossing DST into daylight savings time in the spring (in America/Chicago) you get a negative shift of -06:00 - -05:00 = -01:00 or -60 minutes. The software returns -60 minutes for this case since some offsets are fractions of any hour but always whole minutes. Using minutes is consistent with what moment-timezone does. Note that it is defined to be start - end to make some other items easier and to be consistent with moment that does negates the offset values.
- When crossing DST into standard time in the fall (in America/Chicago) you get a positive shift of -05:00 - -06:00 = +01:00 or 60 minutes.
- When not crossing DST you get a shift of 00:00 or 0 minutes.

Thus, the shift tells you if a reading crosses DST and which direction it is crossing. moment gives these offsets as part of the date/time stamp.

### When DST crossings occur

moment-timezone can return the date/time of all DST crossings for any given timezone. If you ask for data on a timezone it returns several items:

- A string with the name of the timezone, e.g., "America/Chicago".
- An array abbrs[] of strings with the abbreviations of the timezone, e.g., ['CST', 'CDT', 'CST', 'CDT']. The abbreviation is for the timezone that exists between the times given in untils[]. In this case you start in Central Standard Time and then go to Central Daylight Time, etc.
- An array untils[] that have a Unix timestamp for when this time period ends.
- An array offsets[] that have the offset from UTC for the time period in minutes
- A number population that we don't care about.

For example, the two entries in the three arrays when the name is "America/Chicago" is:

- abbrs: [0] = 'CST', [1] = 'CDT'
- untils: [0] = -1633276800000, [1] = -1615136400000
- offsets: [0] = 360, [1] = 300

If you convert the Unix timestamps to a date/time in "America/Chicago" you get: untils: [0] = 1918-03-31 03:00:00-05:00, [1] = 1918-10-27 01:00:00-06:00. This tells you that from March 31, 1918 at 3:00 until October 27, 1918 at 1:00 you were in CDT (Central Daylight Time) which is 300 minutes/5 hours from UTC. (See the moment-timezone documentation for why the offset is positive even though the date/timestamp is negative.) Note that 1:00-2:00 on 1918-03-31 does not exist because the clocks go forward when you leave CDT into CST. Also, 1:00-2:00 is repeated  on 1918-10-27 because the clocks go back when you leave CST into CDT. See the moment-timezone documentation for more information on how it deals with times in these unusual situations. OED will not see the excluded time of 1:00-2:00 in the spring if the meter is reporting correctly but it will see duplicated times in the fall.

For the current year (2022) that are used in the following examples, the untils and offsets are:

- abbrs: 'CDT', 'CST', 'CDT', 'CST'
- untils (converted to a date/time in America/Chicago): 2021-11-07 01:00:00-06:00, 2022-03-13 03:00:00-05:00, 2022-11-06 01:00:00-06:00, 2023-03-12 03:00:00-05:00
- offsets: 300, 360, 300, 360

This is interpreted as:

- Until 2022-03-13 03:00:00-05:00 America/Chicago in 2022 is in CST (Central Standard Time) which actually began 2021-11-07 01:00:00-06:00. The offset is 360 minutes/6 hours.
- After 2022-03-13 03:00:00-05:00 until 2022-11-06 01:00:00-06:00 America/Chicago is in CDT (Central Daylight Time). The offset is 300 minutes/5 hours.
- After 2022-11-06 01:00:00-06:00 America/Chicago in 2022 is in CST (Central Standard Time) which actually ends 2023-03-12 03:00:00-05:00. The offset is 360 minutes/6 hours.

Note the when crossing occurs depends on the year and the timezone. It can even not exist in some years. Thus, you need to consider which year/crossing is involved to determine if/when it occurs.

Note in some timezones the offset change is less than an hour so using minutes is appropriate. The time of the day varies and in some timezones the shift can send you to a different day.

The shift defined before is consistent with these numbers. When you cross from standard time to daylight savings time the offset goes from 360 to 300 so the shift is 300 - 360 = -60 minutes. Note this is done as end - start unlike what OED does because moment uses offsets of the opposite sign from the UTC offset. When you cross from daylight savings time to standard time the offset goes from 300 to 360 so the shift is 360 - 300 = 60 minutes.

## Examples

At the software level, it does not matter how we get the reading with the shifts for daylight savings but just that it exists. Thus, we can deal with the readings that are seen in the pipeline without a timezone associated with it. This is also important because the previous reading date/time stored on the meter in the database do not have timezone information. OED assumes all dates/times are in UTC. If there is a timezone then we ignore it and just used the date/time without shift when placed into UTC.

For the examples, I am going to use America/Chicago that is in Central Time. Other timezones work similarly. See above for the dates and times involved in daylight savings. When you leave standard time and enter daylight savings time, the clocks go forward 1 hour so the offset from UTC does from -05:00 to -06:00. When you leave daylight savings time and enter standard time, the clocks go back 1 hour and the offset from UTC does from -06:00 to -05:00.

We do not need to worry about daylight savings issues with readings when:

1. The meter does not use timezone information. This is true For MAMAC and Obvius(TODO verify) meters. The software that processes meter readings will pass a parameter to tell the pipeline if it needs to adjust for daylight savings. To save time, we skip the checks in this case.
2. If a reading does not cross daylight savings time, then there is no change in the UTC offset so we do not need to do anything special. Most of the readings do not cross daylight savings time so we can stop after this check. This is why the examples only show time around a crossing.

Here is a graphic that shows all the examples:

![graphic of examples](daylightsavings.png "graphic of examples")

The red bar shows the time area with the daylight savings shift happens where the arrow on the right side shows which direction time shifts. The green readings show what the readings would look like without any daylight savings shift. In this case, each reading follows the previous one. The blue readings show what the readings looks like with the daylight savings shift. If the reading label is upside down (only happens on the right side examples) then the shift back in time caused the end time to be earlier than the start time. In example 1B. the label is on the line because the end time is equal to the start time.

The height of the DST bar is one hour and all boxes are relative to this size. The box starts at 2:00 and ends at 3:00.

The ones on the left shift from standard time into daylight savings time so the shift is negative of -60 minutes. The clock is going forward in this case. They have an "F" for forward in the identifier. The ones on the right shift from daylight savings time into standard time with a positive shift of +60 minutes. The clock is going backward in this case. They have "B" for backward in the identifier. Only one reading in each example has this shift when it crosses the red DST shift area.

One reading before any crossing of DST is shown and labeled RX. One reading after any crossing of DST is shown and labeled RZ. Any reading labeled as R#, e.g., R1, R2, ..., is impacted by the shift to DST. For the ones on the left, there is only one such reading since time is going forward. For the ones on the right, there can be multiple readings since time is going backward and multiple readings may lie in the DST shift area. Details for each example are given in the following sections.

Each example has a table. The first column gives the reading label that is in the equivalent part of the figure. The next two columns show reading start and end timestamp. Note the UTC to America/Chicago time is shown but OED stores this date/time in UTC. Thus, a reading of 2022-03-13 00:00:00-06:00 (CST) is stored in OED as 2022-03-13 00:00:00+00:00. The last two columns show the reading in UTC where the date/time is shifted to that timezone. Thus, 2022-03-13 00:00:00-06:00 (CST) becomes 2022-03-13 06:00:00+00:00 (UTC) since it needs to shift forward 6 hours since America/Chicago is -06:00 shifted from UTC in America/Chicago during standard time. These UTC values are not used in OED but show that the readings don't actually shift in absolute time and, except for the precise time, mimic the green readings in the diagram. The meter is assumed to receive a quantity reading that has 1 unit/hour.

## Algorithm

The general algorithm is described here. Following this, its application to the examples is given and the need for these steps should  become clearer.

The algorithm has 2 overall categories/steps. First, the shift is negative so we are crossing into daylight savings time. Second, the shift is positive so we are crossing into standard time. If the shift is zero then we do nothing.

1. The shift is negative and we are entering daylight savings. The end time of the reading has the shift subtracted due to cross into daylight savings. The shift is negative so subtraction makes it go later in time. As the examples show, the timezone reading in blue might start before the DST shift and might end after the DST shift. We cannot have a reading in the DST shift in this case so we use any part of the reading that is outside the DST shift. Thus we use from the start of the reading to the start of the of the moment until time plus the shift (note the shift is negative so this is earlier in time at the start of the DST shift). We also use the reading from the moment until time (end of DST shift) to the end of the reading in timezone aware time. This will, in general, split this reading into two readings. Note if in either case the start time is the same as the end time then we don't use/add that reading. This happens when the reading hits the DST shift boundary. We take the reading value and scale it proportional to the fraction of time that each of these two readings have compared to the original reading without DST. Thus, the time length of the original reading is adjusted by adding the shift. This will cause OED to use all of the reading time and value but distribute it before/after the DST shift time that does not exist in this timezone when going into daylight savings time.

    - The code needs to be modified so warnings about time lengths do not apply in this case if the sum of the two reading times is the expected time length. This is the same as the time length that appears minus the shift.
    - The usual rules for cumulate readings apply assuming the two readings split is done after checks are done.

2. The shift is positive and we are entering standard time. The end time of the reading has the shift subtracted due to the cross into standard time. (This is the same as case 1.) This means that the end time of the reading goes back in time. We do not want to duplicate time in readings in OED and this can happen because we went backward in time. To deal with this we note that this occurred so the future readings are treated differently until we finish. We also record the end time of the previous reading which is the one right before we crossed DST. We drop future readings until the end time of the reading is after the end time of the previous reading recorded. This guarantees that there is no overlap in time with readings already recorded. Note this can be the first reading that crosses DST (2F) or a later reading (1F, 3F, 4F). For the reading that will be used, we set the start time to the maximum of the end time of the previous reading that we recorded and the start time of this reading. We need to do this because it is possible there is a gap between readings which can push the start time of this reading after the end time of the previous reading. In that case we wind up using the entire reading. In most cases we change it to the record reading's end time and this shortens the reading. We then prorate the readings value to the ratio of the new reading time length to the original reading time length or (new length in UTC) / (original length in UTC). If we used the full reading this prorates to 1 so there is no change in value. If we use the first reading then it involves a crossing of DST so its time length needs to be adjusted so the prorating becomes (end time - start time) / (end time - start time + shift). Since the shift is positive, this makes the reading value smaller since it appears to span less time. If not, we will need the previous reading's end time for future use and we also note that we are in the dropping readings process since we will not see a crossing of DST in those readings. In the end, this process means we lose an hour of reading time but that cannot be avoided since the times provided for the readings overlap in the meter timezone due to shifting time backward as we crossed DST.

    - The code needs to be modified so warnings about time lengths do not apply in this case for dropped readings nor one that has it time length adjusted at the end of the process. If the first reading is used then it is possible to check its corrected time length.
    - As usual, the code needs to keep moving forward on the cumulative value used so it is correct after dropping a reading. The same is true for the end time with end only readings.

Note a gap between readings does not impact the algorithm when time goes forward into daylight savings time. Either the reading still spans the DST shift or the reading misses the DST shift. The first case is what step 1 deals with. In the second case it appears there is no DST crossing for that year in that season.

A potential issue can occur if while skipping readings in case 2, OED is given readings that go farther back in time so the start time of the new reading is not after the end time of the previous reading. This can cause OED to think they are part of the daylight saving cross when they are actually a new set of readings. In this case, OED will stop the processing of DST and just accept the new readings but will generate a warning since this could be wrong and if future readings start in the middle of DST then there can be overlap in reading time. OED does not check for overlap when readings come out of order.

Another complication is if the readings sent to the pipeline stop in the middle of case 2 while dropping readings. To deal with this, a new meter attribute is added to the database that tells if OED is in the middle of dropping readings. The pipeline sets the value it uses to the one stored on the meter so it can continue from where it was. Note that the value is false by default so it assumes it is not in DST dropping readings unless it starts that process. Note if the first readings for a meter are inside the DST shift in case 2 that is okay because OED will use the reading(s) but there were not previous ones that overlap and not time shifts occur.

If you are dealing with end only readings then the start time of the next reading is the end time of the previous reading. If the processing of reading batches stops just before crossing DST then the start time comes from the value stored on the meter. This needs an offset to work. Due to the way OED is set up, the moment returned from a Postgres query is always set to zero offset in UTC. To overcome this, the reading date/time on the meter is now stored as a string that preserves the offset. This does not change the readings table.

Note that we assume we never cross two DST shifts in a single reading or while processing a shift backward in time. This seems unlikely so not bothering to fix up this case.

### Hourly readings on the hour

This is the case where the start of the reading exactly hits the daylight savings boundary and a reading is the length of the shift.

#### Spring 2022 at shift to daylight savings

| Reading |      reading start date/time     |       reading end date/time      |   reading start date/time (UTC)  |    reading end date/time (UTC)   |
| :-----: |      :---------------------:     |      :---------------------:     |   :---------------------------:  |   :---------------------------:  |
|    RX   |     2022-03-13 00:00:00-06:00    |     2022-03-13 01:00:00-06:00    |     2022-03-13 06:00:00+00:00    |     2022-03-13 07:00:00+00:00    |
|    R1   |     2022-03-13 01:00:00-06:00    |     2022-03-13 03:00:00-05:00    |     2022-03-13 07:00:00+00:00    |     2022-03-13 08:00:00+00:00    |
|    RZ   |     2022-03-13 03:00:00-05:00    |     2022-03-13 04:00:00-05:00    |     2022-03-13 08:00:00+00:00    |     2022-03-13 09:00:00+00:00    |

This is case 1F. in the diagram and uses case 1 of the algorithm. As the diagram shows, the end time shifts from the expected 2:00 (green R1) to 3:00 (blue R1) in America/Chicago for R1 since the clock shifts one hour forward. We split the reading. The first is from the original start time of 1:45 and goes to 3:00 + -60 (moment until + shift) = 2:00. The second is from 3:00 (moment until time) to the original end time of 3:00. The first reading has the value prorated by (2:00 - 1:00) / (3:00 - 1:00 + -60) = 1. The second has no length and is dropped. In the end, we add R1 but the original value of 1 from 1:00-2:00.

#### fall 2022 at shift to standard time

| Reading |      reading start date/time     |       reading end date/time      |   reading start date/time (UTC)  |    reading end date/time (UTC)   |
| :-----: |      :---------------------:     |      :---------------------:     |   :---------------------------:  |   :---------------------------:  |
|    RX   |     2022-11-06 00:00:00-05:00    |     2022-11-06 01:00:00-05:00    |     2022-11-06 05:00:00+00:00    |     2022-11-06 06:00:00+00:00    |
|    R1   |     2022-11-06 01:00:00-05:00    |     2022-11-06 01:00:00-06:00    |     2022-11-06 06:00:00+00:00    |     2022-11-06 07:00:00+00:00    |
|    R2   |     2022-11-06 01:00:00-06:00    |     2022-11-06 02:00:00-06:00    |     2022-11-06 07:00:00+00:00    |     2022-11-06 08:00:00+00:00    |
|    RZ   |     2022-11-06 02:00:00-06:00    |     2022-11-06 03:00:00-06:00    |     2022-11-06 07:00:00+00:00    |     2022-11-06 08:00:00+00:00    |

This is case 1B. in the diagram and uses case 2/2b. of the algorithm. As the diagram shows, the end time shifts from the expected 2:00 (green R1) to 1:00 (blue R1) in America/Chicago for R1 since the clock shifts one hour backward. As a result, the blue R1 does not span any time. The end time is not after the start time so we drop this reading and are in 2b. Note this just removed 1 hour of readings and that is all that is needed. The end time of the previous reading (RX) is 1:00. The next reading (R2) has an end time of 2:00 which is after the recorded previous reading end time of 1:00 so we use this reading but prorate the value. The reading is set to go from 1:00-2:00. The reading is prorated by (new length in UTC) / (original length in UTC) = (2:00 - 1:00) / (2:00 - 1:00) = 1 so the original value is used. This makes sense since we did not remove any time. It also means we only lost a total of 1 hour as expected.

### daily readings at midnight

This is the case where one reading encompasses the shift for daylight savings but does not include the DST shift time. Note you get the same result if it is longer or shorter as long as the reading covers the entire shift. In this example, the reading takes place at the same time of the day (including the daylight saving shift) at midnight.

#### Spring 2022 at shift to daylight savings

| Reading |      reading start date/time     |       reading end date/time      |   reading start date/time (UTC)  |    reading end date/time (UTC)   |
| :-----: |      :---------------------:     |      :---------------------:     |   :---------------------------:  |   :---------------------------:  |
| no shown|     2022-03-12 00:00:00-06:00    |     2022-03-13 00:00:00-06:00    |     2022-03-12 06:00:00+00:00    |     2022-03-13 06:00:00+00:00    |
| Reading |     2022-03-13 00:00:00-06:00    |     2022-03-14 00:00:00-05:00    |     2022-03-13 06:00:00+00:00    |     2022-03-14 05:00:00+00:00    |
| no shown|     2022-03-14 00:00:00-05:00    |     2022-03-15 00:00:00-05:00    |     2022-03-14 05:00:00+00:00    |     2022-03-15 05:00:00+00:00    |

This is case 2F. in the diagram and uses case 1 of the algorithm. The readings are always at midnight so the green bar spans 24 hours. However, the blue bar actually spans 23 hours because the clock was moved forward but appears as 24 hours. The two readings created in the algorithm are 2022-03-13 00:00-2022-03-13 2:00 and 2022-03-13 3:00-2022-03-14 00:00. We prorate the first by (2022-03-13 02:00 - 2022-03-13 00:00) / (2022-03-14 00:00 - 2022-03-13 00:00 + -60) = 0.087. We prorate the second by (2022-03-14 00:00 - 2022-03-13 03:00) / (2022-03-14 00:00 - 2022-03-13 00:00 + -60) = 0.913. Note both readings together give the full reading (0.087 + 0.913 = 1.0).  The reading actually lasted 23 hours so would have a value of 23. The first reading has a value of 23 \* 0.087 = 2.0 and the second has a value of 23 \* 0.913 = 21.0. The sum is the original value of 23 and each has a rate of 1 unit/hour as it should.
In the end, we add R1 but the original value from 1:00-2:00.

#### fall 2022 at shift to standard time

| Reading |      reading start date/time     |       reading end date/time      |   reading start date/time (UTC)  |    reading end date/time (UTC)   |
| :-----: |      :---------------------:     |      :---------------------:     |   :---------------------------:  |   :---------------------------:  |
| no shown|     2022-11-05 00:00:00-05:00    |     2022-11-06 00:00:00-05:00    |     2022-11-05 05:00:00+00:00    |     2022-11-06 05:00:00+00:00    |
| Reading |     2022-11-06 00:00:00-05:00    |     2022-11-07 00:00:00-06:00    |     2022-11-06 05:00:00+00:00    |     2022-11-07 06:00:00+00:00    |
| no shown|     2022-11-07 00:00:00-06:00    |     2022-11-08 00:00:00-06:00    |     2022-11-07 06:00:00+00:00    |     2022-11-08 06:00:00+00:00    |

This is case 2B. in the diagram and uses case 2/2a. of the algorithm. The reading times stays the same: 2022-03-13 00:00-00:00-2022-03-14 00:00. The value is prorated by (2022-03-14 00:00 - 2022-03-13 00:00) / (2022-03-14 00:00 - 2022-03-13 00:00 + 60) = 0.96. The original value of the readings was 25 because it went for 25 hours. The new reading is 25 * 0.96 = 24. The rate is 1 unit/hour because the reading spans 24 according to OED in UTC.

The fix is identical to the spring case. Here you get 25 / 24 * 10 = 10.42 because one day now has 25 hours (so to speak).

### 15 minute readings on the hour

This is the case where the start/end of the reading exactly hits the daylight savings boundary but the reading also fall during daylight saving.

#### Spring 2022 at shift to daylight savings

| Reading |      reading start date/time     |       reading end date/time      |   reading start date/time (UTC)  |    reading end date/time (UTC)   |
| :-----: |      :---------------------:     |      :---------------------:     |   :---------------------------:  |   :---------------------------:  |
|    RX   |     2022-03-13 01:30:00-06:00    |     2022-03-13 01:45:00-06:00    |     2022-03-13 07:30:00+00:00    |     2022-03-13 07:45:00+00:00    |
|    R1   |     2022-03-13 01:45:00-06:00    |     2022-03-13 03:00:00-05:00    |     2022-03-13 07:45:00+00:00    |     2022-03-13 08:00:00+00:00    |
|    RZ   |     2022-03-13 03:00:00-05:00    |     2022-03-13 03:15:00-05:00    |     2022-03-13 08:00:00+00:00    |     2022-03-13 08:15:00+00:00    |

This is case 3F. in the diagram and uses case 1 of the algorithm. We split R1 into 1:45-2:00 and 3:00-3:00 similarly to other F cases. The first reading value is prorated by (2:00-1:45) / (3:00-1:45 + 60) = 1 so the value is the same 0.25 (because 1 unit/hour and 0.25 hour in 15 minutes). The second reading spans no time so it is dropped.

#### fall 2022 at shift to standard time

| Reading |      reading start date/time     |       reading end date/time      |   reading start date/time (UTC)  |    reading end date/time (UTC)   |
| :-----: |      :---------------------:     |      :---------------------:     |   :---------------------------:  |   :---------------------------:  |
|    RX   |     2022-11-06 01:30:00-05:00    |     2022-11-06 01:45:00-05:00    |     2022-11-06 06:30:00+00:00    |     2022-11-06 06:45:00+00:00    |
|    R1   |     2022-11-06 01:45:00-05:00    |     2022-11-06 01:00:00-06:00    |     2022-11-06 06:45:00+00:00    |     2022-11-06 07:00:00+00:00    |
|    R2   |     2022-11-06 01:00:00-06:00    |     2022-11-06 01:15:00-06:00    |     2022-11-06 07:00:00+00:00    |     2022-11-06 07:15:00+00:00    |
|    R3   |     2022-11-06 01:15:00-06:00    |     2022-11-06 01:30:00-06:00    |     2022-11-06 07:15:00+00:00    |     2022-11-06 07:30:00+00:00    |
|    R4   |     2022-11-06 01:30:00-06:00    |     2022-11-06 01:45:00-06:00    |     2022-11-06 07:30:00+00:00    |     2022-11-06 07:45:00+00:00    |
|    R5   |     2022-11-06 01:45:00-06:00    |     2022-11-06 02:00:00-06:00    |     2022-11-06 07:45:00+00:00    |     2022-11-06 08:00:00+00:00    |
|    RZ   |     2022-11-06 02:00:00-06:00    |     2022-11-06 02:15:00-06:00    |     2022-11-06 08:00:00+00:00    |     2022-11-06 08:15:00+00:00    |

This is case 3B. in the diagram and uses case 2/2b. of the algorithm. R1 crosses DST but the end time is before the start time so we drop the reading. The end time of the previous reading (RX) is 1:45. Thus, R2 (end time of 1:15), R3 (end time of 1:30), R4 (end time of 1:45) are all dropped because their end time is not after 1:45. R5 is used where the start time is set to 1:45 (previous end time) but that does not change anything. Its value is prorated by (2:00 - 1:45) / (2:00-1:45) = 1 as expected since the length did not change. Thus, the reading remains 0.25 for a 15 minute reading.

### 23 minute readings that cross the hour boundary

This is the case where the start/end of the reading are not aligned with the daylight savings boundary and some of the reading fall during daylight saving. This is the most general case.

#### Spring 2022 at shift to daylight savings

| Reading |      reading start date/time     |       reading end date/time      |   reading start date/time (UTC)  |    reading end date/time (UTC)   |
| :-----: |      :---------------------:     |      :---------------------:     |   :---------------------------:  |   :---------------------------:  |
|    RX   |     2022-03-13 01:23:00-06:00    |     2022-03-13 01:46:00-06:00    |     2022-03-13 07:23:00+00:00    |     2022-03-13 07:46:00+00:00    |
|    R1   |     2022-03-13 01:46:00-06:00    |     2022-03-13 03:09:00-05:00    |     2022-03-13 07:46:00+00:00    |     2022-03-13 08:09:00+00:00    |
|    RZ   |     2022-03-13 03:09:00-05:00    |     2022-03-13 03:32:00-05:00    |     2022-03-13 08:09:00+00:00    |     2022-03-13 08:32:00+00:00    |

This is case 4F. in the diagram and uses case 1 of the algorithm. We split the reading R1. The first is from the original start time of 1:46 and goes to 3:00 + -60 (moment until + shift) = 2:00. The second is from 3:00 (moment until time) to the original end time of 3:09. The first reading is prorated by (2:00 - 1:46) / (3:09 - 1:46 + -60) = 14 / 23 = 0.609. The second reading is prorated by (3:09 - 3:00) / (3:09 - 1:46 + -60) = 9 / 23 = 0.391. The original reading has a value of 23 / 60 = 0.383. Thus, the first reading has a value of 0.609 \* 0.383 = 0.233 and the second reading has a value of 0.391 \* 0.383 = 0.150. Both reading together span 23 minutes and a total value of 0.233 + 0.150 = 0.383 which matches the expected value.

#### fall 2022 at shift to standard time

| Reading |      reading start date/time     |       reading end date/time      |   reading start date/time (UTC)  |    reading end date/time (UTC)   |
| :-----: |      :---------------------:     |      :---------------------:     |   :---------------------------:  |   :---------------------------:  |
|    RX   |     2022-11-06 01:23:00-05:00    |     2022-11-06 01:46:00-05:00    |     2022-11-06 06:23:00+00:00    |     2022-11-06 06:46:00+00:00    |
|    R1   |     2022-11-06 01:46:00-05:00    |     2022-11-06 01:09:00-06:00    |     2022-11-06 06:46:00+00:00    |     2022-11-06 07:09:00+00:00    |
|    R2   |     2022-11-06 01:09:00-06:00    |     2022-11-06 01:32:00-06:00    |     2022-11-06 07:09:00+00:00    |     2022-11-06 07:32:00+00:00    |
|    R3   |     2022-11-06 01:32:00-06:00    |     2022-11-06 01:55:00-06:00    |     2022-11-06 07:32:00+00:00    |     2022-11-06 07:55:00+00:00    |
|    R4   |     2022-11-06 01:55:00-06:00    |     2022-11-06 02:18:00-06:00    |     2022-11-06 07:55:00+00:00    |     2022-11-06 08:18:00+00:00    |
|    RZ   |     2022-11-06 02:18:00-06:00    |     2022-11-06 02:41:00-06:00    |     2022-11-06 08:18:00+00:00    |     2022-11-06 08:41:00+00:00    |

This is case 4B. in the diagram and uses case 2/2b. of the algorithm. R1 crosses DST but the end time is before the start time so we drop the reading. The end time of the previous reading (RX) is 1:46. Thus, R2 (end time of 1:32) is dropped because its end time is not after 1:46. R3 is used where the start time is set to 1:46 (previous end time) and its end time stays 1:55. Its value is prorated by (1:55 - 1:46) / (1:55-1:32) = 9 / 23 = 0.391. Thus, the reading is 0.391 \* 0.383 = 0.150. Reading R4 is still within the DST shift but it can be used as usual since it is past other readings used (and abuts the modified R3). RX (23 minutes) + modified R3 (9 minutes) + R4 (23 minutes) span a total of 55 minutes. There total value is 0.383 + 0.150 + 0.383 = 0.916 which matches the expected value of 55 / 60 = 0.917 (within round off error).

### Gap between readings

If there is a gap between readings when time goes forward then the gap will be reported and be longer than expected due to the shift of time forward. However, the entire reading will be in DST and work okay. On the other hand, if there is a gap between readings when time goes backward then it is possible for OED to miss DST. For example, suppose each reading is 15 minutes long so the first of interest is 1:30-05:00 to 1:45-05:00. Now, put in a gap of 30 minutes so the next reading is 1:15-06:00 to 1:45-06:00. OED will not detect this because it did not cross DST. However, there is an overlap of this reading and the one two previously that would be 1:15-05:00 to 1:45-05:00 if it exists without a gap. With other values you can overlap multiple readings. The gap and going back in time will be logged and the pipeline warns if you go back in time and are within a DST shift. This also will not be an issue for cumulative since the reading will be rejected due to going back in time. It also isn't an issue if the gap is large enough so there is no overlap with the previous readings. We probably could detect this by comparing the timezones with the previous reading but that would mean extra work. Note OED does not try to detect all overlaps in readings so we are going to skip this case too. Also note that if the start time is the same as an existing reading (as in this example) then OED will reject the reading as a duplicate key error but only in this case.

## Readings without an offset

It would be possible for OED to infer the offset for a reading. The important part is detecting when a DST crossing has occurred. This can be done when going into DST and time goes forward. It can also be done if time goes backward but does not enter the DST crossing, e.g., 2.B. The other cases are problematic. For example, in 1.B. you have readings of:

|    RX   |     2022-11-06 00:00:00    |     2022-11-06 01:00:00    |
|    R1   |     2022-11-06 01:00:00    |     2022-11-06 01:00:00    |
|    R2   |     2022-11-06 01:00:00    |     2022-11-06 02:00:00    |

How do you know if the first or the second reading crossed DST as they both are 1:00 without offset? You might want to use the start time to help but that does not work in general. Suppose you had a reading of 00:00-1:30 without offset. Did that come from a reading of 00:00-05:00 to 01:30-06:00 (not DST crossing) or from 00:00-05:00 to 02:30-06:00 (DST crossing)? In both cases the end time is after the start time. It is the case that the reading length might vary but OED allows for reading lengths to vary. OED could try to get this right but there is a change it will get it wrong. Given this and the fact that any meter that does DST should have an offset, we are only going to do DST for readings with offsets. If someone gave readings without an offset but asked to honor DST, the offset would always be 0 for all readings (would be in UTC) so OED would never find a DST crossing.

Before this was figured out, the following code was created. It is given here in case someone needs to look at this in the future. It is not complete and is unfinished.

    function dstShift(meterZone, startTimestamp, endTimestamp) {
        // We assume that any shift for DST is less than this amount. The exact value is not important but it
        // is important that it is greater and you don't shift into a future DST crossing. You also don't want
        // to shift so much that a reading that happened to go backward is then shifted enough to go through DST.
        // As pf 2022 the max was 1 hour so pick 1 hour for now.
        const maxHoursShift = 1;
        // Get the UTC offset for the timestamp. It will be zero if in UTC.
        let startOffset = startTimestamp.utcOffset();
        let endOffset = endTimestamp.utcOffset();
        if (startOffset === 0 && endOffset == 0) {
            // We are going to assume we are in UTC if both shifts are zero.
            // If so, then we have to do special work because the offset is not known.

            // This gives the date/time unchanged with the meter zone.
            const startTimestampMz = moment.tz(startTimestamp.format('YYYY-MM-DD HH:mm:ss'), meterZone);
            const endTimestampMz = moment.tz(endTimestamp.format('YYYY-MM-DD HH:mm:ss'), meterZone);
            // Get the shifts for the Mz timestamps.
            let startOffset = startTimestampMz.utcOffset();
            let endOffset = endTimestampMz.utcOffset();
            // The last two timestamps are good to get the offset unless you went backward in time and
            // the end time is within the DST shift so check for this.
            // If so, we get the time in the meter's time zone to see if there is a shift.
            console.log('100 zero offset readings with meterZone ' + meterZone);
            console.log('110 startTimestampMz ' + startTimestampMz.format());
            console.log('111 endTimestampMz ' + endTimestampMz.format());
            console.log('120 startOffset ' + startOffset + ' endOffset ' + endOffset);
            // if (endTimestamp.isSameOrBefore(startTimestamp)) { // TODO correct???
            // This can happen if you crossed out of DST and time went backward.
            // In this case, you may not see a shift because moment does not change the offset
            // which in the DST shift time.
            // This can also happen just because of an out of order reading.
            // To make sure this is is not likely from an out of order reading, check that the
            // end time is during the DST shift that desired.
            // We shift the end time by more than any allowed shift to be sure it is on the other side if
            // there was a DST crossing since time went backward here.
            const laterEndTimestamp = endTimestampMz.clone().add(maxHoursShift, 'hours')
            zoneUntil = getZoneUntil(meterZone, laterEndTimestamp);
            console.log('130 zoneUntil ', zoneUntil);
            // TODO this does not work quite right since if the end time really was 1:00 it will treat as DST crossing but it really was 2:00 shifted back to 1:00.
            if (endTimestamp.isSameOrAfter(zoneUntil) && endTimestamp.isSameOrBefore(zoneUntil)) { // TODO need with shift added???
                // The reading is between the start and end of the DST shift. Thus, we assume it crossed
                // out of DST and return the associated shift.
                // startOffset = startTimestampMz.utcOffset();
                console.log('140');
                endOffset = laterEndTimestamp.utcOffset();
            }
            // 	if (startTimestamp.isDST() !== endTimestamp.isDST()) {
            // 	console.log('*************startTimestamp ' + startTimestamp.format() + ' endTimestamp ' + endTimestamp.format())
            // };
            // }
        }
        console.log('170 startOffset ' + startOffset + ' endOffset ' + endOffset);
        return startOffset - endOffset;
    }

### Meters

The meters table in the DB will have a new attribute/column:  
honor_dst dst_type DEFAULT 'false'::dst_type  
where there is a new enum of  
CREATE TYPE dst_type AS ENUM('true', 'false', 'default')

We also need to add this to the admin meter pages so it can be created/edited for an existing meter.

### Pipeline

src/server/services/pipeline-in-progress/processData.js was modified to do what is described in this document. Please see the code for the details on the implementation.
