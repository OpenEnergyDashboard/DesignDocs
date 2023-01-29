# Documentation on how testing data is created

The directory readingsData/ has all the files used.

## Input values

The following table gives the test readings created so far. The fields are:

1) "Reading Increment" is the time between readings in minutes.
2) "Min Reading" is the smallest random value allowed.
3) "Max Reading" is the largest random value allowed.
4) "File name" is the input file name holding the data for testing that has these fields where all fields are separated by "_":
    - The first field is what the file is. "readings" is the input readings.
    - "ri" stands for reading increment. It is followed by the minutes between readings, e.g., ri_15.
    - "days" stands for the number of days that there are readings. It is followed by a number, e.g., days_75.
5) "Description" is a description of the data.
6) "Cell range" is used in generating the data as described below.

Unless noted, readings start at 2022-08-18 00:00:00.

| Reading Increment | Min Reading | Max Reading | File name                     | Description                                 | Cell range   |
| :---------------: | :---------: | :---------: | :----------------------------:| :-----------------------------------------: | :----------: |
| 15                |  0          | 100         | readings_ri_15_days_75.csv    | 15 min readings; positive values; 75 days   | A5:C7204     |

## Expected values

The following table gives information about the expected readings returned for a meter input with the indicated data. The values have the following meanings:

- "Readings file" is the file used from the table above and determines the readings on the meter.
- "Meter unit" is the unit name used for the meter.
- "Graphic unit" is the unit name given to the DB for the readings requested.
- "slope" is the slope of the conversion from meter unit to graphic unit.
- "intercept" is the intercept of the conversion from meter unit to graphic unit. It is typically zero (temperature unit is an exception).
- "min/reading" is the minutes/reading that is returned by the database when the readings are requested. For example, if expect to get hourly readings then it is 60 and 1440 for daily readings.
- "Cell range" is the range of cells holding the first start time to the last end time stamp for the expected readings. It is used as described below.
- "Start time for readings" is the date/time for the beginning of the readings requested from the DB.
- "End time for readings" is the date/time for the ending of the readings requested from the DB.
- "Expected readings file name" is the file that can be used to compare to the readings from the DB. The name has these fields where all fields are separated by "_":

    1) The first field is what the file is. "expected" is the readings from a request to the DB.
    2) "ri" is the same as readings file.
    3) "mu" stands for the meter unit. It is followed by the unit name, e.g., mu_kWh.
    4) "gu" stands for the graphic unit. It is followed by the unit name, e.g., gu_BTU.
    5) "st" stands for start time. It is followed by the start time for the readings request from the DB where "inf" is short for infinity and "-inf" is negative infinity. It can also be a date/time such as "2022-09-22%13#00#00". Note what is normally a space becomes % and what is normally a : becomes a #. This is to avoid issues with various file systems.
    6) "et" is similar to "st" but the end time for the readings request.

- "Description" gives information on this row.

**TODO The dates needed for expected data need to change after the DB functions for getting data are updated to go raw then hourly then daily.**

