# Weather data

As part of [time varying units](../unitVaryTime/conversionsVaryTime.md), OED wants to track weather data and use to normalize reading data.

At a minimum, OED will want to have temperature data. It may want other information. Exactly what needs to be determined.

## Getting weather data

OED need to acquire weather data to support this feature. In a perfect world, there would be a single source of data for all sites. This may not be possible so having a standard format with modules to talk to different weather sources (similarly to how meter data is done) would be desirable. Demonstrating with two sources (or one if a standard source exists) would be good for the initial work.

Here are some possible sources where more may exist. The value and appropriateness of any options needs to be evaluated.

- [U.S. National Centers for Environmental Information with world-wide data & historical](https://www.ncei.noaa.gov/about-us)
  - [all data](https://www.ncei.noaa.gov/services/world-data-system)
  - [land data including weather](https://www.ncei.noaa.gov/products/land-based-station)
- [seems to have lots of historical and current data world-wide with API](https://open-meteo.com/en/docs/historical-weather-api)
- [U.S. NOAA info with weather/degree days, etc. Need to see what has and if API.](https://www.ncdc.noaa.gov/cdo-web/)
- [U.S. National Weather Service API to get data. Unclear if historical and probably not world-wide.](https://www.weather.gov/documentation/services-web-api)
  - [FAQ](https://weather-gov.github.io/api/general-faqs)
  - https://www.weather.gov/documentation/services-web-api Documentation
- [question about getting weather data but dated](https://opendata.stackexchange.com/questions/7578/historical-weather-forecast-api)
- others are available if needed and find with a web search

## Admin control of weather data

Admins need to be able to set if and how (if needed) weather data is acquired. The exact design depends on how weather data is acquired. Its page may be the general admin panel if it is simple or a newly linked page.

## Use weather data to normalize values

Once appropriate weather data is available, it needs to be used to normalize the meter data. Here are some sources of information on using weather data to normalize usage with basic ideas to modeling. Others are available. The possibilities need to be analyzed, a choice made, tested against real data and implemented within OED.

- [PDF with how to use historical data to get energy normalized data.](https://www.energystar.gov/sites/default/files/tools/Climate_and_Weather_2020_508.pdf)
- [basic CDD/HDD](https://medium.com/builtrix/how-to-calculate-weather-normalized-energy-consumption-55acacad50ea)
- [research paper](https://buildingenergyscore.energy.gov/resources/download?key=publications%2Fweather_normalization.pdf)
- [normalization info and methods from company](https://www.energylens.com/articles/degree-days)
- [Heating/cooling days and normalization](https://energyforums.net/energy-concepts/)degree-days-and-weather-normalization/ 
- [free online CDD/HDD calculator](https://www.energystar.gov/buildings/tools-and-resources/degree_days_calculator)

## Database changes

The exact changes relate to the sections above as the needed data may change. The database and models need to be created. This is a first cut at the DB setup:

### weather location

id, identifier, gps, note

### meter

The field weather_location_id is added (foreign key into weather location table)

### group

Similar to meter

### weather data

weather_location_id (foreign key into weather location table), start_time, end_time, temp

May need other values depending on choices made.

## UI interface

This will be decided after other choices are made.

- It seems a good idea to have a group check the location of the underlying meters and warn if they differ from the group location. This is different but has some similarities to the area calculation for groups.
- Depending on how normalization is done, we may want DB views for hour, half day, full day or something else to optimize normalizing by weather.
- UI choices may be similar to area to turn on/off. Change y-axis label to include "normalized by weather" (internationalized) assuming it fits.
- Need to decide if compatible with area normalization (seems to be) or any other graphic choices.
- There limitations on what data can weather normalized. Need to specify precisely.
