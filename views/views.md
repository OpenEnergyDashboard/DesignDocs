# Updating views

## Introduction

OED uses materialized views in the DB to speed up getting readings for graphics. This proposes changes to this system for several reasons:

- Since its introduction, OED modified the views to be materialized. This make them substantially faster so they are more important to speed.
- Most users see daily or maybe hourly data and not the raw/original meter data. This means the views are the primary way to get reading data.
- Thinking of either daily or hourly views as independent is problematic so both should be kept up-to-date.
- As discussed in [merge meter & groups design doc](../MergeMeterGroup/mergeMeterGroup.md), the difference between meters and groups is blurring so both are equally important and used by users.
- It is believed that the refresh of the hourly and daily views can be sped up and possibly done less frequently.

The proposed changes are:

- Whenever the views are refreshed, the hourly will be done first and the daily second. This will allow the daily to be simplified and sped up by using the current hourly view.
- The refreshing of views will be automated within the OED software rather than a separate cron job. There are several reasons for this:

  - If OED is down then refreshing the views is not important because no one can graph data. This is in contrast to getting the meter data where readings could be lost.
  - This will simplify site setup and make it more robust.
  - The use of cron-type jobs within our node system was demonstrated.

- Group views will be created that mirror the meter ones. This will allow their use to speed up getting group readings similarly to meters. Currently the group readings are determined by summing the underlying meters during each request. There are several reasons for this:

  - Generating the group data on the fly means you always get the latest data. However, groups can only be graphed as hourly or daily. The underlying meters are only correct at this accuracy if the views are refreshed. In the current system it is possible for the sum of the meters in a group to differ from the group in a graphic due to the meter views being out of date. It is believed that making that always work is important so using group views would fix it.
  - OED has gotten all meter readings from the DB to be fast, generally around 20 ms. Groups generally call the meter function for each meter in a group and then sum the values to get the group value. First, with lots of underlying meters it will slow down and scales linearly. This means a group could take longer than desired (OED would like to have all reading requests to the DB complete in less than 100-200 ms). Second, testing on 3D found it took around 100 ms longer in fixed overhead to do a group vs. the sum of the individual meter times. It is believed this is due to the grouping for the sum that does not run quickly. A similar issue was fixed for meters by using an index on the view. It is unclear that would work with the group values generated on the fly. [Postgres query optimization](../postgresQueryOptimization/postgresQueryOptimization.md) has more details.
  - The use of materialized views for meters has been shown to be very effective and the space requirements are not bad so rolling the same idea for groups makes sense at this point. However, as discussed in detail below, a group view requires entries for each compatible unit to a group and not just a single entry for the readings. This means that the space used will be greater. It is hoped the advantages of speed outweigh the space disadvantage but testing is needed.
    - Time-varying conversions may push OED to make a similar change to meters. This could either be a test of the idea or an extension if first done there.
    - OED also chose to include min/max values in the views when they were introduced. This was a similar time/space tradeoff.

  One complication is that modification of a group would make the view data inconsistent with the group views. This is not a common operation so the views will be refreshed when this happens and OED already has done this for other operations.

## Changing meter view refreshing

The current views are created/refreshed by daily_readings_unit & hourly_readings_unit in src/server/sql/reading/create_reading_views.sql. These two views use the same methodologies but vary the time involved. This includes logic to deal with missing readings and readings that cross the hourly/daily time boundaries. The proposed change is to leave the hourly view unchanged. It will always be done first. The daily view is calculated by averaging the hourly view values since the views are rates and each value is the same length of time (1 hour). If an hour value is missing then it will not contribute to the average but the value should be correct considering that. This means that daylight savings transitions or missing reading where the number of hourly readings in the day can be less than 24 will still work correctly.

This should be moderately faster since it is using the hourly view which generally have fewer values than the reading table. It also uses a simpler formula that should slightly increase the speed. The actual speed should be checked as was done in [Postgres query optimization](../postgresQueryOptimization/postgresQueryOptimization.md) to verify this is true since an index or something else might be needed.

The views are primarily refreshed in src/server/services/refreshAllReadingViews.js. This needs to be modified to remove the Promise.all which can run in parallel. It will be replaced with a refresh one at a time in the order desired. src/server/services/refreshHourlyReadingViews.js & src/server/services/refreshReadingViews.js will be left since they may be needed for historical reasons but a comment should be added to indicate they are deprecated and their usage is discouraged. package.json has scripts for each of the refresh methods. The same two should have a comment about being deprecated since they run the deprecated code.

### possible change in daily view values

For this discussion the following example is used:

- The readings are done every 15 minutes for this meter.
- The first hour has three readings that are each a quantity of 25.
- The other 23 hours in the day have a reading of 50.

The current daily view sums the raw/meter readings x the time of the reading (in hours) and divides by the total time of all readings (in hours). This is (25 x 3 + 50 x 92) / 23.75 = 196.842 The values used are:

- In the numerator, the first number is the reading value so it is 25 for the first 3 points and 50 for the next 92 points (23 hours x 4 points/hour).
- In the numerator, the third number is the number of readings so it is 3 and 92. This is equivalent to the sum since the two groups of readings have the same length for each reading.
- The denominator is 23.75 since it is for one day but one reading is missing so it a quarter of an hour less for the total time of all the readings.

