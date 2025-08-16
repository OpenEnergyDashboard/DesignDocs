ToDo:
update createCikTest_v11 to receive parameters for slope and stepSlope

<!-- to run the tests -->
npm run runCikTests -- ./src/server/tmp/uploads/createCikTest_cfg.txt
npm run createCikTest_v5 -- "2020-01-01 00:00:00" "2021-01-01 00:00:00" day
npm run createCikTest_v5 -- "2020-01-01 00:00:00" "2020-01-08 00:00:00" hour
npm run createCikTest_v5 -- "2021-12-30 00:00:00" "2022-01-02 00:00:00" hour
npm run createCikTest_v5 -- "2020-01-01 00:00:00" "2020-01-02 00:00:00" hour
<!-- 25 "Sin Amp 1 kWh" 1 "kWh" 3 "Electric_Utility" -->
npm run createCikTest_v6 -- "2020-01-01 00:00:00" "2020-01-08 00:00:00" hour 25 1 3
npm run runCikTests_v6 -- ./src/server/tmp/uploads/createCikTest_cfgv6.txt
npm run createCikTest_v7 -- "2020-01-01 00:00:00" "2020-01-08 00:00:00" hour 25 1 3
npm run runCikTests_v7 -- ./src/server/tmp/uploads/createCikTest_cfgv7.txt
<!-- run all tests, run a specific test by index -->
npm run createCikTest_v8 ./src/server/tmp/uploads/createCikTest_cfgv8.json
npm run createCikTest_v8 ./src/server/tmp/uploads/createCikTest_cfgv8.json 1
npm run createCikTest_v9 ./src/server/tmp/uploads/createCikTest_cfgv9.json
npm run createCikTest_v9 ./src/server/tmp/uploads/createCikTest_cfgv9.json 1
npm run createCikTest_v11 ./src/server/tmp/uploads/createCikTest_cfgv11.json
npm run createCikTest_v11 ./src/server/tmp/uploads/createCikTest_cfgv11.json 1
<!-- to run the tests for Tyler meter_line_readings_unit_v2/v3-->

<!-- package.json -->
"scripts": {
        ...
	    "createCikTest": "node -e 'require(\"./src/server/tmp/uploads/createCikTest.js\").createHourly()'",
		"createCikTest_v7": "node ./src/server/tmp/uploads/createCikTest_v7.js",
		"createCikTest_v6": "node ./src/server/tmp/uploads/createCikTest_v6.js",
		"createCikTest_v5": "node ./src/server/tmp/uploads/createCikTest_v5.js",
		"createCikTest_v4": "node ./src/server/tmp/uploads/createCikTest_v4.js",
		"runCikTests": "node ./src/server/tmp/uploads/runCikTestsFromFile.js",
		"runCikTests_v6": "node ./src/server/tmp/uploads/runCikTestsFromFile_v6.js",
		"runCikTests_v7": "node ./src/server/tmp/uploads/runCikTestsFromFile_v7.js",
		"createCikTest_v8": "node ./src/server/tmp/uploads/createCikTest_v8.js",
		"createCikTest_v9": "node ./src/server/tmp/uploads/createCikTest_v9.js",
	    "createCikTest_v11": "node ./src/server/tmp/uploads/createCikTest_v11.js"
	},