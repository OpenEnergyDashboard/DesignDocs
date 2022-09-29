# Dealing with long time length readings

## Issue

This relates to issue #665 and other ideas. There are times that a site would have a meter with readings that are long time length. For example, a site wants to show water usage and gets the reading from a monthly bill from the water utility. OED already fixed up the code to show raw readings when there are too few points to show on a graph. After that, OED used daily and hourly readings to show the usage before going to raw readings. This can lead to showing readings that do not exist as averages of underlying readings so it is similar to the previous issue but with a different solution/signature. Examples are:

1. The readings are longer than a day. In this case you will see daily and hourly points on graphs but they will be created by slicing up the longer readings. For example, the monthly water readings will be sliced up into daily readings so 1 reading becomes 28-31 readings. What you really want is to show the raw readings and not interpolated averages.
2. The readings are shorter than a day but longer than an hour. It is okay to see the daily points but you should not see the hourly points. This is the same idea as in case 1 because it is averaging a longer time reading into shorter ones. The current system shows both. Raw readings are okay and should be shown instead of hourly averages.
3. While indirectly related to this, we have an issue that short-time readings need to switch to raw readings later by allowing fewer hourly points. We currently do this with a site environment variable but that does not take into account variation in meter reading length. The proposed solution will also address this issue.

Cases 1 & 2 mean that you do not use averages that are less than the length of the underlying readings.

## Outline of proposed solution for meters

Each meter will have an associated value that gives the expected length of the readings (frequencyReadings or FR). This value can be used to determine the expected number of points for daily, hourly, and raw readings. For now, the value will need to be set by the admin as automating has some issues. The default will be 15 minutes and this causes the system to behave similarly to how it currently does. This is based on the idea that meters typically have a set length of readings. The units will always be minutes/reading. Note OED currently has an environment variable that gives a site level frequency of readings. This will be removed and replaced with one set on the admin page where the default value will be 15 minutes as is currently the case for the environment variable.

Another change is OED will now try to graph with the shortest interval that works. Currently it uses daily then hour then raw where it switches when there are too few points in a category. The idea is that raw readings have no averaging and are the truest representation of the meter. Hourly is next and then daily. This will be done by checking raw then hourly then daily instead of the other way around as is currently done.

Currently, OED has Postgres decide what type of readings (daily, hourly, raw) to return. This will be changed to decided on the server in code and passed to the DB. The primary reason for this change is we are changing OED so the listing of all graphed items will include the frequency of the readings. The DB could return these values for each meter/group but they are not readings so it would probably either be two queries or a more complex return of data. Another advantage is the code can make choices given the entire state of the system. A negative is that we cannot easily count the actual number of points in the readings to make choices. However, we don't currently do that and it would only apply to raw readings (the other can be determined by a formula).
TODO is this okay. The FR for the meter should be in redux state but the DB is always up to date if could use that.

To make the system more general, we define maxReadings or MR as the most readings OED should return for graphing. For now it will be set to 1440 as it currently is. This comes from 60 days of hourly readings or 60 * 24 = 1440. In the future, OED could detect the quality of the screen and set MR appropriately.

The final defined term is timeInterval or TI that is the length of time that is being graphed. Overall, you can relate these by # readings = timeInterval / frequencyReadings or NR = TI / FR.

