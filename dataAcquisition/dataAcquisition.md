# General support for automatic data acquisition for readings via meters

## Introduction

OED has been adding systems over the years that it can acquire meter readings (data) from: MAMAC, Aquisuite/Obvius, eGauge, Metasys/Johnson Controls (in progress as of Aug. 2026). The different systems use different methods/protocols and require different information. So far OED has been encoding this information into the meter url field since it was available and worked for the first system done. OED puts needed information after the ? as key/value pairs but this methodology has several limitations:

- Some systems have a central source for multiple OED meters and this requires duplicating that information on each meter.
- It mixes the meter information with how the data is automatically acquired.
- The admin must worry about the format and key name rather than the usual OED way of a web page to guide the input.

This proposal is to create an object/model/database entity with an admin UI that make a reading acquisition method be a first-class object in OED. This object will be able to store general information about the information/parameters needed for any system being accessed by using JSON key:value pairs. With OED's experience with multiple systems and before too many are added, this seems a good time to do this. A meter will now store an id to this information so it is by database reference rather than directly stored on the meter. This addresses all of the points above by avoiding duplication (multiple meters can have the same id) and separates them appropriately. It also brings a standardized way to store the needed information that should support current and future data acquisition systems. The meter will have its own JSON object that is similar to the one in the reading acquisition to store any additional information needed for each meter. For example, the specialized name for this meter that must be supplied during a request. This new JSON storage will replace the current URL attribute for meters. Finally, the new admin UI will greatly simplify entering the needed information and will be meter type specific.

## Implementation/Details

### DB changes

This section describes the changes needed for the DB.

#### JSON/JSONB

There are currently two choices for storing JSON in Postgres as an actual object: JSON and JSONB. While it isn't likely that OED will want to query the keys/values stored as JSON, it appears JSONB would make that easier. Advantages of JSON are unknown at this time. Whoever does this aspect should research and propose which method should be used.

#### Tables

##### Table Name: readings_acquisition (new)

This will store the data acquisition information.

| Column/attribute name | Type | Note |
| :-------------------: | :-: | :-: |
| id | SERIAL PRIMARY KEY | The key for this entry |
| name | VARCHAR(50) UNIQUE NOT NULL CHECK (char_length(name) >= 1) | The standard OED name for the item |
| type | meter_type | What type of meter this applies to. This is a sanity check to make sure it matches the meter via check(s). |
| data_acquisition_info | JSON/B | The key value JSON information for this entry. |
| note | TEXT | Information on this entry as standard OED note |
| | | |

##### Table Name: meters (modified)

| Column/attribute name | Type | Note |
| :-------------------: | :-: | :-: |
| meter_data_acquisition_info | JSON/B | This is a new column that replaces url column. |
| readings_acquisition | INTEGER REFERENCES readings_acquisition(id) | Identifies the data acquisition method where it is null if no method. |
| | | |

If possible, a DB integrity check should be used to verify that if readings_acquisition is not null then the type in the meter table matches the type in the readings_acquisition table for the row referenced.

#### Migration

For an existing site, the current information in the meter table must be properly updated for the new table structure:

- Each unique url entry means that if two meters have the same url entry and type for multiple meters then there should only be one new entry in readings_acquisition. This involves:
  - A new entry in readings_acquisition needs to be made.
    - The name is a little tricky and up for discussion. Maybe the type and some unique, OED generated info. For example, "AcquiSuite site 1". The documentation should let admins know they can update the name.
    - The type will be the same as the meter row from which it is taken. Note above that if multiple meter rows then they must be the same.
    - The data_acquisition_info will be type unique. The information in the URL must be converted to the desired JSON format. See below for information on each system.
    - The note should give a date/time stamp along with the fact that OED created the name as part of the migration.
  - The entry in meters will be updated for all rows with matching url & type:
    - meter_data_acquisition_info column will sometimes be empty/null but some types will need additional information. See below for information on each system.
    - This will be the id of the new row in readings_acquisition associated with this meter. This entry will be null for meter types obvius and other since they do not need an entry. It would be good to verify the url is empty for these types and warn/log if they are not; when this happens the url is copied to the JSON for that meter with the key migration and will have no other keys.
