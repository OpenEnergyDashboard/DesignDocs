// Code generated in part by ChatGPT-4o 
// prompt: npm run createCikTest_v11.js <startTime> <endTime> <stepUnit> <meterUnit> <graphicUnit> <meterId> <viewsToRefresh, <functionsToCall
// example single: npm run createCikTest_v11 ./src/server/tmp/uploads/createCikTest_cfgv11.json 1
// eaxmple multi: npm run createCikTest_v11 ./src/server/tmp/uploads/createCikTest_cfgv11.json


// --- Import the 'moment' library for easy date/time manipulation and formatting. ---
// Used throughout the script to manage time ranges and durations.
const moment = require('moment');
const fs = require('fs');
const path = require('path');

// --- Utility function to log the duration of an operation in milliseconds. ---
// Takes a label (string) and a start time from process.hrtime(start).
// Uses high-resolution timing to measure performance of specific code blocks.
function logTime(label, start) {
  const diff = process.hrtime(start);
  const ms = (diff[0] * 1000 + diff[1] / 1e6).toFixed(2);
  console.log(`⏱ ${label} took ${ms} ms`);
}

// --- Function to validate if a PostgreSQL function exists. ---
async function validateFunctionExists(client, functionName) {
  const sql = `SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = $1);`;
  const result = await client.query(sql, [functionName]);
  return result.rows[0].exists;
}

// --- Function to validate if a PostgreSQL materialized view exists. ---
async function validateViewExists(client, viewName) {
  const sql = `SELECT EXISTS (SELECT 1 FROM pg_matviews WHERE matviewname = $1);`;
  const result = await client.query(sql, [viewName]);
  return result.rows[0].exists;
}

// --- Main function to generate and insert synthetic CIK data for a given time range. ---
// Parameters:
// - startTimeStr: Start timestamp as a string (e.g., "2020-01-01 00:00:00")
// - endTimeStr: End timestamp as a string (exclusive upper bound)
// - stepUnit: Time interval unit between CIK entries ('hour' or 'day')
// - meterUnitArg: meter_id, ID of the source unit for meter readings (used in meter_line_readings_unit)
// - graphicUnitArg: destination_id, ID of the destination/converted unit (used in CIK and function call)
// - meterIdArg: source_id, ID of the meter for which synthetic data is being generated
// - viewsToRefresh: Array of materialized view names to refresh after data insertion
// - functionsToCall: Array of function names to call after data insertion and view refresh
// - testIndex: Optional index to run a specific test from the configuration file
async function createCikData(startTimeStr, endTimeStr, stepUnit, meterUnitArg, graphicUnitArg, meterIdArg, viewsToRefresh, functionsToCall) {
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

  // Initialize slope - future release will get as parameters
  let slope = 1;
  const stepSlope = 0.1;
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

    // --- Refresh Materialized Views and Call Functions ---
    for (const viewName of viewsToRefresh) {
      const exists = await validateViewExists(client, viewName);
      if (!exists) {
        console.warn(`⚠️ Skipping refresh: materialized view '${viewName}' does not exist.`);
        continue;
      }
      console.log(`🔄 Refreshing materialized view: ${viewName}...`);
      t0 = process.hrtime();
      await client.query(`REFRESH MATERIALIZED VIEW ${viewName} WITH DATA;`);
      logTime(`Refresh ${viewName}`, t0);
    }

    //  --- Call Functions ---
    let intervalType = (stepUnit === 'hour') ? 'hourly' : 'daily';

    for (const functionName of functionsToCall) {
      const exists = await validateFunctionExists(client, functionName);
      if (!exists) {
        console.warn(`⚠️ Skipping call: function '${functionName}' does not exist.`);
        continue;
      }

      const query = `
        SELECT COUNT(*) AS row_count FROM ${functionName}(
          '{${meterUnit}}', ${graphicUnit}, '-infinity', 'infinity', '${intervalType}', 200, 200
        );
      `;

		// Prepare and run functions twice
    // First run (uncached)
      console.log(`Running ${functionName} (1st time, uncached)...`);
      t0 = process.hrtime();
      const result1 = await client.query(query);
      logTime("First execution", t0);
      console.log(`🔢 Rows returned: ${result1.rows[0].row_count}`);

      // Second run (cached)
      console.log(`Running ${functionName} (2nd time, cached)...`);
      t0 = process.hrtime();
      const result2 = await client.query(query);
      logTime("Second execution", t0);
      console.log(`🔢 Rows returned: ${result2.rows[0].row_count}`);
    }
  } catch (err) {
    console.error("❌ Error during DB operations:", err);
  } finally {
    await client.end();
  }
}

// --- check if the script is being run directly or imported as a module ---
// If this script is run directly (not imported as a module), parse command-line arguments
if (require.main === module) {
  const [, , configPath, testIndexArg] = process.argv;
  if (!configPath) {
    console.error("Usage: node createCikTest_v11.js <config_file> [test_index]");
    process.exit(1);
  }

  // Read and parse the configuration file
  let config;
  try {
    const raw = fs.readFileSync(path.resolve(configPath), 'utf-8');
    config = JSON.parse(raw);
  } catch (err) {
    console.error(`❌ Failed to read config: ${err.message}`);
    process.exit(1);
  }

  const views = config.viewsToRefresh;
  const tests = config.tests;
  const functions = config.functionsToCall;

  // Validate that the configuration contains the required arrays
  if (!Array.isArray(views) || !Array.isArray(tests) || !Array.isArray(functions)) {
    console.error("❌ Config must contain 'viewsToRefresh', 'tests', and 'functionsToCall' arrays.");
    process.exit(1);
  }

  // Validate that the tests array is not empty
  // If testIndexArg is provided, run only that test; otherwise, run all tests
  if (testIndexArg !== undefined) {
    const i = parseInt(testIndexArg, 10);
    const t = tests[i];
    if (!t) {
      console.error(`❌ No test found at index ${i}`);
      process.exit(1);
    }
    console.log(`Running test #${i}: ${t.startTime} → ${t.endTime} (${t.stepUnit})`);
    if (t._comment) console.log(`📝 ${t._comment}`);
    createCikData(t.startTime, t.endTime, t.stepUnit, t.meterUnit, t.graphicUnit, t.meterId, views, functions);
  } else {
    (async () => {
      for (const [i, t] of tests.entries()) {
        console.log(`\n🚀 Running test ${i}: ${t.startTime} → ${t.endTime} (${t.stepUnit})`);
        if (t._comment) console.log(`📝 ${t._comment}`);
        await createCikData(t.startTime, t.endTime, t.stepUnit, t.meterUnit, t.graphicUnit, t.meterId, views, functions);
      }
    })();
  }
}
// Export the createCikData function for use in other modules or tests
module.exports = { createCikData };
