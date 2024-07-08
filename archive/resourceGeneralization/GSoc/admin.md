# OED feature enhancement: admin access to expanded information in OED

## Idea

There are a number of enhancements being done to OED that requires admins to be able to enter/change values. These include added resource types (detailed here) and normalized data (detailed here). We also want the admin to be able to modify any meter data. Since these can be laborious tasks, having an interface that allows for CVS files to contain the data is desired.

## Implementation

OED currently has a very basic admin panel. A systematic way to add new inputs and edit these values needs to be developed. This will include individual values in text boxes as well as a robust CSV drop capability. This should allow for the needed entries in the admin panel now and in the future.

Note one way to edit meter data is to allow someone to download the needed meter readings as a CSV file, edit values desired for change, and then upload the CSV file. Another GSoC project to allow people to download raw data would enable this without too much work. We already have a way to upload CSV meter data. This should be easier to implement and use then a complex interface to let admins access any data point on any meter. The complex interface is not deemed valuable given this is a feature only for admins and will received limited but important usage.

## Difficulty

This should be a fairly easy project where the adding new data will make it a little more complex. It is possible to combine this project with the download of raw data for a student with sufficient knowledge and drive.
