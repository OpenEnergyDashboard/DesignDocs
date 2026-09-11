/*
 * CompareGroupDailyReadings.sql
 *
 * Purpose:
 *
 *   Compare results between the existing PostgreSQL materialized view
 *
 *       group_daily_readings_unit
 *
 *   and the TimescaleDB continuous aggregate
 *
 *       group_daily_readings_unit_cagg
 *
 *
 * The purpose of this script is to validate that the TimescaleDB
 * implementation produces equivalent results to the existing materialized
 * view before considering migration.
 *
 *
 * Expected result:
 *
 *   - reading_rate differences should be zero or within floating-point
 *     rounding tolerance.
 *
 *   - Missing rows should be investigated.
 *
 * Results are ordered by the largest differences first to make discrepancies
 * easier to identify.
 */


/*
 * 1. Compare reading_rate values.
 *
 * This compares the primary daily aggregation result between:
 *
 *   Original:
 *       group_daily_readings_unit
 *
 *   TimescaleDB:
 *       group_daily_readings_unit_cagg
 *
 * Any non-zero differences should be investigated.
 */
SELECT

    mv.group_id,

    LOWER(mv.time_interval) AS mv_time,

    LOWER(cagg.time_interval) AS cagg_time,

    mv.reading_rate AS mv_reading_rate,

    cagg.reading_rate AS cagg_reading_rate,

    (
        COALESCE(mv.reading_rate, 0)
        -
        COALESCE(cagg.reading_rate, 0)
    ) AS difference


FROM group_daily_readings_unit AS mv


LEFT JOIN group_daily_readings_unit_cagg AS cagg

    ON mv.group_id = cagg.group_id

    AND mv.time_interval = cagg.time_interval

    AND mv.graphic_unit_id = cagg.graphic_unit_id


ORDER BY

    ABS(
        COALESCE(mv.reading_rate, 0)
        -
        COALESCE(cagg.reading_rate, 0)
    ) DESC


LIMIT 20;



/*
 * 2. Compare row counts.
 *
 * This identifies missing or additional daily buckets between the two
 * implementations.
 */
SELECT

    COUNT(*) AS total_rows,

    COUNT(cagg.group_id) AS matching_cagg_rows,

    COUNT(*) - COUNT(cagg.group_id) AS missing_cagg_rows


FROM group_daily_readings_unit AS mv


LEFT JOIN group_daily_readings_unit_cagg AS cagg

    ON mv.group_id = cagg.group_id

    AND mv.time_interval = cagg.time_interval

    AND mv.graphic_unit_id = cagg.graphic_unit_id;



/*
 * 3. Display missing TimescaleDB rows.
 *
 * These rows exist in the original materialized view but not in the
 * continuous aggregate.
 */
SELECT

    mv.group_id,

    LOWER(mv.time_interval) AS mv_time,

    UPPER(mv.time_interval) AS mv_time_end,

    mv.graphic_unit_id,

    mv.reading_rate


FROM group_daily_readings_unit AS mv


LEFT JOIN group_daily_readings_unit_cagg AS cagg

    ON mv.group_id = cagg.group_id

    AND mv.time_interval = cagg.time_interval

    AND mv.graphic_unit_id = cagg.graphic_unit_id


WHERE cagg.group_id IS NULL


ORDER BY

    mv.group_id,

    mv.time_interval


LIMIT 20;
