# Documentation on how testing data is created and used

## Status of tests: **Important**

**As of 6 February 2025 all test cases are reserved or done. Tests are allocated by the OED project individually or to organizations. If you want to work on a test case then either put a comment in the issue or contact the project to see if we can assign you one. Tests cases that are done without assignment will not be accepted.**

## Creating a new test

- The section on "Generating test data" describes how the test data is generated. Normally the needed files are generate by someone else in the project and provided here.
- The section "Input values" describes the input meter data used. This is normally the same for all tests and involved 75 days of meter readings with a value every 15 minutes. Normally you do not need to know the details and can skip that section.
- The "Expected values" section has two subsections:
  - "Units" describes all the units used in tests. Each is labeled with u# where # identifies each unique unit. Each test specifies the units that are needed. Since the testing database is wiped before each test, the units needed must be loaded for each test. The regularly used unit of kWh (u1) and Electric_Utility (u2) are defined in src/server/util/readingsUtils.js as unitDatakWh. For any other values needed, the JSON object given can normally be included in the unitData used in the test where unitDatakWh.concat() is used if also including the standard kWh unit.
  - "Conversions" describes all the conversions used in tests. Each is labeled with c# where # identifies each unique conversion. Each test specifies the conversions that are needed. Since the testing database is wiped before each test, the conversions needed must be loaded for each test. The regularly used conversion (c1) of Electric_Utility → kWh is defined in src/server/util/readingsUtils.js as conversionDatakWh. For any other values needed, the JSON object given can normally be included in the conversionData used in the test where conversionDatakWh.concat() is used if also including the standard kWh unit.

 Generally you can find a similar test that is already done as an example of how the code should be structured. Directions for creating reading tests:

1) These tests are designed to be done by an early developer working on OED to get experience. As such, a single developer or team normally does 1-2 tests before moving on to other work. If you wish to do more than two test then you need to contact the project first. This guarantees that there are tests for lots of people.
2) If you want to do test "LXX" (where you replace "LXX" with the actual ID of the test you want to do), verify it is not marked done in the table below.
3) To pick a test do the followings:
    1. Look at the tables below for a test that is not yet marked in the "Done" column with "x", "R" or "A". There meaning is described below but that means someone else has done or is working on that test so it is **not** available.
    2. Go to [GitHub issue #962](https://github.com/OpenEnergyDashboard/OED/issues/962).  Check that there is not already a comment indicating the test is in progress. The document may not yet reflect it is active so it is important that you do this. If not, put in a comment such as: "I am working on test LXX". Others now know you are working on this test so you should have exclusive rights to create the test. Note the project reserves the right to remove the allocation of a test if a pull request is not created within one month of a comment allocating the test but you should not assume this - only the project can do this. One may edit the original comment to extend the time with a reason why. What follows is the steps to create the code.
4) There should be a comment in the indicated file of: \
// Add LXX here \
**Replace** this with the desired testing code. Note the comment would be LGXX for line group, BXX for bar meter, etc.
5) Define arrays of data for units, conversions and test meter(s)/group using testing csv. The tables below have the items needed for the code.
6) Load these arrays by invoking prepareTest(**defined data arrays**) function.
7) Create an array of values using the expected values csv by calling parseExpectedCsv on the file and assigning the return value. In general, you need to copy the file from the design document testing/readingsData/ directory to the src/server/test/web/readingsData/ directory since the expected files are not included in th eOED code until a test is written. If it is already there then you don't need to copy it again.
8) Write the test using expectReadingToEqualExpected to check the values and createTimeString.
9) As described in [running limited tests](https://openenergydashboard.org/developer/devDetails/#singleTest), one can run just the file being edited for the test. If you are using Visual Studio Code, you can get the file path/name by right clicking on the editor tab for the file and choosing "Copy Relative Path". Get the test to pass. If there are issue then check over the code but please contact the project if you think the expected file is wrong or the code being tested has an issue so we can verify what you have found.
10) Do the usual steps to create a pull request (see the developer help pages) to submit the work to OED. You can include multiple tests at once if desired..

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
| :---------------: | :---------: | :---------: | ----------------------------- | ------------------------------------------- | :----------: |
| 15                |  0          | 100         | readings_ri_15_days_75.csv    | 15 min readings; positive values; 75 days   | A5:C7204     |

## Expected values

### Units

| Name | Unit definition                                                                                                    |
| :--: | ------------------------------------------------------------------------------------------------------------------ |
| u1   | { name: 'kWh', identifier: '', unitRepresent: Unit.unitRepresentType.QUANTITY, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: true, note: 'OED created standard unit' } |
| u2   | { name: 'Electric_Utility', identifier: '', unitRepresent: Unit.unitRepresentType.QUANTITY, secInRate: 3600, typeOfUnit: Unit.unitType.METER, suffix: '', displayable: Unit.displayableType.NONE, preferredDisplay: false, note: 'special unit' } |
| u3   | { name: 'MJ', identifier: 'megaJoules', unitRepresent: Unit.unitRepresentType.QUANTITY, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: false, note: 'MJ' } |
| u4   | { name: 'kW', identifier: '', unitRepresent: Unit.unitRepresentType.FLOW, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: true, note: 'kilowatts' } |
| u5   | { name: 'Electric', identifier: '', unitRepresent: Unit.unitRepresentType.FLOW, secInRate: 3600, typeOfUnit: Unit.unitType.METER, suffix: '', displayable: Unit.displayableType.NONE, preferredDisplay: false, note: 'special unit' }
| u6   | { name: 'C', identifier: '', unitRepresent: Unit.unitRepresentType.RAW, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: true, note: 'Celsius' } |
| u7   | { name: 'Degrees', identifier: '', unitRepresent: Unit.unitRepresentType.RAW, secInRate: 3600, typeOfUnit: Unit.unitType.METER, suffix: '', displayable: Unit.displayableType.NONE, preferredDisplay: false, note: 'special unit' } |
| u8   | { name: 'F', identifier: '', unitRepresent: Unit.unitRepresentType.RAW, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: false, note: 'OED created standard unit' } |
| u9   | { name: 'Widget', identifier: '', unitRepresent: Unit.unitRepresentType.RAW, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: false, note: 'fake unit' } |
| u10  | { name: 'kg', identifier: '', unitRepresent: Unit.unitRepresentType.QUANTITY, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: false, note: 'OED created standard unit' } |
| u11  | { name: 'metric ton', identifier: '', unitRepresent: Unit.unitRepresentType.QUANTITY, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: false, note: 'OED created standard unit' } |
| u12  | { name: 'kg CO₂', identifier: '', unitRepresent: Unit.unitRepresentType.QUANTITY, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: 'CO₂', displayable: Unit.displayableType.ALL, preferredDisplay: false, note: 'special unit' } |
| u13  | { name: 'pound', identifier: 'lb', unitRepresent: Unit.unitRepresentType.QUANTITY, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: false, note: 'special unit' } |
| u14  | { name: 'Thing_36', identifier: '', unitRepresent: Unit.unitRepresentType.FLOW, secInRate: 36, typeOfUnit: Unit.unitType.METER, suffix: '', displayable: Unit.displayableType.NONE, preferredDisplay: false, note: 'special unit' } |
| u15  | { name: 'thing unit', identifier: '', unitRepresent: Unit.unitRepresentType.FLOW, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: false, note: 'special unit' } |
| u16  | { name: 'BTU', identifier: '', unitRepresent: Unit.unitRepresentType.QUANTITY, secInRate: 3600, typeOfUnit: Unit.unitType.UNIT, suffix: '', displayable: Unit.displayableType.ALL, preferredDisplay: true, note: 'OED created standard unit' } |

Note the last item for each unit, which is a description, is somewhat arbitrary and not used here. It was often from copying the unit from another usage.

### Conversions

| Name | Conversion definition                                              |
| :--: | ------------------------------------------------------------------ |
| c1   | { sourceName: 'Electric_Utility', destinationName: 'kWh', bidirectional: false, slope: 1, intercept: 0, note: 'Electric_Utility → kWh' } |
| c2   | { sourceName: 'kWh', destinationName: 'MJ', bidirectional: true, slope: 3.6, intercept: 0, note: 'kWh → MJ' } |
| c3   | { sourceName: 'MJ', destinationName: 'BTU', bidirectional: true, slope: 947.8, intercept: 0, note: 'MJ → BTU' } |
| c4   | { sourceName: 'Electric', destinationName: 'kW', bidirectional: false, slope: 1, intercept: 0, note: 'Electric → kW' } |
| c5   | { sourceName: 'Degrees', destinationName: 'C', bidirectional: false, slope: 1, intercept: 0, note: 'Degrees → C' } |
| c6   | { sourceName: 'MJ', destinationName: 'kWh', bidirectional: true, slope: 1 / 3.6, intercept: 0, note: 'MJ → KWh' } |
| c7   | { sourceName: 'C', destinationName: 'F', bidirectional: true, slope: 1.8, intercept: 32, note: 'Celsius → Fahrenheit' } |
| c8   | { sourceName: 'F', destinationName: 'C', bidirectional: true, slope: 1 / 1.8, intercept: -32 / 1.8, note: 'Fahrenheit → Celsius' } |
| c9   | { sourceName: 'F', destinationName: 'Widget', bidirectional: true, slope: 5, intercept: 3, note: 'Fahrenheit → Widget' } |
| c10  | { sourceName: 'Widget', destinationName: 'F', bidirectional: true, slope: 0.2, intercept: -0.6, note: 'Fahrenheit → Widget' } |
| c11  | { sourceName: 'Electric_Utility', destinationName: 'kg CO₂', bidirectional: false, slope: 0.709, intercept: 0, note: 'Electric_Utility → kg CO₂' } |
| c12  | { sourceName: 'kg CO₂', destinationName: 'kg', bidirectional: false, slope: 1, intercept: 0, note: 'CO₂ → kg' }, |
| c13  | { sourceName: 'kg', destinationName: 'metric ton', bidirectional: true, slope: 1e-3, intercept: 0, note: 'kg → Metric ton' } |
| C14  | { sourceName: 'pound', destinationName: 'metric ton', bidirectional: true, slope: 454.545454, intercept: 0, note: 'lbs → metric tons' } |
| C15  | { sourceName: 'Thing_36', destinationName: 'thing unit', bidirectional: false, slope: 1, intercept: 0, note: 'Thing_36 → thing unit' } |

