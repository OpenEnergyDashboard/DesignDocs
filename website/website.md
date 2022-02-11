# Documentation on how website data is created

## Steps to load all needed data

* What follows assumes OED is up and running for a number of the steps.
* Login as admin and make site named “OED Demo Site” on admin page.
* Load the website data from CSV files and also create the meters needed. Note that the meter name and identifier will not have the starting M or D but that is added later when another script is run. The ones starting with D are for the useAcademic.html page.
  * cd to the directory with the websiteSetup.sh script. This is often in your clone of the DevDocs repo in the website/ directory. It is assumed that the oedData/ directory is a subdirectory of this directory and it has all the CSV data files for the website.
  * Run the script with: ./websiteSetup.sh
  * If all goes well you will get 9 SUCCESS notices as:\
&lt;h1&gt;SUCCESS&lt;/h1&gt;Successfully inserted the meters.&lt;h1&gt;SUCCESS&lt;/h1&gt;&lt;h2&gt;It looks like the insert of the readings was a success.&lt;/h2&gt;&lt;h1&gt;SUCCESS&lt;/h1&gt;&lt;h2&gt;It looks like the insert of the readings was a success.&lt;/h2&gt;&lt;h1&gt;SUCCESS&lt;/h1&gt;&lt;h2&gt;It looks like the insert of the readings was a success.&lt;/h2&gt;&lt;h1&gt;SUCCESS&lt;/h1&gt;&lt;h2&gt;It looks like the insert of the readings was a success.&lt;/h2&gt;&lt;h1&gt;SUCCESS&lt;/h1&gt;&lt;h2&gt;It looks like the insert of the readings was a success.&lt;/h2&gt;&lt;h1&gt;SUCCESS&lt;/h1&gt;&lt;h2&gt;It looks like the insert of the readings was a success.&lt;/h2&gt;&lt;h1&gt;SUCCESS&lt;/h1&gt;&lt;h2&gt;It looks like the insert of the readings was a success.&lt;/h2&gt;&lt;h1&gt;SUCCESS&lt;/h1&gt;&lt;h2&gt;It looks like the insert of the readings was a success.&lt;/h2&gt;
  * Note this CSV file sets the GPS values so they work for the map below:
    * (M)eter 7 and (D)orm A Residents: (84, 419) GPS (40.00419, -87.99916) which is Play Place
    * (M)eter 8 and (D)orm B Residents: (250, 270) GPS (40.0027, -87.9975) which is Theater
  * You can verify the meters on the meter page in OED if you want.
* Create desired groups. Note all group names do not have the G or D in front as the script will fix this up.
  * Go to the meter page so the new meters are known.
  * Go to the groups page as an admin.
  * Create “roup 1 & 2” that has eter 1, eter 2 in it. Give it GPS coordinates  40.00202, -87.99915 so it will be in the middle of Cafeteria. This was (85, 202) on the calibration coordinates.
  * Create “roup 7 & 8” that has eter 7, eter 8 in it.
  * Create a new group named “roup 1 & 2 & 7 & 8” that contains eter 1, eter 2 and roup 7 & 8.
  * Create a new group name "orm A" with orm A Residents and orm A Other. Give GPS of 40.00419, -87.99916 so it is at Dorm A.
  * Create a new group name "orm B" with orm B Residents and orm B Other. Give GPS of 40.0027, -87.9975 so it is at Dorm B.
* Run script to set the desired meter and group ids. This is done so that they always have the same id which means the same color each time this is done. The meters go from 10012-10025 and groups go from 10012-10016. This also puts the M or D in front of meter name/identifier and G or D in front of group name. See script for why use these ids.
  * In a terminal, cd to the main OED directory.
  * docker exec -i &lt;DB container name&gt; psql -U oed &lt; &lt;path to script&gt;/websiteData.sql
    * &lt;DB container name&gt; found by going to the start of the console output where you install/ran OED and getting the database container name. The line will be:\
Container &lt;mydir&gt;-database-1  Created\
where &lt;mydir&gt; is usually the directory name where you have OED running.
    * &lt;path to script&gt; is the Linux path to where the script is and normally in your devDoc directory that is normally the same place as what you did above for the websiteSetup.sh script.
  * The expected output is shown below since it is many lines.
  * Note that this changes the meter and group info and readings so you need to do the following:
    * Prepare the readings for viewing by doing this in the terminal in main OED directory: docker compose exec web npm run refreshAllReadingViews
    * Make sure the groups and readings are available in the website going to the main OED page (Home) and reloading that page in the web browser.
