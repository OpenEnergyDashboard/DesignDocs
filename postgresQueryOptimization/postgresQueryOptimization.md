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

In this case it returned ``42`. Next, the 3D readings for 24 points/day (not the query takes the hours/pt) is:

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
``

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
``

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

## web browser analysis

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

Hopefully coming.