- For the two possible places where JSON is added, validation of the JSON should be done before any entry is added - see below.

### Individual system (type) JSON details

This section describes the unique aspects of the JSON storage for each type of data acquisition system that will initially be supported. Each table lists the key:value pairs that can exist. If allowed, the key:value pair is optional. The exact names of the keys is open for change if people think there are better names.

There will be common keys (not listed below) that will be in every type for the site and meter. To start, this will be the key "version" that will begin with the value 1. It will be changed if the schema is modified so OED will know the shape of the JSON. People can propose other common keys to be included.

OED uses jsonschema to validate JSON and it is currently used on all routes. The same schema validation will be used for each of these systems and done before any entry is put into the DB. Note some systems will not have an entry in readings_acquisition.

The current thinking is the URL will include the http://, https://, etc. but that could be rethought. The MAMAC meter url currently does not have this information so it would be a change. The advantage is the admin can select the needed protocol if it varies (maybe some sites use http and some https). A final option is to add it with a default if not provided and/or warn if not present. All this needs to be determined.

#### AcquiSuite (type obvius)

This type uses a push system to provide the data to OED. It only needs a user of with user_type of obvius to allow access to OED. As such, it should have no JSON schema entry/no data acquisition entry so no check is needed.

#### eGauge (type egauge)

The URL field has ``<web address>/api?registerName=<register>&username=<username>&password=<password>`` where the items with \< > are the specific value for that meter. This will be put into the JSON as:

- url:\<web address\>
- register:\<register\>
- username:\<username\>
- password:\<password\>

All items are required.

Note an ongoing effort to integrate virtual registers will likely change/add new key(s).

