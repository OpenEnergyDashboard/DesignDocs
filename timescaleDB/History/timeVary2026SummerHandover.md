# Technical Handover Document

## TimescaleDB Migration for Meter Reading Aggregation

---

### Executive Summary

This document provides a technical handover for the TimescaleDB migration completed as part of the meter reading aggregation optimization project.

The objective of the project was to replace the existing PostgreSQL materialized-view-based reporting architecture with a TimescaleDB implementation using hypertables and continuous aggregates.

The migration was driven by the increasing cost of refreshing PostgreSQL materialized views as historical meter data continued to grow. The previous implementation recalculated all of historical data during every refresh, resulting in long execution times and some unnecessary joins repeated across hourly and daily aggregations.

The new implementation introduces:

- A TimescaleDB hypertable that stores precomputed hourly reading slices.
- Continuous aggregates for incremental hourly and daily aggregation.
- Cache tables that replace recursive views and runtime functions required for group aggregation.
- Updated application initialization and refresh workflows.
- Benchmarking and validation tools to verify correctness against the legacy implementation.

The migration successfully preserves analytical correctness while reducing aggregate refresh times by more than two orders of magnitude, even when the amount of historical data is modest. Extensive benchmarking demonstrated approximately 250× faster hourly refreshes and approximately 340× faster daily refreshes compared to the previous implementation.

### Benchmark 

#### Configuration

|        config_key        |             config_value              |                            description
|--------------------------|---------------------------------------|--------------------------------------------------------------------
| baseline_end_date        | 2021-12-31 23:59:59                   | End of baseline dataset
| baseline_start_date      | 2020-01-01 00:00:00                   | Beginning of baseline dataset
| benchmark_meter_id       | 32                                    | Meter ID used for benchmark execution
| daily_cagg               | meter_daily_readings_unit_cagg        | TimescaleDB daily continuous aggregate
| daily_materialized_view  | meter_daily_readings_unit             | Legacy PostgreSQL daily materialized view
| generate_random_seed     | false                                 | Deprecated: benchmark readings are deterministic for repeatability
| hourly_cagg              | meter_hourly_readings_unit_cagg       | TimescaleDB hourly continuous aggregate
| hourly_materialized_view | meter_hourly_readings_unit            | Legacy PostgreSQL hourly materialized view
| hourly_split_table       | hypertable_hourly_split               | TimescaleDB hourly split hypertable
| hourly_split_trigger     | trg_readings_update_hourly_hypertable | Trigger responsible for hourly split generation
| refresh_concurrent       | false                                 | Use concurrent materialized view refresh if supported
| run_query_tests          | true                                  | Enable query performance testing
| run_storage_tests        | true                                  | Enable storage measurements
| source_table             | readings                              | Source readings table

#### Baseline

|           object_name           |      object_type       | row_count |    min_timestamp    |    max_timestamp
|---------------------------------|------------------------|-----------|---------------------|---------------------
| readings                        | SOURCE_TABLE           |     70176 | 2020-01-01 00:00:00 | 2022-01-01 00:00:00
| hypertable_hourly_split         | TIMESCALE_HOURLY_SPLIT |    631584 | 2020-01-01 00:00:00 | 2022-01-01 00:00:00
| meter_hourly_readings_unit_cagg | TIMESCALE_HOURLY_CAGG  |    157896 |                     |
| meter_daily_readings_unit_cagg  | TIMESCALE_DAILY_CAGG   |      6579 |                     |

 Since group is calculated from meter hourly and daily, they are in milliseconds and comparing with legacy views seemed unnecessary.

#### Parameters

|        config_key        |             config_value
|--------------------------|---------------------------------------
| baseline_end_date        | 2021-12-31 23:59:59
| baseline_start_date      | 2020-01-01 00:00:00
| benchmark_meter_id       | 32
| daily_cagg               | meter_daily_readings_unit_cagg
| daily_materialized_view  | meter_daily_readings_unit
| generate_random_seed     | false
| hourly_cagg              | meter_hourly_readings_unit_cagg
| hourly_materialized_view | meter_hourly_readings_unit
| hourly_split_table       | hypertable_hourly_split
| hourly_split_trigger     | trg_readings_update_hourly_hypertable
| refresh_concurrent       | false
| run_query_tests          | true
| run_storage_tests        | true
| source_table             | readings

#### Test Data

|   location_code    |        situation_description         | size_code |       scenario_name        |     start_time      |      end_time
|--------------------|--------------------------------------|-----------|----------------------------|---------------------|---------------------
| AFTER_LAST_DATE    | Append data after existing history   |   DAY     | AFTER_LAST_DATE_DAY      | 2022-01-01 00:00:00 | 2022-01-02 00:00:00
| AFTER_LAST_DATE    | Append data after existing history   |   MONTH   | AFTER_LAST_DATE_MONTH    | 2022-01-01 00:00:00 | 2022-02-01 00:00:00
| AFTER_LAST_DATE    | Append data after existing history   |   WEEK    | AFTER_LAST_DATE_WEEK     | 2022-01-01 00:00:00 | 2022-01-08 00:00:00
| AFTER_LAST_DATE    | Append data after existing history   |   YEAR    | AFTER_LAST_DATE_YEAR     | 2022-01-01 00:00:00 | 2023-01-01 00:00:00
| BEFORE_FIRST_DATE  | Insert data before existing history  |   DAY     | BEFORE_FIRST_DATE_DAY    | 2019-01-01 00:00:00 | 2019-01-02 00:00:00
| BEFORE_FIRST_DATE  | Insert data before existing history  |   MONTH   | BEFORE_FIRST_DATE_MONTH  | 2019-01-01 00:00:00 | 2019-02-01 00:00:00
| BEFORE_FIRST_DATE  | Insert data before existing history  |   WEEK    | BEFORE_FIRST_DATE_WEEK   | 2019-01-01 00:00:00 | 2019-01-08 00:00:00
| BEFORE_FIRST_DATE  | Insert data before existing history  |   YEAR    | BEFORE_FIRST_DATE_YEAR   | 2019-01-01 00:00:00 | 2020-01-01 00:00:00
| MIDDLE_REPLACEMENT | Replace data inside existing history |   MONTH   | MIDDLE_REPLACEMENT_  MONTH | 2020-06-01 00:00:00 | 2020-07-01 00:00:00

