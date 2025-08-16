// Code generated in part by ChatGPT-4o 
const fs = require('fs');
const path = require('path');
const { createCikData } = require('./createCikTest_v5'); // adjust if the filename is different

async function runTestsFromFile(configPath) {
	const filePath = path.resolve(configPath);
	let lines;

	try {
		lines = fs.readFileSync(filePath, 'utf-8')
			.split('\n')
			.map(line => line.trim())
			.filter(line => line && !line.startsWith('#')); // ignore blank or commented lines
	} catch (err) {
		console.error(`❌ Failed to read config file: ${err.message}`);
		process.exit(1);
	}

	for (const [i, line] of lines.entries()) {
		const match = line.match(/"(.+?)"\s+"(.+?)"\s+(hour|day)/i);
		if (!match) {
			console.warn(`⚠️ Skipping invalid line ${i + 1}: ${line}`);
			continue;
		}

		const [, startTime, endTime, stepUnit] = match;
		console.log(`\n🚀 Running test ${i + 1}: ${startTime} to ${endTime} by ${stepUnit}`);
		await createCikData(startTime, endTime, stepUnit.toLowerCase());
	}
}

if (require.main === module) {
	const [, , configArg] = process.argv;
	if (!configArg) {
		console.error("Usage: node runCikTestsFromFile.js <path_to_config_file>");
		process.exit(1);
	}
	runTestsFromFile(configArg);
}
