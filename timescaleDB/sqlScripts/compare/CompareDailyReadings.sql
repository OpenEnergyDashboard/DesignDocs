/*
 * CompareDailyReadings.sql
 *
 * Purpose:
 *
 *   Compare results between the existing PostgreSQL materialized view
 *
 *       meter_daily_readings_unit
 *
 *   and the TimescaleDB continuous aggregate
 *
 *       meter_daily_readings_unit_cagg
 *
 *
 * The purpose of this script is to validate that the TimescaleDB
 * implementation produces equivalent results to the existing materialized
 * view before considering migration.
 *
 * Expected result:
 *
 *   - reading_rate differences should be zero or within floating-point
 *     rounding tolerance.
 *   - max_rate and min_rate differences should be zero or within
 *     floating-point rounding tolerance.
 *
 * Results are ordered by the largest differences first to make discrepancies
 * easier to identify.
 */


/*
 * 1. Compare reading_rate values.
 *
 * This compares the primary hourly aggregation result between:
 *
 *   Original:
 *       meter_daily_readings_unit
 *
 *   TimescaleDB:
 *       meter_daily_readings_unit_cagg
 *
 * Any non-zero differences should be investigated.
 */
SELECT
    mv.meter_id,
    LOWER(mv.time_interval) AS mv_time,
    mv.reading_rate AS mv_reading_rate,
    LOWER(cagg.time_interval) AS cagg_time,
    cagg.reading_rate AS cagg_reading_rate,
    (COALESCE(mv.reading_rate, 0) - COALESCE(cagg.reading_rate, 0)) AS difference
FROM meter_daily_readings_unit AS mv LEFT JOIN 
	 meter_daily_readings_unit_cagg AS cagg
     	 ON mv.meter_id = cagg.meter_id
    		 AND mv.time_interval = cagg.time_interval
    		 AND mv.graphic_unit_id = cagg.graphic_unit_id
ORDER BY
    ABS(COALESCE(mv.reading_rate, 0) - COALESCE(cagg.reading_rate, 0)) DESC
LIMIT 20;


/*
 * 2. Compare max_rate and min_rate values.
 *
 * This verifies that the continuous aggregate preserves the same minimum and
 * maximum hourly rates as the original materialized view.
 *
 * Any non-zero differences should be investigated.
 */
SELECT
    mv.meter_id,
    LOWER(mv.time_interval) AS mv_time_start,
	LOWER(cagg.time_interval) AS cagg_time_start,
	UPPER(mv.time_interval) AS mv_time_end,
	UPPER(cagg.time_interval) AS cagg_time_end,
    mv.max_rate AS mv_max_rate,
    cagg.max_rate AS cagg_max_rate,
    (COALESCE(mv.max_rate, 0) - COALESCE(cagg.max_rate, 0)) AS max_difference,
    mv.min_rate AS mv_min_rate,
	cagg.min_rate AS cagg_min_rate,
	(COALESCE(mv.min_rate, 0) - COALESCE(cagg.min_rate, 0)) AS min_difference
FROM meter_daily_readings_unit AS mv LEFT JOIN 
	 meter_daily_readings_unit_cagg AS cagg
    	 ON mv.meter_id = cagg.meter_id
    	 	 AND mv.time_interval = cagg.time_interval
    	 	 AND mv.graphic_unit_id = cagg.graphic_unit_id
ORDER BY
    GREATEST(
        ABS(COALESCE(mv.max_rate, 0) - COALESCE(cagg.max_rate, 0)),
        ABS(COALESCE(mv.min_rate, 0) - COALESCE(cagg.min_rate, 0))
    ) DESC
LIMIT 20;