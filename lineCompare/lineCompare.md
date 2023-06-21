# Line compare graphic

## Introduction

There are requests to expand the range of graphics OED can display to show resource usage. One request is to do comparisons of time shifted meter/group data on a line graphic. Unlike the comparison graphic, this would have lots of points of comparison along the line graphic. An example is doing the current year's energy usage compared to the previous year. In this graphic you would see the current line graphic of data say from January 1, 2023 to June 15, 2023. Then you would also see a separate line of usage for January 1, 2022 to June 15, 2022. The hope is you could see changes from year to year or at specific dates in the year. With the current compare graphic you see the total usage comparison over time. Thus, both have value.

In the general case you could shift by an arbitrary amount of time. In practice, it seems likely that people will have common shifts that are done where the starting date will relate to the shift. What this means is the starting date will be the start of the shift amount. In the example above, the shift was one year and the line begins at the start of the year. Note it may not be for the full year as in this example where you only have data through June 15 of the current year. Other common ones would seem to be shifts of a day, week, month.

## Specifying values

The graphic will be defined by three values:

1. Length of time for each line.
2. Start day of unshifted line.
3. Number of days to shift for the shifted line.

These values will be input in this order as follows:

1. Length of time for each line.

The user can select day, week, month or year. They also have a way to enter a time period in number of days. The best look/feel needs to be determined.

Note it isn't clear that inputting a length that is a fraction of a day causes issues. Lets see if it could be done and then decide if it is a good idea for the UI.

2. Start day of unshifted line.

The allowed values vary by the input for the length as follows:

- If length == day or user input then any day can be entered. Might be nice if have a calendar popup and field to manually enter the value as seen on many sites.
- if length == week then the user can give the start day (Sunday) of any week in any year. Open to how this is input.
- if length == month then the user can give the start of any month including the year. Open to how this is input.
- if length == year then the user can give the year. Maybe a dropdown of all years or something else?

3. Number of days to shift for the shifted line.

If length was a standard choice (day, week, month, year), then the number of days is that amount. For day it is 1 and week it is 7. For month it is the number of days to get to the start of the previous month and similar for year (so leap years work). The compare bar code has some logic that relates to this idea. The idea is to shift back by that amount of time. Note you graph all the days in a month or year even if two differ. For example, if one month has 30 days and the other has 31 then one line has 30 points and the other has 31. While this is described in terms of the shift, the database query is likely to be by the start and end date so that may be easier to work with.

## Considerations

It may be the case that data is missing for the current line. For example, the user might select the current year where the date in that year is June 15 so only data through that date is available. The previous year likely has all the days. This can happen for weeks and months (less likely for day). Normally the range of dates requested from the database are: start of day input and start of day input plus length of days. If the second (end time of range) is greater than the current day, then it is trimmed back to the current day. In the example above, this would mean the start day would be January 1 and end would be March 12. You could adjust the length but that would be harder. 

If the user wants to avoid this, they need to enter the length manually as 365/366 days to the full year (or month/week) and then enter the shift as 1 year (or month/week). This is harder/more painful but a less used case so it seems fine. When done, the current line will be shorter than previous one (assuming no missing data).

## Implementation

Getting this to work for a single meter and the common shifts could be the first step. Next is could do groups. Then user specified shift. Finally allowing multiple meters/groups. The developer is advised to show the project the inputs while developing (or ideas on what will be done) so feedback can be given before too much work is done.

While graphing multiple meters or groups may not be common, there does not seem to be any reason to exclude it. Hopefully the menus should be similar to the line graphic page (reusing components?) for all the selections. This could be done initially or later.

The accuracy of the data (raw, hourly, daily) will be the same as the current results for line readings of the same length of time for a given meter. The belief is that the new system can use the same line data and similar graphics as the line readings currently done where you view the second line as similar to another meter. There should be a request that returns meter/group data for a specified date/time range.