[OED eGauge documentation](https://openenergydashboard.org/helpV1_0_0/adminEgauge/) may be of interest.

#### Johnson Controls/Metasys (type metasys but verify that is the final name)

This is currently being developed so the information is not available as of this writing.

#### MAMAC (mamac)

The URL field has ``<web address>`` where the items with \< \> are the specific value for that meter. This is the IP address without http:// or anything following, eg., 1111.11.1.0 This will be put into the JSON as:

- url:http://\<web address\>

The http:// is added since it is not currently given and this makes it the same as other meter types. See below for a discussion of this in case this changes.

All items are required.

[OED MAMAC documentation](https://openenergydashboard.org/helpV1_0_0/adminMamac/) may be of interest.

#### Other (other)

This type is normally used to indicate there is no known or desired method for acquiring the data. As such, it should have no JSON schema/data acquisition entry so no check is needed.

### admin UI

OED should consider if it should do an initial check once a data acquisition site and/or when a meter has a site associated with it is saved. It could also happen on changes to the information that impact getting the data. This would help ensure that it will work when done automatically by OED. There are several considerations:

- An admin might want to enter information before the data acquisition system is available or desired to be contacted. In this case, doing the test would fail and could not be fixed or cause issues. Should this be optional via a check box with default of do the check? Should it be skipped if a meter is disabled and done if enabled?
- What should be done if this fails? Should any meter using it be disabled? Should the admin be asked tio edit the information? Something else?
  - One sanity check would be for the http://, etc. on any input URL and warn if not present to reduce some failures.

#### Reading site

This will have the usual create & edit modals. A delete is also desirable but a check needs to be made that the site is not used for any meter.

The create & edit pages will have the standard OED look/feel. This includes field validation, save disabled until input is okay and the logic for leaving the page without saving.

#### Meter page

The input fields for create and edit will have (not necessarily in this order):

- name & note as usual. Checking that the Redux state does not have the name already is always nice since it must be unique.
- The dropdown for meter type will be augmented so input is disabled once a data acquisition site is selected. The admin cannot change the type without first unselecting the site (if already selected).
- Once the meter_type is set (by admin or automatically), the modal will then show all the fields for that meter type. The values will be type specific that might be needed for this meter type. Note that currently none do but the ability should be include in the design/code - it is believed that Metasys will use this ability once it is finalized. The checks for valid input also vary for each type. Once the code has an actual instance for input, it would be nice if the admin is warned on save if none are set to make sure they are aware of this to avoid accidentally not setting the JSON values for this meter type. (See below where this ability will be needed for the data acquisition site UI.)
- There is a dropdown menu for data acquisition site choices including an option for no site (the initial value on create). If no meter type has been selected then all sites are shown. Once a meter type is known, the choices are only for sites with the same type as the meter.  This means the site must have the same type as the meter. If there are already JSON values for the meter and the admin selects no site then a modal popup should be shown to warn that all the site values will be lost and cancel/okay to continue. This will help avoid accidentally losing site input/information. OED has standard confirmation modals, look and type of text. If a site is selected but no meter type is yet selected then the meter type is automatically set to the site type.

For edit, it is similar to create but the values start as the ones already stored.

#### Data acquisition site

- name & note as usual. Checking that the Redux state does not have the name already is always nice since it must be unique.
- The type will work similarly to the meter page with the controlled dropdown menu. The JSON needs for the site type will have input fields once this is selected. Also, on edit, the Redux state should be checked to see if any meter is already using this site if it would have an impact (no check if the name or note is modified since no impact). If so, a confirmation modal is popped up to show the impacted meters and confirm/cancel. There is similar logic on other pages as there is for many aspects of the UI.

### Other changes

#### Routing

A standard Redux Toolkit route on the client will be added for the data acquisition site and the meter one modified for changes. On the server, the route and model is created/modified for the two UI pages.

#### DB

The DB will be changed to support these changes (see above).

#### Current data acquisition software

All systems will need to be modified to use the new JSON instead of the current URL. Using common functions for similar functionality is desirable. Part of this is to make sure the current configuration values that exist will now be meter based rather than more global.

#### Testing

OED will want to modify the meter tests and add ones for data acquisition sites. The tests will be thought through once an implementation is at least somewhat set.

### Rate limiting

The Metasys software includes rate limiting on requests. The eGauge data acquisition also makes axios requests. It should use similar rate limit ideas and testing. The entire OED code base should be checked to see about other possible uses and if they need rate limiting. This may mean that standardized methods are created to support doing rate limits on requests including if the values are admin controllable.

### Security

Some of the information stored about sites is clearly sensitive such as username and password. It may also be prudent to protect other information (such as url) as an extra step. However this is done, it will be used for any information OED wants to protect throughout the project. (Note that OED login passwords are different since only the hashed value is stored.) As such, it should use util functions that can be used in other places.

The exact method is open to change but the current idea is to create an encryption key that is used to encrypt sensitive data before storing in the DB. The encryption key would allow for unencrypting when the original information is needed. A full plan needs to be created for doing this. This may be some useful information and there are many other sources:

- For recommendations on securing information see: https://devguide.owasp.org/en/04-design/02-web-app-checklist/08-protect-data/.
- For NodeJS maybe use AES-256-CBC: see https://dev.to/superviz/implementing-symmetric-and-asymmetric-encryption-with-nodejs-4efp
  - Many other resources: the web search "how to use node crypto for symmetric key encryption" gave info and code - - For NodeJS crypto docs: https://nodejs.org/api/crypto.html.

The encryption key must be secured to protect the sensitive information. [Issue 1650](https://github.com/OpenEnergyDashboard/OED/issues/1650) and the linked items describe an ongoing effort to add a secure vault to OED. In the long-term this is the logical place to keep the key. If this is not yet available, the key will be stored via an environment variable as was done in [PR 1554](https://github.com/OpenEnergyDashboard/OED/pull/1554).

Care should be taken in using the sensitive information. Some of the above links discuss this. For example, encryption key and any decrypted values should be done right before needed and then erased manually so they do not stay in memory.

The information to be encrypted must be decided but the username and password will definitely be done. A negative of encrypting DB information is it cannot be directly looked at via a DB query (which is what protects it). Thus, OED will only encrypt information that is deemed appropriate and not the entire DB.

## Plan/other information

This effort will be tracked with GitHub issues and project board that will be posted here once ready.