Note some conversions should not be mixed such as c2 & c6 since they are inverses and testing different conversions. Also, round off may cause issues with some of these.

The following tables give information about the expected readings returned for a meter input with the indicated data. The values have the following meanings:

- "ID" is the identifier of this test for identification purposes.
- "Done" is marked with "x" if the test is implemented, "R" means it is reserved and "A" means it is actively being worked on in the test suite. None of these should be done by someone else. [GitHub issue #962](https://github.com/OpenEnergyDashboard/OED/issues/962) should have a comment on any tests being actively pursued that are yet to be marked in this document. Sometimes this document has "A" but it may not so checking the issue for open comments about the test of interest is **very** important.
- "Readings file" is the file used from the table above and determines the readings on the meter.
- "Meter unit" is the unit name used for the meter.
- "Graphic unit" is the unit name given to the DB for the readings requested.
- "Units/Conversions" are the units and conversions needed for this test and shown in the tables above.
- "slope" is the slope of the conversion from meter unit to graphic unit.
- "intercept" is the intercept of the conversion from meter unit to graphic unit. It is typically zero (temperature unit is an exception).
- "reading freq" is the time between readings for the meter data.
- "min/reading" is the minutes/reading that is returned by the database when the readings are requested. For example, if expect to get hourly readings then it is 60 and 1440 for daily readings.
- "Quantity" is true if this is a quantity unit. Placed in the "Quantity data?" in expected result.
- "Cell range" is the range of cells holding the first start time to the last end time stamp for the expected readings. It is used as described below.
- "Start time for readings" is the date/time for the beginning of the readings requested from the DB.
- "End time for readings" is the date/time for the ending of the readings requested from the DB.
- "Expected readings file name" is the file that can be used to compare to the readings from the DB. The name has these fields where all fields are separated by "_":

    1) The first field is what the file is. "expected" is the readings from a request to the DB. This will be followed by the type of readings (line, bar, compare, map). If it is for groups then there will be group and if it is for min/max range testing for line then there will be range.
    2) "ri" is the same as readings file.
    3) "mu" stands for the meter unit. It is followed by the unit name, e.g., mu_kWh.
    4) "gu" stands for the graphic unit. It is followed by the unit name, e.g., gu_BTU.
    5) "st" stands for start time. It is followed by the start time for the readings request from the DB where "inf" is short for infinity and "-inf" is negative infinity. It can also be a date/time such as "2022-09-22%13#00#00". Note what is normally a space becomes % and what is normally a : becomes a #. This is to avoid issues with various file systems.
    6) "et" is similar to "st" but the end time for the readings request.
    7) For bar readings there will be "bd" which stands for bar duration. It is followed by the number of days for the requested bar graphic. For example, bd_1, bd_7, etc.

- "Description" gives information on this row.

\* indicates one needs to fix up the first/last readings due to partial times. See below.

### Line reading tests

#### Quantity meter

These are located in the file src/server/test/web/readingsLineMeterQuantity.js.

| ID  | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | min/reading | Quantity | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :---------: | :------: | :-----------: |:---------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: |
| L1  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf.csv                                | should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh |
| L2  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 1440        | true     | E5:G79        | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_line_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv | should have daily points for 15 minute reading intervals and quantity units with explicit start/end time & kWh as kWh |
| L3  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 1440        | true     | E12:G72       | 2022-08-25 00:00:00     | 2022-10-25 00:00:00   | expected_line_ri_15_mu_kWh_gu_kWh_st_2022-08-25%00#00#00_et_2022-10-25%00#00#00.csv | should have daily points for middle readings of 15 minute for a 61 day period and quantity units with kWh as kWh |
| L4  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 60          | true     | E173:G1612    | 2022-08-25 00:00:00     | 2022-10-24 00:00:00   | expected_line_ri_15_mu_kWh_gu_kWh_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv | should have hourly points for middle readings of 15 minute for a 60 day period and quantity units with kWh as kWh |
| L5  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 60          | true     | E821:G1180    | 2022-09-21 00:00:00     | 2022-10-06 00:00:00   | expected_line_ri_15_mu_kWh_gu_kWh_st_2022-09-21%00#00#00_et_2022-10-06%00#00#00.csv | should barely have hourly points for middle readings of 15 minute for a 15 day + 15 min period and quantity units with kWh as kWh |
| L6  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 15          | true     | E3269:G4612   | 2022-09-21 00:00:00     | 2022-10-05 00:00:00   | expected_line_ri_15_mu_kWh_gu_kWh_st_2022-09-21%00#00#00_et_2022-10-05%00#00#00.csv | 14 days barely gives raw points & middle readings |
| L7  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 1440        | true     | E8:G75        | 2022-08-20 07:25:35     | 2022-10-28 13:18:28   | expected_line_ri_15_mu_kWh_gu_kWh_st_2022-08-20%07#25#35_et_2022-10-28%13#18#28.csv | partial days/hours for daily gives only full days |
| L10 | x    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | 15 minutes   | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kWh_gu_MJ_st_-inf_et_inf.csv                                 | should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ |
| L11 | x    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c6                         | 3.6        | 0         | 15 minutes   | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kWh_gu_MJ_st_-inf_et_inf.csv                                 | should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ reverse conversion |
| L12 | x    | readings_ri_15_days_75.csv | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c2, c3                | 3412.08    | 0         | 15 minutes   | 1440        | true     | E5:G79        | -infinity               | +infinity            | expected_line_ri_15_mu_kWh_gu_BTU_st_-inf_et_inf.csv                                | should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU chained |
| L13 | x    | readings_ri_15_days_75.csv | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c6, c3                | 3412.08    | 0         | 15 minutes   | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kWh_gu_BTU_st_-inf_et_inf.csv                                | should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU chained with reverse conversion |
| L18 | x    | readings_ri_15_days_75.csv | Electric_Utility | kg of CO₂         | u2, u10, u12, c11, c12                     | 0.709      | 0         | 15 minutes   | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kWh_gu_kgCO2_st_-inf_et_inf.csv                              | should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kg of CO2 |
| L19 | x    | readings_ri_15_days_75.csv | Electric_Utility | metric ton of CO₂ | u2, u10, u11, u12, c11, c12, c13           | 7.09e-4    | 0         | 15 minutes   | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kWh_gu_MTonCO2_st_-inf_et_inf.csv                              | should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as metric ton of CO2 & chained |
| L20 | x    | readings_ri_15_days_75.csv | Electric_Utility | pound of CO₂      | u2, u10, u11, u12, u13, c11, c12, c13, c14 | 1.5598e-6  | 0         | 15 minutes   | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kWh_gu_lbsCO2_st_-inf_et_inf.csv                              | should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as lbs of CO2 & chained & reversed |
| L21 | x    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | 15 minutes   | 60          | true     | E173:G1612    | 2022-08-25 00:00:00     | 2022-10-24 00:00:00   | expected_line_ri_15_mu_kWh_gu_MJ_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv                                 | should have hourly points for middle readings of 15 minute for a 60 day period and quantity units & kWh as MJ |
| L23 | x    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | 15 minutes   | 15          | false    | E3269:G4612  | 2022-09-21 00:00:00      | 2022-10-05 00:00:00   | expected_line_ri_15_mu_kWh_gu_MJ_st_2022-09-21%00#00#00_et_2022-10-05%00#00#00.csv                                 | should have raw points for middle readings of 15 minute for a 14 day period and quantity units & kWh as MJ |

#### Raw meter

These are located in the file src/server/test/web/readingsLineMeterRaw.js.

| ID  | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | min/reading | Quantity | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :---------: | :------: | :-----------: |:---------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: |
| L9  | x    | readings_ri_15_days_75.csv | Degrees          | C                 | u6, u7, c5                                 | 1          | 0         | 15 minutes   | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kW_gu_kW_st_-inf_et_inf.csv                                  | should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & Celsius as Celsius |
| L14 | x    | readings_ri_15_days_75.csv | Degrees          | F                 | u6, u7, u8, c5, c7                         | 1.8        | 32        | 15 minutes   | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_C_gu_F_st_-inf_et_inf.csv                                    | should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & C as F with intercept|
| L15 | x    | readings_ri_15_days_75.csv | Degrees          | F                 | u6, u7, u8, c5, c8                         | 1.8        | 32        | 15 minutes   | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_C_gu_F_st_-inf_et_inf.csv                                    | should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & C as F with intercept reverse conversion |
| L16 | x    | readings_ri_15_days_75.csv | Degrees          | Widget            | u6, u7, u8, u9, c5, c7, c9                 | 9          | 163       | 15 minutes   | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_C_gu_Widget_st_-inf_et_inf.csv                               | should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & C as Widget with intercept & chained |
| L17 | x    | readings_ri_15_days_75.csv | Degrees          | Widget            | u6, u7, u8, u9, c5, c8, c10                | 9          | 163       | 15 minutes   | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_C_gu_Widget_st_-inf_et_inf.csv                               | should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & C as Widget  with intercept & chained & reverse conversions |
| L22 | x    | readings_ri_15_days_75.csv | Degrees          | F                 | u6, u7, u8, c5, c7                         | 1.8        | 32        | 15 minutes   | 60          | false    | E173:G1612    | 2022-08-25 00:00:00     | 2022-10-24  00:00:00  | expected_line_ri_15_mu_C_gu_F_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv                                    | should have hourly points for middle readings of 15 minute for a 60 day period and raw units & C as F with intercept |
| L24 | x    | readings_ri_15_days_75.csv | Degrees          | F                 | u6, u7, u8, c5, c7                         | 1.8        | 32        | 15 minutes   | 15          | false    | E3269:G4612  | 2022-09-21 00:00:00      | 2022-10-05 00:00:00   | expected_line_ri_15_mu_C_gu_F_st_2022-09-21%00#00#00_et_2022-10-05%00#00#00.csv                                    | should have raw points for middle readings of 15 minute for a 14 day period and raw units & C as F with intercept |

