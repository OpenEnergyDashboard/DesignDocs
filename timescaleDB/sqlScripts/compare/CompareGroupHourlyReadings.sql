/*
 * CompareGroupHourlyReadings.sql
 *
 * Purpose:
 *
 *   Compare results between the existing PostgreSQL materialized view
 *
 *       group_hourly_readings_unit
 *
 *   and the TimescaleDB continuous aggregate
 *
 *       group_hourly_readings_unit_cagg
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
 * Results are ordered by the largest differences first to make discrepancies
 * easier to identify.
 */


/*
 * 1. Compare reading_rate values.
 *
 * This compares the primary hourly aggregation result between:
 *
 *   Original:
 *       group_hourly_readings_unit
 *
 *   TimescaleDB:
 *       group_hourly_readings_unit_cagg
 *
 * Any non-zero differences should be investigated.
 */
SELECT

    mv.group_id,

    LOWER(mv.time_interval) AS mv_time,

    mv.reading_rate AS mv_reading_rate,

    LOWER(cagg.time_interval) AS cagg_time,

    cagg.reading_rate AS cagg_reading_rate,

    (
        COALESCE(mv.reading_rate, 0)
        -
        COALESCE(cagg.reading_rate, 0)
    ) AS difference


FROM group_hourly_readings_unit AS mv

INNER JOIN group_hourly_readings_unit_cagg AS cagg

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
 * 2. Identify rows missing from the TimescaleDB continuous aggregate.
 *
 * This catches cases where the continuous aggregate does not contain a
 * corresponding group/hour/unit combination.
 */
SELECT

    mv.group_id,

    mv.time_interval,

    mv.graphic_unit_id,

    mv.reading_rate

FROM group_hourly_readings_unit AS mv

LEFT JOIN group_hourly_readings_unit_cagg AS cagg

    ON mv.group_id = cagg.group_id

    AND mv.time_interval = cagg.time_interval

    AND mv.graphic_unit_id = cagg.graphic_unit_id


WHERE cagg.group_id IS NULL


ORDER BY

    mv.group_id,

    mv.time_interval


LIMIT 20;