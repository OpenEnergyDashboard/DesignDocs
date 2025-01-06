# Proposal to merge the meter and group menus on graphic pages

## Background

Meters are collection items in OED. Groups are an aggregation of meters. As such, they are different entities in OED. It is less clear that the distinction is as critical to a non-admin user of OED. Consider the following setup:

- Building A has meter MA1 that measures part of the building's usage.
- Building A has meter MA2 that measures a different part of the building's usage.
- Group GA contains MA1 & MA2 to represent the building's total usage.

The user would graph group GA to see the buildings usage. Now consider a variant of this setup:

- Building B has meter MB that measures the building's total usage.

The user would graph meter MB to see the buildings usage. If the user wants to show both buildings A & B together, they need to get one from the meter menu and one from the group menu. This is due to the particulars of the metering of these two buildings and not something a typical user should care about.

Furthermore, you can create a group with only one meter and then the meter and group are (almost) equivalent. There are some subtle differences in that a group will not display or export meter level data.

This is covered by [issue #1302](https://github.com/OpenEnergyDashboard/OED/issues/1302).

## Idea

Fuse the group and meter menus so groups and meters are interleaved alphabetically. Where in the menu they show does not change, such as compatible vs incompatible. Because there are minor differences between meters and groups, they would be distinguished in some way. How needs to be settled but a superscript g or m, a different color, etc. could be used. The current best choice is the Unicode superscripted capital letters (meter: U+1D39, shown as: ᴹ and group: U+1D33, shown as: ᴳ) if they can be added to the menus. Note that OED only keeps names/identifies unique for all meters and all groups but not between all meters and groups. Thus, the name of a group could be the same as a meter. This is another reason they need to be labeled when shown in the menu so they are different. OED also needs to decide the label for this menu. One idea is "Data Sources" but others might make sense.

## Details

This picture shows the 3D graphic page:
![3D graphics page](./merge.png)

Every OED graphics page has the groups and meters boxed in green. These would be fused into a single drop down menu on every page. The code can mostly be found in:

- Starts in src/client/app/components/MenuModalComponent.tsx
- That goes to src/client/app/components/UIOptionsComponent.tsx
- That goes to src/client/app/components/ChartDataSelectComponent.tsx where both meters & groups are shown in separate menus
- That uses src/client/app/components/MeterAndGroupSelectComponent.tsx where it changes what menu is used based on meter or group

The 3D page (but compare line is coming soon) also has pills at the top over the graphic shown boxed in purple. These would be fused in a way that is compatible with the drop down menus. The code for 3D can mostly be found in:

- Starts in src/client/app/components/ThreeDComponent.tsx
- This uses src/client/app/components/ThreeDPillComponent.tsx but it might move as the pills are used in other components

Note that it may be harder to label these with color since gray vs blue identify which item is selected so maybe a scheme for identifying meters vs groups needs to be worked out for the pills and then used for the drop down menu.

This only impacts the graphing menus. The meter/group pages will still exist for admins and other users and not change. All the admin pages will be unmodified.

The color of the graphic lines/bars depends on whether it is a group or meter. This was done to make the visually separate but also because it uses the database id which can overlap for meters and groups. It isn't clear there is a better solution so the same system can continue to be used.

Note internally OED needs to track if an item is a group or meter. Currently this is done by which menu was used to select the item. This needs to be updated for the single menu so it still works. Note the move to the Redux toolkit changed a lot of the code so there is a flag to tell if an item is a meter or group. Then getting the data varies by this flag. It is likely that the new menus should use this scheme where it is updated as needed.