|       scenario_name        |     situation      | date_range | source_rows
|----------------------------|--------------------|------------|-------------
| AFTER_LAST_DATE_ DAY       | AFTER_LAST_DATE    |   DAY      |          24
| AFTER_LAST_DATE_MONTH      | AFTER_LAST_DATE    |   MONTH    |         744
| AFTER_LAST_DATE_WEEK       | AFTER_LAST_DATE    |   WEEK     |         168
| AFTER_LAST_DATE_YEAR       | AFTER_LAST_DATE    |   YEAR     |        8760
| BEFORE_FIRST_DATE_DAY      | BEFORE_FIRST_DATE  |   DAY      |          24
| BEFORE_FIRST_DATE_MONTH    | BEFORE_FIRST_DATE  |   MONTH    |         744
| BEFORE_FIRST_DATE_WEEK     | BEFORE_FIRST_DATE  |   WEEK     |         168
| BEFORE_FIRST_DATE_YEAR     | BEFORE_FIRST_DATE  |   YEAR     |        8760
| MIDDLE_REPLACEMENT_MONTH   | MIDDLE_REPLACEMENT |   MONTH    |         720

#### Insert

|       scenario_name       |     situation     | date_range | implementation | source_rows | hourly_split_rows | duration_ms | rows_per_second
|---------------------------|-------------------|------------|----------------|-------------|-------------------|-------------|-----------------
| AFTER_LAST_DATE_DAY       | AFTER_LAST_DATE   |   DAY      | LEGACY         |          24 |                 0 |       2.587 |        9277.155
| AFTER_LAST_DATE_DAY       | AFTER_LAST_DATE   |   DAY      | TIMESCALE      |          24 |               216 |      31.047 |         773.022
| AFTER_LAST_DATE_WEEK      | AFTER_LAST_DATE   |   WEEK     | LEGACY         |         168 |                 0 |       6.562 |       25601.951
| AFTER_LAST_DATE_WEEK      | AFTER_LAST_DATE   |   WEEK     | TIMESCALE      |         168 |              1512 |      69.547 |        2415.633
| AFTER_LAST_DATE_MONTH     | AFTER_LAST_DATE   |   MONTH    | LEGACY         |         744 |                 0 |      24.533 |       30326.499
| AFTER_LAST_DATE_MONTH     | AFTER_LAST_DATE   |   MONTH    | TIMESCALE      |         744 |              6696 |     298.165 |        2495.263
| AFTER_LAST_DATE_YEAR      | AFTER_LAST_DATE   |   YEAR     | LEGACY         |        8760 |                 0 |     303.218 |       28890.105
| AFTER_LAST_DATE_YEAR      | AFTER_LAST_DATE   |   YEAR     | TIMESCALE      |        8760 |             78840 |    3671.501 |        2385.945
| BEFORE_FIRST_DATE_DAY     | BEFORE_FIRST_DATE |   DAY      | LEGACY         |          24 |                 0 |       2.294 |       10462.075
| BEFORE_FIRST_DATE_DAY     | BEFORE_FIRST_DATE |   DAY      | TIMESCALE      |          24 |               216 |      14.191 |        1691.213
| BEFORE_FIRST_DATE_WEEK    | BEFORE_FIRST_DATE |   WEEK     | LEGACY         |         168 |                 0 |       6.791 |       24738.625
| BEFORE_FIRST_DATE_WEEK    | BEFORE_FIRST_DATE |   WEEK     | TIMESCALE      |         168 |              1512 |      65.123 |        2579.734
| BEFORE_FIRST_DATE_MONTH   | BEFORE_FIRST_DATE |   MONTH    | LEGACY         |         744 |                 0 |      23.744 |       31334.232
| BEFORE_FIRST_DATE_MONTH   | BEFORE_FIRST_DATE |   MONTH    | TIMESCALE      |         744 |              6696 |     306.256 |        2429.340
| BEFORE_FIRST_DATE_YEAR    | BEFORE_FIRST_DATE |   YEAR     | LEGACY         |        8760 |                 0 |     288.164 |       30399.356
| BEFORE_FIRST_DATE_YEAR    | BEFORE_FIRST_DATE |   YEAR     | TIMESCALE      |        8760 |             78840 |    3787.205 |        2313.051

![After Last Date Chart](./Images/after_insert_meter_duration.png) ![Before First Date Chart](./Images/before_insert_meter_duration.png)