#### flow meter

Flow and raw should act the same in the code. At some point we could add more test that are similar to raw but not now. If eliminate raw then need to add them here.

These are located in the file src/server/test/web/readingsLineMeterFlow.js.

| ID  | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | min/reading | Quantity | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :---------: | :------: | :-----------: |:---------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: |
| L8  | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | 15 minutes   | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_kW_gu_kW_st_-inf_et_inf.csv                                  | should have daily points for 15 minute reading intervals and flow units with +-inf start/end time & kW as kW |
| L25 | x    | readings_ri_15_days_75.csv |  Thing_36        | thing unit         | u14, u15, c15                             | 100        | 0         | 15 minutes   | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_ri_15_mu_Thing36_gu_thing_st_-inf_et_inf.csv                          | should have daily points for 15 minute reading intervals and flow units with +-inf start/end time & thing as thing where rate is 36 |
| L26 | R    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | 15 minutes   | 60          | false    | E173:G1612    | 2022-08-25 00:00:00          | 2022-10-24  00:00:00  | expected_line_ri_15_mu_kW_gu_kW_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv         | should have hourly points for middle readings for 15 minute for a 60 day period and flow units & kW as kW |
| L27 | R    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | 15 minutes   | 15          | false    | E3269:G4612   | 2022-09-21 00:00:00      | 2022-10-05 00:00:00  | expected_line_ri_15_mu_kW_gu_kW_st_2022-09-21%00#00#00_et_2022-10-05%00#00#00.csv         | should have raw points for middle readings for 15 minute for a 14 day period and flow units & kW as kW |

#### Quantity group

These are located in the file src/server/test/web/readingsLineGroupQuantity.js. These use standard meters and group found in code.

| ID   | Done | Group (meters)                                                         | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | min/reading | Quantity | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :---------: | :------: | :-----------: |:---------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: |
| LG1  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min  | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_kWh_gu_kWh_st_-inf_et_inf.csv                                | should have daily points for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh |
| LG2  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min  | 1440        | true     | E5:G79        | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_line_group_ri_15-20_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv | should have daily points for 15 + 20 minute reading intervals and quantity units with explicit start/end time & kWh as kWh |
| LG3  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min  | 1440        | true     | E12:G72       | 2022-08-25 00:00:00     | 2022-10-25 00:00:00   | expected_line_group_ri_15-20_mu_kWh_gu_kWh_st_2022-08-25%00#00#00_et_2022-10-25%00#00#00.csv | should have daily points for middle readings of 15 + 20 minute for a 61 day period and quantity units with kWh as kWh |
| LG4  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min  | 60          | true     | E173:G1612    | 2022-08-25 00:00:00     | 2022-10-24 00:00:00   | expected_line_group_ri_15-20_mu_kWh_gu_kWh_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv | should have hourly points for middle readings of 15 + 20 minute for a 60 day period and quantity units with kWh as kWh |
| LG5  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min  | 60          | true     | E821:G1180    | 2022-09-21 00:00:00     | 2022-10-06 00:00:00   | expected_line_group_ri_15-20_mu_kWh_gu_kWh_st_2022-09-21%00#00#00_et_2022-10-06%00#00#00.csv | should barely have hourly points for middle readings of 15 + 20 minute for a 15 day + 15 min period and quantity units with kWh as kWh |
| LG6  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min  | 60          | true     | E821:G1156    | 2022-09-21 00:00:00     | 2022-10-05 00:00:00   | expected_line_group_ri_15-20_mu_kWh_gu_kWh_st_2022-09-21%00#00#00_et_2022-10-05%00#00#00.csv | 14 days still gives hourly points & middle readings |
| LG7  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min  | 1440        | true     | E8:G75        | 2022-08-20 07:25:35     | 2022-10-28 13:18:28   | expected_line_group_ri_15-20_mu_kWh_gu_kWh_st_2022-08-20%07#25#35_et_2022-10-28%13#18#28.csv | partial days/hours for daily gives only full days |
| LG10 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | 15 & 20 min  | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_kWh_gu_MJ_st_-inf_et_inf.csv                                 | should have daily points for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ |
| LG11 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | MJ                | u1, u2, u3, c1, c6                         | 3.6        | 0         | 15 & 20 min  | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_kWh_gu_MJ_st_-inf_et_inf.csv                                 | should have daily points for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ reverse conversion |
| LG12 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c2, c3                | 3412.08    | 0         | 15 & 20 min  | 1440        | true     | E5:G79        | -infinity               | +infinity            | expected_line_group_ri_15-20_mu_kWh_gu_BTU_st_-inf_et_inf.csv                                | should have daily points for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU chained |
| LG13 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c6, c3                | 3412.08    | 0         | 15 & 20 min   | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_kWh_gu_BTU_st_-inf_et_inf.csv                                | should have daily points for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU chained with reverse conversion |
| LG18 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kg of CO₂         | u2, u10, u12, c11, c12                     | 0.709      | 0         | 15 & 20 min  | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_kWh_gu_kgCO2_st_-inf_et_inf.csv                              | should have daily points for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kg of CO2 |
| LG19 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | metric ton of CO₂ | u2, u10, u11, u12, c11, c12, c13           | 7.09e-4    | 0         | 15 & 20 min  | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_kWh_gu_MTonCO2_st_-inf_et_inf.csv                              | should have daily points for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as metric ton of CO2 & chained |
| LG20 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | pound of CO₂      | u2, u10, u11, u12, u13, c11, c12, c13, c14 | 1.5598e-6  | 0         | 15 & 20 min  | 1440        | true     | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_kWh_gu_lbsCO2_st_-inf_et_inf.csv                              | should have daily points for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as lbs of CO2 & chained & reversed |
| LG21 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | 15 & 20 min  | 60          | true     | E173:G1612    | 2022-08-25 00:00:00     | 2022-10-24 00:00:00   | expected_line_group_ri_15-20_mu_kWh_gu_MJ_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv                                 | should have hourly points for middle readings of 15 + 20 minute for a 60 day period and quantity units & kWh as MJ |

#### flow group

Flow and raw should act the same in the code. At some point we could add more test that are similar to raw but not now. If eliminate raw then need to add them here.

These are located in the file src/server/test/web/readingsLineGroupFlow.js.

| ID   | Done | Group (meters)                                                         | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | min/reading | Quantity | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :---------: | :------: | :-----------: |:---------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: |
| LG8  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | 15 & 20 min  | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_kW_gu_kW_st_-inf_et_inf.csv                                  | should have daily points for 15 + 20 minute reading intervals and flow units with +-inf start/end time & kW as kW |
| LG25 | x    | group thing (Thing_36 thing unit, Thing_36 Other)                      |  Thing_36        | thing unit        | u14, u15, c15                              | 100        | 0         | 15 & 20 min  | 1440        | false    | E5:G79        | -infinity               | +infinity             | expected_line_group_ri_15-20_mu_Thing36_gu_thing_st_-inf_et_inf.csv                          | should have daily points for 15 + 20 minute reading intervals and flow units with +-inf start/end time & thing as thing where rate is 36 |
| LG26 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | 15 & 20 min  | 60          | false    | E173:G1612    | 2022-08-25 00:00:00     | 2022-10-24  00:00:00  | expected_line_group_ri_15-20_mu_kW_gu_kW_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv   | should have hourly points for middle readings for 15 minute for a 60 day period and flow units with +-inf start/end time & kW as kW |

### Line range (min/max) tests

These test the min/max (range) for line readings. At the current time the reading & range are all returned for the line route. However, this may change in the future, esp. since OED now uses the Redux Toolkit. Given this, the range tests are done separately but they cover the same types of tests as line above.

There is no range on groups. Unlike line there are no raw points because there is no range (min = reading = max) in this case.

For range the Cell range is for the min/max without the date/time.

#### Quantity meter

These are located in the file src/server/test/web/readingsLineMeterRangeQuantity.js.

