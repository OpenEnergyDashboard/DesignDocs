# Automated test data

## Overview

PR #505 will add automated test data to OED. (see src/server/data/generateTestData.ts or .js?) for generation code and src/server/test/generateTestDataTests.js for its automated testing) At this time it can generate sine and cosine wave data where you can control the amplitude, frequency/rate of points on the curve and timeframe for points. It can write the data to a CSV file for import into OED. Also note the data is now floating point so will no longer be integral. Now that we have this ability, it needs to be more fully integrated into OED. This will partly address issue #141. There are two areas where data is desired: 1) for import into OED for developer and design testing; 2) for automated testing.

## Data for developers to import

Each meter test data generation needs to specify now many cycles of sine it goes through (all will be sine except for the one testing group where one is cosine). I’m not sure the best value but let’s see if having 5-10 cycles (2 Pi per cycle) looks okay. One consistent value can be picked. I also propose the data starts on Jan 1, 2020. I hope this will allow us to do comparison graphs for a while if it has future dates (but this needs to be checked). I would do one at a time and even test 1 case of each before trying more.

The following data would be valuable for importing into OED

1. Data with different frequencies of points. Up until now we have done hourly data. We should try: 1 minute, 15 minute, 23 minute, 4 hour and 4 day. 1 minute is probably as fast as we would ever get. The 15 minute is the fast side of what systems really do. 23 minute is to test when the frequency is not an integral fraction of 1 hour. The 4 hour and 4 day are for testing of longer-term readings that might happen, esp. if manually collected. If we generated 1 year of data we would have 526k, 35k, 22.8k, 2k, 0.09k points, respectively. Rough testing indicates that each point will be about 61 bytes so the file sizes will be 32MB, 2.1MB, 1.4MB, 0.13MB, … These files sizes seem manageable but note this is per meter. For now, we will generate for one meter with an amplitude of 3 for each frequency.
    1. Once we have this data we need to test if fast-pt graphs correctly. This requires figuring out the expected value and knowing this will help with this test in the proposed automated tests. Steve can help with this.
2. We should have multiple meters for developers to use. The exact number is unclear but starting with 7 meters seems okay. To remove the bias toward 1 hour data, we will generate every 15 minutes for 2 years. To be systematic, set the amplitude to be 1-7 (one value for each meter). The total size of all 7 files should be about 29.9MB. 
3. Testing groups and fast-pt. We should have 2 meters for 2 years where one meter is sine<sup>2</sup> at a frequency of 15 minutes with an amplitude of 2 and one is cosine<sup>2</sup> at a frequency of 23 minutes with an amplitude of 3 (the amplitude is before the square of what is given to the test code). The developer can then create a group to combine these where the result should be a flat line since sine<sup>2</sup> + cosine<sup>2</sup> = 1. Since the amplitudes were 2 and 3 before squaring, you will get 4 + 9 = 13 as the value.
4. We have always wanted OED to respond to requests in less than 1 second even if you have lots of meters for long times ranges. Since the readings are currently aggregated into hourly readings in advance (fast-pt), doing less than 1 hour should not change the speed and would create more data. We should have 100 meters with 20 years of data. The amplitudes would be 1, 2, … 100 for the meters. The total size for all 100 files is 1.1GB so this will be moderately large (as expected).

## Automated testing

Most of the current tests of readings, groups, etc. load a few points that were set in some way by the person who wrote the test. It would be better to do more points that have a range of values. The test code will allow us to do that and know the expected value at each reading so it can be tested. It might be helpful to look at the test code generation tests to see how it checked a large number of values to have something to start from. We should make these new tests for now (can be in the same file as current tests) and then consider removing the others in the future (good comments will help with this). Many of the current tests will stay since they are unique/different from what is proposed. We should start with the first two and then try the others after they work, esp. given they will take some thinking/planning.

The tests are in many places in src/server/test/ but here are the ones found so far:

1. db/readingTests.js. New test to load in a fair number of points for one meter and verify get values back. It could be for less time.
2. db/groupTests.js. Do more limited time/points for the test for developers described above where you create two meters, create a group and verify a constant value. I’m not sure we have any current test that groups aggregate correctly.
3. db/compressedReadingsTests.js (unsure how relates to db/newCompressedReadingsTests.js and which is the correct one to use). Maybe test the 15 minute, 23 minute, 4 hour and 4 day data (with fewer points) to see you get the expected result. One thing that needs to be worked out is the value you will get when compressed to 1 day. Need to refresh after add to get compression.
4. db/barchartReadingsTests.js, db/compareTests.js. We need to come up with ideas on how to test bar and compare values (and maps in the future).

## Implementation

1. The file names for the CSVs should be chosen so they describe what they are. There should be no space to make it easier for use in scripts. Note each meter must be in its own file for uploading with the CSV system. It seems desirable that each test type goes into its own directory.
2. We should have a script that can generate the test data. To allow flexible usage by the script and others, add a new entry in the scripts section of package.json that runs the test generation code. It will need to be able to pass parameters for frequency, amplitude, start/end date, output file name (others?). I’m not sure how that is done and if we need another script and/or code to do this.
3. We should have a script to load each type of test data into a developer’s system. The upcoming CSV load via an HTTP request should make this fairly easy. Davin can give the needed curl command for doing this if it is not yet documented.

## Standard images of graphs

Once this is all working, it would be nice to have screen shots of each one graphed as a line and bar graph so developers would know how they are expected to look. This would also serve as a first test of graphing each one. We can probably put multiple meters on an image in many cases.

## Status

All parts were done by March 2021 except the automated testing. This was in PR #614. Some changes (described in code) were made from the plan but not any fundamental ones.
