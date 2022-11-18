# Documentation on how website data is created

## Creating the CSV data readings files

The files to do this are in the webData/ directory. If you are not creating new meter data then they should already be there. webMeter.ods can generate random meter data. It is a LibreOffice file spreadsheet file with formulas. You get get the meter data by setting the following cells:

- B2 is the first date/time for a reading. It is normally in YYYY-MM-DD HH-MM-SS format where HH is in 24 hour time.
- E2 sets the minutes between readings.
- E5 is the initial reading value for the first reading. It is often in the middle of the min and max reading allowed.
- E8 is the minimum value for a reading. If the random values go below this then then the random shift is reversed to keep it above this value.
- E11  is the maximum value for a reading. If the random values go above this then then the random shift is reversed to keep it below this value.
- E14 is the random variation for the next reading. It can go up or down by this amount as long as it does not go outside the bounds allowed.

No other cells should be edited. Note Column D is random values generated to do the calculations. You do not normally touch this column. D2 does not need a value. Note it changes whenever you reopen the spreadsheet or touch cells in the sheet.

After setting the values and creating the values in the three needed columns (A, B, C) you can create a CSV for import as described later by:

1) Selecting the entire columns of A-C or any set of rows that have the dates desired. If you only take a subset of the rows then make sure the separately copy to first header row of columns A-C.
2) Copy the values selected.
3) Open a new spreadsheet.
4) If you are copying all the rows or the header row then click in cell A1. If you have already put in the header row and are now copying the rows with meter data then click in cell A2.
5) Do a special paste by either doing Edit -> Special Paste -> Special Paste ... or control/command-shift-v. In the popup, click the Values Only button on the left because you don't want to get the formulas.
6) Select all of columns B & C. Then do Format -> Cells ... or control/command 1. In Category select date and then in Format select  1999-12-31 13:37:46. This formats the columns as dates in the canonical format. You may need to make the columns wider to see the values (esp. if you see ### instead of date/time).
7) Do File -> Save As ... or control/command-shift S. In File type: select Text CSV (.csv) and enter a file name at the top. Then click the Save button.

Later in this document is the standard values used for the website where this process is done once for each meter desired.

## Entering the website data

The steps for putting the data into a website are

1) Generally you start from a clean version of OED so only the website data is present.
    - An alternative is to delete the current data. In a psql shell you can do: \
    `delete from readings; delete from groups_immediate_meters; delete from groups_immediate_children; delete from groups; delete from meters; delete from conversions; delete from units;`
2) Copy the CSV file from webData/ in devDocs/ to src/server/data/webData.
3) Get OED running if it is not already up.
4) Open a shell in the web terminal.
5) In the shell run: `npm run webData`.
    - This will likely take some time to run as it needs to load a lot of data from CSV files.
6) Open new or refresh you localhost:3000 in a web browser. All the units, conversions, meters and groups should be present.
7) It is important that you delete the files you added to your OED src/ tree since these should **never** be committed to the OED repository.

Copy the websiteData.js file to src/server/data/websiteData.js.

### Compare data