| ID   | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | min/reading | Quantity | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              |
| :--: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :---------: | :------: | :-----------: |:---------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: |
| LR1  | R    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 1440        | true     | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf.csv                                | range should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh |
| LR2  | R    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 1440        | true     | I5:J79        | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_line_range_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv | range should have daily points for 15 minute reading intervals and quantity units with explicit start/end time & kWh as kWh |
| LR3  | R    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 1440        | true     | I12:J72       | 2022-08-25 00:00:00     | 2022-10-25 00:00:00   | expected_line_range_ri_15_mu_kWh_gu_kWh_st_2022-08-25%00#00#00_et_2022-10-25%00#00#00.csv | range should have daily points for middle readings of 15 minute for a 61 day period and quantity units with kWh as kWh |
| LR4  | R    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 60          | true     | I173:J1612    | 2022-08-25 00:00:00     | 2022-10-24 00:00:00   | expected_line_range_ri_15_mu_kWh_gu_kWh_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv | range should have hourly points for middle readings of 15 minute for a 60 day period and quantity units with kWh as kWh |
| LR5  | R    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 60          | true     | I821:J1180    | 2022-09-21 00:00:00     | 2022-10-06 00:00:00   | expected_line_range_ri_15_mu_kWh_gu_kWh_st_2022-09-21%00#00#00_et_2022-10-06%00#00#00.csv | range should barely have hourly points for middle readings of 15 minute for a 15 day + 15 min period and quantity units with kWh as kWh |
| LR6  | R    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 15          | true     | I3269:J4612   | 2022-09-21 00:00:00     | 2022-10-05 00:00:00   | expected_line_range_ri_15_mu_kWh_gu_kWh_st_2022-09-21%00#00#00_et_2022-10-05%00#00#00.csv | range with 14 days barely gives raw points & middle readings |
| LR7  | R    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | 1440        | true     | I8:J75        | 2022-08-20 07:25:35     | 2022-10-28 13:18:28   | expected_line_range_ri_15_mu_kWh_gu_kWh_st_2022-08-20%07#25#35_et_2022-10-28%13#18#28.csv | range with partial days/hours for daily gives only full days |
| LR10 | R    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | 15 minutes   | 1440        | true     | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kWh_gu_MJ_st_-inf_et_inf.csv                                 | range should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ |
| LR11 | R    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c6                         | 3.6        | 0         | 15 minutes   | 1440        | true     | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kWh_gu_MJ_st_-inf_et_inf.csv                                 | range should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ reverse conversion |
| LR12 | R    | readings_ri_15_days_75.csv | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c2, c3                | 3412.08    | 0         | 15 minutes   | 1440        | true     | I5:J79        | -infinity               | +infinity            | expected_line_range_ri_15_mu_kWh_gu_BTU_st_-inf_et_inf.csv                                | range should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU chained |
| LR13 | R    | readings_ri_15_days_75.csv | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c6, c3                | 3412.08    | 0         | 15 minutes   | 1440        | true     | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kWh_gu_BTU_st_-inf_et_inf.csv                                | range should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU chained with reverse conversion |
| LR18 | R    | readings_ri_15_days_75.csv | Electric_Utility | kg of CO₂         | u2, u10, u12, c11, c12                     | 0.709      | 0         | 15 minutes   | 1440        | true     | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kWh_gu_kgCO2_st_-inf_et_inf.csv                              | range should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kg of CO2 |
| LR19 | R    | readings_ri_15_days_75.csv | Electric_Utility | metric ton of CO₂ | u2, u10, u11, u12, c11, c12, c13           | 7.09e-4    | 0         | 15 minutes   | 1440        | true     | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kWh_gu_MTonCO2_st_-inf_et_inf.csv                              | range should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as metric ton of CO2 & chained |
| LR20 | R    | readings_ri_15_days_75.csv | Electric_Utility | pound of CO₂      | u2, u10, u11, u12, u13, c11, c12, c13, c14 | 1.5598e-6  | 0         | 15 minutes   | 1440        | true     | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kWh_gu_lbsCO2_st_-inf_et_inf.csv                              | range should have daily points for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as lbs of CO2 & chained & reversed |
| LR21 | R    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | 15 minutes   | 60          | true     | I173:J1612    | 2022-08-25 00:00:00     | 2022-10-24 00:00:00   | expected_line_range_ri_15_mu_kWh_gu_MJ_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv                                 | range should have hourly points for middle readings of 15 minute for a 60 day period and quantity units & kWh as MJ |

#### Raw meter

These are located in the file src/server/test/web/readingsLineMeterRangeRaw.js.

| ID   | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | min/reading | Quantity | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              |
| :--: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :---------: | :------: | :-----------: |:---------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: |
| LR9  | R    | readings_ri_15_days_75.csv | Degrees          | C                 | u6, u7, c5                                 | 1          | 0         | 15 minutes   | 1440        | false    | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kW_gu_kW_st_-inf_et_inf.csv                                  | range should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & Celsius as Celsius |
| LR14 | R    | readings_ri_15_days_75.csv | Degrees          | F                 | u6, u7, u8, c5, c7                         | 1.8        | 32        | 15 minutes   | 1440        | false    | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_C_gu_F_st_-inf_et_inf.csv                                    | range should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & C as F with intercept|
| LR15 | R    | readings_ri_15_days_75.csv | Degrees          | F                 | u6, u7, u8, c5, c8                         | 1.8        | 32        | 15 minutes   | 1440        | false    | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_C_gu_F_st_-inf_et_inf.csv                                    | range should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & C as F with intercept reverse conversion |
| LR16 | R    | readings_ri_15_days_75.csv | Degrees          | Widget            | u6, u7, u8, u9, c5, c7, c9                 | 9          | 163       | 15 minutes   | 1440        | false    | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_C_gu_Widget_st_-inf_et_inf.csv                               | range should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & C as Widget with intercept & chained |
| LR17 | R    | readings_ri_15_days_75.csv | Degrees          | Widget            | u6, u7, u8, u9, c5, c8, c10                | 9          | 163       | 15 minutes   | 1440        | false    | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_C_gu_Widget_st_-inf_et_inf.csv                               | range should have daily points for 15 minute reading intervals and raw units with +-inf start/end time & C as Widget  with intercept & chained & reverse conversions |
| LR22 | R    | readings_ri_15_days_75.csv | Degrees          | F                 | u6, u7, u8, c5, c7                         | 1.8        | 32        | 15 minutes   | 60          | false    | I173:J1612    | 2022-08-25 00:00:00     | 2022-10-24  00:00:00  | expected_line_range_ri_15_mu_C_gu_F_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv                                    | range should have hourly points for middle readings of 15 minute for a 60 day period and raw units & C as F with intercept |

#### flow meter

Flow and raw should act the same in the code. At some point we could add more test that are similar to raw but not now. If eliminate raw then need to add them here.

These are located in the file src/server/test/web/readingsLineMeterRangeFlow.js.

| ID   | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | min/reading | Quantity | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              |
| :--: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :---------: | :------: | :-----------: |:---------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: |
| LR8  | R    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | 15 minutes   | 1440        | false    | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_kW_gu_kW_st_-inf_et_inf.csv                                  | range should have daily points for 15 minute reading intervals and flow units with +-inf start/end time & kW as kW |
| LR25 | R    | readings_ri_15_days_75.csv |  Thing_36        | thing unit         | u14, u15, c15                             | 100        | 0         | 15 minutes   | 1440        | false    | I5:J79        | -infinity               | +infinity             | expected_line_range_ri_15_mu_Thing36_gu_thing_st_-inf_et_inf.csv                          | range should have daily points for 15 minute reading intervals and flow units with +-inf start/end time & thing as thing where rate is 36 |
| LR26 | R    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | 15 minutes   | 60          | false    | I173:J1612    | 2022-08-25 00:00:00          | 2022-10-24  00:00:00  | expected_line_range_ri_15_mu_kW_gu_kW_st_2022-08-25%00#00#00_et_2022-10-24%00#00#00.csv         | range should have hourly points for middle readings for 15 minute for a 60 day period and flow units & kW as kW |

### Bar reading tests

The values in this table are similar to the ones for line readings except:

- There is no "min/reading" so this can be any reasonable value.
- "Bar width" gives the number of days for each bar in the requested graphic. Standard OED values are 1, 7 & 28 but any value from 1 to 365 is valid.
- You cannot graph raw units as a bar chart.

#### Quantity meter

These are located in the file src/server/test/web/readingsBarMeterQuantity.js.

| ID  | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | Quantity | Bar width | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                 | Notes         |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :------: | :-------: | :-----------: |:----------------------: | :-------------------: | :------------------------------------------------------------------------: | :-----------------------------------------: | :---: |
| B1  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| B2  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 7         | L6:N15        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf_bd_7.csv                                  | 7 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| B3  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 28        | L6:N7         | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf_bd_28.csv                                 | 28 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| B4  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 13        | L6:N10        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf_bd_13.csv                                 | 13 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| B5  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 75        | L5:N5         | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf_bd_75.csv                                 | 75 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| B6  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 76        | no values     | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_kWh_st_-inf_et_inf_bd_76.csv                                 | 76 day bars (no values) for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| B7  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 13        | L6:N10        | 2022-08-20 07:25:35     | 2022-10-28 13:18:28   | expected_bar_ri_15_mu_kWh_gu_kWh_st_2022-08-20%07#25#35_et_2022-10-28%13#18#28_bd_13.csv | 13 day bars for 15 minute reading intervals and quantity units with reduced, partial days & kWh as kWh | must overwrite cell N2 with 6820 and put back to original formula when done: = (MATCH(0, $F:$F, 0) - 5) * $F$2 + 4 |
| B8  | x    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_MJ_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ | |
| B9  | x    | readings_ri_15_days_75.csv | Electric_Utility | MJ                | u1, u2, u3, c1, c6                         | 3.6        | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_MJ_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ reverse conversion | |
| B10 | x    | readings_ri_15_days_75.csv | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c2, c3                | 3412.08    | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_BTU_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU | |
| B11 | x    | readings_ri_15_days_75.csv | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c6, c3                | 3412.08    | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_BTU_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU  reverse conversion| |
| B12 | x    | readings_ri_15_days_75.csv | Electric_Utility | kg of CO₂         | u2, u10, u12, c11, c12                     | 0.709      | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_kgCO2_st_-inf_et_inf_bd_1.csv                              | 1 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as kg of CO2 | |
| B13 | x    | readings_ri_15_days_75.csv | Electric_Utility | metric ton of CO₂ | u2, u10, u11, u12, c11, c12, c13           | 7.09e-4    | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_MTonCO2_st_-inf_et_inf_bd_1.csv                              | 1 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as metric ton of CO2 & chained | |
| B14 | x    | readings_ri_15_days_75.csv | Electric_Utility | pound of CO₂      | u2, u10, u11, u12, u13, c11, c12, c13, c14 | 1.5598e-6  | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_ri_15_mu_kWh_gu_lbsCO2_st_-inf_et_inf_bd_1.csv                              | 1 day bars for 15 minute reading intervals and quantity units with +-inf start/end time & kWh as lbs of CO2 & chained & reversed | |

#### flow meter

These are located in the file src/server/test/web/readingsBarMeterFlow.js.

