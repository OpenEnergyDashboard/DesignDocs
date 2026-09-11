# TimescaleDB Meter Reading Aggregation Handover

## Document status

This document describes the implementation on branch `timeVary2026Summer` at
commit `1c08fb95c` on 2026-08-02. Treat the code and SQL linked below as the
source of truth if the branch advances after this handover.

The TimescaleDB implementation is the active schema and query path for fresh
databases. It includes raw-reading ingestion, an incrementally maintained split
hypertable, four continuous aggregates, group dependency caches, bounded
refreshes, revision-driven rebuilds, and Timescale-backed line, bar, compare,
radar, and 3-D queries.

The implementation is not deployment-complete for existing databases. The
current migration registry does not register the TimescaleDB migration work.
Do not assume that running `npm run migratedb` upgrades an existing production
database to the schema described here.

The development database image is pinned in
[`containers/database/Dockerfile`](containers/database/Dockerfile) to:

```text
timescale/timescaledb:2.27.2-pg17
```

## Current status

Implemented:

- TimescaleDB hypertable preprocessing for raw readings.
- Splitting at both hour boundaries and time-varying conversion boundaries.
- Hourly and daily meter continuous aggregates.
- Hourly and daily group continuous aggregates.
- Physical group membership and graphic-unit compatibility caches.
- Batched raw-reading inserts and upserts.
- Bounded refreshes for CSV and eGauge imports.
- Advisory locking around aggregate refresh and rebuild operations.
- Revision counters for stale split data and stale group caches.
- Set-based meter line queries and multi-meter reading counts.
- Set-based group listing and group-child queries.
- Preloaded conversion metadata during `cik_vary` regeneration.
- Supporting indexes for reading bounds, group relationships, group caches,
  CAGG access, conversion overlap, and log retrieval.

Not complete:

- A registered migration for installing or upgrading these objects in an
  existing database.
- Removal of retained legacy PostgreSQL materialized-view code and SQL.
- Statement-level split-table maintenance for bulk reading writes.
- TimescaleDB chunk, compression/columnstore, retention, and refresh policies.
- Production-scale benchmarks for the current implementation.
- A hierarchical daily meter aggregate.
- Incremental group-cache recomputation.

## Architecture

### Meter data flow

```text
readings
   |
   | AFTER INSERT/UPDATE/DELETE, FOR EACH ROW
   v
hypertable_hourly_split
   |
   +-------------------------------+
   |                               |
   v                               v
meter_hourly_readings_unit_cagg    meter_daily_readings_unit_cagg
```

Both meter aggregates read `hypertable_hourly_split` directly. The daily meter
aggregate does not roll up the hourly meter aggregate.

Each split row is bounded by:

- The source reading interval.
- An hour boundary.
- The active `cik_vary` conversion interval.

The split table copies the unit representation, seconds-in-rate, slope,
intercept, and destination graphic unit needed by downstream aggregation.

### Group data flow

```text
groups_immediate_children       groups_immediate_meters
             |                           |
             +-------------+-------------+
                           |
                           v
              groups_deep_meters_cache
                           |
                           v
              group_graphic_units_cache

meter_hourly_readings_unit_cagg + dependency caches
                           |
                           v
             group_hourly_readings_unit_cagg

meter_daily_readings_unit_cagg + dependency caches
                           |
                           v
             group_daily_readings_unit_cagg
```

The physical caches exist because TimescaleDB continuous aggregates cannot use
the recursive and dynamic dependency logic that previously resolved nested
groups and compatible graphic units at query time.

## Core database objects

| Object | Type | Purpose |
|---|---|---|
| `readings` | PostgreSQL table | Authoritative raw meter readings |
| `hypertable_hourly_split` | TimescaleDB hypertable | Hour- and conversion-bounded reading contributions with copied conversion metadata |
| `meter_hourly_readings_unit_cagg` | Continuous aggregate | Duration-weighted meter rates by hour and graphic unit |
| `meter_daily_readings_unit_cagg` | Continuous aggregate | Duration-weighted meter rates by day and graphic unit |
| `groups_deep_meters_cache` | PostgreSQL table | Flattened group-to-meter membership |
| `group_graphic_units_cache` | PostgreSQL table | Graphic units compatible with every source unit in a group |
| `group_hourly_readings_unit_cagg` | Continuous aggregate | Summed group rates by hour and graphic unit |
| `group_daily_readings_unit_cagg` | Continuous aggregate | Summed group rates by day and graphic unit |
| `reading_aggregate_state` | PostgreSQL table | Split-rebuild and group-cache revision counters |