The numbers before the labels on the graph has no value other than to align the graph better. The alignment would not be correct without the numbers prefixed. Example the spelling of Week starts with "W" and the spelling of Month starts with "M", if ordered by letters, month will be displayed before week, therefore, the numbers appear before the duration.

#### Refresh:

|       scenario_name       |     situation     | date_range | aggregation_level | implementation | rows_affected | duration_ms | rows_per_second
|---------------------------|-------------------|------------|-------------------|----------------|---------------|-------------|-----------------
| AFTER_LAST_DATE_DAY       | AFTER_LAST_DATE   |   DAY      | DAILY             | LEGACY         |             9 |    5094.777 |           1.767
| AFTER_LAST_DATE_DAY       | AFTER_LAST_DATE   |   DAY      | DAILY             | TIMESCALE      |             9 |      15.242 |         590.474
| AFTER_LAST_DATE_WEEK      | AFTER_LAST_DATE   |   WEEK     | DAILY             | LEGACY         |            63 |    4686.750 |          13.442
| AFTER_LAST_DATE_WEEK      | AFTER_LAST_DATE   |   WEEK     | DAILY             | TIMESCALE      |            63 |      11.969 |        5263.598
| AFTER_LAST_DATE_MONTH     | AFTER_LAST_DATE   |   MONTH    | DAILY             | LEGACY         |           279 |    4940.009 |          56.478
| AFTER_LAST_DATE_MONTH     | AFTER_LAST_DATE   |   MONTH    | DAILY             | TIMESCALE      |           279 |      22.093 |       12628.434
| AFTER_LAST_DATE_YEAR      | AFTER_LAST_DATE   |   YEAR     | DAILY             | LEGACY         |          3285 |    5158.685 |         636.790
| AFTER_LAST_DATE_YEAR      | AFTER_LAST_DATE   |   YEAR     | DAILY             | TIMESCALE      |          3285 |      88.837 |       36977.836
| BEFORE_FIRST_DATE_DAY     | BEFORE_FIRST_DATE |   DAY      | DAILY             | LEGACY         |             9 |    4699.987 |           1.915
| BEFORE_FIRST_DATE_DAY     | BEFORE_FIRST_DATE |   DAY      | DAILY             | TIMESCALE      |             9 |      38.082 |         236.332
| BEFORE_FIRST_DATE_WEEK    | BEFORE_FIRST_DATE |   WEEK     | DAILY             | LEGACY         |            63 |    4746.455 |          13.273
| BEFORE_FIRST_DATE_WEEK    | BEFORE_FIRST_DATE |   WEEK     | DAILY             | TIMESCALE      |            63 |      28.580 |        2204.339
| BEFORE_FIRST_DATE_MONTH   | BEFORE_FIRST_DATE |   MONTH    | DAILY             | LEGACY         |           279 |    4952.453 |          56.336
| BEFORE_FIRST_DATE_MONTH   | BEFORE_FIRST_DATE |   MONTH    | DAILY             | TIMESCALE      |           279 |      19.033 |       14658.751
| BEFORE_FIRST_DATE_YEAR    | BEFORE_FIRST_DATE |   YEAR     | DAILY             | LEGACY         |          3285 |    5028.000 |         653.341
| BEFORE_FIRST_DATE_YEAR    | BEFORE_FIRST_DATE |   YEAR     | DAILY             | TIMESCALE      |          3285 |      71.498 |       45945.341
| AFTER_LAST_DATE_DAY       | AFTER_LAST_DATE   |   DAY      | HOURLY            | LEGACY         |           216 |    8427.066 |          25.632
| AFTER_LAST_DATE_DAY       | AFTER_LAST_DATE   |   DAY      | HOURLY            | TIMESCALE      |           216 |      33.005 |        6544.463
| AFTER_LAST_DATE_WEEK      | AFTER_LAST_DATE   |   WEEK     | HOURLY            | LEGACY         |          1512 |    8232.224 |         183.668
| AFTER_LAST_DATE_WEEK      | AFTER_LAST_DATE   |   WEEK     | HOURLY            | TIMESCALE      |          1512 |      59.630 |       25356.364
| AFTER_LAST_DATE_MONTH     | AFTER_LAST_DATE   |   MONTH    | HOURLY            | LEGACY         |          6696 |    8443.237 |         793.061
| AFTER_LAST_DATE_MONTH     | AFTER_LAST_DATE   |   MONTH    | HOURLY            | TIMESCALE      |          6696 |     145.218 |       46109.986
| AFTER_LAST_DATE_YEAR      | AFTER_LAST_DATE   |   YEAR     | HOURLY            | LEGACY         |         78840 |    8688.681 |        9073.874
| AFTER_LAST_DATE_YEAR      | AFTER_LAST_DATE   |   YEAR     | HOURLY            | TIMESCALE      |         78840 |    1020.274 |       77273.360
| BEFORE_FIRST_DATE_DAY     | BEFORE_FIRST_DATE |   DAY      | HOURLY            | LEGACY         |           216 |    8076.936 |          26.743
| BEFORE_FIRST_DATE_DAY     | BEFORE_FIRST_DATE |   DAY      | HOURLY            | TIMESCALE      |           216 |      67.495 |        3200.237
| BEFORE_FIRST_DATE_WEEK    | BEFORE_FIRST_DATE |   WEEK     | HOURLY            | LEGACY         |          1512 |    8114.325 |         186.337
| BEFORE_FIRST_DATE_WEEK    | BEFORE_FIRST_DATE |   WEEK     | HOURLY            | TIMESCALE      |          1512 |      62.265 |       24283.305
| BEFORE_FIRST_DATE_MONTH   | BEFORE_FIRST_DATE |   MONTH    | HOURLY            | LEGACY         |          6696 |    8491.706 |         788.534
| BEFORE_FIRST_DATE_MONTH   | BEFORE_FIRST_DATE |   MONTH    | HOURLY            | TIMESCALE      |          6696 |     137.100 |       48840.263
| BEFORE_FIRST_DATE_YEAR    | BEFORE_FIRST_DATE |   YEAR     | HOURLY            | LEGACY         |         78840 |    8327.288 |        9467.668
| BEFORE_FIRST_DATE_YEAR    | BEFORE_FIRST_DATE |   YEAR     | HOURLY            | TIMESCALE      |         78840 |    1140.075 |       69153.345