| ID  | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | Quantity | Bar width | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              | Notes         |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :------: | :-------: | :-----------: |:----------------------: | :-------------------: | :---------------------------------------------------------------------------------: | :------------------------------------------------------: | :---: |
| B15 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 13        | L6:N10         | -infinity               | +infinity             | expected_bar_ri_15_mu_kW_gu_kW_st_-inf_et_inf_bd_13.csv                                   | 13 day bars for 15 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| B16 | x    | readings_ri_15_days_75.csv |  Thing_36        | thing unit         | u14, u15, c15                             | 100        | 0         | false    | 13        | L6:N10         | -infinity               | +infinity             | expected_bar_ri_15_mu_Thing36_gu_thing_st_-inf_et_inf_bd_13.csv                           | 13 day bars for 15 minute reading intervals and flow units with +-inf start/end time & thing as thing where rate is 36 | |
| B17 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 1         | L5:N79         | -infinity               | +infinity             | expected_bar_ri_15_mu_kW_gu_kW_st_-inf_et_inf_bd_1.csv                                   | 1 day bars for 15 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| B18 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 7         | L6:N15         | -infinity               | +infinity             | expected_bar_ri_15_mu_kW_gu_kW_st_-inf_et_inf_bd_7.csv                                   | 7 day bars for 15 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| B19 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 28        | L6:N7          | -infinity               | +infinity             | expected_bar_ri_15_mu_kW_gu_kW_st_-inf_et_inf_bd_28.csv                                  | 28 day bars for 15 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| B20 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 75        | L5:N5          | -infinity               | +infinity             | expected_bar_ri_15_mu_kW_gu_kW_st_-inf_et_inf_bd_75.csv                                  | 75 day bars for 15 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| B21 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 76        | no values      | -infinity               | +infinity             | expected_bar_ri_15_mu_kW_gu_kW_st_-inf_et_inf_bd_76.csv                                  | 76 day bars (no values) for 15 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| B22 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 13        | L6:N10        | 2022-08-20 07:25:35     | 2022-10-28 13:18:28   | expected_bar_ri_15_mu_kW_gu_kW_st_2022-08-20%07#25#35_et_2022-10-28%13#18#28_bd_13.csv | 13 day bars for 15 minute reading intervals and quantity units with reduced, partial days & kWh as kWh | must overwrite cell N2 with 6820 and put back to original formula when done: = (MATCH(0, $F:$F, 0) - 5) * $F$2 + 4 |

#### Quantity group

These are located in the file src/server/test/web/readingsBarGroupQuantity.js.

| ID   | Done | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | Quantity | Bar width | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                 | Notes         |
| :--: | :--: | :--------------------------------------------------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :------: | :-------: | :-----------: |:----------------------: | :-------------------: | :------------------------------------------------------------------------: | :-----------------------------------------: | :---: |
| BG1  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_kWh_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| BG2  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 7         | L5:N15        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_kWh_st_-inf_et_inf_bd_7.csv                                  | 7 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| BG3  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 28        | L6:N7         | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_kWh_st_-inf_et_inf_bd_28.csv                                 | 28 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| BG4  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 13        | L6:N10        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_kWh_st_-inf_et_inf_bd_13.csv                                 | 13 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| BG5  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 75        | L5:N5         | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_kWh_st_-inf_et_inf_bd_75.csv                                 | 75 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| BG6  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 76        | no values     | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_kWh_st_-inf_et_inf_bd_76.csv                                 | 76 day bars (no values) for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kWh | |
| BG7  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | 13        | L6:N10        | 2022-08-20 07:25:35     | 2022-10-28 13:18:28   | expected_bar_group_ri_15-20_mu_kWh_gu_kWh_st_2022-08-20%07#25#35_et_2022-10-28%13#18#28_bd_13.csv | 13 day bars for 15 + 20 minute reading intervals and quantity units with reduced, partial days & kWh as kWh | must overwrite cell N2 with 1708 and put back to original formula when done: = (MATCH(0, $F:$F, 0) - 5) * $F$2 + 4 |
| BG8  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | MJ                | u1, u2, u3, c1, c2                         | 3.6        | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_MJ_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ | |
| BG9  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | MJ                | u1, u2, u3, c1, c6                         | 3.6        | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_MJ_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as MJ reverse conversion | |
| BG10 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c2, c3                | 3412.08    | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_BTU_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU | |
| BG11 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | BTU               | u1, u2, u3, u16, c1, c6, c3                | 3412.08    | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_BTU_st_-inf_et_inf_bd_1.csv                                  | 1 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as BTU  reverse conversion| |
| BG12 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kg of CO₂         | u2, u10, u12, c11, c12                     | 0.709      | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_kgCO2_st_-inf_et_inf_bd_1.csv                              | 1 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as kg of CO2 | |
| BG13 | X    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | metric ton of CO₂ | u2, u10, u11, u12, c11, c12, c13           | 7.09e-4    | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_MTonCO2_st_-inf_et_inf_bd_1.csv                              | 1 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as metric ton of CO2 & chained | |
| BG14 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | pound of CO₂      | u2, u10, u11, u12, u13, c11, c12, c13, c14 | 1.5598e-6  | 0         | true     | 1         | L5:N79        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kWh_gu_lbsCO2_st_-inf_et_inf_bd_1.csv                              | 1 day bars for 15 + 20 minute reading intervals and quantity units with +-inf start/end time & kWh as lbs of CO2 & chained & reversed | |

#### flow group

These are located in the file src/server/test/web/readingsBarGroupFlow.js.

| ID   | Done | Group (meters)                                                         | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | Quantity | Bar width | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                         | Description                                              | Notes         |
| :--: | :--: | :--------------------------------------------------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :------: | :-------: | :-----------: | :---------------------: | :-------------------- | :---------------------------------------------------------------------------------: | :------------------------------------------------------: | :-----------: |
| BG15 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 13        | L6:N10       | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kW_gu_kW_st_-inf_et_inf_bd_13.csv                                  | 13 day bars for 15 + 20 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| BG16 | x    | group thing (Thing_36 thing unit, Thing_36 Other)                      |  Thing_36        | thing unit        | u14, u15, c15                              | 100        | 0         | false    | 13      | L6:N10        | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_Thing36_gu_thing_st_-inf_et_inf_bd_13.csv                          | 13 day bars for 15 + 20 minute reading intervals and flow units with +-inf start/end time & thing as thing where rate is 36 | |
| BG17 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 1         | L5:N79      | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kW_gu_kW_st_-inf_et_inf_bd_1.csv                                   | 1 day bars for 15 + 20 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| BG18 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 7         | L6:N15      | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kW_gu_kW_st_-inf_et_inf_bd_7.csv                                   | 7 day bars for 15 + 20 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| BG19 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 28        | L6:N7       | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kW_gu_kW_st_-inf_et_inf_bd_28.csv                                  | 28 day bars for 15 + 20 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| BG20 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 75        | L5:N5       | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kW_gu_kW_st_-inf_et_inf_bd_75.csv                                  | 75 day bars for 15 + 20 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| BG21 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 76        | no values   | -infinity               | +infinity             | expected_bar_group_ri_15-20_mu_kW_gu_kW_st_-inf_et_inf_bd_76.csv                                  | 76 day bars (no values) for 15 + 20 minute reading intervals and flow units with +-inf start/end time & kW as kW | |
| BG22 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | 13        | L6:N10      | 2022-08-20 07:25:35     | 2022-10-28 13:18:28     | expected_bar_group_ri_15-20_mu_kW_gu_kW_st_2022-08-20%07#25#35_et_2022-10-28%13#18#28_bd_13.csv                                  | 13 day bars (no values) for 15 + 20 minute reading intervals and flow units with reduced, partial days & kW as kW | must overwrite cell N2 with 1708 and put back to original formula when done: = (MATCH(0, $F:$F, 0) - 5) * $F$2 + 4 |

### Compare readings

The values in this table are similar to the ones for line readings except:

- There is no "min/reading" as this can be any reasonable value.
- There is no "Cell range" as only two values are checked in every case.
- The "Shift" is the number of days the previous start/end is before the current ones. Is in the format of P?D where ? is the number of days as this is the format used in the test code.
- The start and end time is for compare range of current.
- "curr use, prev use" gives the expected values. It is instead of "Expected readings file name".
- You cannot graph raw units as a compare chart.

**While care was taken in creating the following tables, it is difficult to verify the values before the tests are written. If you find that the test fails due to a mismatch in expected value then please contact us so we can double check the values.**

#### Quantity meter

These are located in the file src/server/test/web/readingsCompareMeterQuantity.js.

