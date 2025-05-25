# Analyze and optimize postgreSQL queries

This is a work in progress that began in October 2024. It is anticipated that more information and results will be added as the work progresses.

## Introduction

OED's stated goal is for any standard request (some complex admin ones may be slower) to show the result to the user in one second or less. Assuming a fast network (OED minimizes the quantity of data returned so the bandwidth is normally not an issue) and web browser response, the server needs to respond in hundreds of ms. From a practical standpoint, this means postgres must respond in that amount of time. OED has already worked to met these targets through materialized views for readings but it has not systematically analyzed database usage to optimize response times.

The goal is to focus on the requests that take the most time and are commonly used. The common requests are for graphing readings so those are the first ones to consider. While an analysis is needed of the time take for all requests, it is known that some types take more time than others:

- 3D, esp. for more than 1 hour/point.
- Bar for a small number of days.
- A group is generally slower than a meter because groups sum meters to get the result.

Some queries use the same basic data sources so optimizing the primary one should optimize the others:

- Radar uses the line data.
- Compare line is two separate line data requests.
- Map uses the bar data but only looks at the last value.

Initially, the goal is to analyze and determine which requests are slow and then try to optimize them to run faster. Ultimately, all the main requests can be analyzed and optimized. While the focus is on the postgres time, checking the full time from request to response in the web browser is also valuable and may be easier to identify the best requests to focus on.

## Action items

## 3D

Sections below show that the 3D queries are running slower than desired. @simonbtomlinson looked at this and provided the following analysis. These ideas should be implemented within OED and then the speedup should be checked. It is possible that the special case for one hour per 3D reading could be removed after this is done. Once this is complete, other queries that use generate_series should be examined to see if this would also apply and be valuable.

### Analysis of 3D

The first thing that stood out to me in the plan was the sequential scan on hourly_readings_unit. We aren't using any index on that table, so for every point on the graph, we have to scan the entire thing. In general when I see a seq scan it's probably a mistake unless the table only has a few hundred rows.

hourly_readings_unit is a materialized view, so we can add indexes on it. I suggest an index on (meter_id, lower(time_interval)).

With this index the query runtime is roughly halved. This makes postgres quickly look up the relevant start of rows, but then it scans to the end of the index to look for more since we don't know how many will be needed. So on average it scans half the table each time - halving the runtime. 

If we add a little extra to the query though, postgres will know when to stop scanning the index. We can use the fact that if the start of the hourly_readings_unit range is outside of the currently being collected interval, it can't possibly match. So we just add  AND lower(hr.time_interval) <= hours.hour + reading_length_interval to the query. With this the query runs for me in 15ms.

```text
                                                                                        QUERY PLAN                                                
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=37528.04..37528.54 rows=200 width=28) (actual time=14.186..14.376 rows=2160 loops=1)
   Sort Key: hours.hour
   Sort Method: quicksort  Memory: 198kB
   Buffers: shared hit=9297
   ->  HashAggregate  (cost=37516.39..37520.39 rows=200 width=28) (actual time=13.091..13.569 rows=2160 loops=1)
         Group Key: hours.hour
         Batches: 1  Memory Usage: 641kB
         Buffers: shared hit=9297
         ->  Nested Loop  (cost=0.42..35917.50 rows=319778 width=20) (actual time=0.239..10.638 rows=8640 loops=1)
               Buffers: shared hit=9297
               ->  Function Scan on generate_series hours  (cost=0.00..10.00 rows=1000 width=8) (actual time=0.214..0.441 rows=2160 loops=1)
               ->  Index Scan using hourly_readings_unit_meter_id_lower_idx on hourly_readings_unit hr  (cost=0.42..32.71 rows=320 width=34) (actual time=0.002..0.004 rows=4 loops=2160)
                     Index Cond: ((meter_id = 4) AND (lower(time_interval) >= hours.hour) AND (lower(time_interval) <= (hours.hour + '04:00:00'::interval)))
                     Filter: (upper(time_interval) <= (hours.hour + '04:00:00'::interval))
                     Rows Removed by Filter: 1
                     Buffers: shared hit=9297
 Planning Time: 0.230 ms
 Execution Time: 14.611 ms
(18 rows)
```

Here's my query, with all the constants from the function hardcoded so I didn't need to run the full function.

```sql
explain (analyze, buffers) SELECT hr.meter_id AS meter_id,
       AVG(hr.reading_rate) * 1 + 0 AS reading_rate,
       hours.hour AS start_timestamp,
       hours.hour + interval '4 hours' AS end_timestamp
FROM (
  SELECT hour
  FROM generate_series(lower('[2020-01-01, 2020-12-26]'::tsrange), upper('[2020-01-01, 2020-12-26]'::tsrange) - interval '4 hours', interval '4 hours') hours(hour)
) hours(hour),
hourly_readings_unit hr
WHERE hr.meter_id = 4
  AND lower(hr.time_interval) >= hours.hour
  AND upper(hr.time_interval) <= hours.hour + interval '4 hours'
  AND lower(hr.time_interval) <= hours.hour + interval '4 hours'
GROUP BY hours.hour, hr.meter_id
ORDER BY hr.meter_id, hours.hour;
```

## Postgres analysis

This will mostly use 3D meter readings to show how the analysis is done. It will also use the standard developer meter of "Sin 15 Min kWh" as the example. Information on the 3D meter reading query can be found in ``src/server/models/Reading.js`` in the function ``getThreeDReadings`` and ``src/server/sql/reading/create_function_get_3d_readings.sql`` in ``meter_3d_readings_unit``.

### Query for readings

To mimic the actual request as best as possible where the ids are provided, the id of the desired meter is found:

```sql
select id from meters where name = 'Sin 15 Min kWh';
```

In this case it returned ``698``. Next, the id for the kWh unit is found:

```sql
select id from units where name = 'kWh';
```

In this case it returned ``42``. Next, the 3D readings for 24 points/day (not the query takes the hours/pt) is:

```sql
SELECT meter_3d_readings_unit (
    meter_ids_requested => '{698}',
    graphic_unit_id => 42,
    start_stamp => '2020-01-01 00:00:00',
    end_stamp => '2020-12-26 00:00:00',
    reading_length_hours => 1
);
```

This returns 8640 rows of readings. The same query can be done without naming the parameters with:

```sql
SELECT meter_3d_readings_unit ('{698}', 42, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 1);
```

Multiple meters could be given as ``'{698, 696}'``. Also, ``'-infinity', 'infinity'`` can be used to readings for all time.

### Analyze performance

The [postgres EXPLAIN](https://www.postgresql.org/docs/current/sql-explain.html) will tell information about how to ran a command.

```sql
EXPLAIN SELECT meter_3d_readings_unit ('{698}', 42, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 1);
```

This gives:

```text
                    QUERY PLAN                    
--------------------------------------------------
 ProjectSet  (cost=0.00..5.27 rows=1000 width=32)
   ->  Result  (cost=0.00..0.01 rows=1 width=0)
(2 rows)
```

To get additional information use:

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit ('{698}', 42, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 1);
```

This gives:

```text
                                           QUERY PLAN                                            
-------------------------------------------------------------------------------------------------
 ProjectSet  (cost=0.00..5.27 rows=1000 width=32) (actual time=26.169..27.287 rows=8640 loops=1)
   Buffers: shared hit=1426
   ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.002..0.003 rows=1 loops=1)
 Planning Time: 0.063 ms
 Execution Time: 27.677 ms
