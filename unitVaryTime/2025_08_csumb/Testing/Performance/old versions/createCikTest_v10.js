// Code generated in part by ChatGPT-4o 
const moment = require('moment');
const fs = require('fs');
const path = require('path');

function logTime(label, start) {
	const diff = process.hrtime(start);
	const ms = (diff[0] * 1000 + diff[1] / 1e6).toFixed(2);
	console.log(`⏱ ${label} took ${ms} ms`);
}

async function validateFunctionExists(client, functionName) {
	const sql = `
		SELECT EXISTS (
			SELECT 1 FROM pg_proc
			WHERE proname = $1
		);
	`;
	const result = await client.query(sql, [functionName]);
	return result.rows[0].exists;
}

async function createCikData(startTimeStr, endTimeStr, stepUnit, meterUnitArg, graphicUnitArg, meterIdArg, viewsToRefresh, functionsToCall) {
	const { Client } = require('pg');
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

	const meterUnit = parseInt(meterUnitArg, 10);
	const graphicUnit = parseInt(graphicUnitArg, 10);
	const meterId = parseInt(meterIdArg, 10);

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
		console.log("Deleting all existing records from cik table...");
		let t0 = process.hrtime();
		await client.query('DELETE FROM cik;');
		logTime("Delete", t0);

		console.log("Inserting generated records...");
		t0 = process.hrtime();
		while (startTime.isSameOrBefore(endTime)) {
			const start = startTime.format("YYYY-MM-DD HH:mm:ss");
			const end = startTime.clone().add(stepTime).format("YYYY-MM-DD HH:mm:ss");
			const insertQuery = \`
				INSERT INTO cik (source_id, destination_id, slope, intercept, start_time, end_time)
				VALUES ($1, $2, $3, $4, $5, $6);
			\`;
			const values = [meterId, graphicUnit, slope.toFixed(2), 0, start, end];
			await client.query(insertQuery, values);

			startTime.add(stepTime);
			slope += stepSlope;
		}
		logTime("Insert", t0);
		console.log("✅ Insert complete.");

		for (const viewName of viewsToRefresh) {
			console.log(`🔄 Refreshing materialized view: ${viewName}...`);
			t0 = process.hrtime();
			await client.query(\`REFRESH MATERIALIZED VIEW \${viewName} WITH DATA;\`);
			logTime(`Refresh \${viewName}`, t0);
		}

		let intervalType = (stepUnit === 'hour') ? 'hourly' : 'daily';

		for (const functionName of functionsToCall) {
			const exists = await validateFunctionExists(client, functionName);
			if (!exists) {
				console.warn(`⚠️ Skipping call: function '\${functionName}' does not exist.`);
				continue;
			}

			const query = \`
				SELECT COUNT(*) AS row_count FROM \${functionName}(
					'{\${meterUnit}}', \${graphicUnit}, '-infinity', 'infinity', '\${intervalType}', 200, 200
				);
			\`;

			console.log(`Running \${functionName} (1st time, uncached)...`);
			t0 = process.hrtime();
			const result1 = await client.query(query);
			logTime("First execution", t0);
			console.log(`🔢 Rows returned: \${result1.rows[0].row_count}`);

			console.log(`Running \${functionName} (2nd time, cached)...`);
			t0 = process.hrtime();
			const result2 = await client.query(query);
			logTime("Second execution", t0);
			console.log(`🔢 Rows returned: \${result2.rows[0].row_count}`);
		}
	} catch (err) {
		console.error("❌ Error during DB operations:", err);
	} finally {
		await client.end();
	}
}

if (require.main === module) {
	const [, , configPath, testIndexArg] = process.argv;
	if (!configPath) {
		console.error("Usage: node createCikTest_v10.js <config_file> [test_index]");
		process.exit(1);
	}

	let config;
	try {
		const raw = fs.readFileSync(path.resolve(configPath), 'utf-8');
		config = JSON.parse(raw);
	} catch (err) {
		console.error(`❌ Failed to read config: \${err.message}`);
		process.exit(1);
	}

	const views = config.viewsToRefresh;
	const tests = config.tests;
	const functions = config.functionsToCall;

	if (!Array.isArray(views) || !Array.isArray(tests) || !Array.isArray(functions)) {
		console.error("❌ Config must contain 'viewsToRefresh', 'tests', and 'functionsToCall' arrays.");
		process.exit(1);
	}

	if (testIndexArg !== undefined) {
		const i = parseInt(testIndexArg, 10);
		const t = tests[i];
		if (!t) {
			console.error(`❌ No test found at index \${i}`);
			process.exit(1);
		}
		console.log(`Running test #\${i}: \${t.startTime} → \${t.endTime} (\${t.stepUnit})`);
		if (t._comment) console.log(`📝 \${t._comment}`);
		createCikData(t.startTime, t.endTime, t.stepUnit, t.meterUnit, t.graphicUnit, t.meterId, views, functions);
	} else {
		(async () => {
			for (const [i, t] of tests.entries()) {
				console.log(`\n🚀 Running test \${i}: \${t.startTime} → \${t.endTime} (\${t.stepUnit})`);
				if (t._comment) console.log(`📝 \${t._comment}`);
				await createCikData(t.startTime, t.endTime, t.stepUnit, t.meterUnit, t.graphicUnit, t.meterId, views, functions);
			}
		})();
	}
}

module.exports = { createCikData };
