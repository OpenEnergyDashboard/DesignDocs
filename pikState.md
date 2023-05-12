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
