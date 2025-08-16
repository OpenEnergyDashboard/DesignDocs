// Code generated in part by ChatGPT-4o 
const moment = require('moment');
// const { Client } = require('pg');

// const client = new Client({
// 	user: process.env.PGUSER || 'oed',
// 	host: process.env.PGHOST || 'database-1',
// 	database: process.env.PGDATABASE || 'oed',
// 	password: process.env.PGPASSWORD || 'opened',
// 	port: process.env.PGPORT || 5432,
// });

function logTime(label, start) {
	const diff = process.hrtime(start);
	const ms = (diff[0] * 1000 + diff[1] / 1e6).toFixed(2);
	console.log(`⏱ ${label} took ${ms} ms`);
}

async function createCikData(startTimeStr, endTimeStr, stepUnit) {
	const { Client } = require('pg'); // moved inside for safety
	const client = new Client({
		user: process.env.PGUSER || 'oed',
		host: process.env.PGHOST || 'database-1',
		database: process.env.PGDATABASE || 'oed',
		password: process.env.PGPASSWORD || 'opened',
		port: process.env.PGPORT || 5432,
	});

	const startTime = moment(startTimeStr);
	const endTimeOriginal = moment(endTimeStr);
	const stepTime = moment.duration(1, stepUnit);

	const meterUnit = 4; // "Electric_Utility" in units table; "Sin Amp 1 kWh" in meters table
	const graphicUnit = 1; // "kWh" in units table
	let slope = 1;
	const stepSlope = 0.1;
	const endTime = endTimeOriginal.clone().subtract(stepTime);

	if (!startTime.isValid() || !endTimeOriginal.isValid()) {
		console.error("❌ Invalid date format. Use 'YYYY-MM-DD HH:mm:ss'");
		process.exit(1);
	}
	if (!startTime.isBefore(endTimeOriginal)) {
		console.error("❌ Start time must be before end time.");
		process.exit(1);
	}

	await client.connect();

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
			const values = [meterUnit, graphicUnit, slope.toFixed(2), 0, start, end];
			await client.query(insertQuery, values);

			startTime.add(stepTime);
			slope += stepSlope;
		}
		logTime("Insert", t0);
		console.log("✅ Insert complete.");

		// Prepare and run meter_line_readings_unit twice
		let intervalType = (stepUnit === 'hour') ? 'hourly' : 'daily';

		const readingsQuery = `
			SELECT meter_line_readings_unit(
				'{${meterUnit}}', ${graphicUnit}, '-infinity', 'infinity', '${intervalType}', 200, 200
			);
		`;

		// First run (uncached)
		console.log(`Running meter_line_readings_unit (1st time, uncached)...`);
		t0 = process.hrtime();
		await client.query(readingsQuery);
		logTime("First execution", t0);

		// Second run (cached)
		console.log(`Running meter_line_readings_unit (2nd time, cached)...`);
		t0 = process.hrtime();
		await client.query(readingsQuery);
		logTime("Second execution", t0);

		// Third run (cached)
		// console.log(`Running meter_line_readings_unit (3rd time, cached)...`);
		// t0 = process.hrtime();
		// await client.query(readingsQuery);
		// logTime("Third execution", t0);

		// Fourth run (cached)
		// console.log(`Running meter_line_readings_unit 4th time, cached)...`);
		// t0 = process.hrtime();
		// await client.query(readingsQuery);
		// logTime("Fourth execution", t0);

		console.log("✅ All executions complete.");
	} catch (err) {
		console.error("❌ Error during DB operations:", err);
	} finally {
		await client.end();
	}
}

if (require.main === module) {
	const [, , startTimeArg, endTimeArg, stepUnitArg] = process.argv;

	if (!startTimeArg || !endTimeArg || !stepUnitArg) {
		console.error("Usage: node createCikTest.js <startTime> <endTime> <stepUnit>");
		console.error(`Example: node createCikTest.js "2020-01-01 00:00:00" "2021-01-01 00:00:00" day`);
		process.exit(1);
	}

	createCikData(startTimeArg, endTimeArg, stepUnitArg);
}

module.exports = { createCikData };
// If you want to run this as a script, you can use the command line arguments:
// node createCikTest.js "2020-01-01 00:00:00" "2021-01-01 00:00:00" day
// This will generate the SQL insert statements for the specified time range and step unit.
// If you want to use it as a module, you can import createCikData from this file and call it with the desired parameters.
// Example usage:
// const { createCikData } = require('./createCikTest_v4');
// createCikData("2020-01-01 00:00:00", "2021-01-01 00:00:00", 'day');
// This will generate the SQL insert statements for the specified time range and step unit.
// You can adjust the start time, end time, and step unit as needed.
// Note: The script assumes that the database and table structure is already set up to accept these insertions.
// Make sure to handle the database connection and execution of these SQL statements in your application logic.
// This script is designed to generate SQL insert statements for a time series data set.
// It can be used to create test data for a database table that stores time series data with a specific slope and step time.
// The generated SQL statements can be executed in a database management system to populate the table with the desired data.
// The script uses the moment.js library for date manipulation and formatting.
// It allows you to specify the start time, end time, and step unit (e.g., 'hour' or 'day') for generating the data.
// The generated SQL statements will insert rows into the 'cik' table with the specified meter unit, graphic unit, slope, and time range.
// The slope increases by a specified step slope for each time step, allowing you to create a time series with varying slopes.
// The script can be run directly from the command line or imported as a module in another JavaScript file.
// Make sure to install the moment.js library in your project by running:
// npm install moment

