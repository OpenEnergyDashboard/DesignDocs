# Documentation on how website data is created

## Creating the CSV data readings files

The files to do this are in the webData/ directory. If you are not creating new meter data then they should already be there. webMeter.ods can generate random meter data. It is a LibreOffice file spreadsheet file with formulas. You get the meter data by setting the following cells:

- B2 is the first date/time for a reading. It is normally in YYYY-MM-DD HH-MM-SS format where HH is in 24 hour time.
- E2 sets the minutes between readings.
- E5 is the initial reading value for the first reading. It is often in the middle of the min and max reading allowed.
- E8 is the minimum value for a reading. If the random values go below this then the random shift is reversed to keep it above this value.
- E11  is the maximum value for a reading. If the random values go above this then the random shift is reversed to keep it below this value.
- E14 is the random variation for the next reading. It can go up or down by this amount as long as it does not go outside the bounds allowed.

No other cells should be edited. Note Column D is random values generated to do the calculations. You do not normally touch this column. D2 does not need a value. Note the values change whenever you reopen the spreadsheet or touch cells in the sheet.

After setting the values, the spreadsheet will create the values needed in columns A, B, C. You can create a CSV for import as described later by:

1. Selecting the entire columns of A-C or any set of rows that have the dates desired. If you only take a subset of the rows then make sure to separately copy to first header row of columns A-C.
2. Copy the values selected.
3. Open a new spreadsheet.
4. If you are copying all the rows or the header row then click in cell A1. If you have already put in the header row and are now copying the rows with meter data then click in cell A2.
5. Do a special paste by either doing Edit -> Special Paste -> Special Paste ... or control/command-shift-v. In the popup, click the Values Only button on the left because you don't want to get the formulas.
6. Select all of columns B & C. Then do Format -> Cells ... or control/command 1. In Category select date and then in Format select  1999-12-31 13:37:46. This formats the columns as dates in the canonical format. You may need to make the columns wider to see the values (esp. if you see ### instead of date/time).
7. Do File -> Save As ... or control/command-shift S. In File type: select Text CSV (.csv) and enter a file name at the top. Then click the Save button.

Later in this document is the standard values used for the website where this process is done once for each meter desired.

## Entering the website data

The steps for putting the data into a website are

1. Generally you start from a clean version of OED so only the website data is present.
    - An alternative is to delete the current data. In a psql shell you can do: \
    `delete from readings; delete from groups_immediate_meters; delete from groups_immediate_children; delete from groups; delete from meters; delete from conversions; delete from units;`
2. Link the CSV file from webData/ in devDocs/ to src/server/data/webData. This hard link does not copy the file but creates a link to the inode of the original file so it saves a little disk space. It is okay to delete the link and the original file will not be changed. This is done in a Linux shell/terminal on your machine and not in the web or database shell in an OED container; you can open a terminal in VSC to do this. It must be done in the main OED directory and have your devDocs starting the the directory above or you need to modify the path to the DevDocs/ in the following command: \
  `mkdir -p src/server/data/webData; cp -l ../DevDocs/website/webData/*.csv src/server/data/webData/`
3. Get OED running if it is not already up.
4. Open a shell in the OED web Docker container.
5. In the shell run: \
  `npm run webData`
    - This will likely take some time to run as it needs to load a lot of data from CSV files.
6. Open new or refresh localhost:3000 in a web browser. All the units, conversions, meters and groups should be present.

### Compare data

The comparison page needs current data. To achieve this, you can use a web terminal in the main OED directory and do: \
`node -e 'require("./src/server/data/websiteData.js").webShift("CST")'` \
where you replace the "CST" with the code for the timezone for the web browser you are going to use. Get the timezone of your local machine by doing the following. This is done in a Linux shell/terminal on your machine and not in the web or database shell in an OED container; you can open a terminal in VSC to do this. \
`date +%Z` \

- An older list of Postgres acceptable timezones (they don't usually change) is at [Postgres Timezones](https://www.postgresql.org/docs/7.2/timezones.html).
- You can also use the Postgres SQL command (in a database shell inside `psql -U oed`) of: \
`select * FROM pg_timezone_names;`

You can verify you have the correct timezone code by doing `select clock_timestamp() at time zone 'cst';` in the Postgres shell (see above). Replace 'cst' with the timezone you want to use. The time should match the one on your computer's clock.

Note you can do this as often as you wish to keep the readings current (note it take a little time to execute). Since it brings the readings to current time, the compare graphs will vary unless you do it at the same day of the week and the same hour of the day.

There are meters and groups listed in the table below. They mirror another meter/group where a space character is added to the end of the name. That way they look the same on the menus and graphics since you don't see the extra space. By default they are not displayable so they will not show unless logged in as an admin. You need to make them visible and hide the usual one if you only want to see them in the menus. Note the name with the space comes second in the menus so you can tell which one you are working with if both are present. Also note that the IDs were carefully selected so both meters will show in the same color on all graphics.

### Map data

#### Create the needed maps

This was done once and then reused.

- I used a LibreOffice Drawing document to do this. It is a simple, stylized map. Note I used the grid to create a box that was 9x15 (width x height). The OED map system places a 300x500 grid on the uploaded map. Thus, having an aspect ratio of 3:5 makes it fit without any whitespace. I placed the building on the map and inside the box. I then make the box white and sent it to the back (behind the buildings). I then selected the box and buildings and placed in a group (it seemed I needed select(?) buildings first but not sure why). I selected the group, File→export, choose png and click for selection for save, then it automatically gave the size as 4.5”x7.5” (3:5 ratio) so just used it. The final file is campus.png and campus.odg. You see the while box when you open the PNG with dark mode but not in OED.
- Now create the 30 degree rotated map. Select the group, Format -> Position and Size, then click the Rotation tab and set the angle to 330 degrees. Resize the bounding box to fit the rotated map but make sure the keep the aspect ratio the same where it is not rotated. I did 12x20 so still 3:5 and center horizontally over image but lots of extra vertical space on bottom. Reform group of all items. Export as before. It is in campus30Deg.png (and .odg).

#### Place map in OED

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
- You should now see the meters/groups as is logical for its name and as shown in the tables below. Note that the Gym building has no data and not used on the map.
- You can also use the Campus30Deg.png for a rotated map where it could be named "Campus 30 Deg". The angle to use is 30. The GPS values are the same but the coordinates on the map are different (but you click on the same logical location on the map):
  - top, right corner of Gym: (291, 382) GPS to enter: 40.00461, -87.99723
  - top, left corner of Dining Hall (43, 327) GPS to enter: 40.00238, -87.99966
  - bottom, left corder of Great Dorm (7,166) GPS to enter: 40.00034, -87.99901
    - Note (40.00035, -87.99900) would be perfect but want a little error to show for example. \
After 3 points had error: x: 1.224%, y: 0.136% so save the DB.
  - The circles should show at the same place on buildings as with the zero degree map.

  See the map page on how the calibration discussion was created.

## Test data description

The CSV files for meters and readings are in the subdirectory webData/. The webMeter.ods file has some of the calculations to get a reading of a desired value (see above). The issue is that you cannot set a given reading to what you want to see on the graph when you plot it on a daily basis.

### Meters

At the current time, the end data is 2022-10-16 10:45:00 or the nearest rounded down. Some useful values:

- If start date (B2) is 2019-08-15 10:30:00 with 15 minute readings then 2022-10-16 10:45:00 is in C111170.
- If start date (B2) is 2019-08-15 10:30:00 with 20 minute readings then 2022-10-16 10:30:00 is in C83377.
- If start date (B2) is 2019-08-15 10:30:00 with 23 minute readings then 2022-10-16 10:33:00 is in C72502.
- If start date (B2) is 2019-08-18 00:00:00 with 10080 minute readings then 2022-10-16 00:00:00 is in C166.

You can easily select all for copy/paste is to enter the location of the last reading in the top, left of LibreOffice Calc (Name Box), hit enter, and then go to the top of the sheet and shift-click in A1 to select them all for copy.

Note that GPS is backward due to how OED expects it for a CSV file.

| Name                             | Unit                    | Default Graphic Unit | GPS (long, lat)     | area   | Displayable | ID    | Cell B2             | Reading Increment | Initial Reading | Min Reading | Max Reading | Random Variation | Description |
| :------------------------------: | :---------------------: | :------------------: | :-----------------: | :----: | :---------: | :---: | :-----------------: | :---------------: | :-------------: | :---------: | :---------: | :--------------: | :---------: |
| Campus Recycling                 | Ton                     | pound                |                     |        | true        | 10026 | 2019-08-16 00:00:00 | 10080             | 1               | 0.25        | 1.8         | 0.25             | ~3 years, 7 days per reading |
| Dining Hall Electric             | Electric_Utility        | kWh                  | -87.99913, 40.002   | 1000   | true        | 10012 | 2019-08-15 10:30:00 | 15                | 40              | 10          | 70          | 5                | ~3 years    |
| "Dining Hall Electric "          | Electric_Utility        | kWh                  | -87.99913, 40.002   | 1000   | false       | 10247 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Dining Hall Electric Power       | Electric_kW             | kW                   | -87.99913, 40.002   | 1000   | false       | 10015 | 2020-01-07 14:00:00 | 5                 | 160             | 40          | 280         | 20               | ~3: years but less than others |
| Dining Hall Gas                  | Natural_Gas_BTU         | BTU                  | -87.99913, 40.002   | 1000   | true        | 10013 | 2019-08-15 10:30:00 | 15                | 35000           | 17000       | 50000       | 1000             | ~3 years    |
| Dining Hall Water                | Water_Gallon            | gallon               | -87.99913, 40.002   | 1000   | true        | 10014 | 2020-01-07 14:00:00 | 60                | 100             | 10          | 200         | 20               | ~3: years but less than others |
| Great Dorm 1st floor Electric    | Electric_Solar          | kWh                  | -87.99817, 40.00057 | 5000   | true        | 10022 | 2019-08-15 10:30:00 | 20                | 10              | 5           | 20          | 3                | ~3 years    |
| "Great Dorm 1st floor Electric " | Electric_Solar          | kWh                  | -87.99817, 40.00057 | 5000   | true        | 10257 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Great Dorm 2nd floor Electric    | Electric_Solar          | kWh                  | -87.99817, 40.00057 | 5000   | true        | 10023 | 2019-08-15 10:30:00 | 20                | 15              | 10          | 30          | 3                | ~3 years    |
| "Great Dorm 2nd floor Electric " | Electric_Solar          | kWh                  | -87.99817, 40.00057 | 5000   | true        | 10258 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Great Dorm Gas                   | Natural_Gas_BTU         | BTU                  | -87.99817, 40.00057 | 10000  | true        | 10024 | 2019-08-15 10:30:00 | 20                | 45000           | 25000       | 65000       | 2000             | ~3 years    |
| Great Dorm Water                 | Water_Liter             | gallon               | -87.99817, 40.00057 | 10000  | true        | 10025 | 2019-08-15 10:30:00 | 15                | 150             | 75          | 300         | 50               | ~3 years    |
| Library Electric                 | Electric_Utility        | kWh                  | -87.99916, 40.00419 | 100000 | true        | 10020 | 2019-08-15 10:30:00 | 23                | 20              | 5           | 40          | 3                | ~3 years    |
| "Library Electric "              | Electric_Utility        | kWh                  | -87.99916, 40.00419 | 100000 | true        | 10255 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Library Temperature              | Temperature_Fahrenheit  | Fahrenheit           |                     |        | true        | 10021 | 2019-08-15 10:30:00 | 20                | 75              | 68          | 76          | 1                | ~3 years    |
| Theater Electric                 | Electric_Utility        | kWh                  | -87.9975, 40.0027   | 10000  | true        | 10016 | 2019-08-15 10:30:00 | 20                | 100             | 20          | 200         | 15               | ~3 years    |
| "Theater Electric "              | Electric_Utility        | kWh                  | -87.9975, 40.0027   | 10000  | true        | 10251 |                     |                   |                 |             |             |                  | compare that reuses CSV above |
| Theater Electric Power           | Electric_kW             | kW                   | -87.9975, 40.0027   | 10000  | false       | 10018 | 2019-08-15 10:30:00 | 20                | 400             | 100         | 700         | 50               | ~3 years    |
| Theater Gas                      | Natural_Gas_M3          | BTU                  | -87.9975, 40.0027   | 10000  | true        | 10017 | 2019-08-15 10:30:00 | 20                | 5.5             | 2           | 12          | 0.5              | ~3 years    |
| Theater Temperature              | Temperature_Celsius     | Fahrenheit           |                     |        | true        | 10019 | 2019-08-15 10:30:00 | 20                | 23              | 20          | 24.5        | 0.5              | ~3 years    |

### Groups

| Name                            | Default Graphic Unit | GPS                 | area   | Displayable | Meters                                                             | Groups                                       | ID    | Description |
| :-----------------------------: | :------------------: | :-----------------: | :----: | :---------: | :----------------------------------------------------------------: | :------------------------------------------: | :---: | :---------: |
| Campus All                      | ton of CO2           |                     | 121000 | true        | Dining Hall Water, Great Dorm Water                                | Campus Energy                                | 10024 |             |
| Campus All - Another            | ton of CO2           |                     | 121000 | false       | Library Electric, Dining Hall Electric                             | Dining Hall All, Theater All, Great Dorm All | 10025 | Same as Campus All, also duplicates D.H. Electric |
| Campus Electric                 | kWh                  |                     | 121000 | true        | Dining Hall Electric, Theater Electric, Library Electric           | Great Dorm Electric                          | 10021 |             |
| Campus Energy                   | kWh                  |                     | 121000 | true        |                                                                    | Campus Electric, Campus Gas                  | 10023 |             |
| Campus Gas                      | BTU                  |                     | 121000 | true        | Dining Hall Gas, Theater Gas, Great Dorm Gas                       |                                              | 10022 |             |
| Dining & Theater Electric Power | kW                   |                     | 11000  | false       | Dining Hall Electric Power, Theater Electric Power                 |                                              | 10016 |             |
| Dining Hall All                 | ton of CO2           | -87.99913, 40.002   | 1000   | true        | Dining Hall Water                                                  | Dining Hall Energy                           | 10013 |             |
| Dining Hall Energy              | kWh                  | -87.99913, 40.002   | 1000   | true        | Dining Hall Electric, Dining Hall Gas                              |                                              | 10012 |             |
| Great Dorm All                  | ton of CO2           | -87.99817, 40.00057 | 10000  | true        | Great Dorm water                                                   | Great Dorm Energy                            | 10020 |             |
| Great Dorm Electric             | kWh                  | -87.99817, 40.00057 | 10000  | true        | Great Dorm 1st floor Electric, Great Dorm 2nd floor Electric       |                                              | 10018 |             |
| "Great Dorm Electric "          | kWh                  | -87.99817, 40.00057 | 10000  | true        | "Great Dorm 1st floor Electric ", "Great Dorm 2nd floor Electric " |                                              | 10253 | compare to mirror other |
| Great Dorm Energy               | kWh                  | -87.99817, 40.00057 | 10000  | true        | Great Dorm Gas                                                     | Great Dorm Electric                          | 10019 |             |
| Library Energy                  | kWh                  | -87.99916, 40.00419 | 100000 | true        | Library Electric                                                   |                                              | 10017 |             |
| Theater All                     | ton of CO2           | -87.9975, 40.0027   | 10000  | true        |                                                                    | Theater Energy                               | 10015 |             |
| Theater Energy                  | kWh                  | -87.9975, 40.0027   | 10000  | true        | Theater Electric, Theater Gas                                      |                                              | 10014 |             |

#### Special groups

There are a few places where groups are manually created and can be deleted after use:

- help/v1.0.0/lineGraphic.html uses the "Great Dorm Electric Vary" group. It includes the "Great Dorm 2nd Floor Electric " meter which is the compare one that has the dates shifted to current time.
- help/v1.0.0/adminGroupEditing.html describes special groups created to show warnings. It also creates units, conversions & meters. The page describes what was used.
- help/v1.0.0/adminGroupEditing.html demonstrates a circular dependency message. It is a little tricky because you need to include something to create it. Here are the steps:
  - Create group x with some meter.
  - Create group z with group x as a child group.
  - Edit group x to add group z as a child group. The message appears. 

## Images from OED

### Setting the web browser window size

First I made the window a size and zoom that allowed long menu choices to show completely (Great Dorm 1st Floor is a long one). I then did the sizing below and by trial and error, determined that 1200x830 was a good size. I used 1200 as that is the number of pixels for the max page size in OED per css/main.css.

- Open the developer tools (F12 or right click on window and choose Inspect).

#### For Chrome

- Toggle device toolbar (click on icon in top, left of developer tools area that looks like a monitor/phone or control/command-shift-M). This should cause a ribbon above the webpage that has Dimensions and other info.
- Click the dropdown menu after Dimensions: which lists the device types and choose Edit... a the bottom.
- The developer tools area will change to show Settings with the Devices tab selected. Under Emulated Devices click Add custom device....
- In the input area for the new device use the name "website" (or whatever you want) and use the dimensions you want but used 1200 and 830. Under User agent string use the dropdown and select desktop since that is the target. Finally, click add to save it
- Repeat to create one named long with 1200 and 1800 with desktop. This is useful when a long modal pops up to see it all.
- You can "X" out of the Settings to go back to the normal developer tools if you want.
  - If you ever want to edit this, hover over the device name in Settings and click the pencil to edit similarly to creating it.
- If not already selected, choose website from the dropdown menu next to Dimensions. It should now set the pixels as desired.
- You can use the % dropdown menu to make the actual size shown to be larger or smaller but normally did 100%. Also used the ability to scroll the developer tools area to be smaller to see the entire emulated monitor. Resized to be big enough to see the entire screen of OED. Can also three vertical dots to put developer tools in a separate window.
- After the first time you can simply Toggle device toolbar and select the desired device if not already selected.

#### For Firefox

This did not work and the website would not load after a refresh. Not sure at this time.

- Use Responsive Design Mode by clicking the different sized phone icons in the top, right corner of the developer tools or control/command-shift-M in the original web window. This should cause a ribbon above the webpage that has Dimensions and other info.
- Use the first dropdown menu to create a new device similarly to Chrome. You can also directly change the dimensions for the current device.

### Editing images

Use whatever image editing program you want to highlight items and crop. Areas are highlighted by putting a blue (standard blue color: #3282F6 or Red 50 / Green 130 / Blue 246) rectangle with 5px size lines (squared edges). If a second item is highlighted then it is done in sky blue (standard sky color: #73FBFD or Red 115 / Green 251 / B;ie 253). Each image was put into the website with this command where you change the information to your image:

```<p><img alt="Graphic unit menu" src="./images/graphicUnitMenu.png"></p>```

You need the paragraph for two reasons. First, the img tag is not in the CSS because the it is used for the icon on the pages. Second, this constrains to the text width (set to 1200) rather than the full browser window as desired. Sometimes different widths might be used if needed by putting in the style to override the CSS. For example, the image is smaller than the min used by default in the css. In what follows, the width size used was found by looking at the image properties and selecting the actual width for the value. Do not put in a \<p\>.

```<img alt="Graphic unit menu showing allowed choices" src="./images/graphicUnitMenuAllowedChoices.png" width="543">```

There are examples of othe image sizing for special cases.

## Images from LibreOffice

The graphics are generally done in LibreOffice Draw as an .odg file. It is then exported as follows:

1. Select all
2. File -> Export ... or icon
3. On export popup

    - click checkbox for Selection
    - Save as type: PNG

4. In PNG options popup

    - Under Size use Modify dimensions
    - Use pixels
    - If the width is more than 1024 then set to 1024 which is same size as used for OED images above
    - When you click outside this input box (or tab) then the height should automatically change to keep the aspect ratio
    - Click OK to save the image to the file

Note that the width sometimes seems to be a pixel off but that is not a big issue.

## Videos

While any screen capture software can be used, the following descripes the use of OBS Studio that is open source and cross platform.

### Set web browser size for displaying OED

This is similar to the section "Setting the web browser window size" above but a different name/size.

- Gave name of Video 1024x682
- Set pixels to 1024 & 682
  - This is close to 3:2. 4:3 leaves plank space at bottom and 16:9 tends to cut off items. The chosen one cuts off footer on map but works well overall. 
- Set User agent string to Desktop choice (very important)
- Save
- In size, choose 100% or Fit to window. Auto adjust will probably do 99% and that is okay.

### Set up OBS

- Audio – OBS gives microphone by default so don't need to do this.
  - right click in Sources, Add → Audio input capture. Choose Create new and name as wish.
- Video
  - https://obsproject.com/forum/threads/how-to-record-selected-area-of-screen.95810/

1. start with a fresh scene setup
2. set Settings->Video->Base resolution to your monitor resolution
3. add a display capture source. In the popup, select the Display created. 
4. If not already highlighted, click on the source, you will see the borders and small red circles at the edges of the source.
5. crop your desired area by holding ALT down and move the small red circles with the mouse, so you only have your smaller video clip (this may be Windows specific)
    - In the ideal world you preserve the same size as the web browser window. This means the total cropped above/below or left/right is (screen size – window size where this uses a display of 2560x1440):
      - left/right: 2560 – 1024 = 1536
      - top/bottom: 1440 – 682 = 758
      - It is hard to get perfect but can get very close.
6. drag the cropped source to the top left corner of the preview. If the crop was perfect and the placement at top, left then you see 1536 px to right and 758 to bottom with none at left and right.. You can use the arrow keys to move 1 px at a time.
7. open Settings->Video and as base and output resolution enter your desired resolution that should contain the video file or stream. You will enter a much smaller resolution now, to minimize the black area around the source. Ideally, you set it exactly to the size of your cropped source which is close to 1024x682. The exact is the screen size – cropped. If 1535 to right and 758 to left then get 2560 – 1535 = 1025 and 1440 – 758 = 682 or input 1025x682.
8. right-click your source and in the popup menu select Transform->Fit to screen to make the source the size of your new base resolution

The next time you can drag the web browser window to be the placement you want in the source.

### Doing videos

You can record and do the usual OBS functions.

## Debugging locally

Unless you have Jekyll installed, you cannot see the formatting done by GitHub on your local machine. You need to push the changes to GitHub to see.

You can add ```<link rel="stylesheet" href="../../css/main.css"> <!-- DEBUG - REMOVE -->``` to the top of a page (right below the Jekyll front matter separated by "---") on any help page. You can change the relative path if the file is in another directory. This will load in the CSS file so it will look closer to GitHub. Just remember to delete before committing. Searching for "DEBUG" or "REMOVE" will make this easy.

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
- Can save the result as html and then do “grep -e Line -A 2 foo.html” to see all lines with issues plus the two following to get the message or “grep -e Line foo.html | grep -v -e "mailto:" -e "<http://mozilla.org/MPL/2.0/>" -e "<https://docs.google.com/forms/d/e/1FAIpQLSc2zdF2PqJ14FljfQIyQn_X70xDhnpv-zCda1wU0xIOQ5mp_w/viewform>" -e "<https://www.learn-js.org/>" -e "<https://help.github.com/>" -e "<https://docs.github.com/get-started/quickstart/fork-a-repo"”> for just the ones without the msgs noted above. This may not be perfect but it appears to get everything.
- All okay with warning noted above as of 210807.

### Check accessibility

Not yet done/figured out.
