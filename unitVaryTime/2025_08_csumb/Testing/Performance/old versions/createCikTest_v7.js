// Code generated in part by ChatGPT-4o 
// prompt: npm run createCikTest_v7.js <startTime> <endTime> <stepUnit> <meterUnit> <graphicUnit> <meterId>
// example single: npm run createCikTest_v7.js "2020-01-01 00:00:00" "2021-01-01 00:00:00" day 25 1 3
// eaxmple multi: npm run runCikTests_v7 -- ./src/server/tmp/uploads/createCikTest_cfgv7.txt

// --- Import the 'moment' library for easy date/time manipulation and formatting. ---
// Used throughout the script to manage time ranges and durations.
const moment = require('moment');

// --- Utility function to log the duration of an operation in milliseconds. ---
// Takes a label (string) and a start time from process.hrtime(start).
// Uses high-resolution timing to measure performance of specific code blocks.
function logTime(label, start) {
	const diff = process.hrtime(start);
	const ms = (diff[0] * 1000 + diff[1] / 1e6).toFixed(2);
	console.log(`⏱ ${label} took ${ms} ms`);
}

// --- Main function to generate and insert synthetic CIK data for a given time range. ---
// Parameters:
// - startTimeStr: Start timestamp as a string (e.g., "2020-01-01 00:00:00")
// - endTimeStr: End timestamp as a string (exclusive upper bound)
// - stepUnit: Time interval unit between CIK entries ('hour' or 'day')
// - meterUnitArg: meter_id, ID of the source unit for meter readings (used in meter_line_readings_unit)
// - graphicUnitArg: destination_id, ID of the destination/converted unit (used in CIK and function call)
// - meterIdArg: source_id, ID of the meter for which synthetic data is being generated
async function createCikData(startTimeStr, endTimeStr, stepUnit, meterUnitArg, graphicUnitArg, meterIdArg) {
	// --- Initialize PostgreSQL client using environment variables or defaults. ---
	// Connects to the 'oed' database and is used for all queries in this script.
	// Intended for local testing and development only;
	// using these credentials in production would pose a security risk.
	const { Client } = require('pg');
	const client = new Client({
		user: process.env.PGUSER || 'oed',
		host: process.env.PGHOST || 'database-1',
		database: process.env.PGDATABASE || 'oed',
		password: process.env.PGPASSWORD || 'opened',
		port: process.env.PGPORT || 5432,
	});

	// --- Validate and parse input parameters. ---
	// Parse input strings into Moment.js date objects
	const startTime = moment(startTimeStr);
	const endTimeOriginal = moment(endTimeStr);

	// Define the step interval (e.g., 1 hour or 1 day)
	const stepTime = moment.duration(1, stepUnit);

	// Parse numeric arguments to integers
	const meterUnit = parseInt(meterUnitArg, 10);
	const graphicUnit = parseInt(graphicUnitArg, 10);
	const meterId = parseInt(meterIdArg, 10);
	
	// Initialize slope 
	let slope = 1;
	const stepSlope = 0.1;

	// Calculate effective end time for iteration (exclude last interval)
	const endTime = endTimeOriginal.clone().subtract(stepTime);

	// Validate input dates
	if (!startTime.isValid() || !endTimeOriginal.isValid()) {
		console.error("❌ Invalid date format. Use 'YYYY-MM-DD HH:mm:ss'");
		process.exit(1);
	}
	if (!startTime.isBefore(endTimeOriginal)) {
		console.error("❌ Start time must be before end time.");
		process.exit(1);
	}

	// Connect to the PostgreSQL database
	await client.connect();

	// --- CIK Table Update ---
	try {
		// Delete old records
		console.log("Deleting all existing records from cik table...");
		let t0 = process.hrtime();
		await client.query('DELETE FROM cik;');
		logTime("Delete", t0);

		// Insert new records
		console.log("Inserting generated records...");
		t0 = process.hrtime();
		while (startTime.isSameOrBefore(endTime)) {
			const start = startTime.format("YYYY-MM-DD HH:mm:ss");
			const end = startTime.clone().add(stepTime).format("YYYY-MM-DD HH:mm:ss");
			const insertQuery = `
				INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
				VALUES ($1, $2, $3, $4, $5, $6);
			`;
			const values = [meterId, graphicUnit, slope.toFixed(2), 0, start, end];
			await client.query(insertQuery, values);

			startTime.add(stepTime);
			slope += stepSlope;
		} 
		logTime("Insert", t0);
		console.log("✅ Insert complete.");

		// --- Refresh materialized views ---
		const viewsToRefresh = [
			"meter_raw_readings_unit",
			"meter_hourly_readings_unit_v3",
			"meter_daily_readings_unit"
		];

		for (const viewName of viewsToRefresh) {
			console.log(`🔄 Refreshing materialized view: ${viewName}...`);
			t0 = process.hrtime();
			await client.query(`REFRESH MATERIALIZED VIEW ${viewName} WITH DATA;`);
			logTime(`Refresh ${viewName}`, t0);
		}

		// --- meter_line_readings_unit ---
		// Prepare and run meter_line_readings_unit twice
		let intervalType = (stepUnit === 'hour') ? 'hourly' : 'daily';

		// get count of records returned by meter_line_readings_unit
		const readingsQuery = `
			SELECT COUNT(*) AS row_count FROM meter_line_readings_unit(
				'{${meterUnit}}', ${graphicUnit}, '-infinity', 'infinity', '${intervalType}', 200, 200
			);
		`;


		// First run (uncached)
		console.log(`Running meter_line_readings_unit (1st time, uncached)...`);
		t0 = process.hrtime();
		const result1 = await client.query(readingsQuery);
		logTime("First execution", t0);
		console.log(`🔢 Rows returned: ${result1.rows[0].row_count}`);

		// Second run (cached)
		console.log(`Running meter_line_readings_unit (2nd time, cached)...`);
		t0 = process.hrtime();
		const result2 = await client.query(readingsQuery);
		logTime("Second execution", t0);
		console.log(`🔢 Rows returned: ${result2.rows[0].row_count}`);
		
		console.log("✅ All executions complete.");
	} catch (err) {
		console.error("❌ Error during DB operations:", err);
	} finally {
		await client.end();
	}
}

// --- check if the script is being run directly or imported as a module ---
// If this script is run directly (not imported as a module), parse command-line arguments
if (require.main === module) {
	const [, , startTimeArg, endTimeArg, stepUnitArg, meterUnitArg, graphicUnitArg, meterIdArg] = process.argv;

	// Validate that all required arguments are present
	if (!startTimeArg || !endTimeArg || !stepUnitArg || !meterUnitArg || !graphicUnitArg || !meterIdArg) {
		console.error("prompt: npm run createCikTest_v7.js <startTime> <endTime> <stepUnit> <meterUnit> <graphicUnit> <meterId>");
		console.error(`example: npm run createCikTest_v7.js "2020-01-01 00:00:00" "2021-01-01 00:00:00" day 25 1 3`);
		process.exit(1);
	}

	// Run the main function with provided arguments
	createCikData(startTimeArg, endTimeArg, stepUnitArg, meterUnitArg, graphicUnitArg, meterIdArg);
}

// Export the main function so it can be reused in other scripts (e.g., batch runners)
module.exports = { createCikData };


