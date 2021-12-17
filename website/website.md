# Documentation on how website data is created

## Steps to load all needed data

* What follows assumes OED is up and running for a number of the steps.
* Login as admin and make site named “OED Demo Site” on admin page.
* Load the website data from CSV files and also create the meters needed. Note that the meter name and identifier will not have the starting M but that is added later when another script is run.
  * cd to the directory with the websiteSetup.sh script. This is often in your clone of the DevDocs repo in the website/ directory. It is assumed that the oedData/ directory is a subdirectory of this directory and it has all the CSV data files for the website.
  * Run the script with: ./websiteSetup.sh
  * If all goes well you will get 7 SUCCESS notices as:\
&lt;h1>SUCCESS&lt;/h1>Successfully inserted the meters.&lt;h1>SUCCESS&lt;/h1>&lt;h2>It looks like the insert of the readings was a success.&lt;/h2>&lt;h1>SUCCESS&lt;/h1>&lt;h2>It looks like the insert of the readings was a success.&lt;/h2>&lt;h1>SUCCESS&lt;/h1>&lt;h2>It looks like the insert of the readings was a success.&lt;/h2>&lt;h1>SUCCESS&lt;/h1>&lt;h2>It looks like the insert of the readings was a success.&lt;/h2>&lt;h1>SUCCESS&lt;/h1>&lt;h2>It looks like the insert of the readings was a success.&lt;/h2>&lt;h1>SUCCESS&lt;/h1>&lt;h2>It looks like the insert of the readings was a success.&lt;/h2>
  * Note this CSV file sets the GPS values so they work for the map below:
    * Meter 7: (84, 419) GPS (40.00419, -87.99916) which is Play Place
    * Meter 8: (250, 270) GPS (40.0027, -87.9975) which is Theater
  * You can verify the meters on the meter page in OED if you want.
* Create desired groups. Note all group names do not have the G in front as the script will fix this up.
  * Go to the groups page as an admin.
  * Create “roup 1 & 2” that has eter 1 & 2 in it. Give it GPS coordinates  40.00202, -87.99915 so it will be in the middle of Cafeteria. This was (85, 202) on the calibration coordinates.
  * Create “roup 7 & 8” that has eter 7, 8 in it.
  * Create a new group named “roup 1 & 2 & 7 & 8” that contains eter 1, 2 and roup 7 & 8.
* Run script to set the desired meter and group ids. This is done so that they always have the same id which means the same color each time this is done. The meters go from 10012-10019 and groups go from 10012-10014. This also puts the M in front of meter name/identifier and G in front of group name. See script for why use these ids.
  * In a terminal, cd to the main OED directory.
  * cat &lt;path to script>/websiteData.sql | docker compose exec database psql -U oed
  * The expected output is shown below since it is many lines.
  * Note that this changes the meter and group info and readings so you need to do the following:
    * Prepare the readings for viewing by doing this in the terminal in main OED directory: docker compose exec web npm run refreshReadingViews
    * Make sure the groups and readings are available in the website going to the main OED page (Home) and reloading that page in the web browser..
* Get 2 meters with current data for compare (try to do right before create those images). Also note you cannot do the maps until this is done:
  * Get the timezone of your local machine by doing this in the terminal: date +%Z. For what follows the timezone is assumed to be CST/CDT but you should change if your timezone differs.
  * cd to the main OED directory
  * Now do work in Postgres by doing: docker compose exec database psql -U oed
  * Verify timezone correct by doing: select clock_timestamp() at time zone 'cst';
    * If in daylight savings use: select clock_timestamp() at time zone 'cdt';
    * Make sure that it shows the same time as on the clock on your computer.
  * Get first 3 months of data from Meter 1 & 2 and put into Meter 7 & 8:
    * insert into readings (meter_id, reading, start_timestamp, end_timestamp)  (select M.id, R.reading, R.start_timestamp, R.end_timestamp from meters as M, readings as R where M.name = 'Meter 7' and R.meter_id = (select id from meters where name = 'Meter 1') and R.start_timestamp &lt; '2020-04-01');
    * insert into readings (meter_id, reading, start_timestamp, end_timestamp)  (select M.id, R.reading, R.start_timestamp, R.end_timestamp from meters as M, readings as R where M.name = 'Meter 8' and R.meter_id = (select id from meters where name = 'Meter 2') and R.start_timestamp &lt; '2020-04-01');
    * each is (2184 rows)
  * Shift dates so last end_timestamp is nearest to current hour.
    * Get the time shift
      * select date_trunc('hour', clock_timestamp() at time zone 'cst') - max(end_timestamp) as shift from readings where meter_id = (select id from meters where name = 'Meter 7');
      * use cdt if appropriate
    * Now shift the readings by this amount (both start and end timestamp where you will shift all readings in the 2 new meters). Replace the '504 days 21:00:00 with whatever you got for the shift above. Note you have to do it in 2 places in the following command. So do:
      * update readings set start_timestamp = start_timestamp + interval '509 days 10:00:00', end_timestamp = end_timestamp + interval '509 days 10:00:00' where meter_id in (select id from meters where name in ('Meter 7', 'Meter 8'));
        * 4368 rows
      * (in other terminal in OED main directory): docker compose exec web npm run refreshReadingViews
  * You can repeat these steps in the future to get back to the latest time but you may get error about overlapping start_timestamp. The easiest way around this is the delete all the reading with: \
