# OED UI Testing

**Note this is a first version to start the documentation of UI testing in OED. It is expected that it will be updated with more information as OED develops its processes. It is also anticipated that UI testing will be added to the main OED repo. Please feel free to suggest changes and to use this document with its status in mind.**

This is covered by [issue #1419](https://github.com/OpenEnergyDashboard/OED/issues/1419).

## Requirements

Please refer to the [first steps/getting started page](https://openenergydashboard.org/developer/gettingStarted/) which contain ***installation directions for Docker*** and ***installing running OED*** to get OED to run in your browser. It is best to verify OED runs outside of UI testing before doing UI testing. Note the OED repository contains the needed files to do UI testing but they are only used when UI testing is run.

The tests assume the [standard OED test data](https://openenergydashboard.org/developer/testData/) is loaded. This means ``npm run testData`` was properly executed within the web container. **At the current time, some tests assume a default OED setup for the site and unchanged test data. The hope is to fix this in the future.**

## Testing environment

Cypress testing is installed using the Docker containerization tool, allowing for it to be segregated from the rest of the system. This approach makes updates easier, since docker uses the latest image tag provided by cypress to create the container (Note: you have to delete the docker container and image and then rerun 'docker compose --profile ui-testing up' to create the cypress docker container with the latest updates). Dependencies are also all taken care of through the container definitions. Testing within a standardized Docker Container ensures best practice and results consistency.

Note this means that cypress is not part of the node packages that are installed within OED. As a result, IDEs will generally show issues with the cypress definitions. Extra care should be take to make sure of proper usage.

## Setup/Running Test Walk Through

To start OED you would run ``docker compose up`` in your local terminal which initializes and starts the web and database docker container. To do UI testing, ``docker compose --profile ui-testing up`` must be used which behaves like ``docker compose up`` but it also initializes and starts the cypress container. The flag ``--profile`` specifies a profile must be passed which then ``ui-testing`` is passed as that argument. This tells docker to run the cypress service within the ``docker-compose.yml`` file alongside the web and database services.

<!--
A few notes on adding video:
1. Go to the GitHub web version of this file. Edit it. drag-and-drop the desired video file where you want it, save/commit the changes.
2. There currently is a file size limit for adding files (maybe 10 MB?). If the mp4 file is too large then its size should be reduced. One option is VLC (see https://www.digitalcitizen.life/make-video-smaller-windows-10/, for example). Do: Media > Convert/save, choose file with Add, click Convert/Save, under Settings use a smaller Profile such as Video for Youtube HD, set the Destination file & click Start.
 -->
https://github.com/user-attachments/assets/34ff6fc7-c30d-4709-b3c9-6d6a0d265344

Note: Ensure docker application is running and after running the command ``docker compose --profile ui-testing up`` with the docker container running for cypress, database & web.

### Running test

https://github.com/user-attachments/assets/3d95de2e-ceb6-41d7-b711-bca61b0be840

Command to run test: ``npx cypress run`` which should be done inside a shell of the oed **cypress** Docker container that is probably named cypress/included (see [getting started](https://openenergydashboard.org/developer/gettingStarted/) in the section "Using an OED Docker terminal").

## Testing Strategy

Currently when we want to look at a UI element we must manually navigate the page, inspect the page, and copy as selector on the element that you want to test. Once we have this, cypress is able to get elements based on their selector. We decided to do this since the alternative of iteratively looping through the elements would be less precise and less strict testing. Testing using selectors should work well enough for this, as there are little to no dynamically rendered components. In the case of dynamically rendered components the ability to manipulate them may involve more logic and cypress steps in order to work as intended.

## Testing Scenarios

https://github.com/user-attachments/assets/cf0ba738-8499-4605-ab20-09f83edb8470

Currently we test specific elements using the elements' css selector. In the video I first open the inspect element tool and inspect element the menu bar to pinpoint it's location in the html. In this case I recursively open the element's child to see it's children. This is
since trying to inspect element any specific menu item makes the menu disappear and clicking the drop down on the inspect element interface to see menu items also runs into the same issue.

## YML File

The YML File is used by docker to create and start docker containers using docker images. In the case for UI testing, the cypress testing service is listed towards the bottom of the YML file, which describes how to setup the testing container. Currently we are using the docker image provided by cypress and note currently using a Xvfb (X Virtual Framebuffer) as the display that performs graphical operations without a physical display. Currently we do not know how and if there's an option to display what's running in the cypress container. 

## Limitations

Currently there is no way of showing the browser while the test is running (--headed) or showing the cypress testing application (npx cypress open) within the containerized cypress image . For now all testing must be done through the cli and to utilize Cypress’s screenshot feature in order to check what testing is occurring (refer to cypress screenshot documentation).

All testing must refer to web:3000 like ``cy.visits("http://web:3000”)`` or ``cy.visits(“\”)`` the default url set in the YML file (under environment as ``- CYPRESS_BASE_URL=http://web:3000``).

Many tests assume the standard setup and test data.  In the future we should wipe the database and load the needed data (maybe without the actual meter data until needed) in a similar way to how the Chai/Mocha tests work. There are TODO items in the code for many of these.

src/cypress/e2e/general_ui.cy.ts has tests that do not currently work and need to be fixed:

### Notes

For all cypress testing scenarios is visited the webpage web:3000 is the only page
The cypress container nicely interacts with the web container.

```install_args="--skip_db_initialize" docker compose --profile ui-testing up```

Running the command above skips initializing the database container which saves time during testing. Run the command only if the database hasn’t been altered.

### Known Errors

Error response from daemon: network 6c6712650678a8a6aa53d3a085404410fe64b2dfe2c4e132939beeec1dbef6dc not found \
**Solution: Delete the all or the cypress  docker  container and the image and rerun ``docker compose --profile ui-testing up``**

There might be something wrong with a Docker container during initialization. When in doubt try to delete the docker containers and rerun.

“Failed to connect. Is Docker installed?” (On VSCode Docker Extension) \
Solution: Reboot System

### Video files

The original and reduced size (as displayed with "Small" at end of name) video files are available in the repository file list.
