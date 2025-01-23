# DesignDocs

Holds documentation on OED, esp. design of features.

Note OED is transitioning to mostly public design documents. The private DevDocs repository has some design documents but the plan is to migrate them to this public repository over time.

## Active

- [testing/testing.md](./testing/testing.md): Documents how the testing data was generated into CSV files and gives the tests desired.
- [lineCompare.md](./lineCompare/lineCompare.md): A new graphic to compare different time ranges via a line graphic.
- [mergeMeterGroup.md](./MergeMeterGroup/mergeMeterGroup.md): Proposal to fuse the meter and group menus on graphic pages.
- [parameterOptimization.md](./parameterOptimization/parameterOptimization.md): Proposal to adjust parameters.
- [weather/weather.md](./weather/weather.md): Documents ideas on using weather data to normalize usage.
- [postgresQueryOptimization.md](./postgresQueryOptimization/postgresQueryOptimization.md): how to analyze time spent on OED queries and the results of doing this.
- [unitVaryTime/conversionsVaryTime.md](/unitVaryTime/conversionsVaryTime.md): Documents ideas on how to deal with conversions that vary with time including area, baseline, weather, etc.
- [todoComments/todoComments.md](./todoComments/todoComments.md): Documents TODO comments across the codebase, providing status updates and linking related issues.
- [uiTesting/uiTesting.md](./uiTesting/UITesting.md): Doing UI testing on OED.
- [readingRangeRejection.md](./readingRangeRejection/readingRangeRejection.md): how to modify OED to deal with min/max reading values that takes into account all units and allow for rejection of only readings that are outside the ranges.
- [UIEval/S22UIEval.md](./UIEval/S22UIEval.md): A UI eval of OED with suggestions from Spring 2022.
- [MQTT.md](./MQTT.md): Looking into integrating for meter data acquisition.
- [baseline/baseline.md](./baseline/baseline.md): Add the ability for an admin to add baselines to meters and for users to display on a graphic.
- [enhancementToGithubAction.md](./githubAction/enhancementToGithubAction.md): securing GitHub action information.
- [pikState.md](./pikState.md): Moving from a pik array to cik state for client conversions.

## Information

- [addTooltips/addTooltips.md](./addTooltips/addTooltips.md): Information on putting in more tooltips.
- [website/website.md](./website/website.md): Describes how the OED website data and images are created.

## Historical

All of these are in this archive/ directory

- [simplifyOptions/fewerOptions.md](./archive/simplifyOptions/fewerOptions.md): Move many of the current options for users into a modal popup.
- [3DGraphic/3DGraphic.md](./archive/3DGraphic/3DGraphic.md): A new 3D graphic to show usage.
- [automatedTestData.md](./archive/automatedTestData.md): How to generate mathematical test data and use it in the CI testing.
- [areaNormalization/areaNormalization.md](./archive/areaNormalization/areaNormalization.md): Documents idea on allowing normalization by area but also probably relates to other normalizations to come.
- [color.md](./archive/color.md): Ideas and work around 2020 on choosing the colors of meters/groups for OED graphics.
- [csv.md](./archive/csv/csv.md): adding CSV file input to OED.
- [databaseMigration/databaseMigration.md](./archive/databaseMigration/databaseMigration.md) gives the development and solution of migrating Postgres from version 10 to 15.
- [datetime/datetime.md](./archive/datetime/datetime.md): How OED deals with readings that cross daylight savings for meters that honor daylight savings.
- [export.md](./archive/export.md): Ideas and work around 2021 on exporting raw line graphic data.
- [fast-ptAnalysis/fastPtModification.md](./archive/fast-ptAnalysis/fastPtModification.md): Ideas from 2021 to improve fast-pt to avoid potential performance issues and undesirable graphing results.
- [longReadings.md](./archive/longReadings.md): How to properly get data/plot readings that last a long time.
- [pipeline/earlyHaNotes.md](./archive/pipeline/earlyHaNotes.md): describes ideas of the redesigned pipeline from 2019.
- [radar/radar.md](./archive/radar/radar.md): A new graphic to show in clock/radar form.
- [resourceGeneralization/resourceGeneralization.md](./archive/resourceGeneralization/resourceGeneralization.md): Ideas and work from 2020 onward on expanding OED to be able to work with many unit/resource types. This lead to OED V1.0.0.
- [users.md](./archive/users.md): adding multiple user roles.
- [usingRoutes/usingRoutes.md](./archive/usingRoutes/usingRoutes.md): Information on how React and Redux work with pages and state within OED but before hooks and toolkit.
