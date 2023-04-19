# Reduce options on main graphic page

## Introduction

As OED has added features, there are more options for the user to choose. As a result, OED has changed its look at least twice from buttons to menus:

- The original buttons for choosing a graph type:

![old graph type buttons](./OEDGraphicChoicesOld.png)

became a dropdown menu:

![new graph type buttons](./OEDGraphicChoicesNew.png)

A similar change was made to the page choices in the top, right of the OED screen that went from buttons to a dropdown menu due to the growing number of choices (this is about to be incorporated into OED as of April 2023). In both these cases, the growing number of buttons led to formatting issues.

Another place where the number of choices has increased is options on the left side of the OED screen on the graphic pages. The basic idea of the proposed changes is to move less used options to a modal popup, esp. since OED went to a modal look with version 1.0.

## Overview of change

The OED line graphic page currently has these options on the left:

![line graphic page options](./linePageOptions.png)

The items in the green rectangle will remain on the page as is. The items in the pink rectangle will move to a modal popup. An additional button will be placed below the green rectangle area that will say "More options" (in English and to be internationalized as are all the strings described that are shown to the user). When this is clicked, the modal popup with the moved items will appear. There should be a new help icon for this button (OED will provide the needed text so the implementor can put something short for the help popup that indicates the text is needed.) This modal will also have a "Close" button at the bottom to close the modal.

Note the "Hide options" button does not hide this modal but hides all the options on the left so it will remain as a separate button.

The bar graphic page will be similar as shown in this image:

![bar graphic page options](./barPageOptions.png)

The compare graphic page will be similar as shown in this image:

![compare graphic page options](./comparePageOptions.png)

The map graphic page will be similar as shown in this image:

![map graphic page options](./mapPageOptions.png)

The other pages do not have options so they are unchanged.

## React hooks

OED has been transitioning to the newer React Hooks for all new/edited pages. All the pages touched by these changes should be converted. They will use useSelect, useState and useEffect as needed. The paired Containers will be eliminated in doing this.

The Components/Containers that are known to be involved in this work are:

- src/client/app/components/GraphicRateMenuComponent.tsx is already a function with hooks and a guide for some of the others.
- src/client/app/components/ExportComponent.tsx already changed/guide.
- src/client/app/components/ChartDataSelectComponent.tsx already uses hooks.
- src/client/app/components/MultiSelectComponent.tsx does not have a Container but is still a class. Should look into converting to a function style (assuming that is appropriate/works).
- src/client/app/components/groups/DatasourceBoxComponent.tsx and the paired src/client/app/containers/groups/DatasourceBoxContainer.ts.
- src/client/app/components/ChartLinkComponent.tsx & src/client/app/containers/ChartLinkContainer.ts.
- src/client/app/components/LanguageSelectorComponent.tsx & src/client/app/containers/LanguageSelectorContainer.ts.
- src/client/app/components/UIOptionsComponent.tsx & src/client/app/containers/UIOptionsContainer.ts.
- src/client/app/components/MapChartSelectComponent.tsx seems to be converted.

It is possible that some of these are included in other pages so they should be checked and updated if needed (or you want to do that).

The following OED pages have already been converted and can serve as guides:

- src/client/app/components/units/ on several pages
- src/client/app/components/conversions/ on several pages
- src/client/app/components/meters/ on several pages
- src/client/app/components/groups/ on several pages
- src/client/app/components/admin/users/* but they do not deal with state

Others may be converted by the time this work is done.