| ID  | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | Quantity | Shift | Start compare       | End compare         | curr use, prev use                      | Description                                                                                                                     | Notes         |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :------: | :---: | :-----------------: | :-----------------: | :-------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------: | :-----------: |
| C1  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 5666.35293886656, 5872.41914277899      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as kWh                             | |
| C2  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P7D   | 2022-10-30 00:00:00 | 2022-10-31 17:00:00 | 7962.23097109771, 8230.447588312        | 7 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as kWh                             | |
| C3  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P28D  | 2022-10-09 00:00:00 | 2022-10-31 17:00:00 | 108269.924822581, 108889.847659507      | 28 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as kWh                            | |
| C4  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-11-01 00:00:00 | 4290.60000224332, 4842.21261747704      | 1 day shift end 2022-11-01 00:00:00 (full day) for 15 minute reading intervals and quantity units & kWh as kWh                  | |
| C5  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P7D   | 2022-10-30 00:00:00 | 2022-11-01 15:00:00 | 9132.81261972035, 13147.7382388332      | 7 day shift end 2022-11-01 15:00:00 (beyond data) for 15 minute reading intervals and quantity units & kWh as kWh               | Put readings with zero until 2022-11-01 15:00:00 |
| C6  | x    | readings_ri_15_days_75.csv | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P28D  | 2022-10-09 00:00:00 | 2022-10-31 17:12:34 | 108269.924822581, 108889.847659507      | 28 day shift end 2022-10-31 17:12:34 (partial hour) for 15 minute reading intervals and quantity units & kWh as kWh             | Use end in spreadsheet of 2022-10-31 17:00:00 |
| C8  | x    | readings_ri_15_days_75.csv | Electric_Utility |  MJ               | u1, u2, u3, c1, c2                         | 3.6        | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 11232.0660730344, 12123.0051081528      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as MJ                              | |
| C9  | x    | readings_ri_15_days_75.csv | Electric_Utility |  MJ               | u1, u2, u3, c1, c6                         | 3.6        | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 11232.0660730344, 12123.0051081528      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as MJ reverse conversion           | |
| C10 | x    | readings_ri_15_days_75.csv | Electric_Utility |  BTU              | u1, u2, u3, u16, c1, c2, c3                | 3412.08    | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 10645752.224022, 11490184.2415072       | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as BTU                             | |
| C11 | x    | readings_ri_15_days_75.csv | Electric_Utility |  BTU              | u1, u2, u3, u16, c1, c6, c3                | 3412.08    | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 10645752.224022, 11490184.2415072       | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as BTU reverse conversion          | |
| C12 | x    | readings_ri_15_days_75.csv | Electric_Utility | kg of CO₂         | u2, u10, u12, c11, c12                     | 0.709      | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 2212.09301271706, 2387.55850602232      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as kg of CO2                       | |
| C13 | x    | readings_ri_15_days_75.csv | Electric_Utility | metric ton of CO₂ | u2, u10, u11, u12, c11, c12, c13           | 7.09e-4    | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 2.21209301271706, 2.38755850602232      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as metric ton of CO2 & chained     | |
| C14 | x    | readings_ri_15_days_75.csv | Electric_Utility | pound of CO₂      |  u2, u10, u11, u12, u13, c11, c12, c13, c14 | 1.5598e-6 | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 0.00486660462797753, 0.0052526287132491 | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as lbs of CO2 & chained & reversed | |

#### flow meter

These are located in the file src/server/test/web/readingsCompareMeterFlow.js.

| ID  | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | Quantity | Shift | Start compare       | End compare         | curr use, prev use                      | Description                                                                                                                     | Notes         |
| :-: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :------: | :---: | :-----------------: | :-----------------: | :-------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------: | :-----------: |
| C15 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P7D   | 2022-10-30 00:00:00 | 2022-10-31 17:00:00 | 1990.55774277443, 2057.611897078 | 7 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and flow units & kW as kW                               | curr: =SUM(A7013:A7176)/4, prev: =SUM(A6341:A6504)/4 |
| C16 | x    | readings_ri_15_days_75.csv |  Thing_36        | thing unit         | u14, u15, c15                             | 100        | 0         | false    | P7D   | 2022-10-30 00:00:00 | 2022-10-31 17:00:00 | 199055.77427744, 205761.1897078        | 7 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and flow units & thing as thing where rate is 36         | The slope is to take into account the sec. in rate for the graphing unit (3600 / 36) and not a unit conversion. |
| C17 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P1D   | 2022-10-30 00:00:00 | 2022-10-31 00:00:00 | 1210.55315436926, 1349.13987250313 | 1 full day shift for 15 minute reading intervals and flow units & kW as kW                               | curr: =SUM(A7013:A7108)/4, prev: =SUM(A6917:A7012)/4 |
| C18 | x    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P28D  | 2022-10-02 00:00:00 | 2022-10-28 00:00:00 | 30830.9420431404, 31064.5397007187 | 28 day shift for 26 days for 15 minute reading intervals and flow units & kW as kW                               | curr: =SUM(A4325:A6820)/4, prev: =SUM(A1637:A4132)/4 |
| C19 | A    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P7D   | 2022-10-30 00:00:00 | 2022-11-01 15:00:00 | 2283.20315493009, 3286.9345597083 | 7 day shift end 2022-11-01 15:00:00 (beyond data) for 15 minute reading intervals and quantity units & kWh as kWh                                 | curr: =SUM(A7013:A7204)/4, prev: =SUM(A6341:A6592)/4 |
| C20 | A    | readings_ri_15_days_75.csv | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P28D  | 2022-10-09 00:00:00 | 2022-10-31 17:12:34 | 27067.4812056454, 27222.4619148768 | 28 day shift end 2022-10-31 17:12:34 (partial hour) for 15 minute reading intervals and quantity units & kWh as kWh                           | curr: =SUM(A4997:A7176)/4, prev: =SUM(A2309:A4488)/4 |

#### Quantity group

These are located in the file src/server/test/web/readingsCompareGroupQuantity.js.

| ID  | Done | Group                                                                   | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | Quantity | Shift | Start compare       | End compare         | curr use, prev use                      | Description                                                                                                                     | Notes         |
| :-: | :--: | :---------------------------------------------------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :------: | :---: | :-----------------: | :-----------------: | :-------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------: | :------------: |
| CG1  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 5666.35293886656, 5872.41914277899      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as kWh                             | |
| CG2  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P7D   | 2022-10-30 00:00:00 | 2022-10-31 17:00:00 | 14017.4841100155, 14605.4957015091      | 7 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as kWh                             | |
| CG3  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P28D  | 2022-10-09 00:00:00 | 2022-10-31 17:00:00 | 189951.689612281, 190855.90449004  | 28 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as kWh                            | |
| CG4  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-11-01 00:00:00 | 7820.41927336775, 8351.13117114892      | 1 day shift end 2022-11-01 00:00:00 (full day) for 15 minute reading intervals and quantity units & kWh as kWh                  | |
| CG5  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P7D   | 2022-10-30 00:00:00 | 2022-11-01 15:00:00 | 16171.5504445167, 23010.8509932843 | 7 day shift end 2022-11-01 15:00:00 (beyond data) for 15 minute reading intervals and quantity units & kWh as kWh               | Put readings with zero until 2022-11-01 15:00:00 |
| CG6  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kWh               | u1, u2, c1                                 | 1          | 0         | true     | P28D  | 2022-10-09 00:00:00 | 2022-10-31 17:12:34 | 189951.689612281, 190855.90449004      | 28 day shift end 2022-10-31 17:12:34 (partial hour) for 15 minute reading intervals and quantity units & kWh as kWh             | Use end in spreadsheet of 2022-10-31 17:00:00 |
| CG8  | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility |  MJ               | u1, u2, u3, c1, c2                         | 3.6        | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 20398.8705799196, 21140.7089140044      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as MJ                              | |
| CG9  | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility |  MJ               | u1, u2, u3, c1, c6                         | 3.6        | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 20398.8705799196, 21140.7089140044      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as MJ reverse conversion           | |
| CG10 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility |  BTU              | u1, u2, u3, u16, c1, c2, c3                | 3412.08    | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 19334049.5356478, 20037163.9086933      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as BTU                             | |
| CG11 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility |  BTU              | u1, u2, u3, u16, c1, c6, c3                | 3412.08    | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 19334049.5356478, 20037163.9086933      | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as BTU reverse conversion          | |
| CG12 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | kg of CO₂         | u2, u10, u12, c11, c12                     | 0.709      | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 4017.44423365639, 4163.5451722303       | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as kg of CO2                       | |
| CG13 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | metric ton of CO₂ | u2, u10, u11, u12, c11, c12, c13           | 7.09e-4    | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 4.01744423365639, 4.1635451722303       | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as metric ton of CO2 & chained     | |
| CG14 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility | pound of CO₂      |  u2, u10, u11, u12, u13, c11, c12, c13, c14 | 1.5598e-6 | 0         | true     | P1D   | 2022-10-31 00:00:00 | 2022-10-31 17:00:00 | 0.00883837731404406, 0.00915979937890667 | 1 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and quantity units & kWh as lbs of CO2 & chained & reversed | |

#### flow group

These are located in the file src/server/test/web/readingsCompareGroupFlow.js.

| ID   | Done | Group                                                                  | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | Quantity | Shift | Start compare       | End compare         | curr use, prev use                      | Description                                                                                                                     | Notes         |
| :-: | :--: | :---------------------------------------------------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :------: | :---: | :-----------------: | :-----------------: | :-------------------------------------: | :-----------------------------------------------------------------------------------------------------------------------------: | :------------: |
| CG15 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P7D   | 2022-10-30 00:00:00 | 2022-10-31 17:00:00 | 4008.97545574702, 4182.62793481036      | 7 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and flow units & kW as kW                               | |
| CG16 | x    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) |  Thing_36        | thing unit         | u14, u15, c15                             | 100        | 0         | false    | P7D   | 2022-10-30 00:00:00 | 2022-10-31 17:00:00 | 400897.545574702, 418262.793481036      | 7 day shift end 2022-10-31 17:00:00 for 15 minute reading intervals and flow units & thing as thing where rate is 36         | The slope is to take into account the sec. in rate for the graphing unit (3600 / 36) and not a unit conversion. |
| CG17 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P1D   | 2022-10-30 00:00:00 | 2022-10-31 00:00:00 | 2380.19267225989, 2549.69370712913      | 1 full day shift for 15 minute reading intervals and flow units & kW as kW                                                    | curr: =SUM(A1757:A1780), prev: =SUM(A1733:A1756) |
| CG18 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P28D  | 2022-10-02 00:00:00 | 2022-10-28 00:00:00 | 62096.8746333032, 62332.3593184904      | 28 full day shift for 26 days for 15 minute reading intervals and flow units & kW as kW                                                   | curr: =SUM(A1085:A1708), prev: =SUM(A413:A1036) |
| CG19 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P7D   | 2022-10-30 00:00:00 | 2022-11-01 15:00:00 | 4629.44909652886, 6766.9039865054      | 7 day shift end 2022-11-01 15:00:00 (beyond data) for 15 minute reading intervals and flow units & kW as kW                                                    | curr: =SUM(A1757:A1804), prev: =SUM(A1589:A1629) |
| CG20 | R    | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric         | kW                | u4, u5, c4                                 | 1          | 0         | false    | P28D  | 2022-10-09 00:00:00 | 2022-10-31 17:12:34 | 54294.7361355451, 54544.4808583878      | 28 day shift end 2022-10-31 17:12:34 (partial hour) for 15 minute reading intervals and flow units & kW as kW                                                    | curr: =SUM(A1253:A1797), prev: =SUM(A581:A1125) |

