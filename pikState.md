# Converting from pik array to state

## Introduction

The resource generalization design uses the pik array on the client. This served the following purposes:

1. Lookup of a conversion from a meter to graphing unit was very fast since it was an array.
2. The size was smaller than the conversion array since it was boolean values. This made transfer faster. The client also had no need to know the actual conversion.

These decisions were fine at the time but are being reconsidered for a number of reasons.

1. OED looks at state in moderately complex ways for all the menus and choices. This has turned out to be fast and OED is not having performance issues from this. Thus, storing the values in state should not make any significant difference from the array.
2. The size to transfer the conversions instead of a boolean should not be too bad. Lets say JSON needed 2 bytes per character as in Unicode. If each boolean takes 2 characters (T/F and comma) then that is 4 bytes per entry. Transferring a conversion would be 2 floating point numbers. Say each number takes 22 bytes (15 for mantissa, 5 for exponent and 1 for sign) plus 2 commas then it is a total of 46 bytes for each conversion. That is 11.5x more per entry. However, even a larger site might have 20 meter types and 50 units for 1000 entries. That means the current system with pik transfer 1000 x 4 = 4k bytes. The new system would be 46k bytes. However, it is going to be less because the array must send each possible entry but the new system only needs the conversions that are possible. Many conversions are not allowed such as between different types of units. Lets guess that only 1/3 of all possible conversions are allowed so it is a modestly sparse array for pik. This means it only transfers 1/3 x 46 = 15.4k bytes or about 4 time more. If you compare this to the total size of all items loaded when OED starts or the typical amount for each line request then it is not big. (For readings it might be half the max # points or 720 with three values per point at a size comparable to floating point so 720 x 3 x 23 bytes each = 49.7k). Thus, sending conversions seems to be fine.
3. The original design had all conversions done on the server. When area normalization was added, it was limited to sq. feet and sq. meters so general conversions were not needed on the client as the normalization is done on the client-side. The plan for baselines that don't change with time is to also do the conversion on the client-side. Note both of these are fast and save state as only the original values are stored and not for each area normalization or baseline. To generalize area to any unit or to do baselines as desired, the client needs the cik values and not pik. Note if OED goes to time varying conversions then this may change but for now it is fine.
4. The array format of pik has caused issues. It required units to have a unit index that complicates all access. It also means that when cik is updated, it invalidates all current pik arrays stored on clients. It is also a reason OED forces a reload when certain changes are made by an admin. Having the values in state that are accessed by the id instead of the index would mean that existing values do not change as they currently do because the unit index can be changed. It will also help allow forbidden operations such as deleting units.

Putting these reasons together, it seems to make sense to store cik in Redux state and get rid of pik.

## Implementation

The changes that are known to be needed are:

1. A new set of values will be stored in state. It will be under the name cik. The structure will be:

cik

- meter unit id
  - non-meter unit id
    - slope and intercept value for the conversion

2. The cik state needs to be loaded when OED starts. It should set the equivalent of pikAvaliable().
3. The code involving pik needs to change to cik

- src/client/app/utils/determineCompatibleUnits.ts
  - unitsCompatibleWithUnit function will have this pseudocode:

```js
export function unitsCompatibleWithUnit(meterUnitId: number): Set<number> {
    // unitSet starts as an empty set.
    const unitSet = new Set<number>();
    // If unit was null in the database then -99. This means there is no unit
    // so nothing is compatible with it. Skip processing and return empty set at end.
    // Do same if pik is not yet available.
    if (meterUnitId != -99 && ConversionArray.cikAvailable()) {
        // The compatible units are all entries for the given unitID.
        for each entry unitId in cik[meterUnitId]
            unitSet.add(unitId);
            }
        }
    }
    return unitSet;
}
```

4. All the uses of pik need to be updated. Searching for pik should find them. Other changes will be needed.

- src/client/app/types/conversionArray.ts is changed to cik.
- src/server/models/Cik.js needs getPik to become getCik and placed in state instead of an array.
- src/server/routes/conversionArray.js need to do cik. Since unitIndex is going away, this will require changes to the storage of the c array. It could even stop being an array. This also means that the storage of cik in the DB is altered.
- src/server/services/graph/createConversionArrays.js should not need createPikArray.
- src/server/services/graph/redoCik.js should not need createPik but may need something for cik depending on how the code is done.
- src/client/app/components/InitializationComponent.tsx now get cik.
- Many involve pikAvalable and become cikAvailable.
- src/server/sql/reading/create_reading_views.sql and src/server/sql/reading/create_function_get_compare_readings.sql needs the references to unit_index removed and the queries updated.

It is likely these overlap the next item and that items are missing. Hopefully testing and searching will figure out any missing items.

5. When all this work is done and working, a number of items can be removed from the OED codebase:

- In src/client/app/utils/determineCompatibleUnits.ts the following can go:
  - pRowFromUnit function should no longer be used.
  - unitFromPRow function was never used but there for symmetry.
  - unitFromPRow function should not longer be used.
- src/client/app/components/InitializationComponent.tsx fetchPik() is not needed.
- unitIndex of units can go away:
  - src/server/models/Unit.js has several places to remove. getByUnitIndexMeter and getByUnitIndexUnit seem only to be used for testing so purge it.
  - src/client/app/components/unit/ needs to have unitIndex removed. The routes need to be changed for this (src/server/routes/units.js)
  - src/client/app/utils/input.ts has it removed.
  - src/server/models/Meter.js getUnitIndex can go. Need to remove from test in src/server/test/db/meterTests.js.
  - update the DB for this: src/server/sql/unit/get_by_unit_index_meter.sql, src/server/sql/unit/get_by_unit_index_unit.sql, src/server/sql/unit/insert_new_unit.sql, src/server/sql/unit/update_unit.sql, src/server/sql/unit/create_units_table.sql
- src/server/models/Unit.js needs it removed. getByUnitIndexMeter & getByUnitIndexUnit seem only used for testing and can go.
- src/server/services/graph/createConversionArrays.js can remove assignIndex.

## Integrating cik

Once the code is switched to cik, the code can be modified to take advantage of the existence of cik rather than pik.

### Avoid reloading OED

As noted in the introduction, certain changes modified pik and the unit_index that necessitated a window reload. With the change to cik, the DB id is used as the key and these do not change. It also removes the unit_index. This means it is should no longer be necessary to do a window reload for this reason. There are two cases discussed for each current reload that need to be addressed:

1. Some changes to cik will mean that some currently graphed meters/groups can no longer be valid for the admin. The admin state should be updated to reflect the new values in cik whenever cik is updated. This can also happen to a current user working on OED but this is just one of many cases where changes by an admin can impact a user so is not addressed at this time. Once conversions are done on the client side, this will mean that previously allowed conversion can still take place until the cik state is updated and new conversions will not be available until cik updates. This should not have serious consequences.
2. OED also does a reload if the DB views are refreshed since the values being graphed can be impacted. This is not necessary but some actions do need to be taken.

The `window.location.reload()` of interest for these cases are all encapsulated in src/client/app/actions/admin.ts in updateCikAndDBViewsIfNeeded. This function causes the cik update and the DB view refresh. This is used by:

- src/client/app/actions/conversions.ts in add, edit and delete of a conversion.
  1. Those that shouldRedoCik should now reload the cik state. If you edit or delete a conversion then the selected meters/groups can be impacted. It is possible to check if there is an impact but for now the simpler change of removing all the selected meters/groups and removing all readings state will be taken since this is not common.
  2. The DB views are never refreshed here.
- src/client/app/actions/meters.ts when a meter is edited.
  1. This never refreshes cik so it is okay as is.
  2. The DB views are refreshed when the meter goes to/from no unit and to/from quantity. In these cases the meters or groups can be impacted. The case of groups should be handled by not allowing a meter to be changed in these ways if it is still used in any group. This is related to the checks in units that stop changes if it is used in a meter. src/client/app/components/meters/EditMeterModalComponent.tsx should be changed to disallow this change. In the case of meters, the cases there that are an issue can be limited by checking if the meter is currently being graphed. If so, then problems could be created so the selected meters and groups are removed from Redux state as is all readings state. It may be possible to avoid this in some cases but that is not done at this time.
- src/client/app/actions/units.ts when a unit is edited or added.
  1. Those that shouldRedoCik should now reload the cik state. The case of adding a unit is safe for selected meters/groups since it cannot yet be used. In the case of unit edit it can be complex so all the selected meters/groups are removed from Redux state as well as all reading state. As noted above, some of these removal might not be needed but this is not done now.
  2. src/client/app/components/unit/EditUnitModalComponent.tsx does the DB view refresh in several cases. First, if what the unit represents changes. However, this is no longer allowed (admin cannot edit) so this part of the check should be removed. Second, if the sec in rate changes. The value of any selected meter/group that uses this unit (including meters included in a selected group) will be impacted. To avoid a complex check in a very unusual case, all the selected meters/groups will be removed from Redux state and all reading state is also removed.

The updateCikAndDBViewsIfNeeded will likely need new parameter(s) to allow finer grain control for these other actions. It seems best to continue to encapsulate the changes there. Also, the reload of cik needs to happen after the cik update is done.

The refresh of the DB views can take some time. It would be nice if the standard bouncing balls were displayed so the admin waits until the process is done. It is believed this was not done before because the reload wiped them out.

### Client-side unit conversions

The original design meant that readings were fetched from the server each time the graphic unit changed. Now that the client knows the conversions in cik Redux state, the client can do the conversions. OED is already doing the area conversions on the client side (and some others in some cases) so the combined conversion can be determined and used to modify all the readings. The changes will be done in two stages: 1) meters and 2) groups.

