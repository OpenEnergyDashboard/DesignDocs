# oed-resource-generalization

# Warning

**This is far from done and it isn't consistent. However, the old version is so far out of date with current thinking that this one is being shared. Many edits are expected in the near future.**

# ??TODO DO NOW

- fix up all ?? items
- change functions that return unit to be index and convert to name when shown
- See code Z on notes for needing to add units renamed from path in graph and adding to all units to consider. Think through.
- check when should loop over units with unit_index != -1 (in Cij) and when all/unit ones with issue that ones derived from graph conversions and name changes
- make sure y-axis label and places units shown use identifier and not name
- if default graphic units is fk then how deal with no unit. The functions with type?? relate because unsure if string or id.

## Items that need to be addressed

- See all the places with a TODO and address.
- Need to figure out how to do steam as heating energy and maybe chilled water. The issue is it comes as multiple values so either need an extension to OED or need to precalculate the single value and store (but then lose original values). Add to OED units as needed.

**Please use care in editing the document so the ideas stays intact until a final decision is made and nothing bad is done to the document. Having said that, this is a living document that you can edit.**

??TODO the equations were originally done by <img src="https://render.githubusercontent.com/render/math?math=math eqns \neq"> but seem to work with just $. This can be removed once sure works on GitHub.

This is a working document (started Nov 2020 but includes previous work/ideas) that gives ideas on how to generalize OED resources from electricity to any type (hopefully). The previous document when we thought we would use a unit conversion package is [available](unitPackageIdeas.md)

Note: The equations in this document should render in Visual Studio Markdown Preview window. They are in LaTex format. Also note that a heading must be lowercase and words separated by - to allow links so this is used throughout this document.

## overview

OED started by working with electrical data as a proof of concept and to support the resource requested the most. With that complete, OED is generalizing to support any resource such as natural gas, water, steam, recycling, temperature, etc. Instead of addressing these as individual cases, OED is being modified to store information about compatible resources (energy, power, volume, temperature, etc.) and how to convert between them. This will allow OED to address several feature requests with this single change including:

- Allow arbitrary resource units (natural gas, energy, power, etc.).
- Allow sites to choose the unit for graphical display where the most common request is for English vs. metric units.
- Allow OED to display usage in units not associated with resource consumption such as CO2, cost, equivalent miles of driving a car, etc., which may be more natural to some users and allow for common sustainability units to be used.
- Allow OED sites to add new units to the system that are not automatically supplied with OED

The idea behind the system is that all compatible resources can be converted from one to the other via a linear transformation. For example, 1 BTU is 2.93x10-4 KWh. While most conversions are multiplicative factors, temperature is the one notable exception where Fahrenheit = 1.8 * Celsius + 32.

Note that even though we are the Open Energy Dashboard, this generalization will allow for non-energy units such as volume, temperature, money, etc.

The GitHub issues #[211](https://github.com/OpenEnergyDashboard/OED/issues/211), #[214](https://github.com/OpenEnergyDashboard/OED/issues/214) & #[164](https://github.com/OpenEnergyDashboard/OED/issues/164) relate to units/generalization. Displaying by cost is related to issue #[61](https://github.com/OpenEnergyDashboard/OED/issues/61). This may also relate to the request to negate meters (issue #[161](https://github.com/OpenEnergyDashboard/OED/issues/161)) as this is a special case of a linear transformation. It is planned that completion (at least to a reasonable degree) of this work will be OED release 1.0 as a fully functional dashboard. Issue #[139](https://github.com/OpenEnergyDashboard/OED/issues/139) on adding notes to items has some relationship to this.

## units-and-conversions-overview