delete from readings where meter_id in (select id from meters where name in ('Meter 7', 'Meter 8')); \
and then start again from above to add values and then do the shift.
* Creating the map data. Note if you are changing the images for map calibration then you can do this as part of that process to save doing it twice.
  * First need to create a map. This was done once and then reused. I used a LibreOffice Drawing document to do this. It is a simple, stylized map. Note I used the grid to create a box that was 9x15 (width x height). The OED map system places a 300x500 grid on the uploaded map. Thus, having an aspect ratio of 3:5 makes it fit without any whitespace. I placed the building on the map and inside the box. I then make the box white and sent it to the back (behind the buildings). I then selected the box and buildings and placed in a group (it seemed I needed to buildings first but not sure why). I selected the group, File→export, choose png and click for selection for save, then it automatically gave the size as 4.5”x7.5” (3:5 ratio) so just used it. The final file is with the other web page info in happyPlace.png and happyPlace.odg. You see the while box when you open the PNG with dark mode but not in OED. Note I tried other techniques to do the box but had issues where the area on edge of box did not show up. (unsure what this was used for)Shape→Group→Ungroup. Highlight all items and change Line to black so can see the box. Reset its rotation angle to 0 deg. Now it cannot fit over the entire image. Resize box to 12x20 so still 3:5 and center horizontally over image but lots of extra vertical space on bottom. Leaving box shown for now to test. Reform group of all items. Export as before.
  * Go to map page, create new map, load the happyPlace.png and give it the name “Happy Place” and make the angle 0.
  * For calibration, I treated the lower, left corner to have GPS 40.0, -88.0 and this is grid point 0, 0. I  treated the upper, right corner to have GPS 40.005, -87.997 and this gives point 300, 500. Note GPS is (latitude,longitude) or (y,x) in the grid so you always have to reverse x,y for GPS values.  Given this, you can calculate the GPS value by: \
latitude = 40 + y * 10<sup>-5</sup> \
longitude = -88 + x * 10<sup>-5</sup> \
 For calibration points I used:
    * top, right corner of swimming pool: (277, 461) GPS to enter: 40.00461, -87.99723
    * top, left corner of Cafeteria (34, 238) GPS to enter: 40.00238, -87.99966
    * bottom, left corder of Housing (100, 35) GPS to enter: 40.00034, -87.99901
      * Note (40.00035, -87.99900) would be perfect but want a little error to show for example. \
After 3 points had error: x: 1.202%, y: 0.25% so save the DB.
  * Now see on map page. Click Show & Save map edits to get Display Enabled.
  * If you map Meter 7 & 8 they should be right on these two buildings since GPS set in CSV file that uploaded. Group 1 & 2 should be on another building.
  * See the map page on how the calibration discussion was created.

### Restarting