Note the actual code is more complex to deal with readings that are not entirely within the day and ones that vary in length. However, this gives the same value in a simpler way for these readings.

The new daily view will average the hourly view for the day which has:

- 100 for the first hour because there are 3 readings of 25 so it is 25 x 3 / 0.75 = 100. This is for similar reasons to the discussion above for the current daily view.
- 200 for the other 23 hours because 50 x 92 / 23 = 200.
- The average of these values is (100 x 1 + 200 x 23) / 24 = 195.833.

Note this differs from the value above. It is not a lot in this case and, in general, will not be but can be large in special cases.

The new value actually has a positive attributes. It is averaging within the hour so it is considering the points within that hour when correcting for the missing time. The daily corrects across the entire day. It seems more likely that the missing value will be closer to ones near it in time. A better solution might be to average the points right around the missing one but that can cross hours (and days) so it is likely to be significantly slower and more complex. Given all of this, the new way seems fine but the documentation for OED should note the change for this migration.

## Group views

Group views will be similar in concept to the current meter views but will have to differ in important ways.

Currently, the group readings are determined by summing the underlying meters during each request by calling the meter readings function for each deep meter. This means the readings returned for each meter is converted into the desired graphic unit before it is summed. This is necessary since different meters within a group can collect in different units so you can't directly sum them. Given this, OED cannot sum the meters into a materialized view as done for meters that represents the group with a single value for each reading.

The overall change for groups is that the method used to get group graphic data must be rolled into the group view but made to work for any compatible graphic unit. This means that for each allowed graphic unit the meter data is converted to that unit and then summed. It is stored in the view with an additional column of graphic unit.

The compatible graphic units of a group is the graphic units that are compatible with each deep meter of the group. Currently this is only calculated on the client-side using functions in src/client/app/utils/determineCompatibleUnits.ts. The basic idea is:

- For each meter, get the set of compatible graphic units. These are the ones with an entry in cik for that meter unit and graphic unit pair.
- Find the intersection of all the meter sets. This is the set of compatible graphic units for the group.
  - Note that since the group is the intersection of the meters, the number of compatible graphic units of the group is generally smaller than the underlying meters. It is at most the smallest number of compatible graphic units in any deep meter.

There are likely several ways to do this calculation in the DB. Here is one thought that might work:

- Get the deep meter ids in the group and store in variable deep_meters.
- Calculate the number of deep meters in the group and store in variable num_deep_meters.
- For each visible graphic unit (type_of_unit is not a meter unit or displayable is not none), count the number of rows in cik where the source is in deep_meters and the destination is the graphic unit being considered. If this number is the same as num_deep_meters then this graphic unit is compatible with the meter. The reason is that there must be an entry in cik for each group deep meter and graphic unit.
- The group view needs to calculate the view for each of the compatible graphic units found for the group.

In some cases you could pick a common unit to sum them in and then convert for the desired graphic unit but that does not work if the conversions have different values to a unit. For example, the cost per energy unit is not the same for different meters so you cannot convert to a common energy and then convert to cost. Given this, this potential optimization is not done since it adds nontrivial complexity to the code.

Now a rough estimate of the increase in database size is made. The following sizes in byes for each type is used:

- integer: 4
- double precision: 8
- timestamp: 8
- tsrange: 20 (which seems to vary but using 8 bytes per time and overhead)

x is used as the number of readings. It is assumed that each meter and group has the same number of readings.

This assumes the reading are every 15 minutes for a meter. Thus, the hourly view is 0.25 the number of readings and daily view is 1/96 = 0.01. Both are 0.25 + 0.01 = 0.26. So, having x readings means both meter views have 0.26x.

The space requirements for the current readings:

- A row in readings has 28 bytes
  - meter_id/integer: 4
  - reading/double precision: 8
  - 2 x timestamp: 16
- All readings are 28x in size

The space requirements for the current meter views:

- Each row in the hourly/daily meter view has 48 bytes:
  - meter_id/integer: 4
  - reading/double precision: 8
  - min/double precision: 8
  - max/double precision: 8
  - interval/tsrange: 20
- Both views are 0.26x \* 48 = 12.48x or 12.48 / 28 \* 100 = 44.6% of the reading size

The space requirements for the proposed group views:

- Each row in the hourly/daily group view has 52 bytes:
  - meter_id/integer: 4
  - graphic unit id/integer: 4
  - reading/double precision: 8
  - min/double precision: 8
  - max/double precision: 8
  - interval/tsrange: 20
- An estimate (hard to know value) of the number of compatible graphic units in  group is 2-10 with an average of 6.
- Both views are 6 \* 0.26x \* 52 = 81.1x
  - This is 81.1 / 28 \* 100 = 290% of the reading size
  - Compared to the current situation it is 81.1 / (28 + 12.48) \* 100 = 200% increase

This means the DB will be about 3x larger which isn't trivial but isn't terrible. It might be more or less depending on the average number of compatible units per group at a site.

A very big site might need:

