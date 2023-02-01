# Normalize graphics by area

This is a first, rough draft of these ideas where more work is anticipated. 

## Introduction

Resource usage is likely to scale with the size of the building where the area represents the size. For example, if two buildings are equally efficient then one that is twice the area should use twice the resources. To account for this, OED wants to allow an option that the user can select that would take the values shown in any graphic and normalize by area. Thus, this would include meters and groups. OED already has DB and admin edit ability for an area field for meters and groups.

There are other items that cause resource usage to vary. These include weather, baseline and cost; OED is interested in doing this in the future. Some are additive factors (baseline), some are multiplicative (cost) and some may involve a formula (weather). A system that would accommodate this would be great.

## Meters

Meters are fairly straightforward. The area of the meter is entered by the admin (several ways to do this: admin web page, CSV) and stored in the DB (already done). The readings that are displayed are then divided by this area for the final value shown to the user. See below on what to do if a meter does not have an area.

## Groups

In principle, group area works the same as the reading value. OED sums the readings across all the unique meters in a group to get the reading value. (See next paragraph about groups with groups.) If the area of all the meters are summed then all the readings can be divided by this area to display to the user. Note you must sum the readings and areas separately and then divide so the average is correct. See below on what to do if a meter does not have an area. Also note that included groups will have their area added since it may differ from the sum of the meters (see below).

One question is how to determine the area of the group. In principle, it should be the sum of the underlying meters/groups areas. Thus, the area of a group included in this group is its area and not the sum the its groups/meters. However, the admin may wish to use a different value for several reasons. First, not all meters may have an area but the area of the group is known so it can be manually set. Second, the area desired might differ from the meter sum. Given this, OED should allow admins to use the value desired. Thus, OED will do the following:

- There is a button next to the area input for a group labeled something like "Calculate area from meters". When clicked, this button sums the areas of all unique meters in the group.
- A popup will give the area calculated where the admin can accept this value (so it is entered into the area field for the group) or not.
- It is unclear if we should track which groups had the value set automatically but it may be desirable so we should probably do it.

Given some groups/meters in the group may not have an area and the action to take is uncertain, the admin will need to be asked in this case. What seems best is to have a popup give the list of group/meter identifiers without an area (and maybe the ones with an area) so the admin has this information when they decide to accept the area of not. It also makes it easier to set the need areas that are missing.

Another complication is what to do if a meter/group contained in a group has its area changed after the area of the group is set. There is an analogous situation for units on the group page. If you change the unit of a group then other groups can be impacted.  (The same is true if you edit a meter but I don't think we currently handle that). What the page does is calculate the impacted groups and warns the user (or rejects in some cases given issues with units that are not present here). The proposal is to do the same thing here. If a group or meter area is edited, then a search is made for the impacted groups where the admin is warned (in a way that makes it easy to copy the identifiers). The admin would then need to manually update these groups as desired. Not saving the page edits allows the admin to avoid the area change impact or a stop button if done after save is clicked. The exact details need to be worked out. Note if this is done for meters then we should probably do something similar for the unit for groups as this is not yet done (only does for group unit changes not meter).

## Meter/Group without an area

Since groups are not automatically assigned areas in this proposal, it does not make sense to graph a group or meter that does not have an area associated with it. Here are some options for dealing with a meter/group without an area:

- Don't graph any meter or group, even ones with areas. While this makes some sense and has some analogies to units, it will not be done.
- Since this will be an option that the user selects and it can be made after meters/groups are selected, it will be treated similarly to maps. In that case, if you go to the map graphic and a meter/group is not graphable (off the map) then all the possible meters/groups are graphed and the ungraphable ones are grayed out on the appropriate menu. Note this includes meters/groups without any GPS. The current code makes sure that all selected groups are graphed when another graphic is selected. Thus, when the user selects to normalize by area, the following happens:
  - Any meter/group with an area of 0 (no area) will not be displayed on the graphic.
  - The menus for meters & groups will be updated so the ones without an area are grayed out similar to maps.
  - If the user makes a change so the data is no longer normalized by area, any selected meter/group that is appropriate will display so ones without an area are again eligible.

Hopefully this can be done with reuse or similar code to what maps do.

## Area and units

At the current time there is a single area value for a meter/group. This implies that the unit is the same for all meters/groups but the actual unit is unknown. It would be nice to upgrade this given OED now understands units. Thus, the following is proposed:

- OED will provide (at least) two standard area units: sq. meter & sq. foot. (Alright, now meter has another meaning but hopefully clear from context :-) The conversion between them will also be provided. Any area unit (as described below) is okay to use for the area of a meter/group.
- The DB and menus for area will be modified so they include all area units. The ones for meter/group editing should be clear. There will also be one associated with choosing the normalize graphics by area. The thought was to have a checkbox to enable this with a menu nearby that allows the user to select any area unit. OED will need to do a conversion if the area unit of the meter/group differs from the one chosen for display. This is the same process done for the graphic unit in OED and should be handled similarly. As such, it will be done in the DB on the server. This seems an okay choice given the user isn't likely to change the unit very often. The Redux state will need to handle this and the normalized area readings.
- The admin preferences will have another menu to set the site default area unit as is done for language, graphic, etc. This will also require it to be added to the DB. All the menus for area (meter/group editing and user selected area unit for graphic normalization) will have this as the default value when it comes up before the user may change it.
- Each of the three places that need an area unit choice will have to decide which units are allows (hopefully using the same code). This will be determined by whether a unit can be converted from sq. meters. This means any unit that has true in the Pik row with sq. meters. src/client/app/utils/determineCompatibleUnits.ts function unitsCompatibleWithUnit() can do this. This will allow admins to add more area units for normalization by creating a bidirectional conversion to any existing area unit.

## Area varying with time

This is by far the most complex possible change. It does not have to be done now but would be nice to design/consider.

The issue is that area is generally fixed forever or long periods of time. However, it can vary. For example, a building can be renovated so its size changes. It would be possible to create new meters/groups whenever this happens and then combine them into a new group where one entry is has the old area/dates and the other has the new area/dates. This is a bit ugly and will not work well if changes are made frequently (so lots of values over time). Note that other items may also vary with time. For example, the baseline and cost for meter value (electricity, gas, water, etc. so the unit conversion varies with time). In particular, the cost of resources can vary frequently (even as a function of the time of day) so finding a more general solution is desirable.

Note that any DB with an existing area needs to have dates added to it where it goes over all time. This will be a migration for this OED version.

Whatever solution is found for calculating the needed readings, the editing of areas will need to be modified to allow for multiple areas and the DB needs to store them. This will be some work but should not be complex compared to how readings will be calculated. Thus, this is put off for now.

One idea is to create virtual meters that only have points for the number of values. For example, if the area was 100 until 1/1/2022 and 125 after that, there would be the points \
value, start date/time, end date/time \
100, -inf/some special value, 1/1/2022 00:00:00 \
125, 1/1/2022 00:00:00, inf/some special value \
where the value to represent all time before or after needs to be worked out. Given current code we could create a group of the original meter and this one to get the net value for additive changes (such as baseline). The code would need to be changed for multiplicative changes. I think the current code requires these new meters to be put into the views tables which means a lot of identical points would be created. An open question is whether this could be avoided while still allowing for fast calculations (seems possible but not analyzed).

Another idea is to modify the current units (or create special new ones) that can vary with time. It would clearly allow a combination of multiplicative and additive factors. It is unclear if that is needed but should be done if easy (including any other idea used).  How that would work has not been thought out.

A final idea is another idea yet to be thought of!
