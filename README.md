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
- [mergeMeterGroup.md](./MergeMeterGroup/mergeMeterGroup.md): Proposal to fuse the meter and group menus on graphic pages.
- [parameterOptimization.md](./parameterOptimization/parameterOptimization.md): Proposal to adjust parameters.
- [enhancementToGithubAction.md](./githubAction/enhancementToGithubAction.md): securing GitHub action information.

## Information

- [website/website.md](./website/website.md): Describes how the OED website data and images are created.
- [addTooltips/addTooltips.md](./addTooltips/addTooltips.md): Information on putting in more tooltips.

## Historical

All of these are in this archive/ directory

- [databaseMigration/databaseMigration.md](./archive/databaseMigration/databaseMigration.md) gives the development and solution of migrating Postgres from version 10 to 15.
- [areaNormalization/areaNormalization.md](./archive/areaNormalization/areaNormalization.md): Documents idea on allowing normalization by area but also probably relates to other normalizations to come.
- [3DGraphic/3DGraphic.md](./archive/3DGraphic/3DGraphic.md): A new 3D graphic to show usage.
- [radar/radar.md](./archive/radar/radar.md): A new graphic to show in clock/radar form.
- [resourceGeneralization/resourceGeneralization.md](./archive/resourceGeneralization/resourceGeneralization.md): Ideas and work from 2020 onward on expanding OED to be able to work with many unit/resource types. This lead to OED V1.0.0.
- [color.md](./archive/color.md): Ideas and work around 2020 on choosing the colors of meters/groups for OED graphics.
- [csv.md](./archive/csv/csv.md): adding CSV file input to OED.
- [datetime/datetime.md](./archive/datetime/datetime.md): How OED deals with readings that cross daylight savings for meters that honor daylight savings.
- [fast-ptAnalysis/fastPtModification.md](./archive/fast-ptAnalysis/fastPtModification.md): Ideas from 2021 to improve fast-pt to avoid potential performance issues and undesirable graphing results.