### Map readings

Maps use the bar readings data. This data is then manipulated in the map component to get the last bar and normalize by day. Thus, this testing needs to be done in the UI when other graphic data is tested too. For the record, the following thoughts come up for this testing:

- How load map for test?
  - Might be best to take the developer test map for Happy Place directly from a live database and reload that were the image could be dummy if possible to reduce size.
- Map intervals:
  - 1 day, 7 days, 4 weeks
  - custom values: 13, 75, 75
- quantity and flow
- meter/group off of map
- meter & group

### Radar

Radar uses the line reading data from Redux state so does not need separate tests.

### 3D

The values in this table are similar to the ones for line readings except:

- "hours/point" gives the number of hours for each point in the day in the requested graphic. This is called hp in the file names. This times 60 is the min/reading from DB used to create the data.

#### Quantity meter

These are located in the file src/server/test/web/readingsThreeDMeterQuantity.js.

| ID   | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | Quantity | hours/point | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                                             | Description                                              |
| :--: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :------: | :---------: | :-----------: |:-----------------------: | :------------------: | :------------------------------------------------------------------------------: | :------------------------------------------------------: |
| 3D1  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | true     | 1            | E5:G1804      | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_1_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 1 hours/point, full time range and quantity units of kWh as kWh |
| 3D2  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | true     | 2            | E5:G904       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_2_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 2 hours/point, full time range and quantity units of kWh as kWh |
| 3D3  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | true     | 3            | E5:G604       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_3_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 3 hours/point, full time range and quantity units of kWh as kWh |
| 3D4  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | true     | 4            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_4_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 4 hours/point, full time range and quantity units of kWh as kWh |
| 3D5  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | true     | 6            | E5:G304       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_6_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 6 hours/point, full time range and quantity units of kWh as kWh |
| 3D6  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | true     | 8            | E5:G229       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_8_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 8 hours/point, full time range and quantity units of kWh as kWh |
| 3D7  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | true     | 12           | E5:G154       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_12_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv | 15 minute readings, 12 hours/point, full time range and quantity units of kWh as kWh |
| 3D8  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 minutes   | true     | 3            | E261:G292     | 2022-09-18 00:00:01     | 2022-09-23 23:59:59   | expected_3d_hp_3_ri_15_mu_kWh_gu_kWh_st_2022-09-19%00#00#00_et_2022-09-23%00#00#00.csv  | 15 minute readings, 3 hours/point, partial time range and quantity units of kWh as kWh|
| 3D9  | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               | u1, u3, u16, c1, c2, c3                    | 1          | 0         | 15 minutes   | true     | 4            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_4_ri_15_mu_kWh_gu_BTU_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 4 hours/point, full time range and quantity units of kWh as BTU |
| 3D10 | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               |  u1, u2, c1                                | 1          | 0         | 15 minutes   | true     | 3            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_4_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 4 hour readings, 3 hours/point returns 4, full time range and quantity units of kWh as kWh |
| 3D11 | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               |  u1, u2, c1                                | 1          | 0         | 12.5 hours   | true     | 12           | NA           | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_meterFrequencyTooLong.csv                                                   | 12.5 hour readings, 12 hours/point gives none, full time range and quantity units of kWh as kWh |
| 3D12 | x   | readings_ri_15_days_75.csv | Electric_Utility  | kWh               |  u1, u2, c1                                | 1          | 0         | 15 minutes   | true     | 8            | E5:G229 + null | 2022-08-03 00:00:00     | 2022-11-11 00:00:00   | expected_3d_hp_8_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00_holes.csv  | 15 minute readings, 8n hours/point with holes, extended time range and quantity units of kWh as kWh |

#### flow meter

These are located in the file src/server/test/web/readingsThreeDMeterFlow.js.

| ID   | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | Quantity | hours/point | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                                             | Description                                              |
| :--: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :------: | :---------: | :-----------: |:-----------------------: | :------------------: | :------------------------------------------------------------------------------: | :------------------------------------------------------: |
| 3D13 | x   | readings_ri_15_days_75.csv | Electric          | kW                | u4, u5, c4                                 | 1          | 0         | 15 minutes   | false    | 4            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_4_ri_15_mu_kW_gu_kW_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 4 hours/point, full time range and flow units of kW as kW |

#### raw meter

These are located in the file src/server/test/web/readingsThreeDMeterRaw.js.

| ID   | Done | Readings file              | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | Quantity | hours/point | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                                             | Description                                              |
| :--: | :--: | :------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :------: | :---------: | :-----------: |:-----------------------: | :------------------: | :------------------------------------------------------------------------------: | :------------------------------------------------------: |
| 3D14 | x   | readings_ri_15_days_75.csv | Degrees           | C                 | u6, u7, c5                                 | 1          | 0         | 15 minutes   | false    | 4            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_hp_4_ri_15_mu_kW_gu_kW_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 4 hours/point, full time range and raw units of Celsius as Celsius |

#### Quantity group

These are located in the file src/server/test/web/readingsThreeDGroupQuantity.js. These use standard meters and group found in code.

| ID    | Done | Group (meters)                                                        | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | Quantity | hours/point | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                                             | Description                                              |
| :--:  | :--: | :-------------------------------------------------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :------: | :---------: | :-----------: |:-----------------------: | :------------------: | :------------------------------------------------------------------------------: | :------------------------------------------------------: |
| 3DG1  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min | true     | 1            | E5:G1804      | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_1_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 + 20 readings, 1 hours/point, full time range and quantity units of kWh as kWh |
| 3DG2  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min | true     | 2            | E5:G904       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_2_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 + 20 readings, 2 hours/point, full time range and quantity units of kWh as kWh |
| 3DG3  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min | true     | 3            | E5:G604       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_3_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 + 20 readings, 3 hours/point, full time range and quantity units of kWh as kWh |
| 3DG4  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min | true     | 4            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_4_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 + 20 readings, 4 hours/point, full time range and quantity units of kWh as kWh |
| 3DG5  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min | true     | 6            | E5:G304       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_6_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 + 20 readings, 6 hours/point, full time range and quantity units of kWh as kWh |
| 3DG6  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min | true     | 8            | E5:G229       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_8_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 + 20 readings, 8 hours/point, full time range and quantity units of kWh as kWh |
| 3DG7  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min | true     | 12           | E5:G154       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_12_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv | 15 + 20 readings, 12 hours/point, full time range and quantity units of kWh as kWh |
| 3DG8  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u2, c1                                 | 1          | 0         | 15 & 20 min | true     | 3            | E261:G292     | 2022-09-18 00:00:01     | 2022-09-23 23:59:59   | expected_3d_group_hp_3_ri_15_mu_kWh_gu_kWh_st_2022-09-19%00#00#00_et_2022-09-23%00#00#00.csv  | 15 minute readings, 3 hours/point, partial time range and quantity units of kWh as kWh|
| 3DG9  | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               | u1, u3, u16, c1, c2, c3                    | 1          | 0         | 15 & 20 min | true     | 4            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_4_ri_15_mu_kWh_gu_BTU_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 minute readings, 4 hours/point, full time range and quantity units of kWh as BTU |
| 3DG10 | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               |  u1, u2, c1                                | 1          | 0         | 15 minutes   | true     | 3            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_4_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 4 & 6 hour readings, 3 hours/point returns 4, full time range and quantity units of kWh as kWh |
| 3DG11 | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               |  u1, u2, c1                                | 1          | 0         | 12.5 hours   | true     | 12           | NA           | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_groupFrequencyTooLong                                                             | 12.5 hour readings, 12 hours/point returns none, full time range and quantity units of kWh as kWh |
| 3DG12 | x   | groupDatakWh (meterDatakWhGroups with meterDatakWh, meterDatakWhOther) | Electric_Utility  | kWh               |  u1, u2, c1                                | 1          | 0         | 15 minutes   | true     | 8            | E5:G229 + null | 2022-08-03 00:00:00     | 2022-11-11 00:00:00   | expected_3d_hp_8_ri_15_mu_kWh_gu_kWh_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00_holes.csv  | 15 minute readings, 8 hours/point with holes, extended time range and quantity units of kWh as kWh |

#### Flow group

These are located in the file src/server/test/web/readingsThreeDGroupFlow.js.

| ID    | Done | Group (meters)                                                        | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | Quantity | hours/point | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                                             | Description                                              |
| :--:  | :--: | :-------------------------------------------------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :------: | :---------: | :-----------: |:-----------------------: | :------------------: | :------------------------------------------------------------------------------: | :------------------------------------------------------: |
| 3DG13 | x    | Electric both (Electric kW, Electric kW Other)                         | Electric          | kW                | u4, u5, c4                                 | 1          | 0         | 15 & 20 min | false    | 4            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_4_ri_15_mu_kW_gu_kW_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 + 20 readings, 4 hours/point, full time range and flow units of kW as kW |

#### Raw group

These are located in the file src/server/test/web/readingsThreeDGroupRaw.js.