The comparison page needs current data. To achieve this, you can use a web terminal and do: `node -e 'require("./src/server/data/websiteData.js").webShift("cst")` where you replace the "cst" with the code for the timezone for the web browser you are going to use. Get the timezone of your local machine by doing this in the terminal (in Linux/MacOS): date +%Z. Note this is in a terminal on your local machine and not in the web or database container in OED.

    - An older list of Postgres acceptable timezones (they don't usually change) is at [Postgres Timezones](https://www.postgresql.org/docs/7.2/timezones.html).
    - You can also use the Postgres SQL command (in a database shell inside `psql -U oed`) of: `select * FROM pg_timezone_names;`. Note you can do this as often as you wish to keep the readings current (note it take a little time to execute). Since it brings the readings to current time, the compare graphs will vary unless you do it at the same day of the week and the same hour of the day.

You can verify you have the correct timezone code by doing `select clock_timestamp() at time zone 'cst';` in the Postgres shell (see above). Replace 'cst' with the timezone you want to use. The time should match the one on your computer's clock.

There are meters and groups listed in the table below. They mirror another meter/group where a space character is added to the end of the name. That way they look the same on the menus and graphics since you don't see the extra space. By default they are not displayable so they will not show. You need to make them visible and hide the usual one if you only want to see them in the menus. Note the name with the space comes second in the menus so you can tell which one you are working with if both are present. Also note that the IDs were carefully selected so both meters will show in the same color on all graphics.

### Map data

Create the needed maps. This was done once and then reused.

- I used a LibreOffice Drawing document to do this. It is a simple, stylized map. Note I used the grid to create a box that was 9x15 (width x height). The OED map system places a 300x500 grid on the uploaded map. Thus, having an aspect ratio of 3:5 makes it fit without any whitespace. I placed the building on the map and inside the box. I then make the box white and sent it to the back (behind the buildings). I then selected the box and buildings and placed in a group (it seemed I needed select(?) buildings first but not sure why). I selected the group, File→export, choose png and click for selection for save, then it automatically gave the size as 4.5”x7.5” (3:5 ratio) so just used it. The final file is with the other web page info in campus.png and campus.odg. You see the while box when you open the PNG with dark mode but not in OED.
- Now create the 30 degree rotated map. Select the group, Format -> Position and Size, then click the Rotation tab and set the angle to 330 degrees. Resize the bounding box to fit the rotated map but make sure the keep the aspect ratio the same where it is not rotated. I did 12x20 so still 3:5 and center horizontally over image but lots of extra vertical space on bottom. Reform group of all items. Export as before. It is in campus30Deg.png (and .odg).

The following steps are done each time the data is redone from scratch. Note if you are changing the images for map calibration then you can do this as part of that process to save doing it twice.

- Go to map page, create new map, load the campus.png and give it the name “My campus” and make the angle 0.
- For calibration, I treated the lower, left corner to have GPS 40.0, -88.0 and this is grid point 0, 0. I  treated the upper, right corner to have GPS 40.005, -87.997 and this gives point 300, 500. Note GPS is (latitude,longitude) or (y,x) in the grid so you always have to reverse x,y for GPS values.  Given this, you can calculate the GPS value by: \
latitude = 40 + y \* 10<sup>-5</sup> \
longitude = -88 + x \* 10<sup>-5</sup> \
 For calibration points I used:
  - top, right corner of Gym: (277, 461) GPS to enter: 40.00461, -87.99723
  - top, left corner of Dinning Hall (34, 238) GPS to enter: 40.00238, -87.99966
  - bottom, left corder of Great Dorm (100, 35) GPS to enter: 40.00034, -87.99901
    - Note (40.00035, -87.99900) would be perfect but want a little error to show for example. \
After 3 points had error: x: 1.202%, y: 0.25% so save the DB.
- Now see on admin map page. Click Show and then "Save map edits" to get Display Enabled.
- You should now see the meters/groups as is logical for its name and as shown in the tables below.
- You can also use the Campus30Deg.png for a rotated map where it could be named "Campus 30 Deg". The angle to use is 30. The GPS values are the same but the coordinates on the map are different (but you click on the same logical location on the map):
  - top, right corner of Gym: (291, 386) GPS to enter: 40.00461, -87.99723
  - top, left corner of Dining Hal (49, 331) GPS to enter: 40.00238, -87.99966
  - bottom, left corder of Great Dorm (15, 174) GPS to enter: 40.00034, -87.99901
    - Note (40.00035, -87.99900) would be perfect but want a little error to show for example. \
After 3 points had error: x: 0.566%, y: 0.429% so save the DB.
  - The circles should show at the same place on buildings as with the zero degree map.
- TODO You need to redo this process where the image is the myUniversity.png at zero degree and the names were changed so Play Place is Dorm A, Theater is Dorm B and Housing is Academic Building. While basically the same, the names were changed for the academic use example.
  See the map page on how the calibration discussion was created.

## Test data description

The CSV files for meters and readings are in the subdirectory oedData/. The readings.ods file has some of the calculations to get a reading of a desired value. The issue is that you cannot set a given reading to what you want to see on the graph when you plot it on a daily basis. This is complicated because the synthetic data spans many days (a step function) and the times were chosen to stop at varying times in the day.

### Meters

At the current time, the end data is 2022-10-16 10:45:00 or the nearest rounded down. Some useful values:

- If start date is 2019-08-15 10:30:00 with 15 minute readings then 2022-10-16 10:45:00 is in C111170.
- If start date is 2019-08-15 10:30:00 with 20 minute readings then 2022-10-16 10:30:00 is in C83377.
- If start date is 2019-08-15 10:30:00 with 23 minute readings then 2022-10-16 10:33:00 is in C72502.
- If start date is 2019-08-18 00:00:00 with 10080 minute readings then 2022-10-16 00:00:00 is in C166.

You can easily select all for copy/paste is to enter the location of the last reading in the top, left of LibreOffice Calc (Name Box), hit enter, and then go to the top of the sheet and shift-click in A1 to select them all for copy.

Note that GPS is backward due to how OED expects it for a CSV file.

| Name                             | Unit                    | Default Graphic Unit | GPS (long, lat)     | Displayable | ID    | Cell B2             | Reading Increment | Initial Reading | Min Reading | Max Reading | Random Variation | Description |
| :------------------------------: | :---------------------: | :------------------: | :-----------------: | :---------: | :---: | :-----------------: | :---------------: | :-------------: | :---------: | :---------: | :--------------: | :---------: |
| Dining Hall Electric             | Electric_Utility        | kWh                  | -87.99913, 40.002   | true        | 10012 | 2019-08-15 10:30:00 | 15                | 40              | 10          | 70          | 5                | ~3 years    |
| "Dining Hall Electric "          | Electric_Utility        | kWh                  | -87.99913, 40.002   | false       | 10247 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Dining Hall Gas                  | Natural_Gas_BTU         | BTU                  | -87.99913, 40.002   | true        | 10013 | 2019-08-15 10:30:00 | 15                | 35000           | 17000       | 50000       | 1000             | ~3 years    |
| Dining Hall Water                | Water_Gallon            | gallon               | -87.99913, 40.002   | true        | 10014 | 2020-01-07 14:00:00 | 60                | 100             | 10          | 200         | 20               | ~3: years but less than others |
| Dining Hall Electric Power       | Electric_kW             | kW                   | -87.99913, 40.002   | false       | 10015 | 2020-01-07 14:00:00 | 5                 | 160             | 40          | 280         | 20               | ~3: years but less than others |
| Theater Electric                 | Electric_Utility        | kWh                  | -87.9975, 40.0027   | true        | 10016 | 2019-08-15 10:30:00 | 20                | 100             | 20          | 200         | 15               | ~3 years    |
| "Theater Electric "              | Electric_Utility        | kWh                  | -87.9975, 40.0027   | true        | 10251 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Theater Gas                      | Natural_Gas_M3          | BTU                  | -87.9975, 40.0027   | true        | 10017 | 2019-08-15 10:30:00 | 20                | 5.5             | 2           | 12          | 0.5              | ~3 years    |
| Theater Electric Power           | Electric_kW             | kW                   | -87.9975, 40.0027   | false       | 10018 | 2019-08-15 10:30:00 | 20                | 400             | 100         | 700         | 50               | ~3 years    |
| Theater Temperature              | Temperature_Celsius     | Fahrenheit           |                     | true        | 10019 | 2019-08-15 10:30:00 | 20                | 23              | 20          | 24.5        | 0.5              | ~3 years    |
| Library Electric                 | Electric_Utility        | kWh                  | -87.99916, 40.00419 | true        | 10020 | 2019-08-15 10:30:00 | 23                | 20              | 5           | 40          | 3                | ~3 years    |
| "Library Electric "              | Electric_Utility        | kWh                  | -87.99916, 40.00419 | true        | 10255 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Library Temperature              | Temperature_Fahrenheit  | Fahrenheit           |                     | true        | 10021 | 2019-08-15 10:30:00 | 20                | 75              | 68          | 76          | 1                | ~3 years    |
| Great Dorm 1st floor Electric    | Electric_Solar          | kWh                  | -87.99817, 40.00057 | true        | 10022 | 2019-08-15 10:30:00 | 20                | 10              | 5           | 20          | 3                | ~3 years    |
| "Great Dorm 1st floor Electric " | Electric_Solar          | kWh                  | -87.99817, 40.00057 | true        | 10257 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Great Dorm 2nd floor Electric    | Electric_Solar          | kWh                  | -87.99817, 40.00057 | true        | 10023 | 2019-08-15 10:30:00 | 20                | 15              | 10          | 30          | 3                | ~3 years    |
| "Great Dorm 2nd floor Electric " | Electric_Solar          | kWh                  | -87.99817, 40.00057 | true        | 10258 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Great Dorm Gas                   | Natural_Gas_BTU         | BTU                  | -87.99817, 40.00057 | true        | 10024 | 2019-08-15 10:30:00 | 20                | 45000           | 25000       | 65000       | 2000             | ~3 years    |
| Great Dorm Water                 | Water_Liter             | gallon               | -87.99817, 40.00057 | true        | 10025 | 2019-08-15 10:30:00 | 15                | 150             | 75          | 300         | 50               | ~3 years    |
| Campus Recycling                 | Ton                     | pound                |                     | true        | 10026 | 2019-08-16 00:00:00 | 10080             | 1               | 0.25        | 1.8         | 0.25             | ~3 years, 7 days per reading |

### Groups

| Name                            | Default Graphic Unit | GPS                 | Displayable | Meters                                                             | Groups                                       | ID    | Description |
| :-----------------------------: | :------------------: | :-----------------: | :---------: | :----------------------------------------------------------------: | :------------------------------------------: | :---: | :---------: |
| Dining Hall Energy              | kWh                  | -87.99913, 40.002   | true        | Dining Hall Electric, Dining Hall Gas                              |                                              | 10012 |             |
| Dining Hall All                 | ton of CO2           | -87.99913, 40.002   | true        | Dining Hall Water                                                  | Dining Hall Energy                           | 10013 |             |
| Theater Energy                  | kWh                  | -87.9975, 40.0027   | true        | Theater Electric, Theater Gas                                      |                                              | 10014 |             |
| Theater All                     | ton of CO2           | -87.9975, 40.0027   | true        |                                                                    | Theater Energy                               | 10015 |             |
| Dining & Theater Electric Power | kW                   |                     | false       | Dining Hall Electric Power, Theater Electric Power                 |                                              | 10016 |             |
| Library Electric                | kWh                  | -87.99916, 40.00419 | true        | Library Electric                                                   |                                              | 10017 |             |
| Great Dorm Electric             | kWh                  | -87.99817, 40.00057 | true        | Great Dorm 1st floor Electric, Great Dorm 2nd floor Electric       |                                              | 10018 |             |
| "Great Dorm Electric "          | kWh                  | -87.99817, 40.00057 | true        | "Great Dorm 1st floor Electric ", "Great Dorm 2nd floor Electric " |                                              | 10253 | compare to mirror other |
| Great Dorm Energy               | kWh                  | -87.99817, 40.00057 | true        | Great Dorm Gas                                                     | Great Dorm Electric                          | 10019 |             |
| Great Dorm All                  | ton of CO2           | -87.99817, 40.00057 | true        | Great Dorm water                                                   | Great Dorm Energy                            | 10020 |             |
| Campus Electric                 | kWh                  |                     | true        | Dining Hall Electric, Theater Electric, Library Electric           | Great Dorm Electric                          | 10021 |             |
| Campus Gas                      | BTU                  |                     | true        | Dining Hall Gas, Theater Gas, Great Dorm Gas                       |                                              | 10022 |             |
| Campus Energy                   | kWh                  |                     | true        |                                                                    | Campus Electric, Campus Gas                  | 10023 |             |
| Campus All                      | ton of CO2           |                     | true        | Dining Hall Water, Great Dorm Water                                | Campus Energy                                | 10024 |             |
| Campus All - Another            | ton of CO2           |                     | false       | Library Electric, Dining Hall Electric                             | Dining Hall All, Theater All, Great Dorm All | 10025 | Same as Campus All, also duplicates D.H. Electric |

## Items for website update

### Overall site

- Check that the site is named “OED Demo Site”.
- Make sure you log out as admin so it looks as a normal user would see unless doing an admin page.
- Unless you want to show the dropdown menus, click off of them.
- Remember to hover over values for many graphs.
- Looking at the current image can help in making the new one. The HTML has the file names that make it easier to name the new screenshots.
- When you want a box around an item, use the border color of 0000FF in web colors. The second, light blue box, is color 3399FF in web colors.

### Update all pages as needed

- If done correctly, all PRs and issues for this milestone are listed in the milestone so you can figure out what needs updating.
- Don’t forget that features.html on the main website also has OED images of many features.
- Sometimes changes impact the developer pages.
- Compare & map values change when re-graph so need to check values in text

### Details on special website pages

- The adminMap.html file discusses calibration issues by changing the inputted GPS value +/: a given amount. Unfortunately I did not record the exact values for each point. However, it was probably +/-/+ for the three points but may be different signs.
- Before doing images for the useAcademic.html, rename the site "My University".

### HTML is valid

Go to [https://validator.w3.org/](https://validator.w3.org/) and enter URL. Seems must do one page at a time.

### check CSS if valid

[https://jigsaw.w3.org/css-validator/](https://jigsaw.w3.org/css-validator/)

Did the only page of css/main.css and no issues found.

### Check links are valid

Go to [https://validator.w3.org/checklink], enter web address, check summary only, set the depth of linked documents recursion to 10 to check all the linked pages. (Note tried checking Hide redirects but it did not help.) It takes a little while but it finds and checks them all.

- Cannot check email links so get at least one warning on each page for contact
- Complains about MPL link on footer of each page but it does seem fine.
- [https://www.learn-js.org/](https://www.learn-js.org/) generally gives an error but the link seems fine.
- [https://help.github.com/](https://help.github.com/) and  [https://docs.github.com/get-started/quickstart/fork-a-repo](https://docs.github.com/get-started/quickstart/fork-a-repo) gives redirect warning but want the redirect since selecting language automatically.
- [https://docs.google.com/forms/d/e/1FAIpQLSc2zdF2PqJ14FljfQIyQn_X70xDhnpv-zCda1wU0xIOQ5mp_w/viewform](https://docs.google.com/forms/d/e/1FAIpQLSc2zdF2PqJ14FljfQIyQn_X70xDhnpv-zCda1wU0xIOQ5mp_w/viewform) gives warning on not checked to to robot exclusion but okay.
- Can save the result as html and then do “grep -e Line -A 2 foo.html” to see all lines with issues plus the two following to get the message or “grep -e Line foo.html | grep -v -e "mailto:" -e "http://mozilla.org/MPL/2.0/" -e "https://docs.google.com/forms/d/e/1FAIpQLSc2zdF2PqJ14FljfQIyQn_X70xDhnpv-zCda1wU0xIOQ5mp_w/viewform" -e "https://www.learn-js.org/" -e "https://help.github.com/" -e "https://docs.github.com/get-started/quickstart/fork-a-repo"” for just the ones without the msgs noted above. This may not be perfect but it appears to get everything.
- All okay with warning noted above as of 210807.

### Check accessibility

Not yet done/figured out.

## **After this needs update and inclusion in new system**
## Uses of meters/readings

* Meter A-D are step functions that make it easier to see the value of a group is correct. Thus, Meter &lt;letter&gt; is step function data.
- Meter A-C are modest values that can be used together.
- Meter D is deliberately larger values to show issue of how others values become hard to see.
- Meters C-D demonstrate what happens when you have missing intervals of values. Deliberately chose to only have time missing at start/end because OED draws a line over the missing time if it is in the middle of the graph. (Maybe we will do something about that some day ;-)
* Meter 1-4 are real data to show something more realistic. This is designed for overview graphics. Thus, Meter # is real data.
* Meters 7-8 & All the Dorm ones are for comparison and having current readings. They are real data that is the same as Meters 1-4 but shifted in time.