Primary definitions:

- [`create_prerequisites.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/create_prerequisites.sql)
- [`create_hourly_readings.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/create_hourly_readings.sql)
- [`create_daily_readings.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/create_daily_readings.sql)
- [`create_group_dependencies.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/create_group_dependencies.sql)
- [`create_group_hourly_readings.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/create_group_hourly_readings.sql)
- [`create_group_daily_readings.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/create_group_daily_readings.sql)

## Reading ingestion

### Application batching

[`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/Reading.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/Reading.js) writes readings
in transactional batches of 1,000 through `jsonb_to_recordset`.

Current conflict behavior:

- `insertAll()` fails on an existing `(meter_id, start_timestamp)` key.
- `insertOrIgnoreAll()` retains the existing row.
- `insertOrUpdateAll()` updates only `reading`.
- Duplicate upsert keys in one input retain the first end timestamp and final
  reading value, matching the former sequential behavior.

Batching reduces application/database round trips. It does not remove the
per-reading trigger cost.

### Split-table trigger

`trigger_readings_update_hourly_hypertable` calls
`update_hourly_hypertable()` once per changed reading.

- `INSERT` generates all hour/conversion overlap slices.
- `UPDATE` deletes slices for the old reading interval and regenerates them.
- `DELETE` deletes slices belonging to the removed reading interval.

The trigger joins the meter to its unit, finds overlapping `cik_vary` rows,
generates touched hours, intersects all boundaries, and inserts only positive
duration slices.

Because conversion and unit metadata are copied, source metadata changes can
make existing split rows stale. Revision-driven rebuilding addresses this.

## Time-varying conversion lifecycle

[`redoCik.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/graph/redoCik.js) performs:

1. Build the unit conversion graph.
2. Process suffix units.
3. Generate time-aligned conversion paths.
4. Replace `cik_vary` set-wise.
5. Rebuild the non-time-varying `cik` pairs from `cik_vary`.
6. Increment split-rebuild and group-cache revisions.

Conversion regeneration now loads units, conversions, and all conversion
segments once before traversing source/destination paths. It performs five
metadata queries regardless of path count instead of querying conversion
segments inside every path edge. Relevant files:

- [`createConversionArrays.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/graph/createConversionArrays.js)
- [`timeVaryingPathConversion.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/graph/timeVaryingPathConversion.js)
- [`ConversionSegment.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/ConversionSegment.js)
- [`CikVary.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/CikVary.js)

`CikVary.insert()` marks derived data stale but does not rebuild it itself. A
later `refreshAllReadingViews()` detects the revision and rebuilds. The normal
client conversion workflow requests both conversion regeneration and reading
refresh, but an API caller can request them separately and leave a rebuild
pending intentionally.

## Continuous aggregates

### Meter hourly

`meter_hourly_readings_unit_cagg` groups split rows by meter, graphic unit,
hour, unit representation, and seconds-in-rate. It computes duration-weighted
`reading_rate`, `min_rate`, and `max_rate`.

### Meter daily

`meter_daily_readings_unit_cagg` groups the split hypertable directly into day
buckets. It is a sibling of the hourly meter aggregate, not a child of it.

Do not replace the weighted calculation with an average of hourly averages. A
correct hierarchical design must carry weighted sums and durations as well as
minimum and maximum state, including partial-hour behavior.

### Group hourly and daily

The group aggregates join the matching meter resolution to
`groups_deep_meters_cache` and `group_graphic_units_cache`, then sum compatible
meter rates:

- Group hourly reads meter hourly.
- Group daily reads meter daily.

Relational cache changes are not native continuous-aggregate invalidations,
so the application refreshes dirty caches before refreshing group aggregates.

### Real-time mode

All four continuous aggregates currently use:

```sql
timescaledb.materialized_only = false
```

Queries can include recent unmaterialized source data. This improves freshness
but adds query-time work. Do not change to materialized-only mode until every
write path has reliable refresh coverage.

