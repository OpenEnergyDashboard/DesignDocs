# OED Holiday Turnover Document

**Date:** August 14, 2026
**Feature branch:** `holidayFrontEnd`
**Implementation PR:** [PR 1697](https://github.com/OpenEnergyDashboard/OED/pull/1697)
**Revision:** converted to MD and refined some of

## What we set out to do

Our goal was to give OED a way to use different Day Patterns on holidays. The configuration flow is:

**Base Holiday -> Holiday Rate -> Holiday Rate Group -> Week Pattern -> Conversion Segment**

A Base Holiday is a dated holiday, such as Thanksgiving 2026. A Holiday Rate connects that holiday to an existing Day Pattern. Holiday Rates can be collected into a Holiday Rate Group, and a Week Pattern can optionally use that group.

We originally expected to build on the previous team’s frontend work and implement more of the holiday rule processing ourselves. During development, we found that the earlier frontend implementation was not available or complete enough to continue directly, and several parts of the original design needed to be reconsidered as our prototypes were added to OED. Later the overall time-varying conversion document was updated to include the remaining server-side RRule integration in [OED issue #1681](https://github.com/OpenEnergyDashboard/OED/issues/1681). That was designed as upcoming, future work. Our team therefore focused on completing the holiday administration UI, API and database persistence, and the selections intended to support the future RRule integration.

## Current project status

The main configuration workflow exists and saves data:

- Base Holidays imports holidays for a country, optional state/province, optional region, and year.
- Holiday Rates connect a Base Holiday to a Day Pattern.
- Holiday Rate Groups collect one or more Holiday Rates.
- Week Pattern create and edit forms include an optional Holiday Rate Group selection and save that relationship.

An administrator can therefore configure holiday information. However, graph readings and conversions do not yet change on holiday dates. Applying these saved exceptions during time-varying conversion processing remains part of issue #1681.

During review, the complete Week Pattern create flow could not be verified because it encountered a separate Week Pattern problem. The Holiday Rate Group selector and persistence are present, but this relationship should be tested again on the final integration branch after the related conversion work is merged.

## Base Holidays page and API

This involved the Base Holidays page and its connection to the backend.

Added the page where an administrator selects a country, optional state/province, optional region, and year. Location choices and holiday dates come from the `date-holidays` npm package through the OED server. The browser uses Redux Toolkit Query (RTK Query) rather than calling the package directly.

When an administrator imports holidays, the server inserts or updates all holidays returned for the selected location and year in a database transaction. RTK Query then invalidates the saved Holiday list and reloads it from the database. The page displays the saved holidays for the current selection as cards in date order.

Main files:

- `src/client/app/components/holiday/HolidayPage.tsx`
- `src/client/app/components/holiday/HolidayViewComponent.tsx`
- `src/client/app/redux/api/holidaysApi.ts`
- `src/client/app/types/redux/holidays.ts`
- `src/server/routes/holidays.js`
- `src/server/models/Holiday.js`
- `src/server/sql/holiday/`

## Holiday Rates

This involved the Holiday Rates page, which connects a Base Holiday to a Day Pattern. In the database and older code, a Holiday Rate is called a `holiday_instance`.

An administrator can create a rate by selecting a location, a Base Holiday, and an existing Day Pattern, then providing a name and optional note. The Base Holiday cannot be changed after creation because doing so would effectively create a different rate. Required fields are highlighted until completed, deletion uses a confirmation prompt, and the edit save button is enabled only after something changes.

The page uses RTK Query to load holidays and Day Patterns and to run the add, edit, and delete mutations. Successful mutations invalidate and reload the Holiday Rate list. The location selector filters the Base Holiday choices after holidays from more than one location have been imported.

The initial `holiday_instance` server routes and model were done pervious on a separate branch. I merged that work, connected the frontend to the GET, add, edit, delete, and details endpoints, and completed the frontend workflow. After review, I added TODO comments for deferred design and consistency improvements.

Main files:

- `src/client/app/components/holiday-instances/HolidayInstancePage.tsx`
- `src/client/app/redux/api/holidayInstancesApi.ts`
- `src/client/app/types/redux/holidays.ts`
- `src/client/app/translations/data.ts`
- `src/server/routes/holidayInstances.js`
- `src/server/models/HolidayInstance.js`
- `src/server/sql/holidayInstance/`

## Holiday Rate Groups and Week Pattern connection

This involved creating the Holiday Rate Groups page and connecting the groups to Week Patterns.

An administrator can create a named group, filter Holiday Rates by location, select multiple rates, and add an optional note. Existing groups appear as cards and can be opened for editing or deleted through a confirmation dialog. The page displays notifications for successful and failed operations.

The page uses RTK Query to load Holiday Rates and Holiday Rate Groups and to run add, edit, and delete mutations. Successful mutations invalidate and reload the group list. Group membership is stored separately so one group can contain multiple Holiday Rates while keeping the group's name and note separate.

I also added an optional Holiday Rate Group selector to the Week Pattern create and edit forms and updated the frontend, route, model, and SQL handling needed to save that relationship.

Main files:

- `src/client/app/components/holiday-instance-groups/CreateHolidayInstanceGroupModalComponent.tsx`
- `src/client/app/components/holiday-instance-groups/EditHolidayInstanceGroupModalComponent.tsx`
- `src/client/app/components/holiday-instance-groups/HolidayInstanceGroupComponent.tsx`
- `src/client/app/components/holiday-instance-groups/HolidayInstanceGroupViewComponent.jsx`
- `src/client/app/redux/api/holidayInstanceGroupsApi.ts`
- `src/server/routes/holidayGroupMembers.js`
- `src/server/models/HolidayGroupMember.js`
- `src/server/routes/holidayInstanceGroups.js`
- `src/server/models/HolidayInstanceGroup.js`
- `src/server/sql/holidayGroupMember/`
- `src/server/sql/holidayInstanceGroup/`
- `src/client/app/components/weeks/CreateWeekModalComponent.tsx`
- `src/client/app/components/weeks/EditWeekModalComponent.tsx`
- `src/server/routes/weeks.js`
- `src/server/models/Week.js`

## Remaining server integration

The current implementation saves holiday configuration but does not apply it to conversion results. The future work described in issue #1681 and the [time-varying conversion design](./conversionsVaryTime.md#exceptions-for-conversion-patterns) needs to resolve the applicable holiday dates, exclude those days from the normal weekly RRule, insert replacement segments from the Holiday Rate's Day Pattern, and verify that the final conversion ranges have no gaps or overlaps.

One important design question remains. The current Base Holidays page saves a concrete date for a selected year, while the RRule design expects a holiday to be resolved for every year covered by a Conversion Segment. Future work must decide whether Base Holidays should become reusable holiday definitions or whether administrators must import and configure each applicable year.

## Known limitations and Future work

Review identified additional changes to the Base Holidays workflow. These changes were left for future contributors rather than being rushed at the end of the capstone. Most are page improvements, although some decisions may also affect the RRule integration in issue #1681.

The main Base Holidays changes to consider are:

- Preview holidays before saving and let the administrator confirm or cancel.
- Separate importing or updating holidays from viewing locations already saved in OED.
- Treat a saved location and year as a manageable item, possibly with cards, notes, and last-updated information.
- Normalize Country, State/Province, and Region instead of repeating one combined location code on every holiday.
- Show readable names with codes, such as `California (CA)`, rather than only codes such as `US-CA`.
- Show which years have already been imported and warn when importing a year other than the current year.
- Retain page selections when the administrator navigates away, with a clear or discard option. **This may be a bug in the branch itself, as this functionality seems broken on other pages as well.**
- Add dependency aware deletion so a Base Holiday, Holiday Rate, or Holiday Rate Group cannot be removed while another item depends on it. The desired behavior requires further design consideration once the RRule backend is connected.
- Decide whether names from `date-holidays` should remain in English or follow the selected OED language.

Additional Holiday Rate improvements include client side duplicate name and duplicate association validation, a specific message when deletion is blocked by a group, and moving remaining page local logic and styles into OED's shared components where appropriate.

Additional Holiday Rate Group improvements include client side duplicate name validation, making location an optional filter rather than a prerequisite, highlighting the required Holiday Rates field when empty, providing a specific message when deletion is blocked by a Week Pattern, and resolving the Week Pattern validation issue.

Likely starting points for the Base Holidays redesign are:

- `src/client/app/components/holiday/HolidayPage.tsx`
- `src/client/app/redux/api/holidaysApi.ts`
- `src/server/routes/holidays.js`
- `src/server/models/Holiday.js`
- `src/server/sql/holiday/`

## Testing completed

- Imported US-CA holidays for 2026 and confirmed that 26 records were saved.
- Repeated the same import and confirmed that the count remained 26 rather than creating duplicates. Importing another year creates separate dated holiday records, as expected.
- Confirmed that the TypeScript check passed.
- Manually tested the three holiday administration pages and database persistence.
- No holiday specific automated tests were added.
- The local full server test run produced existing readings and 3D failures reporting `expected null to be a number`; no holiday-specific failure was identified.

## Handoff references

- [Holiday RRule OED issue #1681](https://github.com/OpenEnergyDashboard/OED/issues/1681)
- [Time-varying conversion design](./conversionsVaryTime.md#exceptions-for-conversion-patterns)
- Implementation PR: [PR 1697](https://github.com/OpenEnergyDashboard/OED/pull/1697)
