# OED Resource Generalization

**Please use care in editing the document so the history stays intact and nothing bad is done to it. Having said that, this is a living document that you can edit.**

This is a working document (started Nov 2020 but includes previous work/ideas) that gives ideas on how to generalize OED resources from electricity to any type (hopefully).

## Todo

- mathjs vs UnitMath [see below](#mathjs-vs-unitmath)

## Overview

OED started by working with electrical data as a proof of concept and to support the resource requested the most. With that complete, OED is generalizing to support any resource such as natural gas, water, steam, recycling, temperature, etc. Instead of addressing these as individual cases, OED is being modified to store information about compatible resources (energy, power, volume, temperature, etc.) and how to convert between them. This will allow OED to address several feature requests with this single change including:

- Allow arbitrary resource units (natural gas, energy, power, etc.).
- Allow sites to choose the unit for graphical display where the most common request is for English vs. metric units.
- Allow OED to display usage in units not associated with resource consumption such as CO2, cost, equivalent miles of driving a car, etc., which may be more natural to some users and allow for common sustainability units to be used.
- Allow OED sites to add new units to the system that are not automatically supplied with OED

The idea behind the system is that all compatible resources can be converted from one to the other via a linear transformation. For example, 1 BTU is 2.93x10-4 KWh. While most conversions are multiplicative factors, temperature is the one notable exception where Fahrenheit = 1.8 * Celsius + 32.

Note that even though we are the Open Energy Dashboard, this generalization will allow for non-energy units such as volume, temperature, money, etc.

The GitHub issues #[211](https://github.com/OpenEnergyDashboard/OED/issues/211), #[214](https://github.com/OpenEnergyDashboard/OED/issues/214) & #[164](https://github.com/OpenEnergyDashboard/OED/issues/164) relate to units/generalization. Displaying by cost is related to issue #[61](https://github.com/OpenEnergyDashboard/OED/issues/61). This may also relate to the request to negate meters (issue #[161](https://github.com/OpenEnergyDashboard/OED/issues/161)) as this is a special case of a linear transformation. It is planned that completion (at least to a reasonable degree) of this work will be OED release 1.0 as a fully functional dashboard. Issue #[139](https://github.com/OpenEnergyDashboard/OED/issues/139) on adding notes to items has some relationship to this.

## Likely steps - needs update (todo)

This is a rough overview. Details are below.

1. Decide how to deal with all the units, conversions & compatibility between units
2. Design changes to OED
    1. DB (tables, etc.)
    2. DB queries (set/get data, etc.)
    3. Admin panel & meter (group) pages
    4. Graphics (display data to the user)
3. Come up with implementation plan & give work to multiple developers

## mathjs-vs-unitmath

- Need to decide if want/can use [UnitMath](https://github.com/ericman314/UnitMath/tree/v1#readme) vs [mathjs](https://mathjs.org/). The driver is that UnitMath is much smaller bundle and does not have a lot of features we do not need.
  - The seem to have similar types of arithmetic functions but use different names and syntax in many cases. UnitMath uses chained functions. Thus, switching from one to the other will take a modest level of effort.
  - Upcoming [release 1](https://github.com/ericman314/UnitMath/tree/v1#readme) uses different syntax from the current one for creating units. It seems very general but more complex than mathjs.
  - unit.definitions() lets you get all the unit definitions so similar to serialization in mathjs.
  - mathjs has documentation on provided units and constants. UnitMath may have them but need to see using function call above.
  - mathjs seems more mature at this time but UnitMath is nice and coming along.
  - The [user-defined section of UnitMath](https://github.com/ericman314/UnitMath#user-defined-units) makes me think that we could store a configuration of the system (i.e. all the user-defined units) as a json object in a file or in the db. The following process could be effective:
    - Download the unit package UnitMath (500 kb) for the react-app
    - When the app loads, serve the json object/configuration from the database/json file.
    - Conversions happen on the client-side only

I would like input from others on this choice. **This needs to happen soon (todo)**

## math.js thoughts

After analysis of a number of open source unit packages, OED decided to use math.js.

- Davin's original mathjs test code from April-May 2021 is at [their fork in mathPackages branch in src/server/unitPackages/](https://github.com/lindavin/OED/tree/mathPackages/src/server/unitPackages). To execute the file, cd into the directory and run `npx mocha testing.js (at least the name seems out of date) This does a lot of [examples 1-7](#examples).
- [general documentation](https://mathjs.org/docs/index.html), [unit documentation](https://mathjs.org/docs/datatypes/units.html) & [unit examples](https://mathjs.org/examples/units.js.html)
- [serialization](https://mathjs.org/docs/core/serialization.html) should allow to store in DB
- baseName for custom units may help in only allowing conversions between desired units. unit.equalBase(unit) tells if two units have the same baseName.
- see [standard unit info and bases](https://mathjs.org/docs/datatypes/units.html#reference).
- unit.toSI() gives the equivalent SI unit. Not sure how works with custom units.
- The print/format methods might be useful for displaying info to user

### Items to think about relating to math.js

- How can we stop undesirable chained conversions and ones that should only go one way?
  - See starting at line 159 in testingMathJS.js in [Davin's fork in mathPackages branch in src/server/unitPackages/](https://github.com/lindavin/OED/tree/mathPackages/src/server/unitPackages) for an example of an issue and some work to get around it.
  - If we think about units as nodes on a graph and dimensions as clusters, and conversions as paths between nodes, then we could eliminate “weird conversions” by enforcing the rule that “any path with endpoints in different clusters must have length one”.
  - Here is what Davin wrote about some chained conversion considerations: [chainConversionsThoughts.pdf](chainConversionsThoughts.pdf)
- A potential strategy to minimize bundle size while keeping things on the client-side as much as possible using mathjs:
  - Use custom bundling to instantiate the unit system
  - Send the system as a object to the client-side (browser)
  - Store the system object in the redux store. It will contain methods for unit conversions, a list of all possible
  - Note using UnitMath eliminates this issue as it is a much smaller bundle.
- Mathjs serialization and storing that in the database will have issues when two admins try to save new units around the same time. One user may overwrite the changes of the other user. UnitMath does it with json objects so we could look into postgres allowing direct mutate json: https://www.freecodecamp.org/news/how-to-update-objects-inside-jsonb-arrays-with-postgresql-5c4e03be256a/. Davin created this image of the potential process:

![image of the potential process](jsonUpdate.png "image of the potential process")

- There is volume and liquid volume.
- How/can we relate certain custom units to underlying general units (will baseName help?). It would be nice if the system automatically converted between the different standard types such as kg, metric ton, lbs.:
  - gallon gasoline to liquid volume units
  - mass of CO2 to mass units
  - cubic meters of natural gas to volume

## examples

Here are some examples that show the range of possibilities and ones that might be tricky. Others are elsewhere in the document.

1. Determine total energy usage from meters that are both electricity & natural gas.
    1. If we store everything in SI units of energy for these types of meters then we can simply add them together. This means the values in the DB are not the ones we got from the meter; this can be a negative when people look directly at them in the DB.
        1. Now I’m not inclined to do this since some conversions are dependent on the type of energy, e.g., cost is different for BTU and kWh. Same is true for CO2.
    2. If we store electricity as kWh and natural gas as BTU, then we need to convert each type to energy (maybe joules as SI/metric). We can then add them together. Note that it is an implementation question (with this one and a number of examples that follow involving multi-step processes) whether it is done as two separate operations or combined in a single step (you can compose linear transformation in any order to get the same result).
2. Determine total cost from meters that are both electricity & natural gas. (See above for related ideas/example with energy instead of cost.)
   1. Since the cost for kWh and BTU is quite different, we need to know the quantity of each (kWh & BTU) to be able to convert individually to cost and then sum these costs to get the final total cost. This is a clear example where having a standard energy unit to store meter data does not allow for grouping them for conversion.
3. Determine total CO2 from gas (BTU) & waste (kilos, where waste is trash). (Note this may be a problematic calculation because the conversions are not precise but it is an example.) This should be similar to the cost example above. Here you need to convert the BTU and kilo separately into CO2 and then combine.
4. Determine total usage from gas (as volume, say cubic meters) and water (volume). This request does not make sense even though both have a common unit of volume. This shows that the grouping of compatible units for transformations cannot assume that the same unit is okay to combine. I would be okay to combine these two to get a cost (money).
5. Display total energy usage as equivalent 100 watt light bulbs for both electricity (kWh) and gas (BTU) meters.
    1. If you have a direct transformation for both kWh & BTU in 100 watt light bulbs then you can do this in the same way as cost for these above. However, it seems unlikely that an admin will, can or want to put in every possible transformation when they (or we) enter the 100 watt light bulb unit. It also means that if someone adds a new energy unit you need to then add that transformation. A high quality system would not require that.
    2. Do the conversion to total energy as discussed above and assume you go to SI units. Then transform this from SI to 100 watt light bulbs. Here we assume that admins enter a single conversion from our standard energy units (probably SI) to 100 watt light bulbs or whatever transformation they want. Having directions to enter one conversion seems easier and much more user friendly. However, it requires determining chained conversions.
6. Display total cost in Euros for electricity (kWh) and gas (BTU) where you have a conversion of kWh to U.S. dollars and BTU to Euros along with U.S. dollars to Euros.
    1. In the basic implementation you would convert each and then convert one of the currencies to the other to do the final add. The one with the currency conversion is a chained conversion because you have to go kWh to U.S. dollars and then U.S. Dollars to Euros. You can avoid the chaining if you require a direct conversion.
7. Display gas usage (BTU) for heating along with the temperature since heating costs vary with temperature. These are not compatible units and there is not a desire to combine them. What the user wants is two lines on the same graph. This requires us to display two y-axis units (one for BTU and one for temperature). We need to have a way to determine when the user is asking for aggregation (sum) vs. two separate lines/values. Note that if we wanted something other than BTU for the energy then that would be a transformation to do first before displaying.
8. Display gas from money. This request does not really make sense. It could happen because we can transform gas in cost and linear transformations are reversible so we can go from cost (money) to gas. This means we need to decide which transformations are reversible (if any).

## Issues to consider

1. Some of the conversions may vary with time. Examples are cost, size of buildings, probably others. How will we deal with this?
    1. Values in DB
    2. Entering the values by admin
    3. Efficiently get/transform the data if this is allowed
2. Some meters or a group of meters provide the values needed to determine usage. For example, steam needs multiple values. How will we deal with this? If we store the raw meter values then need to combine when requested or in advance (maybe in a way similar to the daily aggregation). Here are some older notes on unusual types
    1. Fuel oil
        1. Gallons (volume) but has equivalent energy value
    2. Steam - is this energy or something else?
        1. Believe need pressure, temperature and flow
        2. CEED gives gallons
    3. Heated water
        1. Can be demand (flow) or usage (volume)?
    4. Chilled water
        1. CEED does TonHr which is a normalized BTU/hr (1 ton hr about 12,000 BTU)

## Units and transformations

The heart of the system is allowing for transformations between compatible units. Compatible units are ones that can be aggregated because they can all be converted to the same unit and this is also logical. See [examples above](#examples) for sample transformations.

While most conversions are multiplicative factors, temperature is a linear transformation. Thus, we will use linear transformations (mx + b) in OED where most will have b = 0. We will need to think about whether we should optimize the case of b = 0 or if it does not make any practical difference.

We need to know what units are compatible with what other units. For example (see example #4 above), volume of water really should not be added to volume of gas.

Will we ever need to do a chained conversion? Here are examples (see example #5 above) and (see example #6 above). Do we want to have this complication or would we require a direct, one-step transformation to be stored in the system.

Do we store everything in SI units or the original meter units? This (see example #1 above) shows the basic case and this (see example #2 above) is more complex. While it is early to discuss implementation, would it make sense to sort the items in a group by the underlying compatible unit types for those to be aggregated and then converted or does it not really matter? This could be either in advance or during a request. There are speed and implementation complexity to consider.

Even though these are linear transformations that can be inverted, we don’t always want to do that (see example #8 above). That is a problem. Should we only go one way and require the reverse one to be entered separately or selected as bi-directional? We need to think about what is possible, makes sense, and what is desired by users, esp. with chained transformations.

Users will want to define their own units. For example, they need to enter the cost of kWh, BTU, water, etc. They will also want to define display units such as CO2 (we will likely supply this one) and energy usage equivalent to driving a car, pizza deliveries, etc. We don’t know everything people will want so we should allow them to enter new ones. We need to consider how user defined units will mesh with other details such as what units are compatible with others.

Some transformations and values can likely vary with time. A clear example is the cost of an energy type (electrical rates, etc. vary with time). Do we want to do this (would be nice)? We need a way to store time varying values in the DB and how to label ones that apply for all time before/after the given time. We also need to decide how to efficiently implement this. Breaking up the meter date ranges for each time range of change might be a pain and slow the system down. One idea that needs to be looked at is using dummy meters with limited points that span the time ranges where meters could be multiplied or maybe linearly transformed (not just added) to get the final result.

This is a non-trivial problem that has been addressed by others. We should look at how other resource dashboards deal with this (don’t have a good list here). We should also look at software for unit transformations.  This should be software that we cannot directly incorporate but has nice features and software that we could directly use (need to be careful about open source license). For each, we need to track:

- What is its main features of interest
  - Do they have custom units (we want this)
  - How do they store unit info
  - What type of conversions can they do
- Can it be used directly in OED
- What is its software license (even if not open source)
- If it is under consideration, what is the quality of the project (software, documentation, ongoing development, support, etc.)

Here are some URLs with some possible packages to look at. It is far from complete:

## Testing of unit packages

Steve proposes to test the packages in the following sequence:

1. Test basic multiplicative unit conversion of provided unit. If there is a unit conversion provided (such as meters to feet) then try that. For example, take 13 meters and convert to feet and then reverse to try 13 feet to meters. Note I did not use 1 so we know that it is really working correctly. It can be any unit it has.
2. Test linear conversion. Convert degrees fahrenheit to celsius and reverse. If not provided then use 9/5 * C + 32 = F.
3. Check new unit with multiplicative (all remaining are multiplicative). This assumes that the package does not have energy units. If so, see if get the same result and need to test one where not provided (could be the same but made up names for the units). 1 Megajoule = 0.001055056 BTU and 1 Megajoule = 3.6 kWh. Try converting each of these after enter these two conversions:
    1. 3 BTU into 2843.45 Megajoules
    2. 123 kWh into 34.17 Megajoules
4. See if can convert 34.17 Megajoule into 123 kWh to see if automatically does reverse given entered kWh into Megajoules above.
5. See if allows arithmetic on result so can ask 3 BTU + 123 kWh to see if it can give 2877.62 Megajoules.
6. See about a chained conversion. Enter new unit of 100 watt bulb = 0.1 kWh. Now convert 3 BTU to 100 watt bulb. 3 BTU is 2843.45 Megajoules = 10236.42 kWh = 102364.23 100 watt bulb. This assumes that the package can do reverse conversions (gave Megajoule to kWh above); if not, need to give reverse and note. If that works, see if can take 102364.23 100 watt bulb into BTU (3 BTU).
7. Another chained conversion. Enter 4 new units: 1 kWh = 0.11 US$, 1 BTU = 13 CAN$, 1 US$ = 0.87 Euro and 1 CAN$ = 1.2 Euro. Ask to convert 123 kWh and 3 BTU into Euro. 123 kWh = 13.53 US$ = 11.77 Euro and 3 BTU = 39 CAN$ = 46.80 Euro for a total of 58.57 Euro. Getting the final Euro probably assumes arithmetic is allowed (per test above).
8. Example of multiple paths & what happens if package really smart. Also, how stop some conversions.
9. See [CO2 conversions](https://www.epa.gov/energy/greenhouse-gases-equivalencies-calculator-calculations-and-references) to do example to CO2.

## Groups

Groups are what make this all interesting (because they aggregate values) but also add complications, many of which are noted above. We need to figure out the implementation, esp. when you have a group of groups. Also, we create a materialized view for aggregated daily readings for each meter to make OED faster. Should we do anything like that for groups, esp. given unit transformations?

We could use groups to decide in advance what unit is desired on aggregation. For example, you could have a group of all residence halls where it is the total energy and another that is cost. This would likely mean we need a better interface for groups and users would need access if this was the only way to choose. The tradeoff of this vs a units on demand system is unclear from the user, efficiency & implementation standpoint. Also, do groups have a unit similarly to meters? This may depend on whether they are static or dynamic in units used.

## Internal storage

OED may store SI (metric) units. A few people want us to store the raw meter value in that unit. However, the conversion should be very accurate and not introduce any significant error. We could choose to do arbitrary units for each meter but then we would need to convert before we aggregate whereas we can do the conversion afterward if they are all in the same unit. We still need to do conversions for units that are compatible but not the same unit such as kWh and BTU. This (see example #1 above) and (see example #2 above) show this. The final implementation will depend on other design choices.

## Graphical display

When we aggregate meters through a group, we may have the final result in a unit that is not desired by the user (see example #5 above). Thus, we are going to need to transform each data point back into the user desired unit. We need to decide where to do this conversion but it may well be fastest via the DB using SQL. Also, we need to know the unit that the user wants. This probably means the admin can set a default unit for each type (as they do with a default chart type, etc.). It may make sense for a site to choose between English, metric, British where all displayed results default to the default unit type for that region chosen by the admin. It would be good if the user can override this and change the graph display unit. For example, they might want to aggregate as energy, cost, etc. in another unit equivalent. If so, would we go back to the DB to redo all the work or do it in the user browser via JS?

How will we display meters/groups that have different units but are compatible. For example, you graph meters where some are BTU and some are kWh. Another (see example #7 above) is to show gas or electrical usage with temperature (or degree heating/cooling for each day which is a transformation of temperature) since one would expect usage for heating and cooling to be impacted by temperature. Some options are: disallow, display in specified default/given units that is compatible for all items in graph, show multiple scales, others. Another related complication is what if you want to graph items that do not have compatible units. The options overlap above but you cannot show in a compatible unit for all. Whatever we choose, we need to be sure the units are clear on any graphical display.

## Admin panel

A systematic way to add new inputs and edit these values needs to be developed. This will include individual values in text boxes as well as a robust CSV drop capability. This should allow for the needed entries in the admin panel now and in the future.

Note one way to edit meter data is to allow someone to download the needed meter readings as a CSV file, edit values desired for change, and then upload the CSV file.

## Related changes to consider in design

1. There is a long standing issue that OED shows kW on line, bar and compare graphs. Line should be kW as it is an instantaneous reading (but issue that is actually an average) but bar and compare really are kWh. This should be fixed up, esp. as OED understands and can store these different units. Finding a general solution would be nice.
2. We have wanted to allow scaling (at least +/- but general linear would be nice) when a meter is combined into a group. This might fit in with this work. (issue #[161](https://github.com/OpenEnergyDashboard/OED/issues/161))
3. Energy usage in buildings varies by size, number of occupants and the weather conditions. To allow sites to better understand how their energy usage compared to expectations and across buildings, we will allow the data presented to be normalized for these considerations. This requires normalizing data based on values in the database (except for weather where the data often comes from a weather service and hooking this up for some systems is part of this work). This is more important now that we have map graphics. \
 Here are [some ideas/plans from 2018 GSoC](./GSoc/normalize.md) \
 Here are some other ideas for normalizing:
    1. Sq feet or cubic feet
        1. Can vary with time
    2. people in building
        2. Will vary with time
    3. Weather: degree heat/cooling days, sunny/shady, wind
        3. Old work to get national weather service data
        4. [http://www.degreedays.net/](http://www.degreedays.net/) for degree days in CSV to correct data for weather, normalize data on 68 degree day is 0 for normal \
 Here are [some ideas/plans from 2018 GSoC](./GSoc/admin.md)

## DB generalize info

1. [Energy Star DB Schemas](./otherSources/EnergyDatabaseStarSchema.pdf) show how they do it and we should review.
2. Here are some older ideas on what might go into DB
    1. Meters
        1. Unit
        2. Note
        3. Frequency to read
        4. GIS coordinates
        5. Consumption vs. generation
            1. When do this need to fix graphs/compare so make sense. Now you use less if you generate less which seems backward since reverse of production.
        6. Draw related to meter - can vary with time
            1. no. people and/or no. people FTE
            2. Sq. feet - should we allow sq. m?
        7. Do we have to worry about reactive power, apparent power, power factor, Volt-amperes?
        8. Do we want to allow generalization to garbage and recycling by having pounds/Kg units?

### Items to remember

1. For testing, esp. steam that is harder, we might be able to use: Macalester College has (2) accessible Steam condensate at: [http://bigelowcond.meters.macalester.edu/start.html](http://bigelowcond.meters.macalester.edu/start.html) & [http://gddcondreturn.meters.macalester.edu](http://gddcondreturn.meters.macalester.edu)
2. See [https://github.com/jamielepito/OED/tree/api-tests/src/server/sql/group](https://github.com/jamielepito/OED/tree/api-tests/src/server/sql/group) for building work that was historical but may be useful to look at.
3. Some thoughts from Wadood in an 201128 email:

So I have gone over the document and obviously it raises some very important questions. I personally think that storing data in a single standard unit (SI/metric maybe) will be better as it will be easier to use that data in the code. Maybe we can put conversion algorithms/code in the 'pipeline' so that it is easier for us when coding.

Secondly, as far as changes to the DB go, I think maybe we can use multiple tables to store various types of energy sources but with a uniform SI unit. This will also have the additional benefit of the ability to group and store various types of meters separately according to their respective energy sources.

Thirdly, energy to cost conversions would be better if we can keep it as simple as we can. One step conversion would be more convenient than chained conversions and will require less time. As you have mentioned in the document, cost and other quantities can vary with time, in order to accommodate that my idea is to see what postgresql has to offer by default (for example postgresql giving us all the time zones). The other thing would be that the admin can change the quantities periodically so that the final output data and any relevant conversions give the up-to-date result.

## Information resources

- [conversionFactors.xlsx](./conversionFactors.xlsx) has a list of ways to relate one resource unit to another with the conversions. We may want to preload OED with some/all of these. They are separated by resource type/compatibility.
- An [older doc](./1711DBGeneralize.docx) with resource generalization thoughts including a number of details that may be valuable.
- [Anthony Database Resource Generalization Thoughts.odt](./AnthonyDatabaseResourceGeneralizationThoughts.odt) has thoughts on doing this and code that needs to be changed. A lot was already integrated into this document.
- [https://www5.eere.energy.gov/manufacturing/tech_deployment/amo_steam_tool/#Properties](https://www5.eere.energy.gov/manufacturing/tech_deployment/amo_steam_tool/#Properties) has lots of conversion information
- The [info from other sources folder](./otherSources/) has stuff found that might be useful, including:
  - [APPA key metrics poster](./otherSources/APPAKeyMetrics.jpg) with info on what they think are essential information
  - [Central building analysis with graphs](./otherSources/CentralBuildingProfiles.xlsx)
  - [Macalester energy analysis spreadsheet](./otherSources/Macalester_2015_2016_Campus_Energy_Rpt_Wkbk.xlsx)
  - [Macalester electric analysis spreadsheet](./otherSources/Macalester_Aggregated_Elec_Totals.xlsx)
  - [Getting energy on chilled water](./otherSources/HowToCalculateBTU_sOnCHWSystem.pdf)
  - [Steam flow info](./otherSources/steam_flow_measurement.pdf)

## Historical

### Meter types

Meters currently store their meter type as 1 of 2 enums (now three with obvius). If we’re generalizing resources, users might be adding a lot of different types of meters. Do we want to let users register their own meter types? Does the meter type in the database actually do anything other than get stored right now? What’s actually the difference between Mamac and Metasys meters in the code (we really should check that we are receiving data for the correct meter type when it arrives)?

- OED has now added the other type for meters that OED does not acquire data from and are unknown to OED. For now, we are not going to have user defined meters expect to add types as OED knows how to acquire data from a specific meter type.

### Multiple readings tables

All readings in the database are kept in a single readings table. Do we want to store all  reading types in this table or would there be any benefit in separating the different resources’ readings into multiple tables? When users add new resource types, do we automatically add a new table for it?

- OED seems fast enough to get readings when there are lots of them. Also, with the ability to combine various resource types into a single group/grapth, it is less clear that separating them out is a good idea. At least for now we are not going to pursue this.

## Analysis of unit packages - Historical

## Short list/Promising

- [https://mathjs.org/docs/datatypes/units.html](https://mathjs.org/docs/datatypes/units.html)
  - Wadood looked at & liked
  - Steve added some info and concurs
  - On short list
- [https://www.npmjs.com/package/js-quantities](https://www.npmjs.com/package/js-quantities)
  - Wadood looked at & liked
  - Steve looked at & concurs but concerned about upkeep and what exactly it can convert
  - On short list
- [https://www.npmjs.com/package/unit-system](https://www.npmjs.com/package/unit-system)
  - Wadood looked at; unsure why not marked at liked
  - Steve looked at and was encouraged but concerned that not maintained & did not find a license.
  - On short list

## Possible

- [https://www.npmjs.com/package/uom](https://www.npmjs.com/package/uom)
  - Wadood looked at
  - Steve looked at. Seems possible but unsure and also uncertain about maintenance. Could look at but wait.
  - High on possible list.
- [https://www.gnu.org/software/units/manual/units.html#Interactive-Use](https://www.gnu.org/software/units/manual/units.html#Interactive-Use)
  - Steve looked at & looked pretty good. However had some concerns about using it
  - On possible list
- [https://www.npmjs.com/package/@speleotica/unitized](https://www.npmjs.com/package/@speleotica/unitized)  
  - Wadood looked at
  - Steve looked at. Might be fine but only 1 person with limited use.
  - On possible list.
- [https://sourceforge.net/projects/jconvert/](https://sourceforge.net/projects/jconvert/)
  - Wadood looked at & liked
  - Steve looked at and was concerned in Java, not used much, no recent activity. Did not carefully check out features.
  - On possible list
- [https://www.npmjs.com/package/@allisonshaw/js-quantities](https://www.npmjs.com/package/@allisonshaw/js-quantities)  
  - Wadood looked at
  - Steve looked at and has concerns about upkeep, etc.
  - On possible list

### Unlikely (based on Wadood looking at)

- [https://sourceforge.net/projects/unit-converter/reviews](https://sourceforge.net/projects/unit-converter/reviews)
  - Wadood looked at
- [https://sourceforge.net/projects/tbunitconverter/](https://sourceforge.net/projects/tbunitconverter/)
  - Wadood looked at
- [https://sourceforge.net/projects/unit/](https://sourceforge.net/projects/unit/)
  - Wadood looked at
- [https://sourceforge.net/projects/lnrsoftunitconv/](https://sourceforge.net/projects/lnrsoftunitconv/)
  - Wadood looked at
- [https://www.unitconverters.net/](https://www.unitconverters.net/)
  - Wadood looked at
- [https://proglogic.com/code/javascript/calculator/lengthconverter.php](https://proglogic.com/code/javascript/calculator/lengthconverter.php)
  - Wadood looked at
- [https://github.com/ben-ng/convert-units](https://github.com/ben-ng/convert-units)
  - Wadood looked at

### Notes on packages (By Wadood Alam; sorted by Steve)

## Promising

### [https://mathjs.org/docs/datatypes/units.html](https://mathjs.org/docs/datatypes/units.html)

1. What is its main features of interest
   1. Do they have custom units (we want this)

        ⇒ Yes it does! Includes new base units. Allows for alias names for units. Does work in SI. Has built-in values for the common units we are likely to use including the prefixes (k, mega, etc.) Can also give the unit transformation so we can do it in Postgres.

   2. How do they store unit info

        ⇒ They use arrays for custom units

   3. What type of conversions can they do

        ⇒ I think they can do chained conversions. What they call chaining is a series of operations (such as add and multiply) but not what we mean. \
It appears to be able to simplify units and this might allow this too.

2. Can it be used directly in OED

    ⇒ yes it can be used. It is written in javascript and node.js. It is part of the larger Math.js package so unclear how much we need to use.

3. What is its software license (even if not open source)

    ⇒ Apache 2.0

    **I personally think this is a good package. It has good documentation, code, npm install etc**

    Notes: \
It can do arithmetic on values or arrays. \
Decent documentation \
Heavily used (300+k/week), on GitHub, around for 7+ years, mostly 1 developer but a few other (mostly in the past); moderately active \
8.5 MB so would add to our payload \
Need to see if can do chained conversions that OED needs.

### [https://www.npmjs.com/package/js-quantities](https://www.npmjs.com/package/js-quantities)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        Yes it seems like it does have custom units

    2. How do they store unit info

        They can be stored in the database

    3. What type of conversions can they do

        I think they do chained conversion b/c the manual did mention converting for celsius to fahrenheit, so I guess yes

2. Can it be used directly in OED

    I think yes(not sure). Written in Ruby. Steve found it is all JS.

3. What is its software license (even if not open source)

    MIT \
Notes: \
Okay level of downloads (15k/week) \
600k so small \
8 years old, changes but sporadic, mostly one person

    **I personally like this one, has good documentation and explanation**

### [https://www.npmjs.com/package/unit-system](https://www.npmjs.com/package/unit-system)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ Yes it does. You can create custom units and create a corresponding measurement for it.

    2. How do they store unit info

        ⇒ They use constant variables and you assign aliases to a unit as well.

    3. What type of conversions can they do

        ⇒ They do both types of conversions i.e chained and other.

2. Can it be used directly in OED

    ⇒ Yes it can be used directly with OED i think. The code is in js and uses npm.

3. What is its software license (even if not open source)

    ⇒ ISC (only shown on npm) \
Notes: \
Low download rate, nothing new in 2 years, done by one person 2 years ago and not activity since. \
75k so very small

    It looks like it does what we want but is it okay given status? \
Steve could not find the license

### Possible

### [https://www.npmjs.com/package/uom](https://www.npmjs.com/package/uom)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ It does have custom units. You can create units off of SI units or “base” units.

    2. How do they store unit info

        ⇒ It uses constant variables.

    3. What type of conversions can they do

        ⇒ There is no mention of this in the documentation and I have tried to look at the code. It seems that this might be possible.

2. Can it be used directly in OED

    ⇒ Yes it can be used with typescript.

3. What is its software license (even if not open source)

    ⇒ MIT

    **This looks like a decent package. It is relatively new and has good documentation etc. But might require some edits for chained conversions maybe…**

Notes: \
Moderate level of usage \
Periodically updated, by 1 or 2 people \
Only 335 k size \
May do what want but need to check out.

### [https://www.gnu.org/software/units/manual/units.html#Interactive-Use](https://www.gnu.org/software/units/manual/units.html#Interactive-Use)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ yes & it does complex units; has many built-in units

    2. How do they store unit info

        ⇒ files

    3. What type of conversions can they do

        ⇒ may do chained via calculator function

2. Can it be used directly in OED

    ⇒ has a command line interface; has unix and windows versions; it is written in C with makefiles

3. What is its software license (even if not open source)

    ⇒ GPL 3+ \
Notes \
GPL harder to deal with but okay \
C going to be harder to use; provides releases via ftp not standard package way and not on standard repo site \
It does a lot but should look at others first

### [https://www.npmjs.com/package/@speleotica/unitized](https://www.npmjs.com/package/@speleotica/unitized)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ You can declare your own units using the API.

    2. How do they store unit info
    3. What type of conversions can they do

        ⇒ I don’t think it can do it by default. Maybe we can edit it and allow for it.

2. Can it be used directly in OED

    ⇒ Yes it can. Typescript is used.

3. What is its software license (even if not open source)

    ⇒ MIT \
Notes: \
Very few downloads/week

    All done about 1 year ago by a single person; 13 old and open PRs, no issues

    Small 450k size

    Might be interesting but not first one to look at

### [https://sourceforge.net/projects/jconvert/](https://sourceforge.net/projects/jconvert/)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ It mentions custom conversions so I think it supports custom units.

    2. How do they store unit info

        ⇒ The code is written in java and they are using arrays(among other things like hash maps) to store into.

    3. What type of conversions can they do

        ⇒ They can do custom conversions and also chained conversion.

2. Can it be used directly in OED

    ⇒ It can be integrated I think. But the interface is windows based so a little unsure.

3. What is its software license (even if not open source)

    ⇒ [GNU General Public License version 2.0 (GPLv2)](https://sourceforge.net/directory/license:gpl/)

    *This looks like a decent package but will require edits. It is a bit old though* \
Notes:

    Very low download rate \
From 10+ years ago and don’t see any recent activity (last 5+ years ago) \
It is in Java so less desirable

### [https://www.npmjs.com/package/@allisonshaw/js-quantities](https://www.npmjs.com/package/@allisonshaw/js-quantities)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ Unsure about this

    2. How do they store unit info

        ⇒ I think it uses arrays

    3. What type of conversions can they do

        ⇒ I think they allow for chained conversions

2. Can it be used directly in OED

    ⇒ Yes it can

3. What is its software license (even if not open source)

    ⇒ MIT \
Notes: \
Very few download/week \
Only 1 version ever published, last work was 2+ years ago, mostly done by 1 person

### Unlikely of interest but only based on Wadood looking

### [https://sourceforge.net/projects/unit-converter/reviews](https://sourceforge.net/projects/unit-converter/reviews)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        I don’t think it allows custom units although has a lot to choose from

    2. How do they store unit info

        The website does not connect so unable to find that information

    3. What type of conversions can they do

        I think it does NOT do chained conversions, but again, not enough info available

2. Can it be used directly in OED

    Probably not because it seems to have exe files. More suitable for windows OS. Also has an interface.

3. What is its software license (even if not open source)

    GNU public license version 2.0

### [https://sourceforge.net/projects/tbunitconverter/](https://sourceforge.net/projects/tbunitconverter/)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        Doesn’t seem so

    2. How do they store unit info

        Has an API that takes in the values

    3. What type of conversions can they do

      Can’t tell

2. Can it be used directly in OED

    Probably not because it has an outdated API for mac.

3. What is its software license (even if not open source)

    GNU public license version 2.0

### [https://sourceforge.net/projects/unit/](https://sourceforge.net/projects/unit/)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        Doesn't look like it has. Couldn’t access the code for this as it is on git, instead on csv.

    2. How do they store unit info

        Couldn’t access the code for this as it is on git, instead on csv.

    3. What type of conversions can they do
2. Can it be used directly in OED

    Probably yes because it is written in java.

3. What is its software license (even if not open source)

    [Public Domain](https://sourceforge.net/directory/license:publicdomain/), [GNU Library or Lesser General Public License version 2.0 (LGPLv2)](https://sourceforge.net/directory/license:lgpl/)

### [https://github.com/ben-ng/convert-units](https://github.com/ben-ng/convert-units)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        They do not have custom units. But they have a generous collection of units.

    2. How do they store unit info

        They are using javascript and its data structures,

    3. What type of conversions can they do

        They cannot do chained conversions.

2. Can it be used directly in OED

    Yes I think we can integrate it easily. Has a simple chained API.

3. What is its software license (even if not open source)

    Copyright (c) 2013-2017 Ben Ng and Contributors

### [https://proglogic.com/code/javascript/calculator/lengthconverter.php](https://proglogic.com/code/javascript/calculator/lengthconverter.php)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ I don’t think they have custom units. It seems they just have basic javascript code for a few conversions.

    2. How do they store unit info

        ⇒ Just a regular function call and getting the value from the front end. Uses setters and getters i think.

    3. What type of conversions can they do

        ⇒ it can do regular conversions. Unsure about chained conversions, it does do fahrenheit conversions though.

2. Can it be used directly in OED

    ⇒ Yes it can be integrated very easily as it is just javascript code.

3. What is its software license (even if not open source)

    ⇒ It seems open source to me.

### [https://sourceforge.net/projects/lnrsoftunitconv/](https://sourceforge.net/projects/lnrsoftunitconv/)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ Doesn’t seem to have to costum units. It’s more oriented towards popular units.

    2. How do they store unit info

        ⇒ unable to find the source code or details in wiki. So don’t know where they store unit info.

    3. What type of conversions can they do

        ⇒ Just regular conversions.

2. Can it be used directly in OED

    ⇒ seems like a windows interface so I think not.

3. What is its software license (even if not open source)

    ⇒ [GNU General Public License version 2.0 (GPLv2)](https://sourceforge.net/directory/license:gpl/)

### [https://www.unitconverters.net/](https://www.unitconverters.net/)

1. What is its main features of interest
    1. Do they have custom units (we want this)

        ⇒ It does not

    2. How do they store unit info

        ⇒ was unable to find to the source code so cannot tell

    3. What type of conversions can they do

        ⇒ They have a variety of conversions they can do.

2. Can it be used directly in OED

    ⇒ It is hard to tell. No code available

3. What is its software license (even if not open source)

    ⇒ Open source maybe.not sure. Very vague