## Refresh and rebuild orchestration

The main entry point is
[`refreshAllReadingViews.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/refreshAllReadingViews.js).
It holds PostgreSQL advisory lock `724536221` so application refreshers do not
refresh the same aggregates concurrently.

### Normal refresh

When no rebuild is pending:

1. Refresh meter hourly.
2. Refresh meter daily.
3. Refresh group caches only if their revision is dirty.
4. Refresh group hourly.
5. Refresh group daily.

Bounded refreshes expand timestamps to full UTC bucket boundaries:

- Meter/group hourly use hour boundaries.
- Meter/group daily use day boundaries.

Passing neither bound refreshes all materialized ranges. Passing only one
bound throws an error.

### Full rebuild

A rebuild runs when either:

- The caller passes `{ rebuild: true }`.
- `rebuild_revision > completed_rebuild_revision`.

`rebuild_hourly_hypertable_split()` deletes and regenerates the entire split
hypertable from raw readings and current conversion/unit metadata. All four
continuous aggregates are then refreshed without bounds.

The refresher records only the revision observed before work began. A newer
concurrent source change remains pending.

### Rebuild invalidation

| Source change | Split rebuild | Group-cache refresh |
|---|---:|---:|
| `meters.unit_id` changes | Yes | Yes |
| `units.unit_represent` changes | Yes | No |
| `units.sec_in_rate` changes | Yes | No |
| `cik`/`cik_vary` replacement | Yes | Yes |
| Group hierarchy changes | No | Yes |
| Direct group-meter changes | No | Yes |

### Import behavior

- CSV reading upload supplies its accepted range when refresh is requested.
- eGauge combines successful meter ranges and performs one bounded refresh.
- MAMAC acquisition does not refresh directly; deployment cron scripts run an
  independent, currently unbounded refresh.
- Ordinary raw-reading imports do not recompute group dependency caches unless
  their revision is dirty.

## Commands and state inspection

```bash
# Refresh CAGGs; a pending revision still causes an automatic full rebuild.
npm run refreshAllReadingViews

# Force split regeneration and refresh every aggregate.
npm run rebuildAllReadingViews

# Recalculate cik/cik_vary, then rebuild dependent reading data.
npm run updateCikAndViews
```

Inspect pending work:

```sql
SELECT
    rebuild_revision,
    completed_rebuild_revision,
    group_cache_revision,
    completed_group_cache_revision
FROM reading_aggregate_state
WHERE id = 1;
```

Pending conditions:

```text
rebuild_revision > completed_rebuild_revision
group_cache_revision > completed_group_cache_revision
```

Do not manually advance completed revisions unless repairing a verified state
problem.

## Query integration and current performance work

Active graph functions are installed from:

- [`update_meter_line_readings_unit.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/update_meter_line_readings_unit.sql)
- [`update_group_line_readings_unit.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/update_group_line_readings_unit.sql)
- [`update_meter_group_bar.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/update_meter_group_bar.sql)
- [`update_function_get_compare_readings.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/update_function_get_compare_readings.sql)
- [`update_function_get_3d_readings.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/update_function_get_3d_readings.sql)

Implemented optimizations include:

- Set-based requested-meter processing in the meter line function.
- Direct bucket predicates for index use and chunk pruning.
- Indexed first-start and last-end lookups instead of full-history scans.
- Set-based multi-meter count queries.
- Batched raw-reading and `cik_vary` writes.
- Preloaded conversion metadata during conversion-path generation.
- Set-based `/api/groups` retrieval of all groups and deep meters.
- Independent aggregation of immediate group and meter children, avoiding a
  child-meter by child-group Cartesian intermediate result.
- Reverse-key relationship indexes for parent lookups, recursive maintenance,
  and foreign-key checks.
- `EXISTS` rather than `COUNT(*)` for group cycle detection.
- Time-first log indexing for bounded, ordered log retrieval.

A synthetic comparison of the immediate-child query with 100 groups, each
having 100 meter and 100 group children, reduced execution from approximately
510 ms to 9.6 ms in the local container. This is development evidence, not a
production benchmark.

## Important indexes