![After Last Date Chart](./Images/after_refresh_meter_hourly.png) ![After Last Date Chart](./Images/after_refresh_meter_daily.png)
![Before First Date Chart](./Images/before_refresh_meter_hourly.png) ![Before First Date Chart](./Images/before_refresh_meter_daily.png)

The numbers before the labels on the graph has no value other than to align the graph better. The alignment would not be correct without the numbers prefixed. Example the spelling of Week starts with "W" and the spelling of Month starts with "M", if ordered by letters, month will be displayed before week, therefore, the numbers appear before the duration.

#### Mismatch:

| aggregation_level | legacy_rows | timescale_rows | mismatch_rows | tolerance | passed
|-------------------|-------------|----------------|---------------|-----------|--------
| DAILY             |        6579 |           6579 |             0 |     1e-11 | t
| HOURLY            |      157896 |         157896 |             0 |     1e-11 | t


#### Fair Comparison
At this point it is unfair to just compare the refresh data. Since TimeScaleDB uses significant time to insert data, and overall comparison seems fair.

![After Last Date Chart](./Images/after_insert_refresh_meter_hourly.png) ![Before Last Date Chart](./Images/before_insert_refresh_meter_hourly.png)
![After Last Date Chart](./Images/after_insert_refresh_meter_daily.png) ![Before Last Date Chart](./Images/before_insert_refresh_meter_daily.png)

The numbers before the labels on the graph has no value other than to align the graph better. The alignment would not be correct without the numbers prefixed. Example the spelling of Week starts with "W" and the spelling of Month starts with "M", if ordered by letters, month will be displayed before week, therefore, the numbers appear before the duration.

The implementation is functionally complete and ready for continued development.

---

# 1. Background

## Existing Architecture

Prior to this project, reporting was performed entirely using PostgreSQL materialized views. Below the readings were a regular table and the rest were materialized views. Note this is based on work done in the timeVary branch so the development branch did not have the group views, dealing with conversions in views and some other changes.

```
readings
    │
    ▼
meter_hourly_readings_unit
    │
    ▼
meter_daily_readings_unit
    │
    ▼
group_hourly_readings_unit
    │
    ▼
group_daily_readings_unit
```

These materialized views were responsible for:

- Splitting readings across hourly boundaries
- Applying unit conversions
- Handling time-varying conversion factors
- Aggregating readings into hourly values
- Rolling hourly values into daily values
- Aggregating meters into groups

Although functionally correct, the design had several limitations.

### Expensive Refreshes

Materialized views refreshed by recomputing all of historical data.

As the database grew, refresh times increased proportionally.

### Duplicate Work

Before the previous time-varying work, where this was originally addressed, hourly and daily materialized views independently repeated much of the same aggregation logic.

### Runtime Conversion Overhead

Every refresh repeatedly joined against conversion tables and recalculated overlap durations.

### Group Aggregation Limitations

Group aggregation depended on recursive views and runtime helper functions that are incompatible with TimescaleDB continuous aggregates.

# 2. Project Objectives

The migration was designed around four primary objectives.

## Performance

Replace expensive full refreshes with TimescaleDB's incremental aggregation model.

## Correctness

Maintain identical analytical results compared with the existing PostgreSQL implementation.

## Scalability

Support significantly larger datasets without proportional increases in refresh time.

## Maintainability

Move expensive calculations into predictable preprocessing and refresh stages rather than executing them repeatedly during aggregation.

# 3. Final Architecture

The implemented architecture is shown below.

```
                    readings
                       │
                    Trigger
                       │
                       ▼
            hypertable_hourly_split
                       │
        ┌──────────────┴──────────────┐
        ▼                             ▼
meter_hourly_readings_unit_cagg   meter_daily_readings_unit_cagg
        │                             │
        ▼                             ▼
group_hourly_readings_unit_cagg  group_daily_readings_unit_cagg
```

The intended aggregation hierarchy is:

1. Convert raw readings into hourly slices.
2. Aggregate hourly slices into meter hourly values.
3. Roll hourly values into daily values.
4. Aggregate meter values into group values.

This layered design minimizes repeated calculations and enables TimescaleDB to perform incremental refreshes efficiently.

# 4. Database Components

## 4.1 hypertable_hourly_split

File:

```
TimeScaleDB/create_prerequisites.sql
```

### Purpose

The hypertable stores hourly reading slices derived from the raw readings table.

Each row contains:

- hourly overlap duration
- weighted reading contribution
- unit metadata
- conversion metadata
- graphic unit information

Previously this information was calculated every time aggregation occurred.

The new implementation performs the calculation once during ingestion and stores the results for reuse.