* If you ever want to restart you can do the following steps:
  1. Delete the groups on OED website (Group 1 & 2, Group 1 & 2 & 7 & 8, Group 7 & 8.
  2. in psql: delete from readings where meter_id in (select id from meters where name in ('Meter 1', 'Meter 2', 'Meter A', 'Meter B', 'Meter C', 'Meter D', 'Meter 7', 'Meter 8'));
      * gives: DELETE 21810
  3. in psql: delete from meters where id in (select id from meters where name in ('Meter 1', 'Meter 2', 'Meter A', 'Meter B', 'Meter C', 'Meter D', 'Meter 7', 'Meter 8'));
      * gives: DELETE 8

Expected output from the websiteDate.sql script:

INSERT 0 1 \
UPDATE 0 \
UPDATE 2 \
UPDATE 0 \
UPDATE 0 \
UPDATE 8712 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 2 \
UPDATE 0 \
UPDATE 0 \
UPDATE 8712 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 5 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 5 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 3 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 5 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 2 \
DELETE 1 \
INSERT 0 1 \
UPDATE 1 \
UPDATE 0 \
UPDATE 2 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 1 \
UPDATE 2 \
DELETE 1

## Items for website update

### Overall site

* Check that the site is named “OED Demo Site”.
* Make sure you log out as admin so it looks as a normal user would see unless doing an admin page.
* Unless you want to show the dropdown menus, click off of them.
* Remember to hover over values for many graphs.
* Looking at the current image can help in making the new one. The HTML has the file names that make it easier to name the new screenshots.
* When you want a box around an item, use the border color of 0000FF in web colors. The second, light blue box, is color 3399FF in web colors.

### Update all pages as needed

* If done correctly, all PRs and issues for this milestone are listed in the milestone so you can figure out what needs updating.
* Don’t forget that features.html on the main website also has OED images of many features.
* Sometimes changes impact the developer pages.
* Compare & map values change when re-graph so need to check values in text

### Details on special website pages

* The adminMap.html file discusses calibration issues by changing the inputted GPS value +/- a given amount. Unfortunately I did not record the exact values for each point. However, it was probably +/-/+ for the three points but may be different signs.

### HTML is valid

Go to [https://validator.w3.org/](https://validator.w3.org/) and enter URL. Seems must do one page at a time.

### check CSS if valid

[https://jigsaw.w3.org/css-validator/](https://jigsaw.w3.org/css-validator/)

Did the only page of css/main.css and no issues found.

### Check links are valid

Go to [https://validator.w3.org/checklink], enter web address, check summary only, set the depth of linked documents recursion to 10 to check all the linked pages. (Note tried checking Hide redirects but it did not help.) It takes a little while but it finds and checks them all.

* Cannot check email links so get at least one warning on each page for contact
* Complains about MPL link on footer of each page but it does seem fine.
* [https://www.learn-js.org/](https://www.learn-js.org/) generally gives an error but the link seems fine.
* [https://help.github.com/](https://help.github.com/) and  [https://docs.github.com/get-started/quickstart/fork-a-repo](https://docs.github.com/get-started/quickstart/fork-a-repo) gives redirect warning but want the redirect since selecting language automatically.
* [https://docs.google.com/forms/d/e/1FAIpQLSc2zdF2PqJ14FljfQIyQn_X70xDhnpv-zCda1wU0xIOQ5mp_w/viewform](https://docs.google.com/forms/d/e/1FAIpQLSc2zdF2PqJ14FljfQIyQn_X70xDhnpv-zCda1wU0xIOQ5mp_w/viewform) gives warning on not checked to to robot exclusion but okay.
* Can save the result as html and then do “grep -e Line -A 2 foo.html” to see all lines with issues plus the two following to get the message or “grep -e Line foo.html | grep -v -e "mailto:" -e "http://mozilla.org/MPL/2.0/" -e "https://docs.google.com/forms/d/e/1FAIpQLSc2zdF2PqJ14FljfQIyQn_X70xDhnpv-zCda1wU0xIOQ5mp_w/viewform" -e "https://www.learn-js.org/" -e "https://help.github.com/" -e "https://docs.github.com/get-started/quickstart/fork-a-repo"” for just the ones without the msgs noted above. This may not be perfect but it appears to get everything.
* All okay with warning noted above as of 210807.

### Check accessibility

Not yet done/figured out.

## Test data description

The CSV files for meters and readings are in the subdirectory oedData/. The readings.ods file has some of the calculations to get a reading of a desired value. The issue is that you cannot set a given reading to what you want to see on the graph when you plot it on a daily basis. This is complicated because the synthetic data spans many days (a step function) and the times were chosen to stop at varying times in the day.

## Meters

| Name&nbsp;&nbsp;&nbsp;&nbsp; | ID | Description |
| -------- | --    | ----------- |
| Meter A  | 10012 | Full year 2020, step function, 5 steps (1-3.5 on line graph) |
| Meter B  | 10013 | Full year 2020, step function, 5 steps (2.5-5 on line graph) |
| Meter C  | 10014 | Year 2020 missing start and end, step function, 3 steps (5.5-9.2 on line graph) |
| Meter D  | 10015 | Year 2020 missing start and end but different start/stop than Meter 3, step function, 5 steps (72-101 on line graph), big values compared to others |
| Meter 1  | 10016 | Full Year 2020, read integer data (~6.5-30.25 on line graph) |
| Meter 2  | 10017 | Full Year 2020, read integer data (~22.5-82.7 on line graph) |
| Meter 7  | 10018 | 3 months from current date, same values as first 3 months from Meter 1, see below on how this is created as not in readings.csv |
| Meter 8  | 10019 | 3 months from current date, same values as first 3 months from Meter 1, see below on how this is created as not in readings.csv |

Note I trimmed the time to stop on Dec. 28 so the last bar was virtually full. Otherwise you get one more bar for each meter with small values due to an issue in using regular bars.

## Uses of meters/readings

* Meter A-D are step functions that make it easier to see the value of a group is correct. Thus, Meter &lt;letter> is step function data.
  * Meter A-C are modest values that can be used together.
  * Meter D is deliberately larger values to show issue of how others values become hard to see.
  * Meters C-D demonstrate what happens when you have missing intervals of values. Deliberately chose to only have time missing at start/end because OED draws a line over the missing time if it is in the middle of the graph. (Maybe we will do something about that some day ;-)
* Meter 1-2 are real data to show something more realistic. This is designed for overview graphics. Thus, Meter # is real data.
