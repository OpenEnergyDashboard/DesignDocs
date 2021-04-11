# Thoughts on modifying fast-pt

## Overview note

After having spent too much time analyzing the possibilities, it may be the case that we don’t want to create new views. We really need to see how fast that is in the DB to decide if it would help and be worth the storage.

The other points/questions are still worth pursuing independently of this.

## Current system

The current system (as of Dec. 2020) uses a materialized view to aggregate the meter readings to get the usage for each day. This is updated via a cron job each day somewhat after midnight. It also creates a view (not materialized) that gives the minute and hourly values. The idea is that we often have enough days that graphics can use the day view so it should be materialized to make it fast. Also, this table would be 1/24 the size of the reading table if we had hourly readings. The other views seemed less likely to be used so it was fine not materialize them but having them made access easier. (See Question below on speed of hourly view if have hourly data.) When we do look at the hourly values, it should be for a limited number of points because the request was for a limited time range; if it is for a longer time range then we would use the day view.

The SQL makes sure that there is a minimum number of points in a line graph (when possible). It starts with the view with the least data and checks if it has the needed number of points. If yes, it uses that view. If no, then it goes to the next view. Once it picks a view it determines if it should regularly average points to reduce the number to display. (I have not yet carefully analyzed the regular average so am not certain of these details.) I believe it tries to get within a range of points. For example, if you have 3 years worth of data and you want 50 to 500 points, you could average every three points to get 365 graph points of the total of 3 * 365 readings points. For this to work you need to touch all the points in the range.