The hypertable includes sec_in_rate and unit_represents columns. Since this code was based on the work of previous cohorts, these columns have been kept in place. If these two columns are not used in future, they must be removed from create statement and the trigger function must be adjusted accordingly.


### Benefits

- Eliminates repeated hourly splitting.
- Eliminates repeated conversion joins.
- Provides a stable source for continuous aggregates.
- Improves refresh performance.

---

## 4.2 Meter Hourly Continuous Aggregate

File:

```
TimeScaleDB/create_hourly_readings.sql
```

Created object:

```
meter_hourly_readings_unit_cagg
```

This replaces:

```
meter_hourly_readings_unit
```

Responsibilities include:

- hourly bucketing
- weighted aggregation
- minimum values
- maximum values
- unit conversion

Because the hourly split hypertable already contains precomputed overlap information, expensive calculations are not repeated.

## 4.3 Meter Daily Continuous Aggregate

File:

```
TimeScaleDB/create_daily_readings.sql
```

Created object:

```
meter_daily_readings_unit_cagg
```

The current implementation aggregates directly from:

```
hypertable_hourly_split
```

rather than from the hourly continuous aggregate.

While this maintains correctness, it does not yet realize the full benefits of hierarchical aggregation.

A future implementation should expose rollup state from the hourly aggregate (weighted sums, durations, minimums, and maximums) so that daily aggregates can be computed by summing intermediate states rather than reprocessing raw hourly slices. Since the daily meter values are used by daily group view and the buckets are hourly, the bucket could be lost and TimeScaleDB need the underlying hourly bucket on the hypertable to track changes, tehrefore this design was chosen.

Care must be taken not to average hourly averages, as this would produce incorrect weighted results. There was an instance where not having a better understanding of how daily rates were calculated for KWh, incorrect result was discovered during materialized view and TimeScaleDB. This may nhot be a problem, but if you find the values are different, this is a good starting point.

---

## 4.4 Group Aggregation

### Challenge

The legacy implementation depended on:

- recursive views
- PL/pgSQL helper functions

Examples include:

- groups_deep_meters
- get_graphic_unit()

Continuous aggregates cannot depend on these objects.

### Solution

The project introduced cache tables that are refreshed before group aggregate refreshes.

```
groups_immediate_children
            │
            ▼
groups_deep_children
            │
            ▼
groups_deep_meters_cache
            │
            ▼
group_graphic_units_cache
            │
            ▼
group continuous aggregates
```

Implemented components include:

- cache tables
- cache refresh procedures
- hourly group continuous aggregates
- daily group continuous aggregates

This removes runtime recursion while remaining compatible with TimescaleDB.

# 5. Application Integration

The application initialization workflow was updated to create and maintain the new TimescaleDB objects.

Implemented in:

```
TimeScaleDB/Reading.js
```

Functions added include:

- createPrerequisites()
- createGroupDependencies()
- createHourlyReadings()
- createDailyReadings()
- createGroupHourlyReadings()
- createGroupDailyReadings()

Existing query functions were updated to reference the new continuous aggregates.

Meter queries now use:

- meter_hourly_readings_unit_cagg
- meter_daily_readings_unit_cagg

Group queries now use:

- group_hourly_readings_unit_cagg
- group_daily_readings_unit_cagg

---

# 6. Refresh Workflow

The implemented refresh order is:

1. Rebuild hypertable_hourly_split (when required, changes to cik and cik_vary data).
2. Refresh hourly continuous aggregate.
3. Refresh daily continuous aggregate.
4. Refresh group dependency caches.
5. Refresh hourly group aggregate.
6. Refresh daily group aggregate.

This dependency order must be preserved because each stage depends on results produced by previous stages.

# 7. Testing and Validation

A comprehensive validation suite was created to compare the TimescaleDB implementation against the last time-vary version that had already modified/added views and was moderately tested to verify it is correct.

Comparison scripts were created for:

- meter hourly
- meter daily
- group hourly
- group daily

Validation confirmed:

| Aggregate | Legacy | TimescaleDB | Mismatches |
|-----------|---------|-------------|------------|
| Hourly | 157,896 | 157,896 | 0 |
| Daily | 6,579 | 6,579 | 0 |

Comparison tolerance: 10e-11

The following values were validated:

- reading_rate
- minimum
- maximum
- timestamps
- missing rows

No analytical differences were detected.