The heart of the system is allowing for conversions between compatible units. Compatible units are ones that can be aggregated because they can all be converted to the same unit and this is also logical. See [examples](#examples) for sample conversions and [unit compatibility section](#determining-units-that-are-compatible-with-a-meter-or-group) for more on what compatibility means.

While most conversions are multiplicative factors, temperature is a linear transformation. Thus, we will use linear transformations/conversions (ax + b or the same slope * x + intercept) in OED where most will have b = 0. We will need to think about whether we should optimize the case of b = 0 or if it does not make any practical difference.

To simplify what conversions must be input by an admin, we will allow what we call chained conversions. This means that you have conversions from a -> b and b -> c and the user wants to get a -> c. With chained conversions, OED will be able to figure out a -> c from the other two. Without this the admin would be required to input a direct, one-step transformation for any desired conversion. With chained conversions the system may figure out allowed conversions that admins were not thinking of and allow them as options; [Example](#examples) #9 shows this. An advantage of chained conversions is it is much simpler to store meters in their original units because they can automatically be converted to other compatible units for grouping.

Users will want to define their own units. For example, they need to enter the cost of kWh, BTU, water, etc. They will also want to define display units such as CO2 (we will likely supply this one) and energy usage equivalent to driving a car, pizza deliveries, etc. We don’t know everything people will want so we should allow them to enter new ones.

## sample-conversions

As discussed in more detail in the [compatibility section](#determining-units-that-are-compatible-with-a-meter-or-group), the problem of determining compatible units is the same as seeing if a path exists from the starting to the desired unit. The following graphic shows a graph with units where the allowed conversions are are the edges:

![image of sample conversions](sampleConversions.png "image of sample conversions")

Notation in figure: W is Watts, kWh is kilo-watt-hour, BTU is British Thermal Unit, MJ is megajoules. The black rectangles are meters, the orange ovals are basic units and the blue ovals are units that are different. Note the two types of units are the same in terms of the graph but shown in different colors to indicate that the linking is different. More details are [elsewhere](#vertices).

The double-ended arrow to/from MJ and BTU indicates that you can convert from MJ to BTU and BTU to MJ. The single dashed orange arrows indicate the unit of a meter, e.g., Electric utility to kWh means the meter is reporting to OED in kWh. The single solid black arrow from Trash to kg CO2 indicates you can only convert from Trash to CO2 (there is a standard conversion for CO2 from Trash). If the arrow went the other way then you could take CO2 and create trash which is not allowed. An example of a chained conversion is taking the Trash meter that collects in kg and displaying it in US tons. You would do the sequence of conversions of Trash -> kg -> lbs -> US tons meaning first you convert the kg to lbs and then the lbs to US tons. You could also do Trash -> kg -> Metric tons -> US tons. The result would be the same and OED will arbitrary choose which one to use since the path length is the same.

It may seem strange in the example just done that you first do the Trash -> kg conversion. This conversion is actually the identity conversion (slope = 1, intercept = 0) so it does not change the values and this is normally the case. That is part of the reason the arrow is dotted and orange. The need for meters is shown by having Electric utility and Electric solar meters. When you are working with energy, you first convert to kWh as shown and this is similar to the conversion of Trash to kg. Note, that both Electric utility and Electric solr have conversions to US dollar and they are different lines so produce different values. This makes sense because the cost of creating electricity is different for these two sources. This is one example of why meters are decoupled from the unit they collect in. Note that two different electric meters that both measure kWh coming from the utility can both use the Electric utility unit.

There are units for cubic meters of gas and cubic meters. While they both may seem to be volume, they are not. Cubic meters of gas is an energy unit and represents the amount of energy that a given volume of gas represents. It is a standard unit of measure. Cubic meters is a volume measurement. If you used cubic meters for both and had a conversion from cubic meters to energy (say BTU) would lead to a weird conversions. Since we allow chained conversions, you could take Water -> liters -> cubic meters -> BTU and that makes no sense since water is not energy. The different fundamental units remove this issue.

There are three meter units for Natural Gas. One for cubic meters that measures the amount of gas and another records the cost in US dollar. You can also convert the Natural Gas that is cubic meters into US dollar. This was done to show the generality of the system. At a site they may have a meter to measure the quantity of gas consumed (Natural Gas in cubic meters). They may also manually load in cost data for the natural gas (Natural Gas in US dollar) and this is the second meter type. This would be the actual cost from the utility and not a set cost represented by the conversion of Natural Gal in cubic meters to US dollar. The former is likely to be more accurate and may include fixed costs. The third meter is Natural Gas in BTU. Both the Natural Gas in cubic meters and BTU record energy. A site can have meters that measure in different units for the same type of item (gas here). This setup allows recording the original values in a simple way so special software is not needed to convert meter data to required OED units that are the same for all meters of the same type.

## examples

Here are some examples that show how conversions can and cannot happen with the given example/system. They show use cases for actual use in OED.

1. Determine total energy usage in MJ from meters that are both Electric utility in kg & Natural gas in cubic meters. You do the conversion Electric utility -> kwh -> MJ and Natural Gas -> cubic meters -> MJ. You can do this for as many meters are associated with each starting unit. Once all the meter values are in MJ you can sum them up to get the total MJ for all such meters desired. Note that including meters that measure in Natural Gas BTU is not fundamentally different. They would be converted by Natural Gas -> BTU -> MJ and then combined with the other two. Note that displaying each meter separately is the same except you do not do the final summing. This is true in all examples.
2. Determine total cost in US dollars for meters that are Electric utility, Electric solar, Natural gas in cubic meters, Natural Gas as BTU & Water. This is not fundamentally different than example #1. You do each conversion to US dollars and then sum them. The needed conversions are: Electric utility -> US dollar, Electric solar -> US dollar, Natural Gas as cubic meters -> US dollar, Natural gas as BTU -> Euro -> US dollar in cubic meters & Water -> Euro -> US dollar.
3. Determine total CO2 as US tons from Natural Gas as BTU & Trash in kg. Convert Natural Gas as BTU -> kg CO2 -> kg -> lbs -> US tons & Trash in kg -> kg CO2 -> kg -> lbs -> US tons and then sum. Note you could add Electric utility meters since there is a conversion to kg CO2 but you cannot do it for Electric Solar since there is not conversion to kg CO2. This is an example of a unit that is linked to other units in only one direction but is the same in other respects.
4. Determine total volume as liters of Natural Gas as cubic meters and water as liter. This request does not make sense even though both seem to have a common unit of volume. This is not possible since there is no path from Natural Gas as cubic meters to liter so it does the right thing. See the [sample conversions](#sample-conversions) for why this is not allowed and the unit types.
5. Determine total cost as Euros for Natural Gas as cubic meters and water as liter. This is done by Natural Gas as cubic meters -> US dollar -> Euro and Water -> Euro and summing. This is just shows that even though the last one was properly excluded, this one does work.
6. Display total energy usage as 100 watt bulb for 10 hrs (1 kWh) for both Electric solar as kWh and Natural Gas as BTU meters. This is done by Electric solar as kWh -> kWh -> energy usage as 100 watt bulb for 10 hrs and Natural Gas as BTU -> BTU -> MJ -> kWh -> 100 watt bulb for 10 hrs then sum. This is very different but shows an example with a unit with only links into it.
7. Display Natural Gas as BTU along with the temperature in Celsius. This is interesting since heating costs vary with temperature. These are not compatible units and there is not a desire to combine them. What the user wants is two lines on the same graph. This requires us to display two y-axis units (one for BTU and one for temperature). We need to have a way to determine when the user is asking for aggregation (sum) vs. two separate lines/values. Note that if we wanted something other than BTU for the energy then that would be a transformation to do first before displaying. See [potential future work](#potential-future-enhancements) for dealing with this.
8. Display Natural Gas in cubic meters from US dollars. This request does not really make sense as the dashboard should not be buying things. It cannot happen because the conversion can only go the other way. It also won't be an option for the user since they have to graph a meter and US dollar is a unit.
9. Determine total volume as liters of Gasoline and Water meters. This is allowed because both meters are linked to liter. However, you really don't want to do this since they are very different types of liquids. Here are thoughts:
    1. You can graph them both as separate meters each with its own line. If you understand what it means then this is okay.
    2. If you put both types of meters into a group then you will get a line with the sum. This is probably a bad idea. The way around this is for the admin not to put them in a group and that is what you would expect.
    3. Create a new type of liter Gasoline. Then link the Gasoline meter to this unit. This unit has the same links as the current figure with Gasoline (to BTU and Euro). Now you cannot group it with water and cannot graph it with water. The two negatives are that you need to create this unit and you cannot automatically convert it to other volume units because there is no link to liter. To get other units you need to create other Gasoline units and link them to allow conversion.
This is all okay but needs to be documented for admin/user.
10. Add power units to example. They should act the same as the other units and will be disjoint from them so no conversion issues should exist.

## determining-units-that-are-compatible-with-a-meter-or-group

Finding whether two units are compatible is the same as determining if a path exists in an unweighted, directed graph. Each vertex is a desired type of unit in OED. If an edge exists then there is a conversion between the two vertices/types. If u_source is the starting unit and u_destination is the ending unit then if u_destination is reachable, e.g., there is a path, from u_source then there is a conversion from u_source to u_destination. This means u_source is compatible with u_destination. Since this is a directed graph, this does not mean there is path from u_destination to u_source and this is very important to avoid unwanted conversions. The problem of determining if a multiple meters are compatible with a unit can be determined by seeing if the unit is reachable by every meter. Determining if a path exists and the actual path is the shortest path algorithm for a single source or all sources and it can be done reasonably efficiently. Given OED will probably have less than 100 units, this is a very practical solution.

## supporting-structure-for-units

OED needs to figure out if a set of meters is compatible with a given unit. In the case of a group, the set of meters is all the underlying meters of the group. This is a recursive process where any included groups must then be analyzed. A meter is a special case where the set has only one member. How the overall conversion from one unit to another is done is [discussed below](#graph-details) and for now we assume we have this information.

OED will have a 2D array of conversions between units that we will call Cik where i is the row and k is the column. Both the rows and columns will contain all units. Thus, if #units is the total number of units there will be #units rows and #units columns with a total of $\rm\#units^2$ entries in the array. Each entry will specify the conversion from unit i to unit k and the y-axis display unit (not need for this). (Recall i to k differs from k to i.) The conversion is specified as a pair of real values of (slope, intercept) so the conversion is unit_k = slope * unit_i + intercept. If there is no conversion from unit i to unit k then slope = intercept = NaN so you have (NaN, NaN). (Note, earlier it was consider to use slope of 0 but if you are converting solar energy to CO2 you might use this value. Useful for groups of energy with total CO2 so can do total energy & CO2.) It could be any value but using NaN makes products give the desired result (see below). It isn't clear that is a big win so another value could be chosen. The [edges section of graph details](#edges) discusses the creation and maintenance of the Cij array but is suffices to note here that it will not change very often and is thus a useful structure to speed up the calculations around units.

A set of units is compatible with a given unit d if and only if
$$\prod_{i=\rm{units\ in\ set}}C_{id}\ \rm{slope} \neq NaN$$
so it is not compatible if it is NaN. This is true since NaN as either operand in arithmetic operations results in a NaN so the product is NaN if any of the slopes are NaN. The $C_{id}\ \rm{slope}$ is the slope associated with the conversion stored at that index in the array. It isn't clear if OED will use this in the actual code.

When this structure is used by OED, it will often start from a meter name. The name of the meter can be used to get the values associated with the meter (already provided in OED software). One of these values will be the unit that the meter receives data.

## determining-compatible-units

In what follows, the graphic unit will sometimes be set to "no unit". Rather than include "no unit" logic in determining compatibility and in the following pseudocode, it is always treated as a separate case. This was chosen since other items were either all compatible or not compatible so all the work to perform the tests could be avoided. As such, "no uni" is not considered one of the units but a placeholder for special unit situations that are treated separately.

The details of why compatible units is needed are given later but OED needs to determine what units are compatible with a set of meters. For example, this would allow you to know all the possible units you can use to graph this set of meters. To do this analysis, start with a set with only one meter. The set of compatible units are all units that are compatible with the type of unit that the meter collect. This can be gotten from Cij by getting the unit_index from the meter name and then looking across row unit_index of Cij to find all conversions where the slope is not NaN. This is the same as the product idea above. Now, if you have a set of meters to find compatible units for, it is all the units that are compatible with all meters in the set. This is the intersection of all the sets of compatible units for each meter. This can be expressed in pseudocode as

    // Takes a set of meter ids and returns the set of compatible units as names.
    function Set unitsCompatibleWithMeters(Set meters) {
      // The first meter processed is different
      boolean first = true
      // Holds current set of compatible units
      Set compatibleUnits
      // Loop over all meters
      for each meter M in meters {
        // Get row in Cij associated with this meter
        integer m = unit_index of M
        // Set of compatible units with this meter.
        Set meterUnits = unitsCompatibleWithUnit(m)
         // meterUnits how has all compatible unit names. ??TODO actually index
        if (first) {
          // First meter so all its units are acceptable at this point
          compatibleUnits = meterUnits
          first = false
        } else {
          // Do intersection of compatible units so far with ones for this meter
          compatibleUnits = compatibleUnits ∩ meterUnits
        }
      }
      // Now have final compatible units for the provided set of meter
      return compatibleUnits
    }

    // Return a set of units as an index into units table/Cij that are compatible with row in Cij.
    // This is all columns with slope = Nan in row row of Cij.
    function Set unitsCompatibleWithUnit(integer row) {
      // units starts as an empty set
      Set units = {}
      // Loop over all columns of Cij in row m
      // # units is same as the row or column dimension of Cij
      for k = 0 to # units - 1 {
        if (C[m]k] != Nan) {
          // unit at index k is compatible with meter unit so add to set.
          units += M
        }
      }
      return units
    }

The compatible units of a group can be determined by the above function by determining all the child meters recursively and creating a set of the unique meters. Start with this function:

    // Returns the set of meters associated with the group_id used by the OED software and in the database for the group.
    function Set metersInGroup(integer group_id) {
      // The group model (src/server/models/Groups.js has function getDeepGroupsByGroupID that will get all these ids)
      // It is unclear what the unit will be on meters - depends on how done in the end.
      meters = Get all child meters for group_id
      // Make the ids into a set. Not needed if already a set.
      Set metersSet = meters as a set
      return metersSet
    }

One reason this is made into a function even though there is an easy way to get the needed ids is that this will take a modest amount of time for each group and it will take more if there are lots of included groups, recursively. If it is too slow then OED can either precalculate the meters of the group (maybe even storing in DB and loaded when OED starts) or use dynamic programming to only calculate the first time and then store the result. If stored in DB then need to update appropriately. That would make this an O(1) operation excluding the initial calculation. This would also allow OED to easily display all the meters associated with a group as requested in [issue #591](https://github.com/OpenEnergyDashboard/OED/issues/591). The first shot should just do the function as is to see it works properly and then the OED team can discuss the optimization.

The compatible units of a group is then unitsCompatibleWithMeters(metersInGroup(group_id)).

The function unitsCompatibleWithUnit takes O(# units) and unitsCompatibleWithMeters takes O(# meters in Set meters x # units). Since the set of meters passed to unitsCompatibleWithMeters changes with user selection, it cannot easily be precalculated. If the overall process takes too long, OED optimize as proposed for metersInGroup. However, since the it will then take time of the number of unis compatible with the meter instead of # units, this will likely be a more modest speedup than the one for group child meters just above. The first shot implementation will not do this.

The functions in this section will be used below when changes to the graphics, meter and group pages are described.

## graph-details

### vertices

The graph will have two types of vertices. The graph store program probably will not know this so it is enforced via software. The vertex type will impact how it is used in the graph. The two types are:

1) unit. When edges are added using this vertex, the vertex can be the source and/or destination vertex. When both the source and destination vertex is of a fundamental unit (SI units and similar ones), then it is common for the link to go both ways (bidirectional) where the conversion in one direction must be the inverse of the conversion in the other direction. Obviously, only compatible units should be linked. In the example, the orange ovals are this type of unit, e.g., BTU can be converted to MJ and MJ can be converted to BTU. For certain units, esp. ones defined by the site, the link only goes one way. In the example, the blue dashed ovals are this type of unit. In the case of CO2, the arrow goes from CO2 to kg with the identity conversion (1, 0). This allows the quantity of CO2 to be converted to any of the mass units (lbs, Metric tons, etc.). In the case of 100 W bulb for 10 hrs, the arrow goes from kWh to 100 W bulb for 10 hrs. The conversion happens to be the identity since 100 W x 10 hrs is 1 kWh. Another example would creating the custom unit for liter Gasoline ([see example 10](#examples)) but then add a link to liter. This causes the issue that existed when this was done for the Gasoline meter. It is possible to do but the admin should avoid this for the same reason. It is an example of a bad use of outgoing link from a unit when there are incoming links.  
Why do the units have these different types of arrows? If you are deals with fundamental units that can be interchanged back and forth and the new unit makes sense then it is bidirectional. In the case of CO2, it is not a fundamental unit. If the arrow went both ways to include kg to CO2, then you could do Trash -> kg -> CO2 kg so trash would be shown as kg of CO2. This is not desirable so this direction of the arrow is not included. Now, why does the arrow go the other way? We want to allow the user to select any mass unit for CO2 so it could be kg, lbs, etc. The arrow in this direction permits these conversions. In the case of 100 W bulb for 10 hrs, we want the user to be able to display in this unit so the arrow only goes into this unit. While it would not cause issues, having the arrow go in both directions would allow converting from 100 W bulb for 10 hrs to other energy units. In this case we really need to label this bulb and have the unit be 1 kWh (100 W x 10 hours). Then we could convert the kWh to other energy units but then you have bulb kWh, bulb BTU, etc. and users don't think of bulbs in this way. Thus, the arrow does not have 100 W bulb for 10 hrs as the source.  
A final issue is how units will be named for display. For most units, when you convert to another unit the graphic should label the y-axis with that unit. In [example #2](#examples), several different meter units are converted to US dollar. It does not matter what the original units are, OED should label the y-axis as US dollar. Most units work this way including units that have bidirectional links. The units with one directional links, esp. where the arrow is away from that unit, can be different. In the case of CO2, you can convert the kg to lbs. If we just labeled it as lbs then it would be misleading. It is lbs of CO2. To allow this, each unit will have a suffix value. In the case of kg CO2 is will be CO2 but in most cases it will be blank. (In the sample ecample diagram, units with bidirectional links have no suffix listed and it is assumed blank. In the case of 100 W bulb for 10 hrs it is --- to indicate it is blank.) When the [path is determine](#determining-conversions), the suffix to use for display is equal to the last suffix that is not blank. (It seems unlikely that two units on the path will have suffixes but we cover that case.) If they are all blank then it is blank. The graphic unit is the final unit of the conversion followed by the suffix. In [example #3](#examples), it would be US tons because all suffixes are blank along each path except for CO2 and the y-axis label would be US tons CO2. In examples without CO2, the suffix would be blank so the y-axis would be labeled with the final unit.  
How do units get the correct type of links? The majority will be provided by OED and be correct. Others, such as adding a new unit of money can follow what OED provides for other money units. In other cases, the admin adding the unit needs to analyze the situation to get the correct type of link. A mistake should not lead to incorrect results but will allow for displaying of funny units.

2) meter. When edges are added using this vertex, the vertex must be the source and cannot be the destination. Thus, a meter vertex can be converted to another unit type but other unit types cannot be converted to a meter. These are expected to be used to represent a meter. It may seem strange that a meter resides in the graph but this controls allowed conversions and specifies the unit of the meter inside the graph. The [examples](#examples) also show that this allows for different types of meters with the same unit to have different transformations such as electric meters from solar vs electric meters from the power grid to money units. Generally a meter vertex will link to the unit of the meter where that the conversion has slope = 1 and intercept = 0 so not actual conversion happens. For example, it could be a kWh electric meter linked to the kWh unit or a liter water meter linked to the liter unit.

### edges

Edges represents a conversion between the units of two vertices (it really is the reading value for the meter when the source is a meter). The constraint on edges is given in the [vertices](#vertices) section. The graph is unweighted and the conversion factors are not stored in the graph. They are found from the path of the shortest path algorithm run on the graph as described the section on [determining-conversions](#determining-conversions). Note that it is possible to have multiple paths leading from one source to one destination. Fundamental units with bidirectional links should not be an issue since all their conversions should be consistent. For units with only incoming links this cannot happen. When there outgoing links that are not bidirectional, it could pose an issue. However, it is unclear that any such use will be useful in OED and seems to come from a misuse/problem. Thus, this issue is considered settled. The graph algorithm will provide the shortest one (or one of the shortest ones if multiple of the same length so in that last case of potentially inconsistent paths a consistent value will be displayed). This will be a little more efficient for OED to deal with the path but does not matter in principle since all paths have equivalent conversions. The trash example in [sample-conversions](#sample-conversions) shows one of these where you can get to US tons through two paths with the same overall conversion.

### determining-conversions

It is assumed that the shortest path algorithm will return the edges associated with the path between the source and destination units. It is also assumed that the information returned will allow OED to look up the conversion represented by each edge in the path and the information on the nodes involved. For example, it is possible to return a tree where the source is the root, the leaves are reachable destinations and each node passed through represents a vertex on the path. Each pair of vertices in a path from the root to the leaf would give OED the source and destination to look up the conversion and node information. The exact details will depend on the graph software used and how we store the conversion/node information in OED.

Lets say you want to know the conversion from source vertex a to destination vertex e where the path goes through all the inclusive letter vertices so it is a -> b -> c -> d -> e. For each edge i -> k, there is an associated conversion we will label CONVik that has CONVik.slope and CONVik.intercept for the two values of the conversion. The overall conversion a -> e can be found by combining the conversions of each edge. We describe a single conversion as a mathematical function of conv(slope, intercept, x) = slope \* x + intercept. Thus, the first conversion would be
conv_ab(CONVab.slope, CONVab.intercept, unit) = CONVab.slope * unit + CONVab.intercept. The second conversion would be similar with ab replaced by bc. To add the second conversion to the first, compose the first conversion with the second so

    conv_ac(slope, intersept, unit)
        = conv_bc(CONVbc.slope, CONVbc.intercept, CONVab.slope * unit + CONVab.intercept)
        = CONVbc.slope * (CONVab.slope * unit + CONVab.intercept) + CONVbc.intercept
        = CONVbc.slope * CONVab.slope * unit + CONVbc.slope * CONVab.intercept + CONVbc.intercept

Thus, slope = CONVbc.slope * CONVab.slope and intercept = CONVbc.slope * CONVab.intercept + CONVbc.intercept and are the logical values for CONVac. This can now be combined with CONVcd to get logical CONVad, etc. 

The code also needs to keep track of the [prefix for the final unit](#vertices). Assume CONVik.prefix has this value stored in it for conversion i -> k. It also needs the unit name to display which is in CONV.destination.identifier because we want the destination unit.

The overall pseudocode is:

    // Assumes a path exists because it will return identity conversion if loop does not execute, could easily return something else but why :-)
    // Initial values so the starting conversion is the identity.
    slope = 1
    intercept = 0
    // The prefix is blank by default.
    prefix = ""
    Loop over path edges for source to destination
      get CONV.slope, CONV.intercept, CONV.prefix that are the current edge values
      slope = CONV.slope * slope
      intercept = CONV.slope * intercept + CONV.intercept
      if (CONV.prefix != "") prefix = CONV.prefix
      // Grab the last unit in the conversion, can skip if can easily get after loop
      lastUnit = CONV.destination.identifier
    // end of loop, slope, intercept and prefix are the ones for the whole path.
    // The y-axis unit for labeling is lastUnit + prefix.

The array Cij can be set as follows. Call the graph algorithm to determine paths from all vertices to all other vertices. This may be a single call or multiple calls (such as one for each source vertex). If a path exists between units, i.e, i -> k then use the pseudocode above to get the slope, intercept and y-axis unit. Store these results in Cik. If there is no path then set slope = intercept = NaN and the y-axis unit can be any string so make it an empty string. By looping over all the rows and columns in the array you can completely fill it in. Note a special case: if i = j so it is on the diagonal, the code should set so it converts to self with slope = 1, y-axis = 0 and y-axis label is the unit of the vertex associated with this index.

Where to calculate Cij? Given that Cij won't be too big, it seems best to do the calculation on the server and then send to the client. The current ideas mean the client only needs Cij to do its work. This could be changed if there are speed issues.

When does Cij need to be calculated? OED needs this information when it first loads into the web browser. If this is fast then OED can recalculate each time or it can store in the DB and retrieve each time. We can start with recalculating and store in the DB if speed becomes an issue or do as a later optimization. Cij also needs to be modified in the following circumstances:

- A new unit is created via the [admin unit page](#new-admin-unit-page). All the current values stay the same but a new row/column is add where every value indicates that no path exists.
- A conversion is changed including being added on the [admin unit page](#new-admin-unit-page). While it may be possible to figure out which values need to be updated, for now we will update the entire array using the method described above for creating Cij. It is possible an admin will make a series of unit changes so we should have a save button to put any number of changes into the database. Right after that happens, OED needs to reload Cij just as it did at startup to get the new values.

It is not expected that this will happen very often and it will only happen to an admin who is working on units. Other users will delay seeing the unit changes until the reload OED into the web browser.

## default_graphic_unit

There is a startup consideration in determining the graphic unit. When no meter or group has been selected for graphing, it is unclear what unit to use when one is selected since, in general, there are multiple choices. Note the same situation occurs if the user later deselects all meters and groups. OED could make the user decide by either selecting the unit in advance or choosing a compatible one once the meter is selected. First,  this might confuse the user and be overly complicated to decide the best unit. Second, the admin who created the meter/group may have thoughts on the best default unit the user will see. Thus, OED will have the admin choose the default graphic unit for the meter and group and it will be stored with the meter/group. This unit will be used when the first meter or group is selected and will be made the graphic unit. For further meter/group additions to the graph, this unit will be used.

The admin can make the default graphic unit be an unit that is compatible with that meter or group. Note that the default graphic unit does not change the compatibility units of the meter/group but is consistent with them. OED thought about forcing the admin to select a default graphic unit but chose to make it optional but encouraged. In the case of meters, the default graphic unit is the unit associated with the meter. In the case of groups, it is not clear what the default should be. Thus, it is "no unit"; this is the same value taken by the graphic unit by default. How OED deals with "no unit" is described in other sections that deal with this value. Note that a group that has a default graphic unit of "no unit" cannot be used if the graphic unit is "no unit" since there is no obvious way (other than random) to select the graphic unit.
## database-changes-for-units


- need unit_type as enum of values unit, meter
- new table named unit_vertices that has columns:
  - integer id that auto increments and is primary key
  - string name that is unique (name of unit for identification)
  - string identifier that is unique (display name of unit, often similar/same as name)
  - unit_type type_of_unit
  - integer unit_index that is unique and is the row/column index in Cij for this unit.
  - string prefix ([see for description](#vertices))
  - boolean displayable (whether it can be seen/used for graphing)
  - boolean primary (If this unit is always displayed. If not, the it is secondary and the user needs to ask to see. To be used in a future enhancement.)
- new table named conversions. The primary key is the source_units_id, destination_units_id. Need to make sure the source_units_id is not the same as destination_unit_id in any row to avoid self conversion. It has columns:
  - source_unit_id that is foreign key of id in units table
  - destination_unit_id that is foreign key of id in units table
  - floating point slope
  - floating point intercept
- meters table needs the following new column:
  - unit_id that is foreign key to id in units table. We need to be sure that the type_of_unit for the supplied unit_id is meter. This is the unit that the meter receives data in and is the one pointed to by the meter in the graph.
  - integer default_graphic_unit that is foreign key to id in units table and null if no unit.
- groups table needs new column:
  - integer default_graphic_unit that is foreign key to id in units table and null if no unit.
- see [database readings changes](#how-oed-should-calculate-readings-displayed-in-line-graphics) for other database changes.
- src/server/sql/reading/create_compressed_reading_views.sql has compressed_group_readings_2 & compressed_bar_group_readings_2 that appear to first get all the meter ids and then sum the result of querying over all the meters to get the readings to display. Since we need, in general, to now apply different unit transformations to the different meters in a group so these will need to be changed.
  - TODO figure out an efficient way to do this
- Need to load all the predefined OED units and conversions in those tables  where some ideas where:
  - Energy units: kWh, BTU, therm (100,000 BTUs), cubic feet of natural gas, cubic meters of natural gas, gallon of gasoline (?) [see list of conversions](conversionFactors.xlsx)
  - Volume (not equivalent to power): liters, gallons, cubic feet, Mcf (thousands of cubic feet), Ccc (hundreds of cubic feet)
  - Power: kW, BTU/hr
  - Weight/mass: lbs, kg, ton (2000 lbs), metric ton (1000 kg)
  - CO2 is in terms of mass but need [conversions](https://www.epa.gov/energy/greenhouse-gases-equivalencies-calculator-calculations-and-references) from kWh, gasoline (ga), diesel (ga), BTU, natural gas (therms or Mcf)
  - Temperature: degree Celsius, degree Fahrenheit
  - TODO figure out complete list
  - The [EPA web page](https://www.epa.gov/energy/greenhouse-gases-equivalencies-calculator-calculations-and-references) has a lot of other conversions for CO2 such as coal, impact of recycling, etc. Want any?
  - Do we need to do any type of money to prime the system for easy usage?

- When we migrate a current DB we need to set some default values:
  - For meters, the unit_id should correspond to kWh since all current meters are that.
  - For groups, the default graphic unit is also kWh since that is the current usage.
## model-changes-for-inits

The models in src/server/models need to be updated for the database changes and for places where subsets of the data is needed from the database for the pseudocode proposed in this document. Every model code will have a constructor, createTable, mapRow, insert and getAll as exist in current models. Changes for specific database changes are:

TODO Go through document to specify all the functions needed from database based on algorithms.

### Unit

This is a new model. Functions needed:

- createUnitTypesEnum for the new enum needed.
- getDisplayable for if unit displayable
- getTypeMeter for if unit is of type meter
- getTypeUnit for if unit is of type unit

There needs to be an equivalent enum/structure for unit_type. It will be named UnitType. If on client side so similarly to src/client/app/types/items.ts and any others like it. If on server side the similar to src/server/models/Meter.js.

### Conversion

This is a new model.

### Meter

This exists but needs to be changed for new columns.

### Group

This exists but needs to be changed for new columns.

## OED page changes

What follows are the changes needed on specific OED web pages.

### new-units-menu

Each graphics page (line, bar, compare, map) will have a dropdown menu that shows the graphic units for graphing (including "no unit"). It will probably go right below the groups: and meters: dropdown menus and have a similar look with title and then the menu. This dropdown has some similarities to the map dropdown for meters/groups that are filtered based on the selected map. The default menu value is "no unit" when the page is first loaded and this is set before the algorithm below is run so there is already a selected unit. Note the meters/groups menus must be updated to the compatible units as [described](#changes-to-meters-groups-dropdown-menus). Also note that if the current unit is "no unit" then once the first meter/group is selected then its default graphic unit becomes the default graphic unit for the selected meter/group. If "no unit" is selected then all meters and groups are deselected since none could have been selected with this choice. Note this is an easy way to restart the graphing process. It would be good to warn the user if "no unit" is selected but there are selected meters/groups so they can either continue or cancel to avoid accidentally removing all meters/groups. A graphic unit is defined as follows:

1. Only units in the unit_vertices table that are of type unit (so not meter) can be a graphic unit.
2. If the user is not the admin, then a unit is not included in the graphic units if its displayable is false.
3. If every meter and group that is already selected for graphing is compatible with a graphic unit then it is shown in the usual dropdown font. Note if no meter/group is yet selected then this is all displayable units.
4. If the unit does not pass step 2 then it is shown in another font/style. Maybe italic or labeled in some way? (Open for discussion/design choice and consider font/display chosen for meters/groups menus) These are all the units that would change some of the available meters/groups by either removing them from display or making them displayable. The meters/groups dropdown menus must be updated on a selection of one of these units so only meters compatible with the graphic unit are shown.

Each time the graphic unit is changed the y-axis graphic values need to change. See the section below for [unit-display](#unit-display) for information on how this is done. The selected unit is the graphic unit choice.

The following pseudocode will create the graphic unit menu (see [determining-compatible-units](#determining-compatible-units) for functions):

    // Holds all units that are compatible with selected meters/groups
    Set compatibleUnits = {}
    // Holds all units that are compatible with selected meters/groups
    Set incompatibleUnits = {}
    if (the currently selected unit is no unit) {
      // Every unit is okay/compatible in this case so skip the work needed below.
      // Can only show unit types (not meters) and only displayable ones if not the admin
      compatibleUnits = all unit_vertices where type_of_unit is unit and (displayable is true or admin)
    } else {
      // Some meter or group is selected
      // Holds the units compatible with the meters/groups selected so only ones in all are okay.
      Set units = {}
      // Get for all meters
      for each meter M that is selected where M is the meter id {
        // {M} means turn M into a set.
        units = units ∩ unitsCompatibleWithMeters({M})
      }
      // Get for all groups
      for each group G that is selected where G is the meter id {
        units = units ∩ unitsCompatibleWithMeters(metersInGroup(G))
      }

      // Loop over all units that are of type unit (case 1)
      for each unit U in unit_vertices where type_of_unit is unit {
        // Control displayable ones for non-admin users (case 2)
        if (user is admin or U.displayable) {
          if (U is in units) {
            // Should show as compatible (case 3)
            compatibleUnits += U
          } else {
            // Should show as incompatible (case 4)
            incompatibleUnits += U
          }
        }
      }
    }
    // Ready to display unit.
    Add each compatibleUnit to unit menu is alphabetically sorted order in regular font
    Add each incompatibleUnit to unit menu is alphabetically sorted order in font chosen for case 4

### changes-to-meters-groups-dropdown-menus

The possible meters/groups in the dropdown menu will be in two potential states that relate to the units menu [discussed above](#new-units-menu).

1. If the meter/group is [compatible](#determining-units-that-are-compatible-with-a-meter-or-group) with the graphic unit then it is in the usual dropdown font. Note when you first go to the graphics page the graphic unit is set to "no unit" and this means that every meter/group is compatible. Just listing them all is much faster than checking each one and is done in the pseudocode below.
2. Otherwise (not compatible) the meter/group is shown in grayed out font. This is the same look as the map page where meters/groups that cannot be graphed on the selected map are grayed out.

This does not change the current situation that hides some meters/groups if they are not displayable to a user. All meters/groups for case 1 are displayed first and then the ones for case 2 where the items in each set are in alphabetically sorted order. (As separate work not part of resource generalization, we should probably make maps sort this way too.)

As [discussed above](#new-units-menu), both the meter and groups dropdown menus must be updated whenever the graphic unit is updated. The algorithm for updating the meter menu is:

    if (graphicUnit = no unit) {
      // If there is no graphic unit then no meters/groups are displayed and you can display all meters
      compatibleMeters = all meters that user/admin can see.
      incompatibleMeters = {}
    } else {}
      // meters that can graph
      Set compatibleMeters = {}
      // meters that cannot graph.
      Set incompatibleMeters = {}
      // If not admin, then meters not displayable are not viewable. admin can see all.
      for each meter M in OED that is displayable where M is the meter id {
        // {M} means turn M into a set.
        Set units = unitsCompatibleWithMeters({M})
        if (graphicUnit is in units) {
          // The compatible units of the meter have graphic unit so can graph
          compatibleMeters += M
        } else {
          incompatibleMeters += M
        }
      }
    }
    // compatibleMeters are shown in regular font and incompatibleMeters are shown in grayed out font.

The algorithm for groups is similar where doing displayable for groups partly addresses [issue #414](https://github.com/OpenEnergyDashboard/OED/issues/414) where the other part is addressed in [group viewing page](#group-viewing-pages):

    // groups that can graph
    Set compatibleGroups = {}
    // groups that cannot graph.
    Set incompatibleGroups = {}
    if (graphicUnit = no unit) {
      // If there is no graphic unit then no meters/groups are displayed and you can display all groups
      // that have a default graphic unit. Also, If not admin, then meters not displayable are not viewable.
      // admin can see all.
      for each group G that is displayable to user in OED where G is the group id {
        if (G's default_graphic_unit = no unit or G not displayable to this user) {
          // If the graphic unit is no unit and group has no default graphic unit then cannot graph
          incompatibleGroups += G
        } else {
          compatibleGroups += G
        }
    } else {
      // If not admin, then groups not displayable are not viewable. admin can see all.
      for each group G in OED where G is the group id is displayable to this user {
        // Get the meters associated with this group.
        Set meters = metersInGroup(G)
        Set units = unitsCompatibleWithMeters(meters)
        if (graphicUnit is in units) {
          // The compatible units of the group have graphic unit so can graph
          compatibleGroups += G
        } else {
          incompatibleGroups += G
        }
      }
    }
    // compatibleGroups are shown in regular font and incompatibleGroups are shown in grayed out font.

### meter-viewing-page

If an admin is viewing the page then the new items in the [database schema](#database-changes-for-units) for meters should be displayed where the ids are converted to names for the units. These values are editable and are displayed with a dropdown menu where it is set to the current value when loading this page. The values listed in the unit_id are any unit in the unit table with type_of_unit = unit (not meters). The value for the [default_graphic_unit](#default_graphic_unit) are the list of all units compatible with the current unit_id unit. This can be found by:

    Set allowedDefaultGraphicUnit = unitsCompatibleWithUnit(unit_index)

The menu will contain the identifier associated with each id in allowedDefaultGraphicUnit.

Whenever either value is changed then it needs to be stored into the meter table in the database. In addition, these actions need to happen whenever the unit_id is changed:

- The set compatible units of the new unit_id are calculated as above. If the current value of default_graphic_unit is not in this set then it is changed to the new unit_id and the admin is notified of this change.
- update groups that contain this meter if editing
  - TODO probably similar to analysis of editing a group member but need to figure get pseudocode done

A change in a meter's graphhic unit will likely change the graphable meters and groups. While it could be handled in real-time, this is only for admins and these changes are not likely to be done very often. Thus, the admin will be told that they need to reload OED to see the change. A user will see the change the next time they reload and that delay is fine.

A feature that would be desirable is to list all compatible units for the meter as is suggested for groups. As with groups, this isn't strictly necessary as a similar workaround will get the needed information. This would be viewable by any user and not just admins.

### group-viewing-pages

The group page needs to have the [default_graphic_unit](#default_graphic_unit) added as was done for meters. Note in this case it is both on the viewing page for edits and on the group creation page. One other difference is the menu will also include the "no unit" option and that will be the default value on group creation unless the admin choose another value. Finally, the way to determine the values to display on the default graphic unit menu is different than for meters as [described elsewhere](#determining-compatible-units). When this needs to happen is described below.

As long as this page is being updated, it will be modified so non-admins can only see displayable groups.  This partly addresses [issue #414](https://github.com/OpenEnergyDashboard/OED/issues/414) where the other part is address in [group graphic menus](#changes-to-meters-groups-dropdown-menus).

When the admin edits a group, then the default graphic unit can be set via a dropdown menu. This menu should only show [compatible units based on the underlying meters](#determining-compatible-units) (unitsCompatibleWithMeters(metersInGroup(group_id))) along with "no unit".

When an admin creates a group, there is a dropdown to select the default graphic unit as with editing a group where "no unit" is selected. Before saving the group, an admin should choose a default graphic unit to eliminate "no unit" since [this restricts certain graphing choice](#default_graphic_unit).

Allowing an admin to select select/add/remove multiple meters and/or groups at a time during creation and editing means incompatibility changes between these meters/groups is possible. As a result, OED will be removing this feature. When there was only one unit in OED this was not an issue. While OED is open to other ideas, a way that is compatible with other menus in OED is to have a dropdown menu for meters and one for groups. This is what exists on each graphic page so will have a similar look and feel. As with the existing menus, the change takes place as soon as it is selected. The create page will be very similar except the change will impact the meter and group menus right away. For the edit page, a select causes that meter/group to immediately go to the other menu of that type. This means the meter/group switches between left column of Child meter/group and the right column of Unused meter/group. For example if an unused meter is selected, it is not longer unused and becomes part of the Child meters and its menu. After this, all menu choices must be updated as described below. As a result, the arrows will be removed from the groups pages for creating and editing and this eliminates [issue #413](#https://github.com/OpenEnergyDashboard/OED/issues/413) once completed.

The compatible units of a group has impacts as discussed below. Note this only applies to admins since they are the only ones who can make changes. This will naturally happen since the page only displays these items if an admin. There are two cases:

1. A meter/groups is removed from the group. This either leaves the compatible units of the group the same or adds compatible units. This case does not cause any of the problems below so the checks are not needed.
2. A meter/group is added to the group. This could reduce the compatible units of the group and can lead to the issues described below. Thus, the following checks only need to be done on adding a meter/group.

The dropdown menus of meters and groups will change so they are listed as follows (note all units are compatible with the default graphic unit if it is "no unit".):

1. Adding this meter/group will not change the compatibility units for the group. This also means the default graphic unit is not required to change. In this case the meter is shown in normal font. In this case the meter/group will not alter the attributes of this group.
2. Adding this meter/group will change some of the compatibility units of the group but there is still at least one compatibility unit for this group. This is the same as saying the meter/group's compatible units overall the groups compatible units but some do not overlap. This means that the possible graphic unit choices is reduced but the group would still be graphable. This has two subgroups:
    1. The meter/group is compatible with the default graphic unit. This is equivalent to saying that one of the compatible units of the meter/group is the default graphic unit. This means the graphic unit options for this group will be reduced but OED does not need to make any other change to the group. These meters/groups will be shown in a different font/label that needs to be determined.
    2. The meter/group is not compatible with the default graphic unit. This is equivalent to saying that one (of maybe several) of the units removed from the from the compatible units for this group by adding this meter/group is the default graphic unit. In this case the admin is warned when this choice is made that the default graphic unit has been reset to "no unit" and they should choose a new default graphic unit. These meters/groups will be shown in a different font/label and different that 2.1. that needs to be determined.
3) The meter/group will cause the compatible units for the group to be empty. This means it would be impossible to graph this group and OED does not want such groups since they are not interesting to OED. Thus, this meter/group is grayed out and cannot be selected.

The pseudocode for setting the meter/group menus is (see [compatible unit code](#determining-compatible-units) on functions called):

    // Determine compatibility of meter/group to the current group being worked on (currentGroup)
    // Get the currentGroup's compatible units.
    Set currentUnits = unitsCompatibleWithMeters(metersInGroup(group_id))
    // Current groups default graphic unit
    type?? currentDefaultGraphicUnit = group_id default graphic unit
    // Now check each meter
    for each meter M {
      // Get the case involved
      integer case = compatibleChanges(currentUnits, M's id, "meter", currentDefaultGraphicUnit)
      // If case 4 then won't display. Otherwise you the correct "font" or whatever need to show as desired.
      if (case != 4) {
        add M to menu with "font" howToDisplay(case)
      }
    }
    // Now check each group
    for each group G {
      // Get the case involved
      integer case = compatibleChanges(currentUnits, G's id, "group", currentDefaultGraphicUnit)
      // If case 4 then won't display. Otherwise you the correct "font" or whatever need to show as desired.
      if (case != 4) {
        add G to menu with "font" howToDisplay(case)
      }
    }

    // Returns the the state (see groupCase function) for meter or group provided by id and
    // otherUnits where type is either meter or group
    // TODO see if OED already has set symbols for meter and group.
    function integer compatibleChanges(Set otherUnits, integer id, String type, type?? defaultGraphicUnit) {
      // Determine the compatible units for meter or group represented by id
      Set newUnits = compatibleUnits(id, type)
      // Determine case
      integer case = groupCase(otherUnits, newUnits, defaultGraphicUnit)
      return case
    }

    // Finds all compatible units for this id based on if meter or group. See compatibleChanges for parameter.
    function Set compatibleUnits(integer id, String type) {
      if (type = "meter") {
        integer unitId = use id to get unit_id of group
        newUnits = unitsCompatibleWithUnit(unitId)
      } else {
        // It's a group
        // Note we would do this once for each time we check all groups so point to optimize if needed.
        newUnits = unitsCompatibleWithMeters(metersInGroup(id))
      }
      return newUnits
    }

    // Returns case covered above of 1, 21, 22 or 3 for cases 1, 2.1, 2.2 or 3.
    // currentUnits should be the units already in group
    // newUnits should be the units that will be added
    function integer groupCase(Set currentUnits, Set newUnits, type?? defaultGraphicUnit) {
      // The compatible units of a set of meters or groups is the intersection of the compatible units for each.
      // Thus, we can get the units that will go away with:
      Set lostUnits = currentUnits ∩ newUnits
      // Do the possible cases.
      // 1. no change
      if (lostUnits.size = 0) {
        return 1
      } else if (lostUnits.size = currentUnits.size){
        return 4
      } else if (defaultGraphicUnit is not no unit or lostUnits contains defaultGraphicUnit) {
        return 22
      } else {
        // If the default graphic unit is no unit then you can add any meter/group so check above covers this.
        return 21
      }
    }

    // Returns the way to identify this item in a meter or group menu given the case.
    function somethingLikeFont howToDisplay(integer case) {
      // Maybe you want to use a switch statement :-)
      if (case = 1) {
        return regular font
      } else if (case = 21) {
        return case 2.1 font
      } else if (case = 22) {
        return case 2.2 font
      } else {
        // If case 4 of anything else then should not display.
        return whatever
      }
    }

If this group is contained in another group (recursively) then either possibility of 2) chosen by the admin could change the compatibility units of the other group. The cases here are the same as the ones just described but the action taken is different:

1. The change in this groups' compatible units does not change the compatible units of the other group. This is a safe change so nothing needs to be done.
2. The change in this groups compatible units does change the compatible units of the the other group. This has two subgroups:
    1. The change is does not impact the default graphic unit of the other group. The admin is warned but the change is okay.
    2. The change makes the default graphic unit of the other group to become invalid and OED would need to change the default graphic unit of the other group to "no unit". The admin is warned but the change is okay.
3. The change causes the other group to have no compatible units. The change is rejected and the admin is told this and informed they must change the other group before making this change.

This check is made before the selected meter/group is changed but after the checks within the group. The pseudocode for the second set of choices is:

    // Determine if the change in compatible units of one group are okay and if the admin needs to be warned.
    // All admin messages are grouped together and a popup is used where the admin can copy the items since the
    // number of messages could be long.
    // Get the unit for the meter/group that is going to change, e.g., selected and get its compatible units
    // depending on if meter or group.
    Set currentGroupUnits = compatibleUnits(current group's id, "group")

    // This will hold the overall message for the admin alert
    msg = ""
    // Tells if the change should be cancelled
    cancel = false
    // This can be found via getDeepGroupsByGroupID in src/server/models/Group.js. The returned groups will not change
    // while this group is being edited.
    for each group G containing the group selected {
      // Get the case for group G if current group is changed.
      integer case = compatibleChanges(currentUnits, G's id, "group", G's default graphic unit)
      if (case = 21) {
        msg += Group <G's name> will have its compatible units changed by the edit to this group\n
      } else if (case = 22) {
        msg += Group <G's name> will have its compatible units changed and its default graphic unit set to no unit by the edit to this group\n
      } else {
        // Case 4
        msg += Group <G's name> would have compatible units by the edit to this group so the edit is cancelled\n
        cancel = true
      }
    }
    if (msg is not blank) {
      if (cancel) {
        msg += \nTHE CHANGE TO THE GROUP IS CANCELLED"
        display msg with only okay choice
      } else {
        msg += \nGiven the messages, do you want to cancel this change or continue?
        display msg with cancel and continue choices
        if user clicks cancel then set cancel variable to true
      }
    }
    if (cancel) {
      don't apply change and undo anything needed
    } else {
      apply change to group
      update all impacted groups. This is the loop above except instead of message you do what is stated
    }

If this turns out to be expensive and takes time then the second set of checks can be done after all selections are made and when the changes are saved if any meter/group was added. This will make it harder for the admin to know which change relates to which message. If needed, after the initial implementation, a better idea is to cache the compatible units of all groups that contain this group when the check is first done and reuse on subsequent checks. Note that setting up the menus should already have all the group info but it needs to be updated per changes and that is similar to this code. This assumes OED has not already stored this information. There are some notes in the pseudocode about where this might be done but don't need to go into actual code.

Note that changing the underlying meters of a group can make groups currently displayed on a graphic become undisplayable since they are no longer compatible with the graphic unit. The same effect happens to groups changed indirectly. Since the changes are stored to the DB, it is possible a user will make a request that is not longer valid. This shouldn't happen very often and will be cleared up on a page reload. Given there is no easy fix, the admin documentation should note this and esp. warn that it is much easier for this to happen to the admin.

A feature that would be desirable is to list all the compatible units for a group on the group viewing page (for everyone). As with the desired feature to see all the underlying meters of a group, this will make it easier for any user to figure out allowed combinations for graphing. Note this should be the same as when the user selects just this group and then sees the allowed graphic units so it is not absolutely required but would be nice at some point.

### new-admin-unit-page

OED needs to allow an admin to see all units as a table. There would be a column for each [column in the database](#database-changes-for-units) and a row for each unit. This will be very similar to the meter and map admin pages. All values but the id can be changed by the admin.

OED allow admins to add a new unit. An "add unit" button would be available on this page that would then reveal the needed input items. This could be very similar to editing a unit. The unit_id would automatically be set to the current (before the add) number of units already in the database. This works because Cij is an array, and value needs to be the a valid index. It can go from 0 to # units - 1. Thus, the first one is zero (# units is 0) and increments by 1 each time a unit is added. A "save" button would put the changes into the database. If a unit is added then cause Cij to be updated as described in [determining-conversions](#determining-conversions).

### new-admin-conversion-page

OED needs to allow an admin to see all unit conversions as a table. There would be a column for each [column in the database](#database-changes-for-units) and a row for each conversion. This will be very similar to the meter and map admin pages. All values but the id can be changed by the admin.

OED allow admins to add a new conversions. An "add conversion" button would be available on this page that would then reveal the needed input items. This could be very similar to editing a conversion. A "save" button would put the changes into the database. If a conversion slope or intercept is changed (by edit or created) then cause Cij to be updated as described in [determining-conversions](#determining-conversions).

Note we need to be sure that whenever the source_unit or destination_unit is modified then they are not the same for any row.

### csv-upload-page

Both upload tabs (readings and meters) need to have a dropdown menu with all allowed units and "use meter value" (default selected when menu first displayed). It will have the following impact:

- If uploading a meter it will define the unit for the meter. If "use meter value" is specified and the CSV does not have a unit value in the unit column then the request fails with error. If the value is set to a unit in OED then this unit is used for all meters. It would be nice to report a warning or error (which one is preferred?) if the CSV also has a value for the meter unit. Note that an incorrect unit name is an error.
- If uploading readings, this value is only normally set if the option to create a new meter is being used. In this case it defines the unit of the new meter created (or error if invalid). If not creating a new meter then it causes an error if it does not match the value on the meter.

Note that equivalent parameters need to be created for a URL request to upload a CSV. It acts the same as above. Open to ideas but maybe:

- unit=value for the unit value. It will match by the name of the unit displayed on the unit page. The default value if the parameter is not given is "use meter value".

### multiple-edits

OED has never protected against two different admin pages simultaneously changing the same item or items that could be in conflict. Some conflicts are relatively benign such as both changing a preference where the last one would stay. Some might cause an internal error, such as deleting a group that another page tries to access but probably would not hurt OED in the long-term. Some, not analyzed, might cause OED issues in what is in the database. The chance of this happening now seems greater given the added complexities of units. For now, admins will be warned not to do this to avoid potential issues. How easy a good fix will be and if it is needed is left for the future.

## unit-display

Currently OED uses kW on line graphics and kWh on bar and compare, and kWh/day (really kWh per day) on map graphics. As such, the line graphic is a rate, the bar and compare graphic is usage and the map is usage (likely to relabel and change what map displays in other work). With the ability to do lots of units, the kWh becomes the y-axis unit stored in Cij for the conversion used to get the graphic values. Since all meters/groups are graphed with the same value, it can be the y-axis value for any of the conversions used. It is not believed (and hoped) that conversions taking different paths could have different values.

At this point OED needs to support three types of units for readings:

1. Quantity that represent something physical and can be consumed. In OED these are energy (kWh, BTU, ...), volume, mass, etc. Note a number of other units used fall into this including CO2 as mass, money, gasoline (volume), etc. This is how the code and DB code gets readings and that will continue to work for units other than kWh that currently done.
2. Rates that are typically quantity/time. In OED these are power (watt, ...). OED needs to change how it gets readings for this to work (see below).
3. Quantities that are not consumable and do not have a rate of usage associated with them. The only one at this time is temperature. Unlike the other two, it does not make sense to sum these to get a total quantity. For example, summing temperatures (not for finding the average) does not really make sense. Thus, these can only be shown on a line graph where the unit is the original quantity but often averaged. It will get the line value in the same way as rates.

## how-oed-should-calculate-readings-displayed-in-line-graphics

compressed_group_readings_2 in src/server/sql/reading/create_compressed_reading_views.sql returns the desired points for graphing readings for the meters selected for the first case above (physical units that are consumed). It uses the following formula (done cleverly in Postgres SQL):
$$\frac{\sum_{\rm all\ readings\ in\ desired\ time\ frame\ of\ point} \left(\frac{\rm readings\ value}{\rm reading\ length\ in\ hours} \times {\rm number\ of\ seconds\ of\ reading\ needed}\right)}{\sum_{\rm all\ readings\ in\ desired\ timeframe\ of\ each\ point} \left(\rm{time\ for\ reading\ within\ desired\ time\ frame\ in\ seconds}\right)}$$
In the current code the units are: $\frac{\frac{{\rm kWh} \equiv {\rm kWhours}}{\rm hours} \times {\rm seconds}} {\rm seconds} = kW$. This is a unit of power which is what you want for the line graphic.

One reason this formula is so complex is to deal with the case where a reading value does not lie completely within the desired time frame of a point for graphing. For example, if you are dealing with the second point where the time frame for the graphing point is 1 hour so this point's time frame goes from 60-120 minutes and each reading is 23 minutes, then the third reading begins/ends at 46/69 so only 9 minutes of this reading is within the second time frame of one hour. For what follows, assume the reading value is 10kWh. What this formula does is:

1. Converts the reading value of kWh to kW with: $\frac{\rm readings\ value}{\rm reading\ length\ in\ hours}$. For the example this is: $\frac{10\ kWh}{\frac{\rm 23\ minutes}{60\ minutes/hour}} = 26.09 kW$.
2. The multiplication of this by "number of seconds of reading needed" only includes the energy that this point has within the desired point time frame. For the example, this gives: $26.09\ \rm{kW} \times (\rm{9\ min} \times \rm{60\ sec/min}) = 14088\ \rm{kWsec}$. Note this is the same as $10\ \rm{kWh} \times \frac{\rm 9\ min}{\rm 23 min} \times \rm{3600\ sec/hour}$. The second way might be clearer as it is the fraction of the reading time converted to seconds.
3. Now divide by the total time for the time frame in seconds. This gives for the example: $\frac{\rm 14088\ kWsec}{9\ min \times 60\ sec/min} = 26.09 kW$. In this case you get the same value as step 1 but the sums in the actual formula would often be over multiple readings with different values so this would not be the case.

It might see unnecessary to have the sum in the denominator in the formula at top and just use the known time frame for the point. However, consider what happens if there are gaps between the readings. In this case the time summed over in the numerator is only for the time the readings actual cover. Thus, the denominator must only use the sum of these times and not the total time frame that is already known. Note the sums also account for readings of different lengths.

The formula could be simpler if readings did not cross the time frame boundaries so they were always within the time frame and there are not gaps between readings. In this case the "reading length in hours" is the same time as the "number of seconds of reading needed" (ignoring that one is hours and one is seconds) so they cancel expect for the conversion of hours to seconds. The denominator can be simplified since the sum is now the time frame for the point which is the same for all points. The algebra shows the final formula is:
$$\frac{\rm{3600\ sec/hour} \times \sum_{\rm all\ readings\ in\ desired\ time\ frame}{\rm reading\ values}}{\rm time\ frame\ of\ point\ in\ sec}$$
where the units are (sec/hour * kWh) / sec = kW as expected. Note you could just work in hours if you wanted to avoid the conversion of 3600. This formula sums the energy and divides by the time it took to use that energy to get the average rate/power over the time interval of the point. It is probably easier to see what it means than the one that deals with special cases.

Now let's discuss the second case of rates. The formula for case one can be simplified in this case since you already have the rate and that is part of what the numerator is calculating. Thus, the formula becomes:
$$\frac{\sum_{\rm all\ readings\ in\ desired\ time\ frame\ of\ each\ point} \left({\rm readings\ value}\times {\rm number\ of\ seconds\ of\ reading\ needed}\right)}{\sum_{\rm all\ readings\ in\ desired\ timeframe\ of\ each\ point} \left({\rm time\ for\ reading\ within\ desired\ time\ frame\ in\ seconds}\right)}$$
The units of each reading for electricity is watts which is power. Note watts are joules/sec or J/sec. Thus, the overall units are: $\frac{{\rm J/sec} \times {\rm sec}}{\rm sec} = {\rm J/sec}$ which is a rate just as in the first case. Note this will work for any rate unit.

Finally, let's consider case 3 of something like temperature. In this case you want to graph to average value. If you look at the formula for rates, it is just calculating the average over the time frame. That is why it starts with readings with a rate (such as J/sec) and finishes with a rate (such as J/sec). Thus, this case can use the same formula as case two.

See [unit table changes](#database_changes_for_units) for other database changes.

## implementation-plan

TODO

## possible-ways-to-store-unit-graph

### JavaScript-npm-packages

TODO Right now we are planning to use a JS package. They are being reviewed and which one we will use is an urgent question.

Once a package is determined, we need to see how to create the graph to be sure what we store in unit and conversion tables is all that is needed. We also need to figure out what algorithm(s) within the graph package will be used to create the needed paths to create Cij.

This is a very incomplete list that was created to show it could be done:

- [Graphlib](https://github.com/dagrejs/graphlib/wiki/API-Reference) is interesting but no longer maintained.
- [ngraph](https://github.com/anvaka/ngraph) seems okay and still has developers
- [@datastructures-js/graph](https://www.npmjs.com/package/@datastructures-js/graph) is interesting but a single person
- [js-graph-algoriths](https://www.npmjs.com/package/js-graph-algorithms) is fine but one person and not updated in many years

### PostgreSQL

This has some appeal but it isn't clear that they are read for usage in OED. It may also be the case that this is more complex. Given we have determined that the graph will not be looked at too often, it isn't clear this is a better solution. These are just here for reference in case we want to consider these in the future (maybe get rid of our homemade graph for groups?).

- [AGE](https://age.apache.org/) is very interesting but may not yet be ready for usage
- [AgensGraph](https://wiki.postgresql.org/wiki/AgensGraph) is what AGE is based on but it is older and seems to be a fork of Postgres but unsure.

## testing

TODO possible tests to consider - outdated and should be made up to date with examples

Steve proposes to test the packages in the following sequence:

1. Test basic multiplicative unit conversion of provided unit. If there is a unit conversion provided (such as meters to feet) then try that. For example, take 13 meters and convert to feet and then reverse to try 13 feet to meters. Note I did not use 1 so we know that it is really working correctly. It can be any unit it has.
2. Test linear conversion. Convert degrees fahrenheit to celsius and reverse. If not provided then use 9/5 * C + 32 = F.
3. Check new unit with multiplicative (all remaining are multiplicative). This assumes that the package does not have energy units. If so, see if get the same result and need to test one where not provided (could be the same but made up names for the units). 1 Megajoule = 0.001055056 BTU and 1 Megajoule = 3.6 kWh. Try converting each of these after enter these two conversions:
    1. 3 BTU into 2843.45 Megajoules
    2. 123 kWh into 34.17 Megajoules
4. See if can convert 34.17 Megajoule into 123 kWh to see if automatically does reverse given entered kWh into Megajoules above.
5. See if allows arithmetic on result so can ask 3 BTU + 123 kWh to see if it can give 2877.62 Megajoules.
6. See about a chained conversion. Enter new unit of 100 watt bulb = 0.1 kWh. Now convert 3 BTU to 100 watt bulb. 3 BTU is 2843.45 Megajoules = 10236.42 kWh = 102364.23 100 watt bulb. This assumes that the package can do reverse conversions (gave Megajoule to kWh above); if not, need to give reverse and note. If that works, see if can take 102364.23 100 watt bulb into BTU (3 BTU).
7. Another chained conversion. Enter 4 new units: 1 kWh = 0.11 US\$, 1 BTU = 13 CAN\$, 1 US\$ = 0.87 Euro and 1 CAN\$ = 1.2 Euro. Ask to convert 123 kWh and 3 BTU into Euro. 123 kWh = 13.53 US\$ = 11.77 Euro and 3 BTU = 39 CAN\$ = 46.80 Euro for a total of 58.57 Euro. Getting the final Euro probably assumes arithmetic is allowed (per test above).
8. Example of multiple paths & what happens if package really smart. Also, how stop some conversions.
9. See [CO2 conversions](https://www.epa.gov/energy/greenhouse-gases-equivalencies-calculator-calculations-and-references) to do example to CO2.

include temperature since has intercept != 0

### bar/compare/map graphic values

TODO An analysis of the current code has not yet been made. It is hoped that it will work as expected if lines are changed but that is not known since they may not use those database functions.

## issues-to-consider
### unusual-units

1. Some meters or a group of meters provide the values needed to determine usage. For example, steam needs multiple values. How will we deal with this? If we store the raw meter values then need to combine when requested or in advance (maybe in a way similar to the daily aggregation). Here are some older notes on unusual types
    1. Fuel oil - proposal can deal with this one
        1. Gallons (volume) but has equivalent energy value
    2. Steam - is this energy or something else?
        1. Believe need pressure, temperature and flow
        2. CEED gives gallons
    3. Heated water
        1. Can be demand (flow) or usage (volume)?
    4. Chilled water
        1. CEED does TonHr which is a normalized BTU/hr (1 ton hr about 12,000 BTU)

#### meter-graphic-values

The database function discussed above also has logic for determining the time frame for each point based on the total date ranges to be graphed. Thus, the x-axis values are part of this function and do not change based on the unit being graphed. The y-axis values depend on the unit being graphed. For meters this is a single unit calculation that transforms the meter from the meter's unit to the display unit chosen by the user. The known transformation could be passed as a new parameter to the database function and the transformation could be applied in the select statement. In general, one value would be needed per meter. An alternative would be to do the transformation after the data is gotten from the database. Note that this also allows the y-axis values to be recalculated without going to the database when the graphic unit is changed.

#### group-graphic-values

Since groups often have multiple underlying meters, in general, you need to apply different unit transformations to each  meter in the group. To do this within the database would mean providing all unit transformations for every underlying meter. The practicality of doing this so the database function can easily choose the needed transformation for each meter is not known. A more complex way would be to separate the underlying meters into groups where each group has meters with the same unit. Then the transformation is the same within each group so they could easily be done together within the database. The returned sum from each unit group would then be summed together to get the final y-axis graphic value. Since the y-axis graphic points are the sum of the transformed values for each meter it is not possible to take y-axis values from one unit and transform them into y-axis value in another unit unless all the unit group y-axis values are saved. The question of server vs. client side is also related and discussed next.

## server-side-vs-client-side-calculations

The current design makes decisions about units by using the Cij array. This array needs to be available on the client side due to how often it is accessed and the fact it rarely changes. It is less clear where it should be created. The same is true for the graph. It is also unclear where the transformations for meter and groups will happen to get the graphic unit.

TODO figure out how we want to do this and then update for meters and groups above.

### unit display questions

- How will units be identified for which of the three types of units they are?
- How will the unit label for the y-axis be associated with the unit? Most line graphs will be unit/time such as liters/day, money/day, etc. and represent the rate of usage.
- How will user defined units fit in?

TODO The code should have some basics of this description of how readings are turned into graphics points for the line graphic. It should also have a link to the document that holds this (this document if not moved).

??TODO update, esp. given the changes for how units and menus are calculated

There are unit calculations described above that are needed to decide what to display on dropdown menus. If this happens on the client-side then the client-side needs to know the unit system. The alternative is to go to the server with each change where the server knows the unit system. The initial design will put the unit system on the client-side to avoid the need to go to the server. Note that for this to work for groups, the client-side needs the underlying meters for each group (believed not to be the case at this time). This is not a major change and not a lot of state to transfer from the server to the client. It would have been needed anyway for the issue to show the user the underlying meters on the group viewing page so it might as well happen.

Each time the graphic display unit is changed or a meter/group is added, needed transformations from meters' and groups' unit to the graphic unit needs to be determined. This could happen on either the client-side or the server-side. Since the unit system already needs to be on the client-side given the previous paragraph, it is appealing to do this one on the client-side too.
Assuming that calculating the compatible units would allow getting the needed transformation without much extra work, the client-side could do the needed transformations for the y-axis graphic values without much extra work. If the client-side already has the needed y-axis values in Redux state then it could do the transformation needed without going to the server. This is easy for meters. As discussed above in the group graphics values section, a group cannot, in general, be transformed this way without knowing the y-axis values for each underlying meter. This can be done by going to the database in the same way as the original request. An alternative would be to get each meter of the group (or the sum of all the ones with the same unit) and cache them in Redux on the client side. This may significantly increase the data that must be transferred with each initial group request but reduces future requests. The initial request is increased by at least the number of different meter graphic unit types along with the underlying meters in the group and future requests are reduced by one set of y-axis points (and the database time and network latency). Given that graphic unit changes seem less likely, it would probably take multiple unit changes to make up the extra data send if done on the client-side, and the software would be more complex, the initial design will be for group's graphic data points will be done only on the server-side. This raises the question of whether the server-side should also know about the unit system. The client-side should know the needed values and they could be saved when the menus compatibility calculations are done. The only additional cost seems to sending them to the server but this is a small amount of data. Thus, the initial design will only have the unit system on the client-side. Note this also avoids the question of keeping the client- and server-side unit values in sync when changes are made to units. Note every type of graphic cached needs to be changed on unit change.

Given the choices above, it is open to whether meters y-axis values should be done on the client-side or the server-side. The server-side is simpler from a software standpoint since it would be the same as an initial request to the server. However, it is likely to be slower. This is because the number of points is currently set to be < 1000 for each line so it is not much work (and the other graphics are even faster). The initial software could always go to the server as done for groups and a future optimization could do the transformation on the client-side when possible. However, given groups go to the server, the speedup may not be as great as expected when groups are also graphed so this seems lower priority. It might be part of consideration of doing groups on the client-side if the speed up is deemed necessary.

Given it takes some work to recalculate the y-axis graphic points, esp. for groups, and the amount of state is not too large, it makes sense to cache each unit graphics values in the Redux state. Currently it holds a single value for each meter/group since there is only kWh. This will require adding the state for the unit to each set of values stored. This will speed up going back to a unit previously displayed.  

## Potential-future-enhancements

We may want to think about these in case they impact how we plan to do the current work.

- On all graphics pages and the unit page, add a click box "secondary" that is unchecked by default. It will go next to the units dropdown menu on graphics pages and somewhere appropriate on the unit page. The units displayed will be limited to primary units. If the "secondary" box is check then all displayable units are listed except for admins on the unit page. The idea is that there may be a lot of units so limiting to the common ones by default is valuable. Sites not wanting this can make all units primary.
- Allowing CSV input/export of units and conversions.
- Groups have an area field. We probably want one for meters too. Also, the unit is unclear and should probably be connected to the new units.
- Should be allow multiple y-axis units so could graph more than one type of unit at a time?  
From [Examples](#examples): Display Natural Gas as BTU along with the temperature in Celsius. This is interesting since heating costs vary with temperature. These are not compatible units and there is not a desire to combine them. What the user wants is two lines on the same graph. This requires us to display two y-axis units (one for BTU and one for temperature). We need to have a way to determine when the user is asking for aggregation (sum) vs. two separate lines/values. Note that if we wanted something other than BTU for the energy then that would be a transformation to do first before displaying. See [potential future work](#potential-future-enhancements) for dealing with this.
- Some of the conversions may vary with time. Examples are cost, size of buildings, probably others. Concretely, the cost of an energy type (electrical rates, etc. vary with time). Do we want to do this (would be nice)? We need a way to store time varying values in the DB and how to label ones that apply for all time before/after the given time. We also need to decide how to efficiently implement this. Breaking up the meter date ranges for each time range of change might be a pain and slow the system down. One idea that needs to be looked at is using dummy meters with limited points that span the time ranges where meters could be multiplied or maybe linearly transformed (not just added) to get the final result.
    1. Values in DB
    2. Entering the values by admin
    3. Efficiently get/transform the data if this is allowed
- We have wanted to allow scaling (at least +/- but general linear would be nice) when a meter is combined into a group. This might fit in with this work. (issue #[161](https://github.com/OpenEnergyDashboard/OED/issues/161))
- Energy usage in buildings varies by size, number of occupants and the weather conditions. To allow sites to better understand how their energy usage compared to expectations and across buildings, we will allow the data presented to be normalized for these considerations. This requires normalizing data based on values in the database (except for weather where the data often comes from a weather service and hooking this up for some systems is part of this work). This is more important now that we have map graphics.  
 Here are [some ideas/plans from 2018 GSoC](./GSoc/normalize.md) \
 Here are some other ideas for normalizing:
    1. Sq feet or cubic feet
        1. Can vary with time
    2. people in building
        2. Will vary with time
    3. Weather: degree heat/cooling days, sunny/shady, wind
        3. Old work to get national weather service data
        4. [http://www.degreedays.net/](http://www.degreedays.net/) for degree days in CSV to correct data for weather, normalize data on 68 degree day is 0 for normal
- Should a site be able to set a default graphic unit that would be chosen as default when OED is first loaded? Unclear if needed. Also seems risky if used this to set default meter value as likely to lead to mistakes.

## db-generalize-info

1. [Energy Star DB Schemas](./otherSources/EnergyDatabaseStarSchema.pdf) show how they do it and it might be useful in the future.
2. There is some info on other systems on Steve's computer

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

## Old conversion code

The [zip of GitHub clone on conversion branch](old-conversion-branch.zip) has work for 4-5 years ago on starting the code for conversions. It isn't likely to be useful but might help with some setup if we roll our own converstions.