| Readings file                 | Meter unit  | Graphic unit | slope      | intercept | min/reading | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                    | Description                                 |
| :------------------------: | :---------: | :----------: | :--------: | :-------: | :---------: | :-----------: |:----------------------: | :-------------------: | :----------------------------------------------------------------------------: | :-----------------------------------------: |
| readings_ri_15_days_75.csv |  kWh        | kWh          | 1          | 0         | 1440        | E5:G79        | -infinity               | +infinity             | expected_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf.csv                                | gives daily points of all readings |
| readings_ri_15_days_75.csv |  kWh        | kWh          | 1          | 0         | 1440        | E5:G79        | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv | same as above but explicit dates |
| readings_ri_15_days_75.csv |  kWh        | kWh          | 1          | 0         | 1440        | E12:G72       | 2022-08-25 00:00:00     | 2022-10-25 00:00:00   | expected_ri_15_mu_kWh_gu_kWh_st_2022-08-25%00#00#00_et_2022-10-25%00#00#00.csv | 61 days barely gives daily points & middle readings |
| readings_ri_15_days_75.csv |  kWh        | kWh          | 1          | 0         | 60          | E173:G1612    | 2022-08-25 00:00:00     | 2022-10-24 00:00:00   | expected_ri_15_mu_kWh_gu_kWh_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv | 60 days gives hourly points & middle readings |
| readings_ri_15_days_75.csv |  kWh        | kWh          | 1          | 0         | 60          | E821:G1180    | 2022-09-21 00:00:00     | 2022-10-06 00:00:00   | expected_ri_15_mu_kWh_gu_kWh_st_2022-09-21%00#00#00_et_2022-10-06%00#00#00.csv | 15 days barely gives hourly points & middle readings |
| readings_ri_15_days_75.csv |  kWh        | kWh          | 1          | 0         | 15          | E3269:G4612   | 2022-09-21 00:00:00     | 2022-10-05 00:00:00   | expected_ri_15_mu_kWh_gu_kWh_st_2022-09-21%00#00#00_et_2022-10-05%00#00#00.csv | 14 days barely gives raw points & middle readings |
| readings_ri_15_days_75.csv |  kWh        | kWh          | 1          | 0         | 1440        | E7:G76 \*     | 2022-08-20 07:25:35     | 2022-10-28 13:18:28   | expected_ri_15_mu_kWh_gu_kWh_st_2022-08-20%07#25#35_et_2022-10-28%13#18#28.csv | partial days/hours for daily: 292:227, 6873:6821 |
| readings_ri_15_days_75.csv |  kW         | kW           | 1          | 0         | 1440        | E5:G79        | -infinity               | +infinity             | expected_ri_15_mu_kW_gu_kW_st_-inf_et_inf.csv                                  | gives daily points of all readings |

\* indicates you need to fix up the first/last readings due to partial times. See below.

## Generating test data

### Selecting a range of values

You can copy the "Cell range" from the desired table and paste it into the top, left of LibreOffice Calc (Name Box) and then press the enter key on your keyboard.

### Generating readings

The readings.ods was used to generate the test data. If you are not creating new reading test data then they should already be there. readings.ods can generate random readings data. It is a LibreOffice file spreadsheet file with formulas. You get get the meter data by setting the following cells:

- B5 is the first date/time for a reading. It is normally in YYYY-MM-DD HH-MM-SS format where HH is in 24 hour time.
- A2 sets the minutes between readings.
- B2 is the minimum value for a reading.
- C2  is the maximum value for a reading.

No other cells should be edited. Note the readings change whenever you reopen the spreadsheet or touch cells in the sheet. To keep the same value they are copied to another CSV file as only values (see next).

After setting the values and creating the values in the three needed columns (A, B, C) you can create a CSV for testing usage by:

1) Select the range indicated for "Cell range" for your test in the readings table (not the expected table).
2) Copy the values selected.
3) Open a new spreadsheet.
4) Do a special paste starting in cell A2 by either doing Edit -> Special Paste -> Special Paste ... or control/command-shift v. In the popup, click the Values Only button on the left because you don't want to get the formulas. Resizing the columns will likely make the values easier to see. The rows should now have the desired readings to input into the meter.
5) Select all of columns B & C. Then do Format -> Cells ... or control/command 1. In Category select date and then in Format select  1999-12-31 13:37:46. This formats the columns as dates in the canonical format. You may need to make the columns wider to see the values (esp. if you see ### instead of date/time).
6) Go back to the readings.ods spreadsheet and select A4:C4. Copy these values for the header.
7) Go back to the readings spreadsheet you are creating and paste starting in A1. You now have the header row for the CSV.
8) Do File -> Save As ... or control/command-shift S. In File type: select Text CSV (.csv) and enter a file name for the row for the readings you are creating. Then click the Save button.

The spreadsheet uses these formula:

- Each reading in column A uses: \
= RAND() * ($C$2 - $B$2) + $B$2 \
which takes a random value and scales it to be between the min (B2) and the max (C2)
- Each start time in column B (except the first that is set with the initial value in B5) uses: \
= $B$5 +  (ROW() - 5) * $A$2 / (24 * 60) \
which takes the first start time and shifts it by the "reading time increment in minutes" value in A2 multiplied by how many readings down it is. Since the readings start in row 5, the value of the ROW() is shifted back by 5. It is divided by 24 * 60 since this is the number of minutes in a day.
- Each end time in column C uses (this is for row 5 so is B5 and would be B6 for row 6, etc.\
= B5 +  $A$2 / (24 * 60) \
which takes the start time of the same row and shifts it by the "reading time increment in minutes" value in A2 which is divided by minutes in the day (24 * 60).

### Generating expected result from OED

The file expected.ods can calculate the expected values. It currently does it for fixed reading time steps that evenly divide one hour (15 minute, 20 minutes, etc.). Note you have to set special formulas when the first/last readings are not aligned with the times returned by the DB. 

#### Line readings

Set the following to get the desired result:

- A2 should be the slope for the conversion from the meter unit to the graphing unit. It is given in the expected table above as "slope".
- B2 should be the intercept for the conversion from the meter unit to the graphing unit. It is normally 0 (temperature is an exception). It is given in the expected table above as "intercept".
- C2 should be the time in minutes between readings returned by the DB. It is given in the table above as "min/reading". The most common are 60 for hourly and 1440 for daily readings.
- D2 is true if the meter is a quantity (kWh, liters, C02, ...) and false if not, e.g., flow or raw (kW, Fahrenheit, ...). When you click on the cell you get a dropdown menu to choose one of these two choices.

After setting the values and creating the values in the three needed columns (A, B, C) you can create a CSV for testing usage by:

1) In "expected.ods", select the range A5:C108101 (see above on how to do that and note there may be many fewer rows in the spreadsheet) and then right click to choose "Clear Contents...".
2) Open the file with the input readings. Select the "Cell range" given in the input table (not the expected table) for row you are creating.
3) Copy the values selected.
4) Go back to the expected values spreadsheet, click in cell A5 and paste these values. (Note if you are copying directly from expected.ods - not common - then you will need to do a special paste.) These should now have the reading value and start/end time.
5) Enter the values for A2, B2, C2 and D2 from the expected table above for the test you want to create. These are, respectively, slope, intercept and min/reading. Note F2 will automatically be calculated and should be the number of rows of the readings in columns A-C per reading returned by the database.
6) Select the range indicated for "Cell range" for your test in the expected table (not the input table). Copy these values that should be the expected output from querying the DB for the line readings.
7) Open a new spreadsheet.
8) Do a special paste starting in cell A2 by either doing Edit -> Special Paste -> Special Paste ... or control/command-shift v. In the popup, click the Values Only button on the left because you don't want to get the formulas. Resizing the columns will likely make the values easier to see. This should now have the expected readings for the desired date/time range but see below if you are doing any partial readings at the start/end.
9) Go back to the readings spreadsheet and select A1:C1. Copy these values for the header.
10) Go back to the expected spreadsheet you are creating and paste starting in A1. You now have the header row for the CSV.
11) Do File -> Save or control/command s. In File type: select Text CSV (.csv) and enter a file name for the desired test in the expected table. Then click the Save button.

The spreadsheet uses these formula:

- "rows/reading from DB (calculated)" in F2 uses: \
= ROUND($C$2 / (($C$5 - $B$5) * 24 * 60), 0) \
This takes the difference in time for the first readings ($C$5 - $B$5) where it is assumed all readings are the same length, converts it from days to minutes ( * 24 * 60 since that is the number of minutes in a day) and divides this into "min/reading from DB" (C2). This gives per reading which is the number of rows each line reading will include. The ROUND makes it have no decimal part since it must be a whole number. This was needed because the calculation was not exact and led to small deviation from the desired value.
- Each reading in column E uses: \
= IF(($D$2), (SUM(INDIRECT("A" & ((ROW() - 5) * $F$2  + 5)):INDIRECT("A" & ((ROW() - 4) * $F$2  + 4)))  / ($C$2 / 60) * $A$2 + $B$2),(AVERAGE(INDIRECT("A" & ((ROW() - 5) * $F$2  + 5)):INDIRECT("A" & ((ROW() - 4) * $F$2  + 4))) * $A$2 + $B$2)) \
which does the following:
    - The IF changes the formula depending on whether the data is quantity or not.
    - INDIRECT("A" & ((ROW() - 5) * $F$2  + 5)) determines a cell. It it in column A where the row is the current row minus 5 since the values start in row 5. It is multiplied by "rows/reading from DB (calculated)" in F2 since that is how many rows each point will average from the input readings. For example, if the readings are every 15 minutes and F2 is 96, then you average 96 rows which is 96 * 15 min = 1440 min (24 hour or 1 day). It then shifts back by + 5 to get to the needed row.
    - INDIRECT("A" & ((ROW() - 4) * $F$2  + 4)) is very similar but shifts by 1 less so it goes one move block of readings down.
    - The two INDIRECT commands are put together with a : to give a cell range. The number of cells is the value in F2 because the shifts differ by 1.
    - If the data is quantity (true for D2) then you sum all the readings (which are quantities). These are divided by $C$2 / 60 because C2 is the "min/reading from DB" and dividing by 60 gives the hours/reading from the DB. You normalize by hours since OED returns a rate for line readings that is per hour. This value is multiplied by slope (A2) and added by the intercept (B2) to get it into the desired unit.
    - If the data is flow/raw (false for D2) then you average all the readings. Everything else is the same as the quantity case except there is no normalization by time. This is because OED returns the average value in this case and the readings were already a rate.
- Each start time in column E uses: \
= INDIRECT("B" & ((ROW() - 5) * $F$2)  + 5) \
This calculates the row in column B where the first meter reading that was included in line reading is and its start time is the one for the line point. The ((ROW() - 5) * $F$2)  + 5 is the same as first part of the range as described in the reading forumula above.
- Each end time in column F uses: \
= INDIRECT("C" & ((ROW() - 4) * $F$2)  + 4) \
which is very similar to the start time but finds the end time (in column C) of the last meter reading used so it is the end time of the line reading returned.

##### Partial readings

A \* in the expected table for the "Cell range" indicates that the first/last reading from the DB is calculated where some expected readings are not present. Usually this test is seeing if the range begins/ends during the day or hour. Use the two ranges in the description and sum them to get the needed values. Take the values in the comment and use them in a formula similar to this (in H2 in expected.ods) where this is an example: \
= SUM(A6821:A6873) / ( (C6873 - C6821) * 24) \
Note you can put the cells in the first sum the other way around but LibreOffice will invert after entering. You do this for each partial reading and then paste that value into the expected file you are creating for that time range. What this does is sum the readings for the times you want (excluding times outside the range asked for from the DB) and divide by the number of hours in that range.

#### Bar readings

Set the following to get the desired result:

- A2, B2, C2 & D2 are the same as described for line readings.
- I2 should be the number of days in each bar for the graphic values you want.

Note that J2, K2 & L2 should be automatically calculated and correct.

The readings values used are the same as the description for the line readings. Generally, they are the same as a line reading example and can be reused. Some formulas used assume the line reading span the same time as the bar so they need to be set.

The spreadsheet uses these formula. Since the DB returns bars starting with the most recent time, it has to work from the last reading backward.:

- "rows/bar from DB (calculated)" in J2 uses: \
= ROUND($I$2 / ($C$5 - $B$5), 0) \
This takes the difference in time for the first readings ($C$5 - $B$5), which is in days, where it is assumed all readings are the same length and divides this into "day/bar from DB" (I2). This gives the number of rows/readings each bar reading will include. The ROUND makes it have no decimal part since it must be a whole number. This was needed because the calculation was not exact and led to small deviation from the desired value.
- "Last row with reading in column A (calculated)" in K2 uses: \
= (MATCH(0, $F:$F, 0) - 5) * $F$2 + 4 \
The MATCH is searching column F to find the first row that has the value of 0. A 0 entry indicates it is not part of the line values/date range used. It subtracts 5 because the first row with readings is in row 5 and this was an offset so that is the number of items. By multiplying by F2 you get the number of items in the meter readings in column A. Adding back 4 compensates for starting in row 5 so this should be the last row with meter readings.
- "# full bars in graph or one less if all full (calculated)" in L2 uses: \
= IF(MOD((($K$2 - 4) / $J$2), 1) = 0, ($K$2 - 4) / $J$2 - 1, TRUNC(($K$2 - 4) / $J$2)) \
It is using the value from the match (K2) and subtracting 4 to remove the first 4 rows that don't have readings so this is the number of meter readings. It then divides by J2 which is the number of rows/bar so it gets the number of bars. The first bar is special so the value is truncated to not include that. The IF(MOD((($K$2 - 4) / $J$2), 1) = 0 checks if the result is exactly an integer (no decimal part). This is needed since it treats the first bar as special and it must be removed from the total when the readings exactly fit into the first bar.
- Each reading (except the first one) in column I uses: \
= IF(($D$2), (SUM(INDIRECT("A" & ($K$2 - (($L$2 - ROW() + 6) * $J$2) + 1)):INDIRECT("A" & ($K$2 - (($L$2 - ROW() + 5) * $J$2)))) * $A$2 + $B$2), (AVERAGE(INDIRECT("A" & ($K$2 - (($L$2 - ROW() + 6) * $J$2) + 1)):INDIRECT("A" & ($K$2 - (($L$2 - ROW() + 5) * $J$2)))) * $I$2 * 24 * $A$2 + $B$2)) \
Much of this formula is the same as the line reading case as described above. The differences are:
    - The row used is calculated by subtracting from K2 which is the last row with readings. The calculation is run backward because the DB starts with the latest date and goes backward. This means that all the bars but the first one (earliest in time) have a complete set of readings.
    - For quantity readings (D2 is true), you do not divide by the time because bars are a quantity and not a rate. For flow/raw readings (D2 false), you need to take the average and multiply by the time spanned in hours (I8 * 24) to get the quantity from the average (which is a rate). Note OED does not allow raw to be displayed in a bar graph.
- The first reading (I5) uses: \
= IF(($D$2), (SUM($A$5:INDIRECT("A" & ($K$2 - (($L$2 - ROW() + 5) * $J$2)))) * $A$2 + $B$2), (AVERAGE($A$5:INDIRECT("A" & ($K$2 - (($L$2 - ROW() + 5) * $J$2)))) * (($K$2 - 4) - ($J$2 * $L$2)) * ($C$5 - $B$5) * 24 * $A$2 + $B$2)) \
The changes from other readings are: \
    - The INDIRECT starts in A5 since this is the first row. If this was not done then it would go before this row if the bar does not have a full set of readings.
    - The INDIRECT ends at the a row that may not be the same number of rows as all the other bars since there may not be enough readings. ($L$2 - ROW() + 5) * $J$2 tells how many rows have already been used and this is subtracted from the first row (K2) to give the last row for the first bar.
    - In the case of flow, the AVERAGE must be multiplied by the actual time range for the bar. $C$5 - $B$5) * 24 gives the hours for each reading, ($K$2 - 4) - ($J$2 * $L$2) gives the number of rows in this bar so multiplying them gives the number of hours for this bar.
- Each start time in column J (except the first) uses: \
= INDIRECT("B" & ($K$2 - (($L$2 - ROW() + 6) * $J$2) + 1)) \
This calculates the row in column C where the first meter reading that was included in bar reading is and its start time is the one for the bar. The logic is similar to the calculation in each reading.
- The start time for the first bar (I5) uses:
= INDIRECT("C" & ($K$2 - (($L$2 - ROW() + 5) * $J$2))) - $I$2 \
This gets the end time of this reading and then subtracts the days for each bar. This brings it to the start time of this bar. Note that the DB returns equal date range bars even though there may not be data.
- Each end time in column K uses: \
= INDIRECT("C" & ($K$2 - (($L$2 - ROW() + 5) * $J$2))) \
which is very similar to the start time but finds the end time (in column C) of the last meter reading used so it is the end time of the bar reading returned. It works because it does + 5 instead of + 6 so it is one bars days earlier.