- readings:
  - 50 meters
  - 20 years per meter
  - 20 years \* 365.25 days/year \* 24 hours/day \* 4 readings/hour = 701280 readings/meter
  - 701280 readings/meter \* 50 meters = 35 million which is x.
- The size needed for the DB would be:
  - Current readings: 35M \* 28 = 0.98 GB
  - Current readings & meter views:  35M \* (28 + 12.48) = 1.4 GB
  - Current readings & meter views & new group views:  35M \* (28 + 12.48 + 81.1) = 4.3 GB

This does not account for the smaller tables nor the DB overhead.

Just for the record, if the following view changes are made then it would impact the size as follows:

- Do meter views for each compatible graphic unit. This should allow time-varying via views for hourly & daily:
  - Assume 10 compatible graphic units per meter. It is higher than groups since it is not the intersection of many meters.
  - Both views are 10 \* 0.26x \* 48 = 124.8x.
  - A very big site would need 35M \* (28 + 124.8 + 81.1) = 8.2 GB
- Do baseline via views. This means a second entry for each current one so 16.4 GB.

These increases in view size will slow down the refresh so the ideas below on speeding them up may be important.The overall DB size is getting nontrivial but may be okay for a larger site. The tradeoff of speed of views vs. space needs to be tested and decided.

### graphic readings with group views

The DB logic to sum the individual meters needs to be replaced to use the group views. It is likely to be similar types of changes across all the functions. In the end, the result should be the same (except when readings are missing for daily as described above). There is sometimes other logic in meter readings for each graph type that is not currently present in group readings since groups reuse meters. That logic will need to be added to the group DB functions. It is likely it will be the same (or very similar) so it probably should be moved to a function so it can be used across the meter and group code. Another change is the the lookup to the group view will take care of the graphic unit.

The following changes are needed to use the group views when getting readings for graphics:

- src/server/sql/reading/create_reading_views.sql has group_line_readings_unit & group_bar_readings_unit. Note radar and compare line use the line data too. Similarly, map uses the bar readings.
- src/server/sql/reading/create_function_get_3d_readings.sql has group_3d_readings_unit.
- src/server/sql/reading/create_function_get_compare_readings.sql has group_compare_readings_unit.

### group view refreshing

The group view refreshing will need to be added in the order specified. It can go into src/server/services/refreshAllReadingViews.js in the desired order.

### group updates

If the deep meters of a group is changed then the view will have the old values. This can be fixed by refreshing the group views. The group deep meters can be changed in either create or edit of a group. This can happen if the child meters or child groups are change. It is probably easiest to check as part of the save (handleSubmit) for a change in the deep children (called all children on the web page) that both pages keep track of. Note it isn't known if the deep meter ids are kept in sorted order so using a lodash function (or something equivalent) to do the compare that takes this into account might be best.

Editing meters in src/client/app/components/meters/EditMeterModalComponent.tsx already has logic for refreshing views in handleSaveChanges() that can be used as a model. This is likely going to change the group component, information sent with the route and the route on the server to do this for groups.

## Automating cron jobs

There are two goals as part of this effort:

- Replace the cron jobs that are set up for a site ([production site help page steps 12 & 13](https://openenergydashboard.org/helpV1_0_0/adminInstallation/)) with JS code to do this.
- Limit the refresh of views to when it is actually needed.

### replacing cron jobs

Get a node package to do the equivalent of cron job by the Unix system. The demonstration probably used node-cron but cron seems more supported and used. Set up the code to use this in JS to refresh the views and make sure it always starts up as needed when OED restarts on the server. By default, it will run every hour. If possible, it should run at 5 min past the hour because many meters are updated on the hour.

The migration documentation for this version needs to tell sites to disable the Unix cron setup so it does not run twice and/or do the wrong order.

It would be nice to modify the site settings (src/client/app/components/admin/PreferencesComponent.tsx) to allow the site to set the frequency of refreshing. In the ideal setup it would have a drop down for hourly and daily along with the ability to put in a custom value. Limits on the value should be considered so it is not done too fast or too slow (need to decide values). See the bar interval in src/client/app/components/BarChartComponent.tsx for an example of doing this. The route and DB need to be modified to store the frequency and it would be used for the setting up the cron job (and changing if the value is updated). In addition, a refresh views button should be added that does a refresh of all views. It will run no matter what, even if it was recently run.

### limiting refreshing

The end of processData in src/server/services/pipeline-in-progress/processData.js returns the result, e.g., the readings to add, so it is easy to know that some readings are being added/changed. This means a refresh should happen at the next time request. If no readings are added then the refresh is not needed based on this reading data processing. If multiple batches of readings are processed then any one with new readings would require a refresh.

An new database attribute should_refresh will store this value. No current table is a great place so either a new table or stick in preferences since it explicitly updates/returns values so it would probably work. New table probably best. On migration it would be false.

should_refresh is set to false after each refresh. It is set to true each time processData returns readings to add as described above.

All the JS code that performs refreshes of the views are modified so the refresh only happens if should_refresh if true. If false then it is skipped. Either way, a log.info logs what happened (done or not). This only applies to the refresh of all views and not the deprecated view refreshes that do only hourly or daily meter views.
