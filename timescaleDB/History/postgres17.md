# TimescaleDB Deployment Instructions

This doc shows how to deploy postgres17 as OEDs Database docker container.

## Pull & Deploy Docker container

> Recommended to start from a fresh OED install to not corrupt/conflict `postgres-data/`

1. pull the specific docker image using the version tag ```docker pull postgres:17.5```
2. From your fresh repo of OED edit `containers/database/Dockerfile` and update the docker tag definition
   `FROM postgres:15.3`->`FROM postgres:17.5`
3. Then follow the typical steps to start up OED. Uncommenting port forwarding in docker-compose `database` and `docker compose up --build`

## Testing Postgres 17.5 compared to 15.3(current)

1. Compare boot and init processing time for materialized views

    ```
    Results:
    ```

2. Confirm that migrating existing OED data is possible
3. Confirm which materialized views and query functions work in 17
