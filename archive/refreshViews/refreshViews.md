# Update method for refreshing views

## New idea

The end of processData in src/server/services/pipeline-in-progress/processData.js returns the result, e.g., the readings to add, so know that some readings are being added/changed. This means a refresh should happen. Do both daily and hourly to be safe. If no readings are added then the refresh is skipped.

New database attribute should_refresh. No current table is a great place so either a new table or stick in preferences since it explicitly updates/returns values so it would probably work. New table probably best. On migration it would be false.

should_refresh is set to false after each refresh. It is set to true each time processData returns readings to add as described above.

src/server/services/refreshHourlyReadingViews.js & src/server/services/refreshReadingViews.js are modified so the refresh only happens if should_refresh if true. If false then log.info that skipped.

## Older

These are some quick notes to remember ideas to do a full writeup.

Later note: This has some issues so is not being done:

- The start/end depends on the meter.
- If load in a sequence of meters (as common on auto update) then refresh many times
- Have to be very careful if new readings before ones already refreshed since could be a short amount of time but still need to refresh both views.

- keep the earliest and latest timestamp for added data to the database via the pipeline.
  - Assumes all data comes via pipeline.
  - Need to make sure it deals with dropped data in pipeline but if not then will only refresh more frequently than needed.
  - Initialize to -infinity, +infinity when start so will do refresh right away.
- Try to create code on server that periodically runs the refresh. The idea is that if OED server is down then a refresh does not matter. This would eliminate the need for a cron job to be set up.
- If the latest - earliest timestamp is more then one hour then run the refresh of the hourly view and if more then one day then run both.
  - Maybe always run both since that is likely to be done in future as it speeds up.
  - Note >@ on range for line means it excludes partial hours & days. For bar it shows the partial day. The difference between line & bar should be resolved. We should see if any other graphics have variations.
- See about using the hourly view to update the daily view to make it faster. Since hourly will now run before daily this should be safe.
- See if can limit refresh to the earliest to latest timestamp since these are the possible dates impacted. Need to round down/up so include a full hour or day.
