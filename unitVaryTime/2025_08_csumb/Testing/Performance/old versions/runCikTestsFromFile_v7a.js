// Code generated in part by ChatGPT-4o 
// runCikTestsFromFile_v7.js
// Run multiple CIK test cases defined in a JSON config file

const fs = require('fs');
const path = require('path');
const { createCikData } = require('./createCikTest_v7'); // Ensure v7 is correct

// Load and run all test cases from JSON config
async function runTestsFromFile(configPath) {
	const filePath = path.resolve(configPath);
	let testCases;

	try {
		// Read and parse JSON file
		const fileContent = fs.readFileSync(filePath, 'utf-8');
		testCases = JSON.parse(fileContent);
	} catch (err) {
		console.error(`❌ Failed to read or parse config file: ${err.message}`);
		process.exit(1);
	}

	if (!Array.isArray(testCases)) {
		console.error("❌ Config file must contain an array of test case objects.");
		process.exit(1);
	}

	// Iterate through test cases
	for (const [i, test] of testCases.entries()) {
		const { startTime, endTime, stepUnit, meterUnit, graphicUnit, meterId } = test;

		// Validate required fields
		if (!startTime || !endTime || !stepUnit || meterUnit == null || graphicUnit == null || meterId == null) {
			console.warn(`⚠️ Skipping invalid test case at index ${i}: ${JSON.stringify(test)}`);
			continue;
		}

		console.log(`\n🚀 Running test ${i + 1}: ${startTime} → ${endTime} (${stepUnit})`);
		try {
			await createCikData(startTime, endTime, stepUnit.toLowerCase(), meterUnit, graphicUnit, meterId);
			console.log(`✅ Test ${i + 1} completed.`);
		} catch (err) {
			console.error(`❌ Error in test ${i + 1}: ${err.message}`);
		}
	}
}

// CLI entry point
if (require.main === module) {
	const [, , configArg] = process.argv;
	if (!configArg) {
		console.error("Usage: node runCikTestsFromFile_v7.js <path_to_config_json>");
		process.exit(1);
	}
	runTestsFromFile(configArg);
}