* Get 6 meters with current data for compare and other uses on academicUse.html (try to do right before create those images).:
  * Get the timezone of your local machine by doing this in the terminal: date +%Z. For what follows the timezone is assumed to be CST/CDT but you should change if your timezone differs.
  * cd to the main OED directory
  * Now do work in Postgres by doing: docker compose exec database psql -U oed
  * Verify timezone correct by doing: select clock_timestamp() at time zone 'cst';
    * If in daylight savings use: select clock_timestamp() at time zone 'cdt';
    * Make sure that it shows the same time as on the clock on your computer.
  * Get first 3 months of data from Meter 1 & 2 and put into Meter 7 & 8:
    * insert into readings (meter_id, reading, start_timestamp, end_timestamp)  (select M.id, R.reading, R.start_timestamp, R.end_timestamp from meters as M, readings as R where M.name = 'Meter 7' and R.meter_id = (select id from meters where name = 'Meter 1') and R.start_timestamp &lt; '2020-04-01');
    * insert into readings (meter_id, reading, start_timestamp, end_timestamp)  (select M.id, R.reading, R.start_timestamp, R.end_timestamp from meters as M, readings as R where M.name = 'Meter 8' and R.meter_id = (select id from meters where name = 'Meter 2') and R.start_timestamp &lt; '2020-04-01');
    * each is INSERT 0 2184
  * Get all data from Meter 1, 2, 3 & 4 and put into Dorm A Residents, Dorm A Other, Dorm B Residents & Dorm B Other:
    * insert into readings (meter_id, reading, start_timestamp, end_timestamp)  (select M.id, R.reading, R.start_timestamp, R.end_timestamp from meters as M, readings as R where M.name = 'Dorm A Residents' and R.meter_id = (select id from meters where name = 'Meter 1') and R.start_timestamp &lt; '2021-01-02');
    * insert into readings (meter_id, reading, start_timestamp, end_timestamp)  (select M.id, R.reading, R.start_timestamp, R.end_timestamp from meters as M, readings as R where M.name = 'Dorm A Other' and R.meter_id = (select id from meters where name = 'Meter 2') and R.start_timestamp &lt; '2021-01-02');
    * insert into readings (meter_id, reading, start_timestamp, end_timestamp)  (select M.id, R.reading, R.start_timestamp, R.end_timestamp from meters as M, readings as R where M.name = 'Dorm B Residents' and R.meter_id = (select id from meters where name = 'Meter 3') and R.start_timestamp &lt; '2021-01-02');
    * insert into readings (meter_id, reading, start_timestamp, end_timestamp)  (select M.id, R.reading, R.start_timestamp, R.end_timestamp from meters as M, readings as R where M.name = 'Dorm B Other' and R.meter_id = (select id from meters where name = 'Meter 4') and R.start_timestamp &lt; '2021-01-02');
    * each is INSERT 0 8712
  * Shift dates so last end_timestamp is nearest to current hour. Note you have to do it in 2 places in the following command. Need to do for two different types of meters since they have different quantities of data.
    * Meters 7 & 8
      * Get the time shift
        * select date_trunc('hour', clock_timestamp() at time zone 'cst') - max(end_timestamp) as shift from readings where meter_id = (select id from meters where name = 'Meter 7');
        * use cdt if appropriate
      * Now shift the readings by this amount (both start and end timestamp where you will shift all readings in the 2 new meters). Replace the '680 days 15:00:00' with whatever you got for the shift above.  So do:
        * update readings set start_timestamp = start_timestamp + interval '680 days 15:00:00', end_timestamp = end_timestamp + interval '680 days 15:00:00' where meter_id in (select id from meters where name in ('Meter 7', 'Meter 8'));
          * 4368 rows
    * Dorm A Residents, Dorm A Other, Dorm B Residents & Dorm B Other
      * Get the time shift
        * select date_trunc('hour', clock_timestamp() at time zone 'cst') - max(end_timestamp) as shift from readings where meter_id = (select id from meters where name = 'Dorm A Other');
        * use cdt if appropriate
      * Now shift the readings by this amount (both start and end timestamp where you will shift all readings in the 2 new meters). Replace the '408 days 16:00:00' with whatever you got for the shift above.  So do:
        * update readings set start_timestamp = start_timestamp + interval '408 days 16:00:00', end_timestamp = end_timestamp + interval '408 days 16:00:00' where meter_id in (select id from meters where name in ('Dorm A Residents', 'Dorm A Other', 'Dorm B Residents', 'Dorm B Other'));
          * 34848 rows
      * You can leave the Postgres console: \q
      * (in other terminal in OED main directory): docker compose exec web npm run refreshAllReadingViews
  * Refresh the readings as was done before.
  * You can repeat these steps in the future to get back to the latest time but you may get error about overlapping start_timestamp. The easiest way around this is the delete all the reading with: \
