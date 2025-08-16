const moment = require('moment');
const { callbackify } = require('util');

async function createHourly() {
	// startTime = moment("2021-06-01 00:00:00");
	// endTime = moment("2021-06-06 00:00:00");
	startTime = moment("2020-01-01 00:00:00");
	endTime = moment("2021-01-08 00:00:00");
	stepTime = moment.duration(1, 'hour');   // 'day' or 'hour'
	// stepTime = moment.duration(1, 'hour');
	meterUnit = 9;   //  = "Electric_Utility" from units table
	graphicUnit = 1;  // 1 = "kWh"
	slope = 1;
	stepSlope = 0.1;
	// Move endTime back one stepTime so can check vs. startTime.
	endTime.subtract(stepTime);
	// Loop over all times wanted.
	while (startTime.isSameOrBefore(endTime)) {
		// First one really should be -infinity and last infinity but not doing now.
		// insert into cik values(10, 1, 2, 0, '-infinity', '2021-06-02 00:00:00');
		// Output a cik to insert into DB. Note it also steps the start time to get the end time so ready for next iteration.
		console.log(`insert into cik values(${meterUnit}, ${graphicUnit}, ${slope.toFixed(2)}, 0, '${startTime.format("YYYY-MM-DD HH:mm:ss")}', '${startTime.add(stepTime).format("YYYY-MM-DD HH:mm:ss")}');`);
		// Next slope.
		slope += stepSlope;
	}
}

module.exports = {
	createHourly,
}