| Index | Purpose |
|---|---|
| `readings` primary key `(meter_id, start_timestamp)` | Writes, raw range access, first-reading lookup |
| `readings_meter_end_timestamp_idx` | Latest reading-end lookup |
| `hypertable_hourly_split_meter_graphic_time_idx` | Meter/graphic-unit/time access |
| `hypertable_hourly_split_meter_time_idx` | Split uniqueness and maintenance |
| `cik_vary_source_time_idx` | Trigger lookup by source and overlapping interval |
| `groups_deep_meters_cache` primary key | Group-to-meter cache access |
| `groups_deep_meters_cache_meter_group_idx` | Meter-to-group aggregate joins |
| `groups_immediate_children_child_parent_idx` | Reverse group relationship lookup |
| `meters_immediate_children_child_parent_idx` | Reverse meter relationship lookup |
| `groups_immediate_meters_meter_group_idx` | Reverse group-meter lookup |
| Meter CAGG meter/graphic/bucket indexes | Meter graph range scans |
| Group CAGG group/graphic/bucket indexes | Group graph range scans |

Check representative `EXPLAIN (ANALYZE, BUFFERS)` plans before adding more
indexes; each additional index increases write and maintenance cost.

## Schema creation and deployment gap

Fresh-schema creation in
[`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/database.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/database.js) installs
objects in this order:

1. Shared reading helper functions.
2. Split hypertable, indexes, state, and triggers.
3. Group dependency caches.
4. Meter hourly CAGG.
5. Meter daily CAGG.
6. Group hourly CAGG.
7. Group daily CAGG.
8. Meter and group line functions.
9. Bar functions.
10. Compare functions.
11. 3-D functions.

`CREATE ... IF NOT EXISTS` makes parts of fresh setup rerunnable, but it does
not replace an existing continuous aggregate definition.

Critical deployment issue:

- [`registerMigration.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/migrations/registerMigration.js)
  currently requires a nonexistent `1.0.0-1.1.0` migration, so loading the
  migration registry is expected to fail before migration begins.
- The repository contains `1.0.0-2.0.0` and `2.0.0-3.0.0` directories, but
  neither is registered.
- A `2.0.0-3.0.0` directory exists but is not registered and does not install
  the complete current TimescaleDB schema.
- `package.json` still reports application version `1.0.0`.

Before production rollout, define the supported source version, create and
register a migration that installs or replaces every required object in a safe
dependency order, test it on a production-like copy, and document rollback or
recovery behavior.

## Testing and validation

Relevant coverage exists in:

- [`readingTests.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/db/readingTests.js)
- [`unitReadingsTests.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/db/unitReadingsTests.js)
- [`compareTests.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/db/compareTests.js)
- [`cikVaryTests.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/db/cikVaryTests.js)
- [`groupTests.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/db/groupTests.js)
- Reading API suites under [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/web`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/web)

Example focused commands:

```bash
docker compose exec -T web npm run testsome -- \
  --timeout 30000 https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/db/cikVaryTests.js

docker compose exec -T web npm run testsome -- \
  --timeout 30000 https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/test/web/readingsLineGroupQuantity.js
```

Do not carry forward old pass counts or benchmark ratios as current evidence.
The current review confirmed the focused `cik_vary` segment integration case,
reverse bidirectional conversion behavior, schema creation for the new indexes,
and the set-based group model query. The full database and web suites were not
revalidated as part of this document update.

## Legacy and possible obsolete code

The active fresh-schema path no longer creates legacy reading materialized
views, but compatibility code remains:

- Deprecated helpers in [`Reading.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/Reading.js).
- Commented legacy setup and refresh calls.
- [`drop_legacy_reading_views.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB/drop_legacy_reading_views.sql),
  whose schema-creation call remains disabled.
- Older SQL definitions retained for migration history and compatibility.

Recent TODO markers identify code that appears unused, duplicated, superseded,
or broken but may have external consumers. These include the `currentDB`
accessor, an unreferenced `CikVary` point-in-time lookup, obsolete group null
cleanup, duplicate group SQL, and unused single-row CIK SQL. Research external
and downstream use before removal.

## Known risks and next priorities

### 1. Build the deployment migration

This is the highest-priority release blocker. Fresh database success does not
prove an existing installation can be upgraded safely.

### 2. Replace row-level split maintenance

