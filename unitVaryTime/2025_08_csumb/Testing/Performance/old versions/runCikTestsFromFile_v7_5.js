// Code generated in part by ChatGPT-4o 
const fs = require('fs');
const path = require('path');
const { createCikData } = require('./createCikTest_v8');

async function runTestsFromFile(configPath) {
	const filePath = path.resolve(configPath);
	let config;

	try {
		const content = fs.readFileSync(filePath, 'utf-8');
		config = JSON.parse(content);
	} catch (err) {
		console.error(`❌ Failed to read or parse config file: ${err.message}`);
		process.exit(1);
	}

	const { viewsToRefresh, tests } = config;

	if (!Array.isArray(viewsToRefresh) || !Array.isArray(tests)) {
		console.error("❌ Config file must contain both 'viewsToRefresh' and 'tests' arrays.");
		process.exit(1);
	}

	for (const [i, test] of tests.entries()) {
		const { startTime, endTime, stepUnit, meterUnit, graphicUnit, meterId } = test;

		if (!startTime || !endTime || !stepUnit || meterUnit == null || graphicUnit == null || meterId == null) {
			console.warn(`⚠️ Skipping invalid test case at index ${i}: ${JSON.stringify(test)}`);
			continue;
		}

		console.log(`\n🚀 Running test ${i + 1}: ${startTime} → ${endTime} (${stepUnit})`);
		try {
			await createCikData(startTime, endTime, stepUnit.toLowerCase(), meterUnit, graphicUnit, meterId, viewsToRefresh);
			console.log(`✅ Test ${i + 1} completed.`);
		} catch (err) {
			console.error(`❌ Error in test ${i + 1}: ${err.message}`);
		}
	}
}

if (require.main === module) {
	const [, , configArg] = process.argv;
	if (!configArg) {
		console.error("Usage: node runCikTestsFromFile_v8.js <path_to_config_json>");
		process.exit(1);
	}
	runTestsFromFile(configArg);
}