TODO Should MR be separated for raw and hourly? This may be a good idea to allow more raw readings when FR is small.
 Here is pseudocode for the proposed solution:

    // What type of graphing should be done.
    Graphing.type = {
        RAW: 'raw',
        HOURLY: 'hourly',
        DAILY: 'daily'
    };

    // Determine whether to use raw, hourly, or daily readings.
    // The function takes the time interval for the graph, the frequency of readings and the maximum number of readings/points to return.
    function typeLineReadings(graphInterval, frequencyReadings, maxReadings) {
        // 1440 minutes is 1 day.
        if ((graphInterval / frequencyReadings <= maxReadings) or (frequencyReadings >= 1440)) {
            // Returning raw means the number of points is less than or equal to the maximum number of points.
            // The "or" allows for long frequency readings in the unlikely case that the time interval is so long that
            // it would return too many points. For now, we let it return as many as needed since we don't want to
            // average if the time interval is so long (at least right now, future enhancement?).
            return Graphing.type.RAW;
            // 60 minutes is 1 hour.
        } else if ((graphInterval / 1 hour <= maxReadings) and (frequencyReadings <= 60)) {
            // Returning hourly means the number of points is less than or equal to the maximum number of points.
            // The "and" prevents returning hourly if the time interval for readings is greater than or equal to an hour
            // where the previous check means it is already less than 1 day.
            return Graphing.type.HOURLY;
        } else {
            // Returning daily because the others do not work. It is possible that the number of days in the time interval is
            // so large that it would return too many points. For now, we let it return as many as needed since we don't want to
            // average if the time interval is so long.
            // Note you would want to average Math.ceil(graphInterval / (1 day * maxReadings)).
            return Graphing.type.DAILY;
        }
    }

    // Determines the time interval based on the start and end timestamps.
    // It uses the shorter of the times provided and the min/max on the meter.
    function timeInterval(start, end, meterMin, meterMax) {
        // make sure works if infinity
        let startUse = max(start, meterMin);
        let endUse = min(end, meterMax;
        return TimeInterval(startUse, endUse);
    }

## Outline of proposed solution for groups

Groups cannot be graphed with raw points because the underlying meters generally have different frequencies of readings. Even if they are the same, if the start time differs or one reading is an exception then it causes issues. The way meters works is not to use select points at a higher rate than the FR for the meter. The question with groups is what to do if the FR varies with the meters included. Suppose there is a meter with a low FR (less than 1 hour) and one with a high FR (1 month). If you use 1 day (because of the 1 month FR) then the other meter will show low frequency data when better is available. Also, you still interpolate the monthly meter to the daily level. If you use 1 hour (because of the less than 1 hour FR) then the other is heavily interpolated (even worse then 1 day level). The best choice is unclear so admin input might be best with a reasonable default. Proposal:

- The default is the median FR to make decisions. This means the "typical" value is chosen.
- The admin has a value that goes from 0-1 (lets call it high frequency skew or HFS). Sort the FR for all meters in the group and use index (# meters - 1) * HFS. If that is not an integer you weight average the two index above and below by the distance to the index value (assuming this is easy to do). This value is the group frequency reading (GFR). Examples:
    - HFS = 0 then you take the smallest FR which skews far from high frequencies.
    - HFS = 1 then you take the largest FR which skews far to high frequencies.
    - HFS = 0.5 then you take the median which is the middle and the default.
    - HFS = 0.75 skews toward higher frequencies.

Use the GFR instead of the meter FR to decide how many points to show but with one change that you never show raw readings. Note that small time intervals may lead to a small number of points but that cannot be avoided. This guarantees that all the meter values are at the same timestamp so can easily be combined.
TODO If do in DB then verify that it does not use a smaller range of time if the meter has a smaller time range so points not aligned.
TODO make sure works if underlying meters span different time lengths - I think it will count them as zero value. This is a question of internal to the TI so time gaps for a meter.

## Subtleties

A meter with a long frequency of readings will not use the hourly or daily view to get readings. For now, it cannot be removed because compare and other parts of the code use these views. The negatives are the time to create the value in the views and the fact that there are more values in the view than the raw readings. For example, monthly readings have about 1 month x 30 days/month x (1 reading/day + 24 readings/day) = 750 new readings for each raw reading. For now, we let this go because it would be painful to fix and because there are not many meters like this nor do they have that many readings.

As the examples below show, when the frequency of readings is low (see 1 minute example), there is only a small time interval that will choose raw. When you switch to hourly, the number of points may be small. This can be adjusted by the site admin to allow more points by setting the frequency of readings to a larger value. However, you will get more points for small time intervals. This would also allow for zooming a scrolling of the raw data as you have more points.

If the frequency of readings actually varies then the formula to get the number of points can be off. If it is a small variation or somewhat random then it may be the average used is pretty good. If not, then some time ranges will return more or less points than desired. This can be an issue near the boundaries of raw, hourly and daily. Most meters do not vary a lot so we will not worry about it for now.

TODO It is possible that either the start or end time is infinity. This happens when the user is using the default value and not the one set. For example, when you first load OED both are infinity so you get all readings. The infinity value cannot be used to get a proper time interval for determining typeLineReadings. Another point is that the current selection done in the DB shortens the time interval if there are not readings in the start/end of the range. Knowing this allows for a better estimate of the number of readings but it may not be essential depending if we do this outside the DB. The case of infinity is more common and must be dealt with. OED will store the min/max time on the meter in the DB. We replace infinity with the appropriate one. We could modify this value when we refresh but that would mean new raw values would be missed. It should not be hard to modify the pipeline to get the min/max of the new readings and then update the meter for them. This seems the best choice. We could keep the min/max for daily and hourly for each meter since they can vary from the raw until the refresh. For now we will not since site are told to refresh regularly and the difference in time should, in general, be small. An alternative is to have the DB calculate each time and/or have a trigger on new readings. An issue is that the time range is for all readings and not each meter. Thus, we will need to take the graph level min/max and shift to the meter min/max for each meter. Given this, it would make sense to do this for all values and not just infinity in case a meter has fewer readings.

## Examples

The examples all use 1440 for the maximum number of readings/MR. FR unit is time/reading, e.g., min/R. timeInterval / frequencyReadings has units of time / time/reading = readings where the last column is the same.

| Ex. # |          FR          |    TI/graphInterval   |        timeInterval / frequencyReadings        |    timeInterval /  1 hour <= maxReadings   | Frequency of points returned |
| :----:| :------------------: | :-------------------: | :--------------------------------------------: | :----------------------------------------: | :--------------------------: |
|   1   | 1 month/R = 30 days  | 3 years = 1096 days   | 1096 days / 30 day/R = 36.5 <= 1440            | NA                                         | raw / 36 points              |
|   2   | 1 day/R              | 3 years = 1096 days   | 1096 days / 1 day/R = 1096 <= 1440             | NA                                         | raw / 1096 points            |
|   3   | 1 day/R              | 10 years = 3652 days  | 3652 days / 1 day/R = 3652 > 1440; FR >= 1 day | NA                                         | raw / 3652 points            |
|   4   | 1 hour/R             | 60 days = 1440 hours  | 1440 hours / 1 hour/R = 1440 <= 1440           | NA                                         | raw / 1440 points            |
|   5   | 1 hour/R             | 61 days = 1464 hours  | 1464 hours / 1 hour/R = 1464 > 1440            | 1464 hours/ 1 hour/R = 1464 > 1440         | daily / 61 points            |
|   6   | 15 min/R = 0.25 hr/R | 360 hours = 15 days   | 360 hours / 0.25 hour/R = 1440 <= 1440         | NA                                         | raw / 1440 points            |
|   7   | 15 min/R = 0.25 hr/R | 361 hours = 15+ days  | 361 hours / 0.25 hour/R = 1444 > 1440          | 361 hours / 1 hour/R = 361 <= 1440         | hourly / 361 points          |
|   8   | 15 min/R = 0.25 hr/R | 1441 hours = 60+ days | 1441 hours / 0.25 hour/R = 5764 > 1440         | 1441 hours / 1 hour/R = 1441 > 1440        | daily / 60 points            |
|   9   | 1 min/R              | 1440 min = 1 day      | 1440 min / 1 min/R = 1440 <= 1440              | NA                                         | raw / 1440 points            |
|   10  | 1 min/R              | 1441 min = 1+ day     | 1441 min / 1 min/R = 1441 > 1440               | 24+ hour / 1 hour/R = 24 <= 1440           | hourly / 24 points           |
|   11  | 1 min/R              | 61 days = 87840 min   | 87840 min / 1 min/R = 87840 > 1440             | 61 days * 24 hr/day / 1 hr/R = 1464 > 1440 | daily / 61 points            |

### Notes

- Ex. 1: The number of points returned is the same as the number of months. Thus, it is possible to get limited points when limited months in the time interval.
- Ex. 3: Any meter with FR >= 1 day will return raw points. The worst possible case for too many points is 1 day/R where greater than 1400 points returned if more than 1440 days = 3.94 years. This clearly can happen but isn't bad but it can be a lot at 20 years (7305 points). This is too bad and, as noted above, we will let it go and not average daily points to reduce.
- Ex. 4: With 1 hour/reading, you stay with raw through 60 days and never exceed limit on points.
- Ex. 5: With 1 hour/reading, you use daily after 60 days. As with Ex. 3, you can get more than the desired maximum number of points.
- Ex. 6/7/8: With 15 minutes readings, you get raw up to 15 days, then hourly until 60 days and finally daily after 60 days. The minimum daily points is 60.
- Ex. 9: With 1 minute readings, you get raw up to 1 day.
- Ex. 10: With 1 minute readings, you get hourly after 1 day and up to 60 days. The number of points can be low.
- Ex. 11: With 1 minute readings, you get daily after 60 days. It is possible to get too many points if you have a long time interval.
- The fact that MR is the same for all checks means the check of "frequencyReadings <= 60" for hourly does not ever have an impact. This can be seen since "graphInterval / frequencyReadings < graphInterval / 1 hour" when FR > 60 minutes as needed for the hourly check. Thus, it would pick raw before hourly.However, it could if they differed when the cutoff for raw was lower than hourly.
TODO Leave test if allow MR to vary by test.

## Current code

src/server/sql/reading/determineMinPoints.js for the current code on when switches occur. It uses daily if the # points > 60 (about 2 months) and 1440 * FR for site for minimum hourly points. The examples above follow this but on a meter not site basis.
