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

## Idea

Fuse the group and meter menus so groups and meters are interleaved alphabetically. Where in the menu they show does not change, such as compatible vs incompatible. Because there are minor differences between meters and groups, they would be distinguished in some way. How needs to be settled but a superscript g or m, a different color, etc. could be used. OED also needs to decide the label for this menu. One idea is "Data Sources" but others might make sense.

This only impacts the graphing menus. The meter/group pages will still exist for admins and other users. All the admin pages will be unmodified.

## Moving forward

This is currently an idea/proposal that seeks input from others. If accepted and the details are worked out then it can be considered a design document. People can comment on the OED Discord channel or put comments/ideas below.

## Comments/ideas

- Enter then here.