delete from readings where meter_id in (select id from meters where name in ('Meter 7', 'Meter 8', 'Dorm A Residents', 'Dorm A Other', 'Dorm B Residents', 'Dorm B Other')); \
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
  * If you map Meter 7 & Meter 8 they should be right on these two buildings since GPS set in CSV file that uploaded. Group 1 & 2 should be on another building.
  * You can also use the HappyPlace30Deg.png for a rotated map where it could be named Happy Place 30 Deg. The angle to use is 30. The GPS values are the same but the coordinates on the map are different (but you click on the same logical location on the map):
    * top, right corner of swimming pool: (291, 386) GPS to enter: 40.00461, -87.99723
    * top, left corner of Cafeteria (49, 331) GPS to enter: 40.00238, -87.99966
    * bottom, left corder of Housing (15, 174) GPS to enter: 40.00034, -87.99901
      * Note (40.00035, -87.99900) would be perfect but want a little error to show for example. \
After 3 points had error: x: 0.566%, y: 0.429% so save the DB.
    * The circles should show at the same place on buildings as with the zero degree map.
  * You need to redo this process where the image is the myUniversity.png at zero degree and the names were changed so Play Place is Dorm A, Theater is Dorm B and Housing is Academic Building. While basically the same, the names were changed for the academic use example.
  See the map page on how the calibration discussion was created.

### Restarting

* If you ever want to restart you can do the following steps:
  1. Delete the groups on OED website: Group 1 & 2, Group 1 & 2 & 7 & 8, Group 7 & 8, Dorm A and Dorm B.
  2. in psql: delete from readings where meter_id in (select id from meters where name in ('Meter 1', 'Meter 2', 'Meter A', 'Meter B', 'Meter C', 'Meter D', 'Meter 7', 'Meter 8', 'Dorm A Residents', 'Dorm A Other', 'Dorm B Residents', 'Dorm B Other', 'Meter 3', 'Meter 4'));
      * gives: DELETE 74082
  3. in psql: delete from meters where id in (select id from meters where name in ('Meter 1', 'Meter 2', 'Meter A', 'Meter B', 'Meter C', 'Meter D', 'Meter 7', 'Meter 8', 'Dorm A Residents', 'Dorm A Other', 'Dorm B Residents', 'Dorm B Other', 'Meter 3', 'Meter 4'));
      * gives: DELETE 14

Expected output from the websiteDate.sql script:??

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
UPDATE 0 \
UPDATE 0 \
UPDATE 8712 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 0 \
UPDATE 8712 \
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
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 0 \
UPDATE 2 \
DELETE 1 \
INSERT 0 1 \
UPDATE 0 \
UPDATE 0 \
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
* Before doing images for the useAcademic.html, rename the site "My University".

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

| Name             | ID    | Description |
| ---------------- | ----- | ----------- |
| Meter A          | 10012 | Full year 2020, step function, 5 steps (1-3.5 on line graph) |
| Meter B          | 10013 | Full year 2020, step function, 5 steps (2.5-5 on line graph) |
| Meter C          | 10014 | Year 2020 missing start and end, step function, 3 steps (5.5-9.2 on line graph) |
| Meter D          | 10015 | Year 2020 missing start and end but different start/stop than Meter 3, step function, 5 steps (72-101 on line graph), big values compared to others |
| Meter 1          | 10016 | Full Year 2020, read integer data (~4-30.25 on line graph) |
| Meter 2          | 10017 | Full Year 2020, read integer data (~22.5-82.7 on line graph) |
| Meter 3          | 10024 | Full Year 2020, read integer data (~22-37.5 on line graph) |
| Meter 4          | 10025 | Full Year 2020, read integer data (~61-104 on line graph) |
| Meter 7          | 10018 | 3 months from current date, same values as first 3 months from Meter 1, see above on how this is created as not in readings.csv |
| Meter 8          | 10019 | 3 months from current date, same values as first 3 months from Meter 1, see above on how this is created as not in readings.csv |
| Dorm A Residents | 10020 | 12 months from current date, same values as Meter 1, see above on how this is created as not in readings.csv |
| Dorm A Other     | 10021 | 12 months from current date, same values as Meter 2, see above on how this is created as not in readings.csv |
| Dorm B Residents | 10022 | 12 months from current date, same values as Meter 1, see above on how this is created as not in readings.csv |
| Dorm B Other     | 10023 | 12 months from current date, same values as Meter 2, see above on how this is created as not in readings.csv |

Note I trimmed the time to stop on Dec. 28 so the last bar was virtually full. Otherwise you get one more bar for each meter with small values due to an issue in using regular bars.

## Uses of meters/readings

* Meter A-D are step functions that make it easier to see the value of a group is correct. Thus, Meter &lt;letter&gt; is step function data.
  * Meter A-C are modest values that can be used together.
  * Meter D is deliberately larger values to show issue of how others values become hard to see.
  * Meters C-D demonstrate what happens when you have missing intervals of values. Deliberately chose to only have time missing at start/end because OED draws a line over the missing time if it is in the middle of the graph. (Maybe we will do something about that some day ;-)
* Meter 1-4 are real data to show something more realistic. This is designed for overview graphics. Thus, Meter # is real data.
* Meters 7-8 & All the Dorm ones are for comparison and having current readings. They are real data that is the same as Meters 1-4 but shifted in time.