Note new readings must be fetched if the time range is modified but they will follow the same ideas for the unit used.

#### meters

For a meter to be allowed to graph, it must have a unitId which is the meter unit. If the Redux state does not yet have the readings for this meter then readings are requested for the graphic unit (and time range). See src/client/app/components/ChartDataSelectComponent.tsx at changeSelectedMeters for the start of the process. The readings stored in Redux state will be the ones returned scaled by the inverse of ciks where i = meter unit and k = graphic unit. Each time a meter is graphed (see src/client/app/containers/LineChartContainer.ts for an example), the scaling of the readings will include ciks where i = meter unit and k = graphic unit. This does mean that the first request will convert from graphic unit to meter unit to put into Redux state and then scale the other way to get back the original values from the DB but that is done so it is the same in every case. Note that the meter unit is not absolutely necessary for Redux state key here since there will only be one unit key but it is left so the state layout is not changed and so it mirrors groups that will have multiple unit keys.

#### groups

Groups can have multiple underlying (deep) meters that may or may not be compatible with a single meter unit for a given graphic unit. If the graphic unit is compatible a single meter unit then the readings are stored in that meter unit. The identity conversion graphing unit is used to get the meter data. The needed pseudocode is:

```js
/**
 * Returns the id of any unit with the identity conversion for this meterUnit or -1 if does not exist
 * @param meterUnit The unit of a meter
 * @returns id or -1 if does not exist
 */
function meterIdentityUnit(meterUnit) {
    // It is not common to have more than one identity conversion. For the needed uses,
    // any one should work so can just use the first one found. It is important that this
    // be consistent so the same result is returned each time.

    // Search Redux ciks where i = meterUnit for any k where slope = 1 and intercept = 0
    // return k if exists or -1 if none
}

/**
 * Tells if two values are very close.
 * @param valueOne The first value to compare
 * @param valueTwo The second value to compare
 * @param epsilon The max difference for the two values to differ to be close enough
 * @returns true if two values are close and false otherwise
 */
function close(valueOne, valueTwo, epsilon = 10e-10) {
    // It is belived that the default epsilon will work fine but it might need to be adjusted.
    if (valueOne == 0) {
        valueTwo == 0 < epsilon ? true : false
    } else {
        // Use relative check since safe to divide.
        Math.abs((valueOne - valueTwo) / valueOne) < epsilon ? true : false
    }
}

/**
 * Determines if the meters in the group and the graphic unit are all compatible for storing in Redux state
 * @param groupId The id of the group being checked
 * @param graphicUnit The graphic unit of interest
 * @returns true if compatible or false otherwise
 */
groupCompatible(groupId, graphicUnit) {
    // The deep meters for the group
    deepMeters = // Redux deep meters for groupId
    // The first deep meter from Redux state
    firstDeepMeter = deepMeters[0]
    // The unit associated with the first deep meter
    firstMeterUnit = // the unitId of firstDeepMeter from Redux state
    // Stores index of the graphing unit with identity conversion for firstMeterUnit or -1.
    firstIdentity = meterIdentityUnit(firstMeterUnit)
    // The conversion from the first meter's unit to the graphic unit. This should exist if
    // able to graph this group.
    firstMeterConversion = // ciks from Redux where i = firstDeepMeter and k = graphic unit.
    // Stores the index of the meter in the group being considered
    i = 1
    // Tells if meters in group are compatible.
    // If the first deep meter did not have an identity conversion then these are not compatible.
    // It may be possible to still be compatible but it is unusual that a meter does not have an
    // identity conversion (at least one) so don't try to fix if not.
    compatible = firstIdentity === -1 ? false : true
    // Loop unit there are no more meters in group to consider or the meters are not compatible.
    // If the first meter is compatible with all other meters then all meters are compatible
    // with each other by transitive property.
    while (i < deepMeters.length && compatible) {
        // The current meter being considered
        currentDeepMeter = deepMeters[i]
        // The unit associated with the first deep meter
        currentMeterUnit = // the unitId of currentDeepMeter from Redux state
        // Stores index of the graphing unit with identity conversion for current meter or -1. 
        currentIdentity = meterIdentityUnit(currentMeterUnit)
        if (currentIdentity === -1) {
            // If the meter has no identity conversion then it is not compatible.
            compatible = false
        } else {
            // To be compatible, the first and current meter meters must have the same value for the graphic unit.
            // If not, then the readings for this group cannot be determined from one of the meter units in the
            // group and must be stored from the actual graphic unit. An example is a group with a kWh and BTU
            // meters. They are normally compatible in energy units but may not be for money since the cost per
            // unit differs for these two meters.
            // The conversion from the current meter's unit to the graphic unit. This should exist if
            // able to graph this group.
            currentMeterConversion = // ciks from Redux where i = currentDeepMeter and k = graphic unit
            // Only compatible if the slope and intercept are very close for two meters which means the ratio is 1.
            compatible = close(firstMeterConversion.slope, currentMeterConversion.slope) &&
                close(firstMeterConversion.intercept, currentMeterConversion.intercept)
            if (compatible) {
                // The second condition for these two meters to be compatible is that the two meters
                // must have the same values for the
                // identity conversion. This means that the two conversions are inverses of each other.
                // The identity conversion is telling the relation of the meter to its fundamental graphing unit.
                // It is unusual that these would not be compatbile but check since storing in the meter unit of one
                // would give different values for the other meter if this is not true.
                // Conversion for the first meter.
                firstConversion = // {slope, intercept} of Redux ciks with i = firstDeepMeter and k = currentIdentity or undefined if does not exist
                // Conversion for the current meter
                currentConversion = // {slope, intercept} of Redux ciks with i = currentDeepMeter and k = firstIdentity or undefined if does not exist
                // This checks if the combined slope is close to 1 and the intercept is close to 0 which means that
                // when combined they are the identity conversion. Close is used to avoid roundoff errors
                // since very close will not make a practical difference in what the user sees. If the identity then
                // the meter is compatible.
                compatible = firstConversion != undefined && currentConversion != undefined &&
                    close(firstConversion.slope * currentConversion.slope, 1) &&
                    close (currentConversion.slope * firstConversion.intercept + currentConversion.intercept, 0)
            }
            }
            // Go to next meter.
            i++
        }
    }
}


// For getting state when a group is added for graphing staring in src/client/app/components/ChartDataSelectComponent.tsx
// with changeSelectedGroups.
if (compatible(groupId, graphicId)) {
    // The deep meters for the group
    deepMeters = // Redux deep meters for groupId
    // The first deep meter from Redux state
    firstDeepMeter = deepMeters[0]
    // The unit associated with the first deep meter
    firstMeterUnit = // the unitId of firstDeepMeter from Redux state
    // Stores index of the graphing unit with identity conversion for firstMeterUnit or -1.
    storeUnit = meterIdentityUnit(firstMeterUnit)
    // load reading data requesitng readings for storeUnit but place into Redux with
    // firstMeterUnit as the key for the unit.
} else {
    // load reading data requesitng readings for graphicUnit and store with that key.
    // This should be similar to current code.
}


// For graphing such as in src/client/app/containers/LineChartContainer.ts
if (compatible(groupId, graphicId)) {
    // The deep meters for the group
    deepMeters = // Redux deep meters for groupId
    // The first deep meter from Redux state
    firstDeepMeter = deepMeters[0]
    // The unit associated with the first deep meter
    firstMeterUnit = // the unitId of firstDeepMeter from Redux state
    // Stores index of the graphing unit with identity conversion for firstMeterUnit or -1.
    storeUnit = meterIdentityUnit(firstMeterUnit)
    unitConversion = // ciks where i = firstMeterUnit and k = graphicUnit
} else {
    unitConversion = // 1, 0 so no scaling
}
// Update overall scaling by unitConversion to use for modifying reradings
```
