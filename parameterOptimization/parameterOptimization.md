# Parameter Optimization

## Introduction

 Parameter Tuning - “involves altering variables such as memory allocation, disk I/O settings, and concurrent connections based on specific hardware and requirements” - Percona

[Issue #162](https://github.com/OpenEnergyDashboard/OED/issues/162) covers this effort.

OED needs to ensure that all parameters are set to what they need to be, so the dashboard is working as efficiently as possible. The parameters that are currently used are located in the postgresql.conf file which is in the postgres-data directory.

To view the parameters set for Postgres & OED, you can run this awk script:

`awk '{ print }' postgres-data/postgresql.conf`


## Suggested Implementation

Two resources, Percona Blog and PostgreSQL wiki, explain potential adjustments for parameters to optimize PostgreSQL. 

https://www.percona.com/blog/tuning-postgresql-database-parameters-to-optimize-performance/ 
https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server

#### After tuning most of these parameters, OED needs to be restarted to have the parameter change since OED sets most of them during the build. 

### Main suggestions:

default wal_buffer size is 16MB, but if there are a lot of concurrent connections a higher value can help performance.

maintenance_work_mem value is 64MB but a large value helps in tasks like VACUUM, RESTORE, CREATE INDEX, ADD FOREIGN KEY, and ALTER TABLE.

max_connections = the maximum number of clients suggests the maximum possible memory use. PostgreSQL on good hardware can support a few hundred connections. If you want to have thousands instead, you should consider using connection pooling software to reduce the connection overhead.

shared_buffers: set to 32MB, if you have a system with 1GB or more of RAM, a reasonable starting value for shared_buffers is 1/4 of the memory in your system.
 
Enabling exit_on_error may help in quickly identifying and addressing issues, but it can also result in abrupt session terminations for users or applications, potentially causing inconvenience or disruption.

Enabling restart_after_crash = on can help in automatically recovering from backend crashes, and reducing downtime.
deadlock_timeout = 1ms A shorter timeout may lead to quicker deadlock detection and resolution but could also increase the likelihood of false positives, where PostgreSQL incorrectly identifies a deadlock.

huge_pages = try PostgreSQL will attempt to use huge pages if they are available and supported by the operating system. Huge pages are larger than regular memory pages (2MB or 1GB?), and using them can potentially improve performance by reducing the overhead associated with managing large amounts of memory. Only useful if you work with large datasets and indexes. If huge pages are not available or cannot be used for some reason, PostgreSQL will fall back to using regular memory pages.


## Next Steps

Most of those running OED cannot fully demonstrate if the parameters are running to their full efficiency. The next step for this parameter optimization would be to test on a larger-scale system. A real-life system with years of test data would need to be loaded up and tested with queries. During these tests, comparisons of time would need to be calculated to check which parameter setting is most efficient. 