Note: The code seems to not do this when there are a limited number of days. See [GitHub issue #519](https://github.com/OpenEnergyDashboard/OED/issues/519) for more information on this.

Question: How much does it cost to get the hourly view data vs. readings when the actual readings are hourly anyway? Should we optimize this case that is common, at least for Mamac meters?

## Analysis

This data was created from this [spreadsheet](./fastPtAnalysis.xlsx). A second version in the original LibreOffice format is also in the same directory.

## Concerns

The first issue is that when you have limited days of data, you need to go to the hourly table to get the needed points. Let's assume we want a minimum of 100 points. (I’m raising the min from 50 to 100 because I expect displays to become higher resolution but the same ideas apply either way. The actual min chosen depends on how users perceive the line graph with that many points.) If you don’t have at least 100 days of readings on the graph then you must use the hourly view. At 100 days, the hourly view has 100*24=2400 points.

(Question: How fast is the DB at getting a subset of the points in a given range of dates where you select the points with a regular number of points to average (average every nth point)? If it is very fast with this many points then this is less of an issue.)

If we had a view that was more than hourly level but less than day level then it could be used in this situation. For example, if you have a view with readings every 4 hours then it could be used after 100*4/24 = 16.7 days. It also gives more points for the days following 100 (where the day would normally start). For example, at 100 days, you have 600 4-hour points so you could use all 600 if desired or 600/2=300 or 600/3=150 to get more points than the 100 day points. Currently you average more hour points to get this value. Clearly, the smaller the time interval then the sooner you can use the view but it takes more memory/computation to create the view (if materialized which seems likely given it probable frequent use). At 4-hour view, you would increase storage over the 1-hour view by 25% (¼ the number of points). This does not seem too bad but finding the optimal view might be interesting if this becomes an issue. Creating the views seems to be very fast for hourly so I’m assuming that won’t be an issue. If it impacts computation time for the DB query with a larger table then the tradeoff of speed of one view vs another needs to be checked out (see above).

The spreadsheet (see above) was designed to test this idea. It analyzed the data considering:

1. It used four different minimum and maximum number of points. They are related to 4 different screen sizes where the maximum number of points is a round number that is about 75% of the maximum number of horizontal pixels. The 480x600 is very low resolution and not as likely to be seen in the future. The 4k screen is now high end.
2. I considered views of 1 (hourly), 4, 6, 8, 24 (1 day), 96 (4 days) hours.
3. Two different numbers of points were computed. The first maximized the number of points so long as it was less than the max points desired. This can cause you to use a view with more points that might be slower. The second picked the smallest view that had at least the minimum number of points.
    1. Note I did not get more sophisticated as we might in the actual code. Sometimes it seems valuable to use another view without too many points stored to get a significant difference in the number of points plotted (closer to max rather than min). This will be a decision to make if we go down this path.
4. This used the full range of time represented by the number of points. This gives the number of readings in that view. You would only look at a subset if the plot had a reduced date range.

As expected in hindsight, having all the tables vs removing the 6 and 8 hour tables does not make much of a difference and slightly improves the second way to pick the number of points. This makes sense since 4 hours is less than 6 or 8 hours. Using 6 hour instead of only 4 hour is not a big change but you need to use the day view more for an intermediate number of days. As noted above, the tradeoff might be space/speed. Overall, this works well with only one more view. At the min of 400 points you need to go to 66.7 days which is larger but still not too bad (about 2 months) vs over a year without the 4 hour view.

I tried 3 days and it was not much better than 4 days so I stuck with 4 days. I don’t think the exact number is too important and it only comes into play when you have a fair amount of data. We can decide based on speed if we want this one. Doing more seems excessive. At 20 years you have 2k points in the DB so it should be fast.

As [GitHub issue 519](https://github.com/OpenEnergyDashboard/OED/issues/519) points out, you get stair step graphs with interpolated points when you go to the minute view unless the underlying data really had these values (very rare). To avoid showing higher resolution values than really exist, I think we should not use the minute view to get data. Instead, if the hourly view does not have sufficient points then we would use the readings table directly to get as many points as needed or possible. Related to other discussion of knowing the expected reading time interval for each meter could make detecting and correcting this much easier. You can use the hourly view if that is what the readings are at and you cannot do any better.

Note: The hourly view will produce interpolated data if the actual data does not have at least hourly readings but it is believed this is rare. We could avoid this if we knew the readings were farther apart and not use a view below this value.

The current code uses a fixed number for the minimum number of points (50). If possible and still efficient, I think the min/max number of points should be parameters so we can decide on the fly what is best for the user or even let the user decide in the future.

## Other Possible changes

As mentioned above, we could keep expected reading time length. Dividing the plot time range by this gives the number of readings assuming they are all this length and there are no gaps. I don’t know if this would speed up our processing much but it probably is worth looking at as we currently count the actual number in the DB. If we want this we need to decide how the value is set (auto from first data received with admin override?).

## Optimizing Bar/Compare graphics

There are times when we want to get the quantity of usage (sum of points) for non-day lengths. Examples are the last bar in a bar graph (its size differs from the others because the bar time length is not necessarily an integral multiple of the total time range of the graphic. (The other bars should not be an issue as they are multiple of one day but we should check what happens if the start time is not at the start of a day.) It also happens in the compare graphics when looking from the current time which is a fraction of a day. It will also be needed when the day view is not up to date with the days you are looking at (should only happen for a day or so if the update is working properly) so you need to use the actual readings for part of the time.

We need to look at the current code to see what it does but I don’t think we optimize this case (or even allow). The seemingly correct way is to look at the start and end times of the range and truncate them to the start and end of a day. So, if you start at 4/3/20 13:00 and end at 4/22/20 7:00 then the first full day is 4/4/20 and the last full day is 4/21/20. These can be calculated using the day view and should be fast (the current API should be able to do this). The remaining time (4/3/20 13:00-24:00 and 4/22/20 0:00-7:00) can be calculated from the hourly view. Note that it is only 11 + 7 = 18 hourly readings. In the worst case for hourly, it would be 2 * 23 = 46 hourly points so this should (hopefully) be fast. You could bring in the 4-hour view (if created) but it might not practically speed this up. Seems more effort than payback so I expect to skip that.

## Impact on database storage used

Getting rid of the minute view will not save much space because it was not materialized. Adding a materialized 4-hour view would be 25% more than the hourly reading points. Compared to the materialized 1-day view this is 6 times more (that is only 4% of hourly readings). This is probably fine if it speeds up the system. Note that the overhead goes down as the actual readings are more frequent.

## Steps (not ordered)

* We should determine the speed of looking at subset of points to get the needed range. If it is fast then we probably don’t need to do any more views.
  * Implement new view if desirable.
* Get rid of the usage of the minute view. Can leave in code in case someone does want to use it. We need to drop to actual readings if hourly not enough points.
* Verify if current code/SQL uses min/max as discussed. Try to make these values parameters and check if impacts speed. Update document if algorithm is not what is written here.
  * We should decide how to set min/max and if it will be dependent on the current web browser space available (menu already  docks if space is too small).
* See if using the hourly view close to as fast as raw readings when have raw hourly readings.
* See if feasible/desirable to have each meter store the normal time length of a reading and then use it to decide which view to use. Implement features as needed.
* Address bar/compare issue
  * API to optimize when many days with fractional ones at end. This would seem to be fairly easy to add to current API.
  * Modify bar to fix up issue with last bar (see [GitHub issue #475](https://github.com/OpenEnergyDashboard/OED/issues/475))
  * Look into fixing compare (See [GitHub issue 478](https://github.com/OpenEnergyDashboard/OED/issues/478) for part of this)
