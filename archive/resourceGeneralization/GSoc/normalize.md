# OED feature enhancement: analyze and display usage in new ways

## Idea

OED currently displays resources as the actual usage or an aggregation of actual usage from arbitrary combination of meters that can represent a building. It is well known that usage in a building is related to the area of the building, number of occupants and the weather. A common technique is it to normalize the resource usage based upon these considerations. The plan is to modify OED to allow for input/collection of this information and to modify the graphics for the normalized data.

The stretch goal would be to use the new GIS coordinates to create a map representation of the normalized data. A circle would be centered at the GIS coordinate of each building. The size/color of the circle would indicate the normalized usage. Implementation

The database needs to be modified to allow for storage of these values and an API created to work with these values. Except for weather, the admin panel needs to be modified to allow entry of the values for each meter and grouping of meters. This may be done in conjunction with another GSoC project that is extending the admin panel. The API for data needs to be modified to normalize the data based on the chosen value. The graphical pages need to have an option added to allow the user to choose to display the desired normalization. Note another GSoC project is doing unit conversion and this has similarities to these steps.

Doing weather is fundamentally different for three reasons. First, the data varies with time so the data API change is not a simple subtraction across all data values. Second, the primary consideration is temperature but weather can also include the amount of sun and wind. This is an area where investigation needs to be made to determine how best to include these effects. Third, the data does not come from the admin panel but is received from an outside source. This means that doing weather will be a separate step from area and number of occupants.

We have already tested getting limited data from the U.S. National Weather Service and it was successful. This needs to be made robust and acquired on a regular basis including allowing the admin to specify the GIS coordinates for deciding what weather data to ask for. It would be desirable to get the weather data from at least one other major source to make sure the methods are general and to allow sites from other geographical areas to use this feature. This should make it much easier to add other geographical areas in the future.

Adding a normalized map representation will use the Plotly graphics package that has features to do this type of representation. Since the geographical area of an organization is considered limited, an image of the map will be loaded in OED where the GIS coordinates of the top left and lower right corners of the image are input. The placement of circles by GIS coordinates of buildings will be based on a linear scale across the image.

## Difficulty

This enhancement includes changes to both the front-end and back-end of OED by touching database queries, the data API and the Plotly graphical package and involves a number of technologies. What will make it somewhat easier is the new code will be based on existing code except for the map representation. As such, it is likely to be a medium difficult project where maps will make it a harder medium difficult project.
