# Exporting readings to user

## Background

OED has always taken the stance that any data we store belongs to the user and should be available to the user. To address this, OED has a button to export the graph data. The idea was the user could select and graph desired data and when they see it is what they want it is then possible to export that data. This avoids exporting data that is not of interest. In the original OED, we graphed raw meter data so this gave the user access to the meter readings. With fast-pt, we changed the system to use aggregated data when there are lots of points (normally every n day points). Also, plotly allows the user to zoom in on date ranges. This allows for naturally selecting subranges of dates before downloading. What we lost was the downloading of the raw meter data. Note when we talk about meter data we also mean any group data on the graph. Also note this only applies to line graphics as others can are aggregates without needing raw data. Issue #101 is for this issue.

## Considerations

As sites have more meters/groups and longer time ranges, the amount of raw meter readings is growing. That is exactly why we went to fast-pt. Thus, we have to be careful not to allow a user to download a large quantity of data since this could impact server performance and not be desired by the user. One option is to put the feature behind the admin login but that limits its usage. Another way would be to queue requests so the server is not overloaded. This is probably the correct solution but more complex. The option for now is to warn users and limit the file size so they can download reasonable size files without being an admin. If sites get attacked or performance becomes an issue then we will need to revisit this decision.

I’m uncertain how we are going to deal with groups since the frequency of the underlying meter data can vary. We need to see what groups do and how to deal with this.

## Design

The export data button on the line graphics page will be modified so you can click a button to get the raw line data. It will be unselected until checked to avoid large downloads by accident. When a request for raw data is made, the following steps are taken:

1. The start and end data/time of the graph is determined. This will allow the calculation of the total time involved.
2. The number of meters and groups on the graph is determined. Call this the # lines.
3. The (hopefully) minimum number of points involved is calculated. For now, it is assumed to be the number of hours involved * # lines. This can be too large if the readings are less frequent than every hour (not common) or if there are gaps in the data. It can be way too small if readings are more frequent than every hour. Given every 15 minutes is the normal minimum, this should not be a large factor but could be significantly off if the raw readings are every minute. Note the error in this estimate can vary if the reading frequency varies for different lines on the graph.
    1. In the future, we may store the normal reading interval for each meter. If we had that then we could make a much more accurate estimate, esp. if missing points are rare.
4. If the calculated minimum number of points is more than a set factor of the maximum number of points (defined by the admin with a default of maybe 1.2? To represent understanding of uncertainty in the estimate) then the following action is taken
    2. If it is a non-admin user they are informed the request seems too large and is not going to be processed.
    3. If it is an admin, the estimated size is given and asked if they want to continue.
5. If you pass the minimum number of points test, you use SQL to count the actual number of points. Let's start by doing the correct count by looking at each line. We could do one or two lines and assume all are the same but that might not be correct (but faster). This is the actual number of points. If it is a non-admin, then they are told it is too large (similar to minimum number of points) but without the factor so it is just compared to the maximum number of points. Admins are dealt with in the next step.
6. The number of points is used to estimate the file size in MB of the CSV that will be downloaded. If this exceeds a set size (say 1 MB) then the user is informed of the file size, warned that this is what will be downloaded, and asked if they want to continue. If no, stop; if yes, continue.
7. The CSV is prepared for the user and sent back to them as a file. We should keep the current OED web browser window and not replace it with a CSV download page (could be a new tab if that seems like a good idea).

Note the admin will be able to set the value of:

1. Maximum number of points to download. This may be input as file size in MB to be easier to understand. The default value will be 50MB?.
2. Threshold factor to use when comparing to estimate with default value of 1.2?. This one seems less important for the admin to set but let’s do it unless it is an issue.

Current Issues: (By Sasank)

1. Endpoints for getting data:

Something that really confused me is that there were /reading and /compressedreading endpoints on the backend. Here, /reading gets a form of compressed readings and /compressedreading gets an even more compressed form of the readings. Unfortunately both of these are not what we want. I couldn't find endpoints for the request we want, so we would need to create some of our own.

I believe the functions we need are all in the models/Reading.js file and they are:

getReadingsByMeterIdAndDateRange()

getBarchartReadings()

getGroupBarchartReadings()

I couldn't find a function to get all readings based on the group, which needs to be created.

2. The compressed data is stored in the redux state. When creating the export button component we format the redux state data to the correct format to export and pass it into the component as a prop.

The problem is that we need to format the raw data into a similar format but doing so before creating the component and passing it as a prop would affect the speed of the site. 

(To have cleaner code I wonder if we should store these loops that format the text into another file and import them as needed.)

## Implementation

This was completed with PR #552 in 2021. It mostly follows this description. I believe it does a direct count instead of estimating the number of points since we do not have a value for expected reading time for a meter. Also, the upcoming User PR means there will be a separate user for downloading that will allow someone logged in to get a larger file. It can take 10s of seconds to get a large number of points.
