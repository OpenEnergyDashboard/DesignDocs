# Documentation on how testing data is created

The directory readingsData/ has all the files used.

## Line Readings

### Input values

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

### Expected values

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

### Generating expected result from OED

The file expected.ods can calculate the expected values. It currently does it for fixed reading time steps that evenly divide one hour (15 minute, 20 minutes, etc.). Note you have to set special formulas when the first/last readings are not aligned with the times returned by the DB. Set the following to get the desired result:

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

### Partial readings

A \* in the expected table for the "Cell range" indicates that the first/last reading from the DB is calculated where some expected readings are not present. Usually this test is seeing if the range begins/ends during the day or hour. Use the two ranges in the description and sum them to get the needed values. Take the values in the comment and use them in a formula similar to this (in I5 in expected.ods) where this is an example: \
= SUM(A6821:A6873) / ( (C6873 - C6821) * 24) \
Note you can put the cells in the first sum the other way around but LibreOffice will invert after entering. You do this for each partial reading and then paste that value into the expected file you are creating for that time range. What this does is sum the readings for the times you want (excluding times outside the range asked for from the DB) and divide by the number of hours in that range.
