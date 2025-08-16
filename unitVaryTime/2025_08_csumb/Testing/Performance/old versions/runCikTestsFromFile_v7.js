// Code generated in part by ChatGPT-4o 
const fs = require('fs');
const path = require('path');
const { createCikData } = require('./createCikTest_v7'); 

// run the main function with par
async function runTestsFromFile(configPath) {
	const filePath = path.resolve(configPath);
	let lines;

	// read parameters from config file
	try {
		lines = fs.readFileSync(filePath, 'utf-8')
			.split('\n')
			.map(line => line.trim())
			.filter(line => line && !line.startsWith('#'));
	} catch (err) {
		console.error(`❌ Failed to read config file: ${err.message}`);
		process.exit(1);
	}

	// validate and process each line of cik parameters
	for (const [i, line] of lines.entries()) {
		const match = line.match(/"(.+?)"\s+"(.+?)"\s+(hour|day)\s+(\d+)\s+(\d+)\s+(\d+)/i);
		// Match format: "startTime" "endTime" stepUnit meterUnit graphicUnit meterId
		if (!match) {
			console.warn(`⚠️ Skipping invalid line ${i + 1}: ${line}`);
			continue;
		}

		const [, startTime, endTime, stepUnit, meterUnit, graphicUnit, meterId] = match;
		if (!startTime || !endTime || !stepUnit || !meterUnit || !graphicUnit || !meterId) {
			console.warn(`⚠️ Skipping incomplete line ${i + 1}: ${line}`);
			continue;
		}

		// call createCikData with cik parameters
		console.log(`\n🚀 Running test ${i + 1}: ${startTime} to ${endTime} by ${stepUnit}`);
		await createCikData(startTime, endTime, stepUnit.toLowerCase(), meterUnit, graphicUnit, meterId);
		console.log(`✅ Test ${i + 1} completed.`);
	}
}

if (require.main === module) {
	const [, , configArg] = process.argv;
	if (!configArg) {
		console.error("Usage: node runCikTestsFromFile_v7.js <path_to_config_file>");
		process.exit(1);
	}
	runTestsFromFile(configArg);
}