```
/*
 * 1. Compare reading_rate values.
 *
 * This compares the primary hourly aggregation result between:
 *
 *   Original:
 *       meter_hourly_readings_unit
 *
 *   TimescaleDB:
 *       meter_hourly_readings_unit_cagg
 *
 * Any non-zero differences should be investigated.
 */
SELECT
    mv.meter_id,
    LOWER(mv.time_interval) AS mv_time,
    mv.reading_rate AS mv_reading_rate,
    cagg.bucket AS cagg_time,
    cagg.reading_rate AS cagg_reading_rate,
    (COALESCE(mv.reading_rate, 0) - COALESCE(cagg.reading_rate)) AS difference
FROM meter_hourly_readings_unit AS mv INNER JOIN 
	 meter_hourly_readings_unit_cagg AS cagg
    	 ON mv.meter_id = cagg.meter_id
    		 AND lower(mv.time_interval) = cagg.bucket
    		 AND mv.graphic_unit_id = cagg.graphic_unit_id
ORDER BY
    ABS(COALESCE(mv.reading_rate) - COALESCE(cagg.reading_rate)) DESC
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
    LOWER(mv.time_interval) AS mv_time,
    mv.max_rate AS mv_max_rate,
    cagg.max_rate AS cagg_max_rate,
    (COALESCE(mv.max_rate) - COALESCE(cagg.max_rate)) AS max_difference,
    mv.min_rate AS mv_min_rate,
    cagg.min_rate AS cagg_min_rate,
    (COALESCE(mv.min_rate) - COALESCE(cagg.min_rate)) AS min_difference
FROM meter_hourly_readings_unit AS mv INNER JOIN 
	 meter_hourly_readings_unit_cagg AS cagg
    	 ON mv.meter_id = cagg.meter_id
    		 AND lower(mv.time_interval) = cagg.bucket
    		 AND mv.graphic_unit_id = cagg.graphic_unit_id
ORDER BY
    GREATEST(
        ABS(COALESCE(mv.max_rate, 0) - COALESCE(cagg.max_rate, 0)),
        ABS(COALESCE(mv.min_rate, 0) - COALESCE(cagg.min_rate, 0))
    ) DESC
LIMIT 20;

/*
 * 3. Compare reading_rate values.
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
 * 4. Compare max_rate and min_rate values.
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

/*
 * 5. Compare reading_rate values.
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
FROM group_hourly_readings_unit AS mv INNER JOIN 
     group_hourly_readings_unit_cagg AS cagg
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
 * 6. Identify rows missing from the TimescaleDB continuous aggregate.
 *
 * This catches cases where the continuous aggregate does not contain a
 * corresponding group/hour/unit combination.
 */
SELECT
    mv.group_id,
    mv.time_interval,
    mv.graphic_unit_id,
    mv.reading_rate
FROM group_hourly_readings_unit AS mv LEFT JOIN 
     group_hourly_readings_unit_cagg AS cagg 
         ON mv.group_id = cagg.group_id 
             AND mv.time_interval = cagg.time_interval 
             AND mv.graphic_unit_id = cagg.graphic_unit_id
WHERE cagg.group_id IS NULL
ORDER BY mv.group_id, mv.time_interval
LIMIT 20;

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
FROM group_daily_readings_unit AS mv LEFT JOIN 
     group_daily_readings_unit_cagg AS cagg
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
FROM group_daily_readings_unit AS mv LEFT JOIN 
     group_daily_readings_unit_cagg AS cagg
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
FROM group_daily_readings_unit AS mv LEFT JOIN 
     group_daily_readings_unit_cagg AS cagg
         ON mv.group_id = cagg.group_id
             AND mv.time_interval = cagg.time_interval
             AND mv.graphic_unit_id = cagg.graphic_unit_id
WHERE cagg.group_id IS NULL
ORDER BY
    mv.group_id,
    mv.time_interval
LIMIT 20;
```

# 8. Benchmark Results

## Hourly Refresh

Legacy: ~8.4 seconds

TimescaleDB: ~33 milliseconds

Approximately **250× faster**. Review benchmark details above for details.

## Daily Refresh

Legacy: ~5.1 seconds

TimescaleDB: ~15 milliseconds

Approximately **340× faster**. Review benchmark details above for details.

# 9. Storage Considerations

|object_name						  | object_type             | size_bytes | size_pretty
|----------------------------------------------------------|-------------------------|------------|-------------
| hypertable_hourly_split                                  | HOURLY_SPLIT_HYPERTABLE | 1360068608 | 1297 MB
| public.hypertable_hourly_split chunks                    | TIMESCALE_CHUNKS        | 1360052224 | 1297 MB
| meter_hourly_readings_unit_cagg                          | TIMESCALE_HOURLY_CAGG   |  229097472 | 218 MB
| _timescaledb_internal._materialized_hypertable_12 chunks | TIMESCALE_CHUNKS        |  229056512 | 218 MB
| meter_hourly_readings_unit                               | LEGACY_HOURLY_MV        |  140754944 | 134 MB
| readings                                                 | SOURCE_TABLE            |   34250752 | 33 MB
| meter_daily_readings_unit_cagg                           | TIMESCALE_DAILY_CAGG    |   13082624 | 12 MB
| _timescaledb_internal._materialized_hypertable_13 chunks | TIMESCALE_CHUNKS        |   13041664 | 12 MB
| meter_daily_readings_unit                                | LEGACY_DAILY_MV         |    5611520 | 5480 kB

The storage increase is primarily due to the hourly split hypertable.

This is expected because each reading is decomposed into hourly slices before aggregation. Since some of the meter readings are in minutes, hourly buckets are expected to be lesser, therefore, requiring lesser storage. But the meta data, and other checks - such as change in bucket and tracking dirty bits per bucket - the storage size increases.

The additional storage represents an intentional trade-off that enables:

- dramatically faster refreshes
- reduced runtime computation
- improved scalability

---

# 10. Files Added and Modified

## SQL