Bulk inserts still invoke conversion joins and `generate_series()` once per
reading. Evaluate statement-level transition-table triggers or an explicit
bulk split-generation path for INSERT, UPDATE, and DELETE.

### 3. Fix suffix-unit asynchronous cleanup

`removeAdditionalConversionsAndUnits()` uses `forEach(async ...)`, so the
function can return before conversion deletion and destination-unit updates
finish. Research and replace it with awaited set-based work or an awaited loop
before relying on conversion refresh ordering.

### 4. Reduce conversion graph CPU work

Database N+1 queries have been removed, but shortest-path search is still run
for each meter-unit/destination pair. One traversal per source or cached path
trees may reduce CPU for large unit graphs.

### 5. Tune group cache maintenance

Any dirty group revision currently recomputes the desired contents of both
group caches globally. Track affected groups if production group graphs make
this expensive.

### 6. Evaluate a hierarchical daily aggregate

Daily currently scans split rows directly. Any hierarchical replacement must
preserve weighted sums, durations, minimums, maximums, conversion boundaries,
and partial-hour behavior.

### 7. Tune remaining graph functions

Use production-like plans to evaluate:

- Set-based 3-D meter processing.
- First/last bucket lookup in 3-D and bar helpers.
- Combined current/previous compare scans.
- Direct bucketing in place of compatible `generate_series()` joins.

### 8. Configure TimescaleDB operational policies

No explicit chunk interval, compression/columnstore policy, retention policy,
or CAGG refresh policy is installed. Base these settings on real ingestion
volume, late data, query windows, storage limits, and TimescaleDB version.

### 9. Limit import concurrency

Meter polling uses parallel network requests and database writes. A large fleet
can pressure the connection pool and per-row split trigger. Evaluate a
configurable concurrency limit.

## Safe maintenance guidance

- Prefer bounded refreshes after ordinary reading imports.
- Force a rebuild only for stale copied metadata, explicit recovery, or a
  verified need.
- Preserve meter-before-group refresh ordering.
- Refresh dirty group caches before group aggregates.
- Do not average already averaged rates without carrying their weights.
- Preserve conversion-boundary splitting when changing ingestion.
- Do not manually advance revision counters casually.
- Test inserts, upserts, deletes, backfills, conversion changes, partial
  buckets, empty groups, nested groups, repeated meters, and missing readings.
- Test migrations on a production-like database rather than only fresh schema
  creation.

## File map

### Orchestration and models

- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/database.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/database.js): schema creation order.
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/TimeScaleDB/Reading.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/TimeScaleDB/Reading.js): CAGG creation and bounded refresh methods.
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/refreshAllReadingViews.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/refreshAllReadingViews.js): advisory lock and rebuild selection.
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/Reading.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/Reading.js): batched writes and graph-query wrappers.
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/CikVary.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/CikVary.js): set-based conversion replacement and revision invalidation.
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/graph`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/graph): graph creation and time-varying path generation.
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/Group.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/models/Group.js): group/cache queries.

### Import paths

- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/routes/csv.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/routes/csv.js): optional bounded refresh after CSV upload.
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/eGauge/updateEgaugeMeters.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/eGauge/updateEgaugeMeters.js): combined bounded refresh.
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/updateMamacMeters.js`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/services/updateMamacMeters.js): acquisition without direct refresh.

### SQL

- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/create_readings_table.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/create_readings_table.sql)
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/reading/TimeScaleDB)
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/group/create_groups_tables.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/group/create_groups_tables.sql)
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/group/get_all_children.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/group/get_all_children.sql)
- [`https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/group/get_all_groups_with_deep_meters.sql`](https://github.com/OpenEnergyDashboard/OED/tree/timeVary/src/server/sql/group/get_all_groups_with_deep_meters.sql)

## Summary

The branch has an integrated TimescaleDB implementation for fresh databases:
raw readings feed an hour- and conversion-aware split hypertable, four
real-time continuous aggregates serve meter and group queries, revision
counters coordinate derived-data maintenance, and recent work removed several
high-cardinality database round trips.

The primary handoff concern is release engineering, not basic architecture:
the current migration registry cannot install this complete schema into an
existing deployment. Address migration coverage, then benchmark the per-row
split trigger and operational TimescaleDB settings with production-like data.
