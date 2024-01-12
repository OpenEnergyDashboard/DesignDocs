# DesignDocs

Holds documentation on OED, esp. design of features.

Note OED is transitioning to mostly public design documents. The private DevDocs repository has some design documents but the plan is to migrate them to this public repository over time.

## Active

- [testing/testing.md](./testing/testing.md): Documents how the testing data was generated into CSV files and gives the tests desired.
- [unitVaryTime/conversionsVaryTime.md](/unitVaryTime/conversionsVaryTime.md): Documents ideas on how to deal with conversions that vary with time including area, baseline, weather, etc.
- [weather/weather.md](./weather/weather.md): Documents ideas on using weather data to normalize usage.
- [simplifyOptions/fewerOptions.md](./simplifyOptions/fewerOptions.md): Move many of the current options for users into a modal popup.
- [pikState.md](./pikState.md): Moving from a pik array to cik state for client conversions.
- [baseline/baseline.md](./baseline/baseline.md): Add the ability for an admin to add baselines to meters and for users to display on a graphic.
- [lineCompare.md](./lineCompare/lineCompare.md): A new graphic to compare different time ranges via a line graphic. 

## Information

- [website/website.md](./website/website.md): Describes how the OED website data and images are created.

## Historical

- [databaseMigration/databaseMigration.md](./databaseMigration/databaseMigration.md) gives the development and solution of migrating Postgres from version 10 to 15.
- [areaNormalization/areaNormalization.md](./areaNormalization/areaNormalization.md): Documents idea on allowing normalization by area but also probably relates to other normalizations to come.
- [3DGraphic/3DGraphic.md](./3DGraphic/3DGraphic.md): A new 3D graphic to show usage.
- [radar/radar.md](./radar/radar.md): A new graphic to show in clock/radar form.