- [create_prerequisites.sql](./sqlScripts/implementation/create_prerequisites.sql)
- [create_group_dependencies.sql](./sqlScripts/implementation/create_group_dependencies.sql)
- [create_hourly_readings.sql](./sqlScripts/implementation/create_hourly_readings.sql)
- [create_daily_readings.sql](./sqlScripts/implementation/create_daily_readings.sql)
- [create_group_hourly_readings.sql](./sqlScripts/implementation/create_group_hourly_readings.sql)
- [create_group_daily_readings.sql](./sqlScripts/implementation/create_group_daily_readings.sql)
- [update_function_get_3d_readings.sql](./sqlScripts/implementation/update_function_get_3d_readings.sql)
- [update_function_get_compare_readings.sql](./sqlScripts/implementation/update_function_get_compare_readings.sql)
- [update_group_line_readings_unit.sql](./sqlScripts/implementation/update_group_line_readings_unit.sql)
- [update_meter_group_bar.sql](./sqlScripts/implementation/update_meter_group_bar.sql)
- [update_meter_line_readings_unit.sql](./sqlScripts/implementation/update_meter_line_readings_unit.sql)
- [update_function_gupdate_reading_viewset_3d_readings.sql](./sqlScripts/implementation/update_reading_views.sql)
- [drop_legacy_reading_views.sql](./sqlScripts/implementation/drop_legacy_reading_views.sql)
- [CompareHourlyReadings.sql](./sqlScripts/compare/CompareHourlyReadings.sql)
- [CompareDailyReadings.sql](./sqlScripts/compare/CompareDailyReadings.sql)
- [CompareGroupHourlyReadings.sql](./sqlScripts/compare/CompareGroupHourlyReadings.sql)
- [CompareGroupDailyReadings.sql](./sqlScripts/compare/CompareGroupDailyReadings.sql)

## Application

```
TimeScaleDB/Reading.js
```

Responsible for:

- object creation
- refresh workflow
- rebuild workflow
- integration with database setup

# 11. Known Limitations

The migration is complete but several areas remain for future optimization.

The current daily aggregate still processes the hourly split hypertable directly rather than rolling up hourly aggregate state.

Full hypertable rebuilds are still used more frequently than necessary.

Group cache tables are refreshed during every refresh cycle regardless of whether metadata has changed.

No explicit chunk interval has been configured.

Historical data compression has not yet been evaluated.

# 12. Future Work and Optimization Opportunities

## 12.1 Batch Reading Ingestion

The current implementation inserts readings sequentially.

Each inserted row triggers the hourly splitting logic independently.

The trigger performs joins against conversion tables and generates hourly slices using `generate_series()`.

Future work should investigate:

- multi-row INSERT statements
- COPY ingestion
- statement-level triggers using transition tables
- set-based generation of hourly slices

These approaches would significantly reduce ingestion overhead.

## 12.2 Avoid Full Hypertable Rebuilds

The refresh workflow currently rebuilds the entire split hypertable whenever no refresh window is supplied.

This process:

- deletes every split row
- regenerates every split row
- refreshes every continuous aggregate

Normal reading imports already maintain the hypertable through triggers.

Full rebuilds should therefore be reserved for:

- conversion changes
- meter-unit changes

Ordinary refreshes should instead use bounded refresh windows or TimescaleDB refresh policies. I initially thought that making unbounded refreshes was inexpensive, but after carefully reviewing the TimeScaleDB document, as the buckets count increases, the surface area of checks increases. This is an opportunity that could be further investigated. For more details, links to useful resources are in the "Recommended References and Further Reading" section below.

## 12.3 Build Daily Aggregates from Hourly Aggregates

The current daily aggregate still processes the hourly split hypertable directly.

A true hierarchical implementation would expose rollup state from the hourly aggregate including:

- weighted sums
- durations
- minimum values
- maximum values

Daily aggregation could then process significantly fewer rows while maintaining correctness. For more information see section 4.3 above, under hypertable_hourly_split.

## 12.4 Improve Time Predicate Efficiency

Several graph functions create temporary `tsrange` values when filtering buckets.

Direct comparisons against the bucket timestamp are more likely to enable:

- chunk pruning
- index range scans

Some queries also call `time_bucket()` on values that are already bucketed.

Removing this unnecessary computation should improve query performance.

## 12.5 Refresh Group Dependency Caches Only When Required

Group cache tables are refreshed during every aggregate refresh.

Normal reading imports do not modify (this needs verification and further research):

- group membership
- conversion compatibility
- meter metadata

Cache refreshes should therefore occur only when metadata changes.

The cache refresh procedures also recompute identical recursive queries multiple times.

Materializing these intermediate results once would reduce unnecessary work.

Additional indexes such as:

```
(meter_id, group_id)
```

should also be benchmarked.

## 12.6 Optimize Conversion Lookups

The ingestion trigger repeatedly searches the conversion table using overlapping time ranges.

The existing primary key is not optimized for this access pattern.

Future benchmarking should evaluate:

- B-tree indexes
- GiST indexes
- range indexes

to improve ingestion performance.

## 12.7 Tune Chunk Size and Historical Storage

The split hypertable currently uses TimescaleDB's default chunk interval.

Future work should determine an optimal chunk size based on:

- ingestion rate
- available memory
- workload characteristics

Historical chunks may also benefit from TimescaleDB columnstore compression once frequent rebuilds are eliminated.

## 12.8 Additional Benchmarking

Several optimizations remain worth investigating.

These include:

- composite continuous aggregate indexes
- materialized_only=true
- precomputed weighted values
- precomputed durations
- larger datasets
- higher-frequency readings
- additional meters
- production-scale workloads

# 13. Lessons Learned

## Continuous Aggregates Require Careful Dependency Planning

Objects used by continuous aggregates cannot depend upon:

- recursive views
- runtime helper functions
- dynamic calculations

Required metadata should be materialized before aggregation.

---