| ID    | Done | Group (meters)                                                        | Meter unit       | Graphic unit      | Units/Conversions                          | slope      | intercept | reading freq | Quantity | hours/point | Cell range    | Start time for readings | End time for readings | Expected readings file name                                                                             | Description                                              |
| :--:  | :--: | :-------------------------------------------------------------------: | :--------------: | :---------------: | :----------------------------------------: | :--------: | :-------: | :----------: | :------: | :---------: | :-----------: |:-----------------------: | :------------------: | :------------------------------------------------------------------------------: | :------------------------------------------------------: |
| 3DG14 | x   | Temperature both (Temperature C, Temperature C Other)                  | Degrees           | C                 | u6, u7, c5                                 | 1          | 0         | 15 & 20 min | false    | 4            | E5:G454       | 2022-08-18 00:00:00     | 2022-11-01 00:00:00   | expected_3d_group_hp_4_ri_15_mu_kW_gu_kW_st_2022-08-18%00#00#00_et_2022-11-01%00#00#00.csv  | 15 + 20 readings, 4 hours/point, full time range and raw units of Celsius as Celsius |

## Generating test data

**Note that all that follows is designed for use by people creating new test cases. While anyone is welcome to look at this, those implementing the test cases that exist are not expected to need this information.**

### Selecting a range of values

You can copy the "Cell range" from the desired table and paste it into the top, left of LibreOffice Calc (Name Box) and then press the enter key on your keyboard.

### Generating readings

The readings.ods was used to generate the test data. If you are not creating new reading test data then they should already be there. readings.ods can generate random readings data. It is a LibreOffice file spreadsheet file with formulas. You get get the meter data by setting the following cells:

- B5 is the first date/time for a reading. It is normally in YYYY-MM-DD HH-MM-SS format where HH is in 24 hour time.
- A2 sets the minutes between readings.
- B2 is the minimum value for a reading.
- C2  is the maximum value for a reading.

No other cells should be edited. Note the readings change whenever you reopen the spreadsheet or touch cells in the sheet. To keep the same value they are copied to another CSV file as only values (see next).

There are two files that are used for meter data. Both has B5 as 2022-08-18 00:00:00.

- The first is the standard one with the readings in readings_ri_15_days_75.csv
  - A2 is 15
  - B2 is 1
  - C2 is 100
  - The cell range to select is B5:C7204
- The second meter is used for groups and deliberately has a different frequency to test combining groups with different values. It also has a different range of values. Note the meters do align on each day so there are no missing/partial reading for the dates selected. The readings are in readings_ri_20_days_75.csv.
  - A2 is 20
  - B2 is 27
  - C2 is 73
  - The cell range to select is B5:C5404

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
  - INDIRECT("A" & ((ROW() - 5) * $F$2  + 5)) determines a cell. It it in column A where the row is the current row minus 5 since the values start in row 5. It is multiplied by "rows/reading from DB (calculated)" in F2 since that is how many rows each point will average from the input readings. For example, if the readings are every 15 minutes and F2 is 96, then you average 96 rows which is 96 \* 15 min = 1440 min (24 hour or 1 day). It then shifts back by + 5 to get to the needed row.
  - INDIRECT("A" & ((ROW() - 4) * $F$2  + 4)) is very similar but shifts by 1 less so it goes one move block of readings down.
  - The two INDIRECT commands are put together with a : to give a cell range. The number of cells is the value in F2 because the shifts differ by 1.
  - If the data is quantity (true for D2) then you sum all the readings (which are quantities). These are divided by $C$2 / 60 because C2 is the "min/reading from DB" and dividing by 60 gives the hours/reading from the DB. You normalize by hours since OED returns a rate for line readings that is per hour. This value is multiplied by slope (A2) and added by the intercept (B2) to get it into the desired unit.
  - If the data is flow/raw (false for D2) then you average all the readings. Everything else is the same as the quantity case except there is no normalization by time. This is because OED returns the average value in this case and the readings were already a rate.
- Each start time in column E uses: \
= INDIRECT("B" & ((ROW() - 5) * $F$2)  + 5) \
This calculates the row in column B where the first meter reading that was included in line reading is and its start time is the one for the line point. The ((ROW() - 5) * $F$2)  + 5 is the same as first part of the range as described in the reading formula above.
- Each end time in column F uses: \
= INDIRECT("C" & ((ROW() - 4) * $F$2)  + 4) \
which is very similar to the start time but finds the end time (in column C) of the last meter reading used so it is the end time of the line reading returned.

##### Partial readings

A \* in the expected table for the "Cell range" indicates that the first/last reading from the DB is calculated where some expected readings are not present. Usually this test is seeing if the range begins/ends during the day or hour. Use the two ranges in the description and sum them to get the needed values. Take the values in the comment and use them in a formula similar to this (in H2 in expected.ods) where this is an example: \
= SUM(A6821:A6873) / ( (C6873 - C6821) * 24) \
Note you can put the cells in the first sum the other way around but LibreOffice will invert after entering. You do this for each partial reading and then paste that value into the expected file you are creating for that time range. What this does is sum the readings for the times you want (excluding times outside the range asked for from the DB) and divide by the number of hours in that range.

#### Bar readings

Set the following to get the desired result:

- A2, B2, C2 & D2 are the same as described for line readings. The value of C2 should be set but should not change the bar result.
- I2 should be the number of days in each bar for the graphic values you want. This is the value in column "Bar width" in the table above.

Note that J2, K2 & L2 should be automatically calculated and correct.

The readings values used are the same as the description for the line readings. Generally, they are the same as a line reading example and can be reused. Some formulas used assume the line reading span the same time as the bar so they need to be set. The cell range will be in columns I to K for bar readings.

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
The changes from other readings are:
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

#### Compare readings

Compare readings have many similarities to bar readings but are different. Set the following to get the desired result:

- A2, B2, C2 & D2 are the same as described for line readings. The value of C2 should be set but should not change the compare result.
- Q2 should be the start date/time of the current compare range. It is normally Sunday at 00:00:00, e.g., the start of the week.
- R2 is similar to Q2 but the end date/time. This can be at any hour in the day for when the compare was requested.
- S2 should be the shift in days for the compare. This is the value in column "Days in compare" in the table above but only the value so P7D is 7.

Note that T2, U2 & V2 should be automatically calculated and correct.

The readings values used are the same as the description for the line readings. Generally, they are the same as a line reading example and can be reused.

Compare only has two return values that are in Q5 and R5.

The spreadsheet uses these formula.:

- "rows shift for compare (calculated)" in T2 uses: \
= ROUND($S$2 / ($C$5 - $B$5), 0) \
This divides the days of compare shift by the time of each reading and rounds to a whole number to make it an integer. This is the number of rows of readings for the compare shift.
- "Start row reading for curr_use (calculated)" in U2 uses: \
= MATCH($Q$2,$B$5:INDIRECT("B"&$N$2),0) + 4 \
This finds the row with the start date/time (Q2) by searching from B5 to the last row with readings (N2). The + 4 is because MATCH returns a value relative to the search range so must add 4 to get the absolute row in the sheet.
- "End row reading for curr_use (calculated)" in V2 is similar to U2 but for the end date/time (R2). It searches column C because it is the end. The formula is: \
= MATCH($R$2,$C$5:INDIRECT("C"&$N$2),0) + 4 \
- curr_use in Q5 uses: \
=  IF($D$2, (SUM(INDIRECT("A" & $U$2):INDIRECT("A" & $V$2)) * $A$2 + $B$2) / $E$2, (AVERAGE(INDIRECT("A" & $U$2):INDIRECT("A" & $V$2)) \* ROUND(($R$2 - $Q$2) \* 24) \* $A$2 + $B$2) / $E$2) \
It uses the IF similarly to line on whether quantity readings or not. \
INDIRECT("A" & $U$2):INDIRECT("A" & $V$2) \
is the range of values for the readings to be compared for the current time. The SUM or AVERAGE is for quantity or not data to get the final result. \
- \* ROUND(($R$2 - $Q$2) * 24) \
Computes the number of hours in the compare range to convert the rate to a quantity. Finally, \
- \* $A$2 + $B$2) / $E$2 \
applies the slope/intercept (A2/B2) and normalizes for area (E2).
- prev_use in R5 is vary similar to curr_use but each row in the range is shifted by the rows shift for compare (T2) so it is the previous range. The formula is: \
=  IF($D$2, (SUM(INDIRECT("A" & ($U$2 - $T$2)):INDIRECT("A" & ($V$2 - $T$2))) \* $A$2 + $B$2) / $E$2, (AVERAGE(INDIRECT("A" & ($U$2 - $T$2)):INDIRECT("A" & ($V$2 - $T$2))) * $A$2 + $B$2) / $E$2)

#### 3D readings

3D is a special case of line readings. As such, it is very similar to line readings with an added parameter "hours/point" which gives the number of hours for each point in the day in the requested graphic. This is called hp in the file names. This times 60 is the min/reading from DB used to create the data. As such, C2 is set to hp * 60 to generate the expected values in a similar way to line data.

#### Group data

Since groups combine the data from meters, the expected value is a combination (addition) of multiple meters. To make testing simpler, only two meters are placed in a group used for testing. The meters used are:

- The first meter is the standard one with readings in readings_ri_15_days_75.csv.
- The second meter is the other meter with readings are in readings_ri_20_days_75.csv.

The group readings are created as follows:

- The spreadsheet readings_group.ods is used.
- A2 is set to the reading increment for the first meter (15).
- E2 is set to the reading increment for the second meter (20).
- The readings for the first meter are pasted starting in A5. This is done as values when pasted.
- The readings for the second meter are pasted starting in E5. This is done as values when pasted.
- I2 is true if the groups are quantity data and false if not (flow or raw). **Note it is important to redo for the two types of data or the expected result will be wrong. This means recopying the data for the steps below whenever changed.**
- The values in I5:K1804 have the hourly readings for the group. Note you cannot do raw readings for groups so hourly allows doing both hourly and daily result points. This is 75 days * 24 points/day = 1800 points.
- The values for the hourly group readings are copied starting in A5 in spreadsheet expected_group.ods. This is done as values when pasted. This is similar to expected.ods but has the group data.

## TODO

- missing readings: probably need to do calculation by hand
- readings where length is not divisible into hour/day
