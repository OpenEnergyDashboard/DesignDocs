# Documentation on how testing data is created

The directory readingsData/ has all the files used.

## Readings

The following table gives the test readings created so far. Note the last date is the cell you can go to for selecting the data. 

| Reading Increment | Min Reading | Max Reading | File name                     | Description                                 | Last Cell |
| :---------------: | :---------: | :---------: | :----------------------------:| :-----------------------------------------: | :-------: |
| 15                |  0          | 100         | readings_ri_15_days_75.csv    | 15 min readings; positive values; 75 days   | C7204     |

The following table gives the file with the expected readings returned for a meter input with the indicated data.

| Input file        | Meter unit  | Graphic unit | Start date for readings | End date for readings | Expected readings file name              | Description                                 |
| :---------------: | :---------: | :----------: | :---------------------: | :-------------------: | :--------------------------------------: | :-----------------------------------------: |
| 15                |  0          | 100          | -infinity               | +infinity             | expected_ri_15_unit_kWh_st_-inf_et_inf.csv     | | gives daily points                        |

## Generating readings

The readings.ods was used to generate the test data. If you are not creating new reading test data then they should already be there. readings.ods can generate random readings data. It is a LibreOffice file spreadsheet file with formulas. You get get the meter data by setting the following cells:

- B5 is the first date/time for a reading. It is normally in YYYY-MM-DD HH-MM-SS format where HH is in 24 hour time.
- A2 sets the minutes between readings.
- B2 is the minimum value for a reading.
- C2  is the maximum value for a reading.

No other cells should be edited. Note the readings change whenever you reopen the spreadsheet or touch cells in the sheet. To keep the same value they are copied to another CSV file as only values (see next).

After setting the values and creating the values in the three needed columns (A, B, C) you can create a CSV for testing usage by:

1) Selecting the entire columns of A-C or any set of rows that have the dates desired. If you only take a subset of the rows then make sure the separately copy to first header row of columns A-C.

    - An easy way to select all the desired values for copy/paste is to enter the location of the last cell in the table below in the top, left of LibreOffice Calc (Name Box), hit enter, and then go to the top of the sheet and shift-click in A4 to select them all for copy.

2) Copy the values selected.
3) Open a new spreadsheet.
4) If you are copying all the rows or the header row then click in cell A1. If you have already put in the header row and are now copying the rows with meter data then click in cell A2.
5) Do a special paste by either doing Edit -> Special Paste -> Special Paste ... or control/command-shift-v. In the popup, click the Values Only button on the left because you don't want to get the formulas.
6) Select all of columns B & C. Then do Format -> Cells ... or control/command 1. In Category select date and then in Format select  1999-12-31 13:37:46. This formats the columns as dates in the canonical format. You may need to make the columns wider to see the values (esp. if you see ### instead of date/time).
7) Do File -> Save As ... or control/command-shift S. In File type: select Text CSV (.csv) and enter a file name at the top. Then click the Save button.

## Generating expected result from OED

The file expected.ods can calculate the expected values. It currently does it for fixed reading time steps that evenly divide one hour (15 minute, 20 minutes, etc.). Set the following to get the desired result:

- A2 should be the slope for the conversion from the meter unit to the graphing unit.
- B2 should be the intercept for the conversion from the meter unit to the graphing unit. It is normally 0 (temperature is an exception).

After setting the values and creating the values in the three needed columns (A, B, C) you can create a CSV for testing usage by:

0) Go to cell C108101 (see above on how to do that), select it, go to cell A5 at the top and shift-click to select the range of cells. Right click and choose to clear the contents. It is likely many of these cells are already empty but this is the safe way.
1) Open the file with the input readings. Select all of columns A-C.
2) Copy the values selected.
3) Go back to the expected values spreadsheet, click in cell A5 and paste these values. These should now have the expected values. You need to select the desired column based on the known frequency of readings and the frequency of data that you are going to ask OED to return.
4) Go to the end time for the last reading and select it. This should be the similar as the "Last Cell" in the table describing the readings that were input. Go to cell B4, shift-click it to select all start and end times for all the readings.
3) Open a new spreadsheet.
x) Paste the values you copied starting at cell B1. Resizing the columns will likely make the values easier to see.
x) Go back to the the expected file and select the column with the reading values you want to test. The row number is the same as before but the column name is which one you want. When you select the first row it should be 4 as you did for the timestamps. Copy the readings.
x) Go to the new spreadsheet and paste these values starting in A1 as **values only**. You should now have the readings, start time, end time as three columns.
7) Do File -> Save As ... or control/command-shift S. In File type: select Text CSV (.csv) and enter a file name at the top. Then click the Save button.