## Hierarchical Aggregation Improves Scalability

Building:

```
hypertable_hourly_split
   │
Hourly
   │
Daily
```

is substantially more efficient than repeatedly aggregating directly from raw data since some expensive calculations are done when the meter reading data is inserted in the readings table.

---

## Correctness Must Be Verified

Performance improvements are only valuable if analytical correctness is preserved.

Every aggregate created during this project was validated against the legacy implementation before benchmarking.

# 14. Acknowledgements

@MartinCSUMB contributed the initial work integrating the group views and provided an important foundation for the final group aggregation implementation.

@huss provided valuable guidance throughout testing, validation, benchmarking, and verification of the implementation.

Their support along with all the previous contributors to OED helped ensure both analytical correctness and significant performance improvements.

# 15. Current Status

The TimescaleDB migration has been:

- implemented
- benchmarked
- validated
- integrated into the application

Current status:

- Correctness: Passed
- Performance: Significantly improved
- Testing: Complete
- Integration: Complete

The project is considered feature complete and ready for future development.

Future contributors should use this document as the primary technical reference when extending, optimizing, or maintaining the TimescaleDB aggregation workflow.

# Recommended References and Further Reading

The following TimescaleDB documentation references provide additional background and guidance for future contributors working on optimization, maintenance, and further development of the aggregation architecture.

## Data Ingestion Optimization

TimescaleDB recommends using multi-row inserts or bulk loading methods such as COPY instead of inserting rows individually. Batch ingestion reduces transaction overhead and improves write performance, particularly for high-volume time-series workloads.

Reference:

https://www.tigerdata.com/docs/build/data-management/write-data/insert

Caption:

TimescaleDB documentation describing recommended approaches for efficient data ingestion, including multi-row INSERT operations and COPY-based loading.

## Continuous Aggregate Refresh Policies

Continuous aggregates should generally use bounded refresh windows or scheduled refresh policies rather than repeatedly performing open-ended full refreshes.

This is particularly relevant to this project because full rebuilds currently regenerate the entire hourly split hypertable and refresh all dependent continuous aggregates.

Reference:

https://www.tigerdata.com/docs/build/continuous-aggregates/refresh-policies

Caption:

TimescaleDB documentation explaining continuous aggregate refresh policies and recommended approaches for managing incremental materialization.

## Hypertable Query Performance and Chunk Pruning

Efficient time filtering is important for TimescaleDB hypertables because queries should allow TimescaleDB to exclude unnecessary chunks.

Future query optimization should ensure that time predicates directly constrain the hypertable time column whenever possible.

Reference:

https://www.tigerdata.com/docs/build/performance-optimization/secondary-indexes

Caption:

TimescaleDB documentation covering query performance optimization, indexing strategies, and efficient access patterns for hypertables.

## Hierarchical Continuous Aggregates

The current architecture uses layered aggregation. Future improvements should consider building daily aggregates from hourly aggregate states rather than recalculating from hourly split data.

When implementing hierarchical continuous aggregates, aggregate states must be designed carefully. For example, averages cannot simply be averaged again because this can produce incorrect results.

Reference:

https://www.tigerdata.com/docs/learn/continuous-aggregates/hierarchical-continuous-aggregates

Caption:

TimescaleDB documentation describing hierarchical continuous aggregates and techniques for building multi-level aggregation pipelines.

## Continuous Aggregate Limitations with Joined Tables

Group aggregation relies on cached dependency tables because continuous aggregates have limitations when tracking changes in joined tables.

Future contributors should consider these limitations when modifying group membership, metadata dependencies, or refresh workflows.

Reference:

https://www.tigerdata.com/docs/learn/continuous-aggregates

Caption:

TimescaleDB documentation explaining continuous aggregate behaviour, limitations, and considerations when using joins.

## Hypertable Chunk Sizing

The current implementation relies on TimescaleDB default chunk sizing.

Future optimization should evaluate explicit chunk intervals based on actual ingestion volume, memory availability, and query patterns.

Reference:

https://www.tigerdata.com/docs/learn/hypertables/understand-hypertables

Caption:

TimescaleDB documentation explaining hypertables, chunk sizing, and storage management considerations.

## Continuous Aggregate Indexing

Future benchmarking should evaluate additional composite indexes on continuous aggregates.

Potential candidates include:

- (meter_id, graphic_unit_id, bucket)
- (group_id, graphic_unit_id, bucket)

The optimal indexing strategy should be determined through workload benchmarking.

Reference:

https://www.tigerdata.com/docs/build/continuous-aggregates/create-index

Caption:

TimescaleDB documentation describing indexing strategies for continuous aggregates.

---

## Real-Time Aggregates

All continuous aggregates currently use real-time aggregation behaviour.

Future benchmarking should compare real-time aggregates against materialized-only queries to determine whether disabling real-time aggregation improves predictability and performance.

Reference:

https://www.tigerdata.com/docs/learn/continuous-aggregates/real-time-aggregates

Caption:

TimescaleDB documentation explaining real-time continuous aggregates and the relationship between materialized data and recent raw data.

---

## Summary

These references should be considered starting points for future optimization work. The current migration has established the TimescaleDB architecture, but additional improvements may be achieved through:

- Optimized batch ingestion.
- Improved refresh strategies.
- Better chunk and index tuning.
- Hierarchical aggregate design.
- Reduced unnecessary rebuild operations.
- Improved monitoring of continuous aggregate performance.