(5 rows)
```

It may be easier to view the result using (https://explain.depesz.com/). Copy the output from explain and submit to get:

![depesz 3D explain result](depesz3DExplainResult.png "depesz 3D explain result")

One can copy the URL to see again/share. In this case it is at (https://explain.depesz.com/s/t9vu).

Changing to 2 hours/point slows it down a lot from 27.677 ms for 1 hour/point to 2266.829 for 2 hours/point or almost two orders of magnitude:

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit ('{698}', 42, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 2);
```

This gives:

```text
                                            QUERY PLAN                                              
-----------------------------------------------------------------------------------------------------
 ProjectSet  (cost=0.00..5.27 rows=1000 width=32) (actual time=2266.236..2266.667 rows=4320 loops=1)
   Buffers: shared hit=1459
   ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.006..0.007 rows=1 loops=1)
 Planning Time: 0.034 ms
 Execution Time: 2266.829 ms
(5 rows)
```

There are other parameters and further analysis to do.

### Line readings

This is an example query for line readings:

```sql
select meter_line_readings_unit('{698, 696}', 42, '-infinity', 'infinity', 'auto', 200, 200);
```

### Running multiple times

There will be variation in the times seen when a query is run multiple times due to variation, DB cache, etc. So far it has not been large but this needs to be tested more.

### DB size

Tests should be run where the total quantity of readings and the readings on the queried meter is greatly increased to see the effect.

## Web Browser Analysis

This uses the same 3D meter described in the previous section for Postgres analysis. The web browser tools are accessed by inspecting the OED web page. These show Firefox results but other web browsers should be similar. The specific request used was for almost the full year of 2020 (ending slightly before Dec. 31).

### Network

This shows the network time for two requests. The first is for 24 readings/day and the second is for 12 readings/day.

![3D network analysis](client3DNetwork.png "3D network analysis")

The first query is for around 360 days at 24 points/day or 172,610 bytes / (360 \* 24) = 20 bytes/point. This is only approximate as there is more than just the points. For the second one of 12 points/day it is 89,300 / (360 \* 12) = 20.7 bytes/point. As expected, this slightly more due to overhead but very similar.

The timings are less important as this is on a development environment where the client and server on on the same machine. (Unsure why only first request as times.)

### Performance

Using the performance tab to record the first request gave:

![3D performance analysis](client3DPerformance.png "3D performance analysis")

There are lots of other options and the absolute speeds will depend on the machine. More analysis of what this means can be done.

## Results

### Summary

Our focus was to analyze queries using PostgresSQL command ANALYZE EXPLAIN and identify performance bottlenecks. 
The meter_3d_readings_unit function is slow and shows performance issues when scaling up hours/point. The performance breakdown seems to be on the database side. 
The meter_bar_readings_unit function performance was acceptable on the database side but there are issues when rendering the graph on the frontend which will require more research. 
Based on our research, the meter_line_readings_unit function does not have issues but further research is still recommended.

### Postgres Setup

```sql
LOAD 'auto_explain'; SET auto_explain.log_min_duration = 0; SET auto_explain.log_analyze = true; SET auto_explain.log_nested_statements = true;
```

Run this in the shell prior to using EXPLAIN ANALYZE. It allows one to view details of nested functions in PostgreSQL logs.

### Query:
```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit ('{21}', 1, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 2);
```

### Resulting Log:

[Clean version in depesz](https://explain.depesz.com/s/rLK2)

```sql
2024-11-14 16:39:09.445 UTC [70] LOG:  duration: 0.036 ms  plan:
  Query Text: SELECT min(reading_frequency) FROM (meters m INNER JOIN unnest(meter_ids_requested) meters(id) ON m.id = meters.id)
  Aggregate  (cost=2.72..2.73 rows=1 width=16) (actual time=0.033..0.035 rows=1 loops=1)
    ->  Hash Join  (cost=0.23..2.70 rows=10 width=16) (actual time=0.026..0.031 rows=1 loops=1)
          Hash Cond: (m.id = meters.id)
          ->  Seq Scan on meters m  (cost=0.00..2.27 rows=27 width=20) (actual time=0.010..0.014 rows=27 loops=1)
          ->  Hash  (cost=0.10..0.10 rows=10 width=4) (actual time=0.008..0.008 rows=1 loops=1)
                Buckets: 1024  Batches: 1  Memory Usage: 9kB
                ->  Function Scan on unnest meters  (cost=0.00..0.10 rows=10 width=4) (actual time=0.005..0.005 rows=1 loops=1)

2024-11-14 16:39:09.445 UTC [70] CONTEXT:  SQL statement "SELECT min(reading_frequency) FROM (meters m INNER JOIN unnest(meter_ids_requested) meters(id) ON m.id = meters.id)"
  PL/pgSQL function meter_3d_readings_unit(integer[], integer, timestamp without time zone, timestamp without time zone, integer) line 1 at SQL statement

2024-11-14 16:39:09.445 UTC [70] LOG:  duration: 0.008 ms  plan:
  Query Text: meter_frequency_hour_up := CEIL((SELECT * FROM EXTRACT(EPOCH FROM meter_frequency)) / 3600)
  Result  (cost=0.01..0.03 rows=1 width=4) (actual time=0.007..0.008 rows=1 loops=1)
    InitPlan 1 (returns $0)
      ->  Function Scan on "extract"  (cost=0.00..0.01 rows=1 width=32) (actual time=0.004..0.004 rows=1 loops=1)

2024-11-14 16:39:09.445 UTC [70] CONTEXT:  PL/pgSQL assignment "meter_frequency_hour_up := CEIL((SELECT * FROM EXTRACT(EPOCH FROM meter_frequency)) / 3600)"
  PL/pgSQL function meter_3d_readings_unit(integer[], integer, timestamp without time zone, timestamp without time zone, integer) line 1 at assignment

2024-11-14 16:39:09.445 UTC [70] LOG:  duration: 0.015 ms  plan:
  Query Text: SELECT c.slope, c.intercept FROM meters m INNER JOIN cik c ON c.source_id = m.unit_id AND c.destination_id = graphic_unit_id WHERE m.id = current_meter_id
  Nested Loop  (cost=0.00..3.84 rows=1 width=16) (actual time=0.013..0.013 rows=1 loops=1)
    Join Filter: (m.unit_id = c.source_id)
    ->  Seq Scan on meters m  (cost=0.00..2.34 rows=1 width=4) (actual time=0.006..0.007 rows=1 loops=1)
          Filter: (id = $17)
          Rows Removed by Filter: 19
    ->  Seq Scan on cik c  (cost=0.00..1.48 rows=2 width=20) (actual time=0.005..0.005 rows=1 loops=1)
          Filter: (destination_id = $2)

2024-11-14 16:39:09.445 UTC [70] CONTEXT:  SQL statement "SELECT c.slope, c.intercept FROM meters m INNER JOIN cik c ON c.source_id = m.unit_id AND c.destination_id = graphic_unit_id WHERE m.id = current_meter_id"
  PL/pgSQL function meter_3d_readings_unit(integer[], integer, timestamp without time zone, timestamp without time zone, integer) line 1 at SQL statement

2024-11-14 16:39:09.446 UTC [70] LOG:  duration: 0.003 ms  plan:
  Query Text: SELECT CASE WHEN ts = date_trunc(interval_precision, ts) THEN ts ELSE date_trunc(interval_precision, ts + ('1 ' || interval_precision)::INTERVAL) END
  Result  (cost=0.00..0.03 rows=1 width=8) (actual time=0.002..0.002 rows=1 loops=1)

2024-11-14 16:39:09.446 UTC [70] CONTEXT:  SQL function "date_trunc_up" statement 1
  PL/pgSQL function meter_3d_readings_unit(integer[], integer, timestamp without time zone, timestamp without time zone, integer) line 1 at assignment

2024-11-14 16:39:09.446 UTC [70] LOG:  duration: 0.387 ms  plan:
  Query Text: SELECT tsrange(min(lower(time_interval)), max(upper(time_interval))) FROM daily_readings_unit WHERE meter_id = meter_id_desired
  Aggregate  (cost=17.26..17.28 rows=1 width=32) (actual time=0.385..0.385 rows=1 loops=1)
    ->  Index Only Scan using idx_daily_readings_unit on daily_readings_unit  (cost=0.15..15.40 rows=186 width=22) (actual time=0.061..0.331 rows=366 loops=1)
          Index Cond: (meter_id = $2)
          Heap Fetches: 0

2024-11-14 16:39:09.446 UTC [70] CONTEXT:  SQL statement "SELECT tsrange(min(lower(time_interval)), max(upper(time_interval))) FROM daily_readings_unit WHERE meter_id = meter_id_desired"
  PL/pgSQL function shrink_tsrange_to_meter_readings_by_day(tsrange, integer) line 1 at SQL statement
  PL/pgSQL function meter_3d_readings_unit(integer[], integer, timestamp without time zone, timestamp without time zone, integer) line 1 at assignment

2024-11-14 16:39:12.133 UTC [70] LOG:  duration: 2687.084 ms  plan:
  Query Text: SELECT hr.meter_id AS meter_id, AVG(hr.reading_rate) * slope + intercept AS reading_rate, hours.hour AS start_timestamp, hours.hour + reading_length_interval AS end_timestamp
  FROM (
    SELECT hour
    FROM generate_series(lower(requested_range), upper(requested_range) - reading_length_interval, reading_length_interval) AS hours(hour)
  ) AS hours(hour), hourly_readings_unit hr
  WHERE hr.meter_id = current_meter_id
    AND lower(hr.time_interval) >= hours.hour
    AND upper(hr.time_interval) <= hours.hour + reading_length_interval
  GROUP BY hours.hour, hr.meter_id
  ORDER BY hr.meter_id, hours.hour

  Finalize GroupAggregate  (cost=174621.47..175362.47 rows=5200 width=28) (actual time=2681.635..2686.613 rows=4320 loops=1)
    Group Key: hr.meter_id, hours.hour
    ->  Gather Merge  (cost=174621.47..175219.47 rows=5200 width=44) (actual time=2681.615..2685.514 rows=4741 loops=1)
          Workers Planned: 1
          Workers Launched: 1
          ->  Sort  (cost=173621.46..173634.46 rows=5200 width=44) (actual time=2667.606..2667.709 rows=2370 loops=2)
                Sort Key: hours.hour
                Sort Method: quicksort  Memory: 339kB
                Worker 0: Sort Method: quicksort  Memory: 335kB
                ->  Partial HashAggregate  (cost=173248.51..173300.51 rows=5200 width=44) (actual time=2666.807..2667.191 rows=2370 loops=2)
                      Group Key: hr.meter_id, hours.hour
                      Batches: 1  Memory Usage: 721kB
                      Worker 0: Batches: 1  Memory Usage: 721kB
                      ->  Nested Loop  (cost=0.00..168968.61 rows=570654 width=20) (actual time=11.196..2661.382 rows=4320 loops=2)
                            Join Filter: ((lower(hr.time_interval) >= hours.hour) AND (upper(hr.time_interval) <= (hours.hour + '02:00:00'::interval)))
                            Rows Removed by Join Filter: 18,969,120
                            ->  Parallel Seq Scan on hourly_readings_unit hr  (cost=0.00..2048.60 rows=5136 width=34) (actual time=10.560..16.968 rows=4392 loops=2)
                                  Filter: (meter_id = 21)
                                  Rows Removed by Filter: 53,585
                            ->  Function Scan on generate_series hours  (cost=0.00..10.00 rows=1000 width=8) (actual time=0.000..0.158 rows=4320 loops=8784)

  JIT:
    Functions: 35
    Options: Inlining false, Optimization false, Expressions true, Deforming true
    Timing: Generation 2.347 ms, Inlining 0.000 ms, Optimization 0.891 ms, Emission 20.336 ms, Total 23.574 ms
```

18,969,120 rows are considered and then filtered out in this query with only 4,320 rows actually being returned.

### Query
```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit ('{21}', 1, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 4);
```

### Resulting Log:

[Clean version in depesz](https://explain.depesz.com/s/KxXNz)

```sql
2024-11-14 19:44:07.728 UTC [70] LOG:  duration: 0.048 ms  plan:
  Query Text: SELECT min(reading_frequency) FROM (meters m INNER JOIN unnest(meter_ids_requested) meters(id) ON m.id = meters.id)
  Aggregate  (cost=2.72..2.73 rows=1 width=16) (actual time=0.045..0.047 rows=1 loops=1)
    ->  Hash Join  (cost=0.23..2.70 rows=10 width=16) (actual time=0.037..0.042 rows=1 loops=1)
          Hash Cond: (m.id = meters.id)
          ->  Seq Scan on meters m  (cost=0.00..2.27 rows=27 width=20) (actual time=0.015..0.020 rows=27 loops=1)
          ->  Hash  (cost=0.10..0.10 rows=10 width=4) (actual time=0.008..0.008 rows=1 loops=1)
                Buckets: 1024  Batches: 1  Memory Usage: 9kB
                ->  Function Scan on unnest meters  (cost=0.00..0.10 rows=10 width=4) (actual time=0.005..0.005 rows=1 loops=1)
2024-11-14 19:44:07.728 UTC [70] CONTEXT:  SQL statement "SELECT min(reading_frequency) FROM (meters m INNER JOIN unnest(meter_ids_requested) meters(id) ON m.id = meters.id)"
  PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at SQL statement
2024-11-14 19:44:07.728 UTC [70] LOG:  duration: 0.011 ms  plan:
  Query Text: meter_frequency_hour_up := CEIL((SELECT * FROM EXTRACT(EPOCH FROM meter_frequency)) / 3600)
  Result  (cost=0.01..0.03 rows=1 width=4) (actual time=0.010..0.011 rows=1 loops=1)
    InitPlan 1 (returns $0)
      ->  Function Scan on "extract"  (cost=0.00..0.01 rows=1 width=32) (actual time=0.005..0.005 rows=1 loops=1)
2024-11-14 19:44:07.728 UTC [70] CONTEXT:  PL/pgSQL assignment "meter_frequency_hour_up := CEIL((SELECT * FROM EXTRACT(EPOCH FROM meter_frequency)) / 3600)"
  PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at assignment
2024-11-14 19:44:07.728 UTC [70] LOG:  duration: 0.015 ms  plan:
  Query Text: SELECT c.slope, c.intercept                       FROM meters m INNER JOIN cik c on c.source_id = m.unit_id AND c.destination_id = graphic_unit_id WHERE m.id = current_meter_id
  Nested Loop  (cost=0.00..3.84 rows=1 width=16) (actual time=0.014..0.015 rows=1 loops=1)
    Join Filter: (m.unit_id = c.source_id)
    ->  Seq Scan on meters m  (cost=0.00..2.34 rows=1 width=4) (actual time=0.006..0.006 rows=1 loops=1)
          Filter: (id = $17)
          Rows Removed by Filter: 19
    ->  Seq Scan on cik c  (cost=0.00..1.48 rows=2 width=20) (actual time=0.006..0.006 rows=1 loops=1)
          Filter: (destination_id = $2)
2024-11-14 19:44:07.728 UTC [70] CONTEXT:  SQL statement "SELECT c.slope, c.intercept FROM meters m INNER JOIN cik c on c.source_id = m.unit_id AND c.destination_id = graphic_unit_id WHERE m.id = current_meter_id"
  PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at SQL statement
2024-11-14 19:44:07.728 UTC [70] LOG:  duration: 0.003 ms  plan:
  Query Text:  SELECT CASE WHEN ts = date_trunc(interval_precision, ts) THEN ts ELSE date_trunc(interval_precision, ts + ('1 ' || interval_precision)::INTERVAL) END
  Result  (cost=0.00..0.03 rows=1 width=8) (actual time=0.002..0.002 rows=1 loops=1)
2024-11-14 19:44:07.728 UTC [70] CONTEXT:  SQL function "date_trunc_up" statement 1
  PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at assignment
2024-11-14 19:44:07.729 UTC [70] LOG:  duration: 0.397 ms  plan:
  Query Text: SELECT tsrange(min(lower(time_interval)), max(upper(time_interval)))                           FROM daily_readings_unit where meter_id = meter_id_desired
  Aggregate  (cost=17.26..17.28 rows=1 width=32) (actual time=0.395..0.395 rows=1 loops=1)
    ->  Index Only Scan using idx_daily_readings_unit on daily_readings_unit  (cost=0.15..15.40 rows=186 width=22) (actual time=0.030..0.327 rows=366 loops=1)
          Index Cond: (meter_id = $2)
          Heap Fetches: 0
2024-11-14 19:44:07.729 UTC [70] CONTEXT:  SQL statement "SELECT tsrange(min(lower(time_interval)), max(upper(time_interval)))                           FROM daily_readings_unit where meter_id = meter_id_desired"
  PL/pgSQL function shrink_tsrange_to_meter_readings_by_day(tsrange,integer) line 1 at SQL statement
  PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at assignment
2024-11-14 19:44:09.487 UTC [70] LOG:  duration: 1757.633 ms  plan:
  Query Text: SELECT hr.meter_id as meter_id, AVG(hr.reading_rate) * slope + intercept as reading_rate, hours.hour AS start_timestamp, hours.hour + reading_length_interval AS end_timestamp FROM ( SELECT hour FROM generate_series( lower(requested_range), upper(requested_range) - reading_length_interval, reading_length_interval ) hours(hour) ) hours(hour), hourly_readings_unit hr WHERE hr.meter_id = current_meter_id AND lower(hr.time_interval) >= hours.hour AND upper(hr.time_interval) <= hours.hour + reading_length_interval GROUP BY hours.hour, hr.meter_id ORDER BY hr.meter_id, hours.hour
  Finalize GroupAggregate  (cost=90887.85..91628.85 rows=5200 width=28) (actual time=1745.627..1757.425 rows=2160 loops=1)
    Group Key: hr.meter_id, hours.hour
    ->  Gather Merge  (cost=90887.85..91485.85 rows=5200 width=44) (actual time=1745.620..1756.601 rows=2766 loops=1)
          Workers Planned: 1
          Workers Launched: 1
          ->  Sort  (cost=89887.84..89900.84 rows=5200 width=44) (actual time=1728.781..1728.853 rows=1383 loops=2)
                Sort Key: hours.hour
                Sort Method: quicksort  Memory: 191kB
                Worker 0:  Sort Method: quicksort  Memory: 187kB
                ->  Partial HashAggregate  (cost=89514.89..89566.89 rows=5200 width=44) (actual time=1728.290..1728.544 rows=1383 loops=2)
                      Group Key: hr.meter_id, hours.hour
                      Batches: 1  Memory Usage: 465kB
                      Worker 0:  Batches: 1  Memory Usage: 465kB
                      ->  Nested Loop  (cost=0.01..87328.61 rows=291504 width=20) (actual time=0.195..1724.431 rows=4320 loops=2)
                            Join Filter: ((lower(hr.time_interval) >= hours.hour) AND (upper(hr.time_interval) <= (hours.hour + $15)))
                            Rows Removed by Join Filter: 9482400
                            ->  Parallel Seq Scan on hourly_readings_unit hr  (cost=0.00..2048.60 rows=2624 width=34) (actual time=0.004..6.878 rows=4392 loops=2)
                                  Filter: (meter_id = $17)
                                  Rows Removed by Filter: 53585
                            ->  Function Scan on generate_series hours  (cost=0.01..10.01 rows=1000 width=8) (actual time=0.000..0.085 rows=2160 loops=8784)
2024-11-14 19:44:09.487 UTC [70] CONTEXT:  SQL statement "SELECT hr.meter_id as meter_id, AVG(hr.reading_rate) * slope + intercept as reading_rate, hours.hour AS start_timestamp, hours.hour + reading_length_interval AS end_timestamp FROM ( SELECT hour FROM generate_series( lower(requested_range), upper(requested_range) - reading_length_interval, reading_length_interval ) hours(hour) ) hours(hour), hourly_readings_unit hr WHERE hr.meter_id = current_meter_id AND lower(hr.time_interval) >= hours.hour AND upper(hr.time_interval) <= hours.hour + reading_length_interval GROUP BY hours.hour, hr.meter_id ORDER BY hr.meter_id, hours.hour"
  PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at RETURN QUERY
2024-11-14 19:44:09.487 UTC [70] LOG:  duration: 1759.328 ms  plan:
  Query Text: EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit ('{21}', 1, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 4);
  ProjectSet  (cost=0.00..5.27 rows=1000 width=32) (actual time=1758.980..1759.250 rows=2160 loops=1)
    ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.001..0.001 rows=1 loops=1)
```

This time 9,482,400 rows are considered with only 2,160 rows actually returned.

### Takeaways

Execution time ballons at the 6th log entry with this subquery:

```sql
SELECT hr.meter_id AS meter_id,
       AVG(hr.reading_rate) * slope + intercept AS reading_rate,
       hours.hour AS start_timestamp,
       hours.hour + reading_length_interval AS end_timestamp
FROM (
  SELECT hour
  FROM generate_series(lower(requested_range), upper(requested_range) - reading_length_interval, reading_length_interval) hours(hour)
) hours(hour),
hourly_readings_unit hr
WHERE hr.meter_id = current_meter_id
  AND lower(hr.time_interval) >= hours.hour
  AND upper(hr.time_interval) <= hours.hour + reading_length_interval
GROUP BY hours.hour, hr.meter_id
ORDER BY hr.meter_id, hours.hour
```

The problematic portion:
```sql
lower(hr.time_interval) >= hours.hour AND
upper(hr.time_interval) <= hours.hour + reading_length_interval
```
- Range comparisons prevent the use of more efficient join algorithms
- Looped cross product produces a lot of rows only to eliminate most of them.
- Has to iterate over every combination of hr and hours to apply the join filter causing high computational cost.

## Improved Query Execution Plan

After the suggestions by @simonbtomlinson were implemented this is the result of looking at the execution. Note the special case for a 3D point every hour was also removed since it did not speed up the code very much. It is noted that the slowdown is gone and everything looks good.

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit ('{21}', 1, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 2);
```

### Resulting Log:
[Clean version in depesz](https://explain.depesz.com/s/FLaJ)

```sql
2025-03-20 05:00:05.728 UTC [390] LOG:  duration: 0.323 ms  plan:
        Query Text: SELECT min(reading_frequency)                      FROM (meters m INNER JOIN unnest(meter_ids_requested) meters(id) ON m.id = meters.id)
        Aggregate  (cost=8.46..8.47 rows=1 width=16) (actual time=0.319..0.320 rows=1 loops=1)
          ->  Nested Loop  (cost=4.15..8.46 rows=1 width=16) (actual time=0.314..0.315 rows=1 loops=1)
                ->  Function Scan on unnest meters  (cost=0.00..0.01 rows=1 width=4) (actual time=0.006..0.006 rows=1 loops=1)
                ->  Bitmap Heap Scan on meters m  (cost=4.15..8.16 rows=1 width=20) (actual time=0.305..0.306 rows=1 loops=1)
                      Recheck Cond: (id = meters.id)
                      Heap Blocks: exact=1
                      ->  Bitmap Index Scan on meters_pkey  (cost=0.00..4.15 rows=1 width=0) (actual time=0.014..0.014 rows=1 loops=1)
                            Index Cond: (id = meters.id)
2025-03-20 05:00:05.728 UTC [390] CONTEXT:  SQL statement "SELECT min(reading_frequency)                      FROM (meters m INNER JOIN unnest(meter_ids_requested) meters(id) ON m.id = meters.id)"
        PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at SQL statement
2025-03-20 05:00:05.729 UTC [390] LOG:  duration: 0.010 ms  plan:
        Query Text: meter_frequency_hour_up := CEIL((SELECT * FROM EXTRACT(EPOCH FROM meter_frequency)) / 3600)
        Result  (cost=0.01..0.03 rows=1 width=4) (actual time=0.006..0.007 rows=1 loops=1)
          InitPlan 1 (returns $0)
            ->  Result  (cost=0.00..0.01 rows=1 width=32) (actual time=0.001..0.001 rows=1 loops=1)
2025-03-20 05:00:05.729 UTC [390] CONTEXT:  PL/pgSQL assignment "meter_frequency_hour_up := CEIL((SELECT * FROM EXTRACT(EPOCH FROM meter_frequency)) / 3600)"
        PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at assignment
2025-03-20 05:00:05.731 UTC [390] LOG:  duration: 0.025 ms  plan:
        Query Text: SELECT c.slope, c.intercept                       FROM meters m INNER JOIN cik c on c.source_id = m.unit_id AND c.destination_id = graphic_unit_id WHERE m.id = current_meter_id
        Nested Loop  (cost=4.15..9.67 rows=1 width=16) (actual time=0.023..0.024 rows=1 loops=1)
          Join Filter: (m.unit_id = c.source_id)
          Rows Removed by Join Filter: 1
          ->  Bitmap Heap Scan on meters m  (cost=4.15..8.16 rows=1 width=4) (actual time=0.008..0.008 rows=1 loops=1)
                Recheck Cond: (id = 21)
                Heap Blocks: exact=1
                ->  Bitmap Index Scan on meters_pkey  (cost=0.00..4.15 rows=1 width=0) (actual time=0.003..0.004 rows=1 loops=1)
                      Index Cond: (id = 21)
          ->  Seq Scan on cik c  (cost=0.00..1.48 rows=3 width=20) (actual time=0.013..0.013 rows=2 loops=1)
                Filter: (destination_id = 1)
                Rows Removed by Filter: 11
2025-03-20 05:00:05.731 UTC [390] CONTEXT:  SQL statement "SELECT c.slope, c.intercept                       FROM meters m INNER JOIN cik c on c.source_id = m.unit_id AND c.destination_id = graphic_unit_id WHERE m.id = current_meter_id"
        PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at SQL statement
2025-03-20 05:00:05.731 UTC [390] LOG:  duration: 0.004 ms  plan:
        Query Text:  SELECT CASE WHEN ts = date_trunc(interval_precision, ts) THEN ts ELSE date_trunc(interval_precision, ts + ('1 ' || interval_precision)::INTERVAL) END 
        Result  (cost=0.00..0.03 rows=1 width=8) (actual time=0.003..0.003 rows=1 loops=1)
2025-03-20 05:00:05.731 UTC [390] CONTEXT:  SQL function "date_trunc_up" statement 1
        PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at assignment
2025-03-20 05:00:05.738 UTC [390] LOG:  duration: 4.157 ms  plan:
        Query Text: SELECT tsrange(min(lower(time_interval)), max(upper(time_interval)))                           FROM daily_readings_unit where meter_id = meter_id_desired
        Aggregate  (cost=30.21..30.23 rows=1 width=32) (actual time=4.154..4.155 rows=1 loops=1)
          ->  Index Only Scan using idx_daily_readings_unit on daily_readings_unit  (cost=0.15..26.55 rows=366 width=22) (actual time=1.913..4.069 rows=366 loops=1)
                Index Cond: (meter_id = 21)
                Heap Fetches: 0
2025-03-20 05:00:05.738 UTC [390] CONTEXT:  SQL statement "SELECT tsrange(min(lower(time_interval)), max(upper(time_interval)))                           FROM daily_readings_unit where meter_id = meter_id_desired"
        PL/pgSQL function shrink_tsrange_to_meter_readings_by_day(tsrange,integer) line 1 at SQL statement
        PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at assignment
2025-03-20 05:00:05.777 UTC [390] LOG:  duration: 34.617 ms  plan:
        Query Text: SELECT hr.meter_id as meter_id, AVG(hr.reading_rate) * slope + intercept as reading_rate, hours.hour AS start_timestamp, hours.hour + reading_length_interval AS end_timestamp FROM ( SELECT hour FROM generate_series( lower(requested_range), upper(requested_range) - reading_length_interval, reading_length_interval ) hours(hour) ) hours(hour), hourly_readings_unit hr WHERE hr.meter_id = current_meter_id AND lower(hr.time_interval) >= hours.hour AND upper(hr.time_interval) <= hours.hour + reading_length_interval AND lower(hr.time_interval) <= hours.hour + reading_length_interval GROUP BY hours.hour, hr.meter_id ORDER BY hr.meter_id, hours.hour
        Sort  (cost=42237.57..42250.57 rows=5200 width=28) (actual time=33.536..34.104 rows=4320 loops=1)
          Sort Key: hours.hour
          Sort Method: quicksort  Memory: 496kB
          ->  HashAggregate  (cost=41812.62..41916.62 rows=5200 width=28) (actual time=30.659..32.242 rows=4320 loops=1)
                Group Key: hr.meter_id, hours.hour
                Batches: 1  Memory Usage: 977kB
                ->  Nested Loop  (cost=0.42..39384.00 rows=323815 width=20) (actual time=1.384..26.867 rows=8640 loops=1)
                      ->  Function Scan on generate_series hours  (cost=0.00..10.00 rows=1000 width=8) (actual time=0.414..0.839 rows=4320 loops=1)
                      ->  Index Scan using idx_hourly_readings_unit_meter_time on hourly_readings_unit hr  (cost=0.42..36.13 rows=324 width=34) (actual time=0.002..0.006 rows=2 loops=4320)
                            Index Cond: ((meter_id = 21) AND (lower(time_interval) >= hours.hour) AND (lower(time_interval) <= (hours.hour + '02:00:00'::interval)))
                            Filter: (upper(time_interval) <= (hours.hour + '02:00:00'::interval))
                            Rows Removed by Filter: 1
2025-03-20 05:00:05.777 UTC [390] CONTEXT:  SQL statement "SELECT hr.meter_id as meter_id, AVG(hr.reading_rate) * slope + intercept as reading_rate, hours.hour AS start_timestamp, hours.hour + reading_length_interval AS end_timestamp FROM ( SELECT hour FROM generate_series( lower(requested_range), upper(requested_range) - reading_length_interval, reading_length_interval ) hours(hour) ) hours(hour), hourly_readings_unit hr WHERE hr.meter_id = current_meter_id AND lower(hr.time_interval) >= hours.hour AND upper(hr.time_interval) <= hours.hour + reading_length_interval AND lower(hr.time_interval) <= hours.hour + reading_length_interval GROUP BY hours.hour, hr.meter_id ORDER BY hr.meter_id, hours.hour"
        PL/pgSQL function meter_3d_readings_unit(integer[],integer,timestamp without time zone,timestamp without time zone,integer) line 1 at RETURN QUERY
2025-03-20 05:00:05.778 UTC [390] LOG:  duration: 56.027 ms  plan:
        Query Text: EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit ('{21}', 1, '2020-01-01 00:00:00', '2020-12-26 00:00:00', 2);
        ProjectSet  (cost=0.00..5.27 rows=1000 width=32) (actual time=55.335..55.871 rows=4320 loops=1)
          ->  Result  (cost=0.00..0.01 rows=1 width=0) (actual time=0.001..0.003 rows=1 loops=1)
2025-03-20 05:00:34.797 UTC [33] LOG:  checkpoint starting: time
2025-03-20 05:00:35.240 UTC [33] LOG:  checkpoint complete: wrote 4 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.402 s, sync=0.014 s, total=0.444 s; sync files=2, longest=0.014 s, average=0.007 s; distance=12 kB, estimate=266 kB
```
8,640 rows were processed in the nested loop join, with 4,320 rows remaining after grouping and aggregation

## Gathered Data

Queries were ran on two different machines:
- Machine 1 was Windows
- Machine 2 was Mac

### Section for meter_3d_readings_unit

Queries for this section were ran on machine 1.

**Vary hours/point with year of data:**  

| Type | Query                                                                                                      | Planning Time (ms) |Exec. Time (ms)| New Exec. Time (ms) | # Rows Returned | Meter                                      | Notes                                                                                                                                                          |
|------|------------------------------------------------------------------------------------------------------------|--------------------|--------|-----------------|-----------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-12-26', 1);        | 0.026              |31.256  | 39.679          | 8,640           | {21} - Sin 15 Min kWh                      | Accessed Cache                                                                                                                                                 |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-12-26', 2);        | 0.021              |2,512.07  | 28.387        | 4,320           | {21} - Sin 15 Min kWh                      | Most of the time is consumed by the 6th log entry.                                                                                                             |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-12-26', 3);        | 0.039              |1,741.775	 | 21.661       | 2,880           | {21} - Sin 15 Min kWh                      | Performance breakdown is similar to previous logs. The nested loop join between `hourly_readings_unit` and the generated series of hours is the main issue.    |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-12-26', 4);        | 0.014              |1,245.155   | 21.116       | 2,160           | {21} - Sin 15 Min kWh                      | Performance issues echo the previous queries.                                                                                                                  |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-12-26', 6);        | 0.038              |724.405   | 18.941         | 1,440           | {21} - Sin 15 Min kWh                      | Accessed Cache                                                                                                                                                 |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-12-26', 8);        | 0.020              |526.671   | 14.827         | 1,080           | {21} - Sin 15 Min kWh                      | Accessed Cache                                                                                                                                                 |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-12-26', 12);       | 0.015              |391.18  | 13.596          | 720             | {21} - Sin 15 Min kWh                      | Accessed Cache                                                                                                                                                 |

**Vary hours/point with half a year of data:**

| Type | Query                                                                                                      | Planning Time (ms) |Exec. Time (ms)| New Exec. Time (ms) | # Rows Returned | Meter                                      | Notes                                                                                                                                                          |
|------|------------------------------------------------------------------------------------------------------------|--------------------|-----------|-----------------|-----------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-06-29', 2);        | 0.027              |1,994.978  | 20.698       | 2,160           | {21} - Sin 15 Min kWh                      |                                                                                                                                                                |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-06-29', 4);        | 0.017              |895.48     | 14.200          | 1,080           | {21} - Sin 15 Min kWh                      |                                                                                                                                                                |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21}', 1, '2020-01-01', '2020-06-29', 6);        | 0.016              |596.478    | 10.030         | 720             | {21} - Sin 15 Min kWh                      |                                                                                                                                                                |

**Vary hours/point, using a year of data, and using two meters:**

- This is for testing only as using multiple meters is not actually possible in OED

| Type | Query                                                                                                      | Planning Time (ms) |Exec. Time (ms)| New Exec. Time (ms) | # Rows Returned | Meter                                      | Notes                                                                                                                                                          |
|------|------------------------------------------------------------------------------------------------------------|--------------------|------------|-----------------|-----------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21,22}', 1, '2020-01-01', '2020-12-26', 1);     | 0.021              |48.82       | 84.578           | 17,280          | {21,22} - Sin & Cos kWh                    |                                                                                                                                                                |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21,22}', 1, '2020-01-01', '2020-12-26', 2);     | 0.015              |6,679.271   | 51.863       | 8,640           | {21,22} - Sin & Cos kWh                    | Most time taken is similar to previous 3D queries.                                                                                                             |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21,22}', 1, '2020-01-01', '2020-12-26', 3);     | 0.059              |4,544.441   | 37.948       | 5,760           | {21,22} - Sin & Cos kWh                    |                                                                                                                                                                |
| 3D   | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_3d_readings_unit('{21,22}', 1, '2020-01-01', '2020-12-26', 4);     | 0.030              |3,252.553   | 35.421       | 4,320           | {21,22} - Sin & Cos kWh                    |   

### Section for meter_bar_readings_unit

Queries for this section were ran on machine 2.

| Type | Query                                                                                                      | Planning Time (ms) | Exec. Time (ms) | # Rows Returned | Meter                                      | Notes                                                                                                                                                          |
|------|------------------------------------------------------------------------------------------------------------|--------------------|-----------------|-----------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 1, '2020-01-01', '2020-12-30');       | 0.161              | 62.135          | 364             | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 1, '2020-01-01', '2020-12-31');       | 0.084              | 50.121          | 365             | {21} - Cos 23 Min kWh                      | Second query using 1 bar per day to get full year.                                                                                                             |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 2, '2020-01-01', '2020-12-30');       | 0.031              | 25.547          | 182             | {21} - Cos 23 Min kWh                      | Do even numbers have more runtime for some reason?                                                                                                             |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 3, '2020-01-01', '2020-12-30');       | 0.059              | 17.641          | 121             | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 4, '2020-01-01', '2020-12-30');       | 0.155              | 17.756          | 91              | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 5, '2020-01-01', '2020-12-30');       | 0.086              | 21.111          | 72              | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 6, '2020-01-01', '2020-12-30');       | 0.086              | 17.259          | 60              | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 7, '2020-01-01', '2020-12-30');       | 0.114              | 17.084          | 52              | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 10, '2020-01-01', '2020-12-30');      | 0.044              | 12.303          | 36              | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 13, '2020-01-01', '2020-12-30');      | 0.075              | 12.132          | 28              | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 14, '2020-01-01', '2020-12-30');      | 0.031              | 14.724          | 26              | {21} - Cos 23 Min kWh                      | Why are these times very consistent? Shouldn't there be some scaling as the number of rows decreases?                                                          |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 21, '2020-01-01', '2020-12-30');      | 0.084              | 10.487          | 17              | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 28, '2020-01-01', '2020-12-30');      | 0.077              | 11.689          | 13              | {21} - Cos 23 Min kWh                      |                                                                                                                                                                |
| Bar  | EXPLAIN (ANALYZE, BUFFERS) SELECT meter_bar_readings_unit('{21}', 1, 30, '2020-01-01', '2020-12-30');      | 0.039              | 7.503           | 12              | {21} - Cos 23 Min kWh                      |      

### Section for meter_line_readings_unit

Queries for this section were ran on machine 2.

**Using 'auto' and altering dates**

| Type | Query                                                                                                      | Planning Time (ms) | Exec. Time (ms) | # Rows Returned | Meter                                      | Notes                                                                                                                                                          |
|------|------------------------------------------------------------------------------------------------------------|--------------------|-----------------|-----------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '-infinity', 'infinity', 'auto', 200, 200);                        | 0.101              | 18.681          | 366             | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-12-30 00:00:00', 'auto', 200, 200);   | 0.074              | 18.705          | 364             | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-06-30 00:00:00', 'auto', 200, 200);   | 0.133              | 10.498          | 181             | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-02-29 00:00:00', 'auto', 200, 200);   | 0.085              | 17.018          | 59              | {21} - Cos 23 Min kWh                      |                                                                                                                                          |
| Line | EXPLAIN (ANALYZE, BUit('{21}', 1, '2020-01-01 00:00:00', '2020-02-29 00:00:00', 'auto', 1440, 1440); | 0.39               | 46.382          | 1416            | {21} - Cos 23 Min kWh                      | Allowing more points turned this meter into an hourly table                                                                                                                                                                                       |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-01-24 00:00:00', 'auto', 1440, 1440); | 0.135              | 29.703          | 1440            | {21} - Cos 23 Min kWh                      | Meter/Reading Table                                                                                

**Using 'raw' and altering dates**

| Type | Query                                                                                                                                    | Planning Time (ms) | Exec. Time (ms) | # Rows Returned | Meter                                      | Notes                                                                                                                                                                                              |
|------|------------------------------------------------------------------------------------------------------------------------------------------|--------------------|-----------------|-----------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '-infinity', 'infinity', 'raw', 200, 200);                         | 0.098              | 57.224          | 22,915          | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-12-30 00:00:00', 'raw', 200, 200);    | 0.546              | 20.056          | 22,789          | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-06-30 00:00:00', 'raw', 200, 200);    | 0.088              | 9.674           | 11,332          | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-02-29 00:00:00', 'raw', 200, 200);    | 0.092              | 11.953          | 3,693           | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |

**Using 'hourly' and altering dates**
| Type | Query                                                                                                                                    | Planning Time (ms) | Exec. Time (ms) | # Rows Returned | Meter                                      | Notes                                                                                                                                                                                              |
|------|------------------------------------------------------------------------------------------------------------------------------------------|--------------------|-----------------|-----------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '-infinity', 'infinity', 'hourly', 200, 200);                      | 0.081              | 35.97           | 8784               | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-12-30 00:00:00', 'hourly', 200, 200); | 0.092              | 10.434          | 8736               | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-06-30 00:00:00', 'hourly', 200, 200); | 0.056              | 61.606          | 4344               | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-02-29 00:00:00', 'hourly', 200, 200); | 0.082              | 33.016          | 1416               | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |

**Using 'daily' and altering dates**
| Type | Query                                                                                                                                    | Planning Time (ms) | Exec. Time (ms) | # Rows Returned | Meter                                      | Notes                                                                                                                                                                                              |
|------|------------------------------------------------------------------------------------------------------------------------------------------|--------------------|-----------------|-----------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '-infinity', 'infinity', 'daily', 200, 200);                       | 0.093              | 20.231          | 366               | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-12-30 00:00:00', 'daily', 200, 200);  | 0.092              | 22.537          | 364               | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-06-30 00:00:00', 'daily', 200, 200);  | 0.035              | 17.527          | 181               | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |
| Line | EXPLAIN (ANALYZE, BUFFERS) select meter_line_readings_unit('{21}', 1, '2020-01-01 00:00:00', '2020-02-29 00:00:00', 'daily', 200, 200);  | 0.086              | 16.928          | 59               | {21} - Cos 23 Min kWh                      |                                                                                                                                                                                                    |

# Bar Chart Rendering Performance Report

This report documents the performance analysis and optimization steps undertaken to improve SVG-based bar chart rendering within our application. Performance metrics were gathered through precise instrumentation, and critical bottlenecks were identified using advanced performance APIs.

**Methodology for Test Case Selection**

To identify the most challenging test scenarios for our performance analysis, we employed the following SQL query to find meters with the highest data volumes:

```sql
SELECT 
  m.id,
  m.name AS meter_name,
  COUNT(*) AS reading_count,
  TO_CHAR(MIN(r.start_timestamp), 'YYYY-MM-DD') AS earliest_date,
  TO_CHAR(MAX(r.end_timestamp), 'YYYY-MM-DD') AS latest_date,
  MAX(r.end_timestamp)::date - MIN(r.start_timestamp)::date AS days_range
FROM readings r
JOIN meters m ON r.meter_id = m.id
GROUP BY m.id, m.name
ORDER BY reading_count DESC;
```

This query revealed that meters 22, 26, and 27 (Sin Amp 1 kWh, Sin Amp 2 kWh, and Sin Amp 3 kWh) each contained 70,176 readings spanning 731 days, making them ideal candidates for stress testing our chart rendering capabilities.

## Initial Investigation

To identify potential performance issues, the RTK-Query hook was instrumented using the User Timing Performance API to measure processing times:

```javascript
//Location in BarChartComponent.tsx
const { data: meterReadings, isFetching: meterIsFetching } = readingsApi.useBarQuery(meterArgs, {  
  skip: meterShouldSkip,  
  selectFromResult: ({ data, ...rest }) => {  
    performance.mark('bar-transform-start');

    const transformed = selectPlotlyBarDataFromResult(  
      data ?? stableEmptyBarReadings,  
      barMeterDeps  
    );

    performance.mark('bar-transform-end');  
    performance.measure('bar-transform-duration', 'bar-transform-start', 'bar-transform-end');

    return {  
      ...rest,  
      data: transformed  
    };  
  }  
});
```

This initial measurement revealed that the selector was **not** the primary source of the performance bottleneck.

## DOM Element Analysis

To accurately measure the number of DOM elements created by Plotly charts, we implemented the following function:

```javascript
countPlotlyDOMElements() {
  const plotlyElement = document.querySelector('.js-plotly-plot');
  if (!plotlyElement) {
    console.log('[DOM Count] No Plotly element found');
    return 0;
  }
  
  // Count all elements inside the Plotly container
  const totalElements = plotlyElement.querySelectorAll('*').length;
  // Count specific bar elements (SVG rect elements)
  const barElements = plotlyElement.querySelectorAll('.bars .point').length;
  
  console.log('[DOM Count] Total DOM elements:', totalElements);
  console.log('[DOM Count] Bar elements:', barElements);
  console.log('[DOM Count] Other elements:', totalElements - barElements); 
  
  return {
    total: totalElements,
    bars: barElements
  };
}
```

We integrated this function into our performance monitoring system to capture DOM element metrics alongside rendering time:

```javascript
React.useEffect(() => {
    setTimeout(() => {
      console.log(`[DOM Count] Dataset points: ${dataPoints}, Meters: ${meterIds.split(',').length}`);
      const domCounts = countPlotlyDOMElements();
      console.log(`[DOM Count] Points × Meters calculation: ${dataPoints} × ${meterIds.split(',').length} = ${dataPoints * meterIds.split(',').length}`);
      console.log(`[DOM Count] Actual DOM elements: ${domCounts.total}`);
      console.log(`[DOM Count] Ratio: ${(domCounts.total / dataPoints).toFixed(2)} DOM elements per data point`);
    }, 1000);
  }
}, [meterIsFetching, groupIsFetching, datasets, meterArgs, groupArgs]);
```

## Advanced Analysis with Long Animation Frames (LoAF)

Long Animation Frames (LoAF) are critical to performance analysis because they help developers detect frame rendering that significantly exceeds ideal responsiveness thresholds (typically 50ms). Frames longer than this threshold can make applications feel sluggish or unresponsive, negatively impacting user experience. By employing LoAF, developers gain insights into specific performance bottlenecks occurring during rendering cycles. The API provides detailed metadata such as total duration, blocking duration (time spent blocking high-priority tasks), timestamps of UI interactions, and script execution details, enabling precise identification and subsequent optimization of problematic code.

```javascript
function initPerformanceObserver() {  
  if (observerInitialized || typeof PerformanceObserver === 'undefined') return;

  obs = new PerformanceObserver((list) => {  
    for (const entry of list.getEntries()) {  
      console.log(`entry.duration=${entry.duration.toFixed(1)}ms`, entry);  
      realRender = Math.max(realRender, entry.duration);  
    }  
  });

  obs.observe({ type: 'long-animation-frame' });  
  observerInitialized = true;  
}
```

## Performance Test Scenarios

| Test Scenario | Meter ID | Meter Names | Data Points | Time Range | Days | Render Time (Ms) | DOM Total Elements | Dom Bar Elements |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Sin Amp 1 kWh - Stress Test Single Bar | 22 | Sin Amp 1 kWh | 731 | 2020-01-01 to 2022-01-02 | 1 | 2425.2 | 9015 | 1462 |
| Sin Amp 1 kWh - Stress Test Week Bar | 22 | Sin Amp 1 kWh | 104 | 2020-01-01 to 2022-01-02 | 7 | 295.5 | 1498 | 208 |
| Sin Amp 1 kWh - Stress Test 4 Weeks | 22 | Sin Amp 1 kWh | 26 | 2020-01-01 to 2022-01-02 | 28 | 126 | 553 | 52 |
| Sin Amp 1 kWh, Sin Amp 2 kWh, Sin Amp 3 kWh - Highest Data Volume - Single Bar | 22,26,27 | Sin Amp 1 kWh; Sin Amp 2 kWh; Sin Amp 3 kWh | 2193 | 2020-01-01 to 2022-01-02 | 1 | 5737 | 26,591 | 4,386 |
| Sin Amp 1 kWh, Sin Amp 2 kWh, Sin Amp 3 kWh - Highest Data Volume - Week Bar | 22,26,27 | Sin Amp 1 kWh; Sin Amp 2 kWh; Sin Amp 3 kWh | 312 | 2020-01-01 to 2022-01-02 | 7 | 1111 | 4011 | 936 |
| Sin Amp 1 kWh, Sin Amp 2 kWh, Sin Amp 3 kWh - Highest Data Volume - 4 Week Bar | 22,26,27 | Sin Amp 1 kWh; Sin Amp 2 kWh; Sin Amp 3 kWh | 78 | 2020-01-01 to 2022-01-02 | 28 | 322.8 | 1209 | 156 |
| Natural Gas BTU in Dollar - Minimal Code | 8 | Natural Gas BTU in Dollar | 5 | 2020-01-01 to 2022-01-02 | 1 | 150.5 | 324 | 10 |
| Natural Gas BTU in Dollar - Error with 0 Data Points | 8 | Natural Gas BTU in Dollar | 0 | 2020-01-01 to 2022-01-02 | 7 | 57.8 | 0 | 0 |

## Critical Findings

A significant Long Animation Frame was identified during this analysis:

* **Duration**: 5737.0ms  
* **Blocking Duration**: 5676.5ms (99% of render time)  
* **scriptDuration**: 5ms, forcedLayout: 0ms  
* **Data Volume**: 2193 points × 3 meters

## DOM Element Analysis

Our DOM element counting tests revealed a significant issue with how Plotly generates SVG elements:

* **Expected DOM Elements**: 6,579 (calculated as 2193 data points × 3 meters)  
* **Actual DOM Elements**: 26,591 (4× more than expected)  
* **Bar Elements**: 4,386 (approximately 2 per data point)  
* **Supporting Elements**: 22,205   
* **DOM Element Ratio**: 12.13 DOM elements created per data point

This high ratio of DOM elements per data point explains the severe performance degradation. For every visible bar in the chart, Plotly creates approximately 12 DOM elements under the hood. These include not only the visible bars but also supporting elements like event listeners, tooltip containers, clipping masks, positioning containers, and accessibility elements.

## Main Thread Saturation

The main JavaScript thread is blocked for 5.6+ seconds during rendering, preventing all user interaction during this period. This creates the perception of an unresponsive application.

## DOM Element Proliferation

The chart creates far more DOM elements than expected, with each data point requiring multiple supporting elements. Each of these requires memory allocation, styling, and positioning within the document flow, creating severe rendering bottlenecks at scale.

## Limitations of Plotly.js Bar Charts

The official Plotly documentation specifically mentions "implement WebGL for increased speed, improved interactivity, and the ability to plot even more data" Plotly but only lists scatter plots (scattergl) as WebGL-enabled, not bar charts.

This documentation explicitly states that "scattergl charts render an order of magnitude faster than their SVG counterparts." Plotly and specifically notes that "All 3D charts in plotly.js are rendered with WebGL," implying that standard 2D charts like bar charts are not. **Which is why 3D maps render faster than Bar Charts**. 

- [https://plotly.com/javascript/](https://plotly.com/javascript/) and https://plotly.com/javascript/webgl-vs-svg/

In this forum thread, a user specifically asks about why Plotly.js doesn't have WebGL versions of bar charts, noting that bar charts "could also get slow if containing a lot of bar DOM nodes" Plotly, which confirms they are rendered as DOM/SVG elements rather than using WebGL.

https://community.plotly.com/t/webgl-for-bar-line-charts/3518

## Alternative High-Performance Bar Chart Solutions

Given the performance limitations of Plotly.js, there may be documentation in the d3.js for more optimized bar graph generation.

## Conclusion

The proposed optimizations and alternative solutions outlined in this report are expected to substantially improve performance, ensuring smoother user interactions and rapid rendering times for complex datasets.



# Google Lighthouse Findings - Resolved

At times, when displaying bar graphs on a daily frequency, there was noticeable lag between the query completion and the graph being rendered on the client side. To investigate this, Google's Lighthouse browser tool was used. Lighthouse is a performance analysis tool built into Chrome upon installation. It can be used as an extension in other Chrome-based browsers, but it can be used as a browser tool in Google Chrome. It is highly recommended that users use Google Chrome to test with this tool.

Using Lighthouse to analyze the performance of generating a daily bar graph with the **Cos 23 Min kWh meter**, the following observations were made:

![Lighthouse Report Results](lighthouseReportResults.png "Lighthouse Report Results")

### Findings
Testing with Lighthouse revealed potential bottlenecks on the **main thread**, which could explain the delayed graph rendering. One possible solution to reduce main-thread load is implementing **web workers**, which allow scripts to run in the background. While this is not a definitive fix, it offers a direction for further experimentation. The analysis provided a clearer understanding of where the time delays might be occurring, though the root cause remains to be fully identified.

---

## Using Lighthouse

### Steps for Chrome Users
1. Open the web page and use **Inspect Element** to access the DOM viewer.
2. Navigate to the **Lighthouse** tab in the DOM tools navbar.
   - **Note**: If the browser window is too small, the Lighthouse tool may be hidden under the **arrow menu** (see image below).

![Lighthouse Navbar Step](lighthouseNavigationStep.png "Lighthouse Navbar Step")

3. Once on the Lighthouse tab:
   - Switch to **Timespan Mode**.
   - Select the appropriate device (e.g., Desktop).
   - Ensure the **Performance** category is checked.

4. Prepare the OED environment, but avoid interacting with the web page to provoke any events that are meant to be tested before starting the timespan.
5. **Start the timespan**, then immediately interact with the page to trigger the desired test event. End the timespan to generate a report.

---
