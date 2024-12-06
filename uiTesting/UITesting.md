# Requirements
If you **don’t have Docker installed** please **refer** to the **getting started page** and **installation directions for Docker** and **installation of an OED site for production** use (getting OED to run in your browser) .

# Testing environment
Cypress testing is installed using the Docker containerization tool, allowing for it to be segregated from the rest of the system. This approach makes updates easier, since docker uses the latest image tag provided by cypress to create the container (Note: you have to delete the docker container and image and then rerun 'docker compose --profile ui-testing up' to create the cypress docker container with the latest updates). Dependences are also all taken care of through the container definitions. Testing within a standardized Docker Container ensures best practice and results consistency. 

# Setup/Running Test Walk Through
For most users looking to get the OED site for production run 'docker compose' up in your local terminal which initalizes and starts the web and database docker container. To do UI testing, 'docker compose --profile ui-testing up' must be used which behaves like 'docker compose up' but it also initalizes and starts the cypress container. The flag --profile specifies a profile must be passed and then ui-testing is passed as the argument as the profile. This tells docker to run the cypress service within the docker-compose.yml file alongside the web and database services.

When all containers are finished initializing, attach the cypress shell and there you can run cypress commands.

##### Clone the testing repoistory from https://github.com/aravindb24/OED

##### Open terminal and run 'docker compose --profile ui-testing up'
https://github.com/user-attachments/assets/3d6c3b49-69c9-42e0-b0f8-a1a56bb9c236

Notes: Ensure docker application is running and after running the command 'docker compose --profile ui-testing up' the docker image and container both show up.

##### Running test
https://github.com/user-attachments/assets/6103e95a-8ffc-4504-a193-3c5b896bb014

Command to run test: 'npx cypress run'
To find more cypress commands related to running cypress.

# Testing Strategy
Currently when we want to look at a UI element we must manually navigate the page, inspect the page, and copy as selector on the element that you want to test. Once we have this, cypress is able to get elements based on their selector. We decided to do this since the alternative of iteratively looping through the elements would be less precise and less strict testing. Testing using selectors should work well enough for this, as there are little to no dynamically rendered components. In the case of dynamically rendered components the ability to manipulate them may involve more logic and cypress steps in order to work as intended. 

# Testing Scenarios:
https://github.com/user-attachments/assets/541a4632-ccdb-4f25-b35c-ee810c89001e

Currently we test specific elements using the elements' css selector. In the video I first open the inspect element tool and inspect element the menu bar to pinpoint it's location in the html. In this case I recursively open the element's child to see it's children. This is
since trying to inspect element any specific menu item makes the menu disappear and clicking the drop down on the inspect element interface to see menu items also runs into the same issue.

# YML File:
The YML File is used by docker to create and start docker containers using docker images. In the case for UI testing, the cypress testing service is listed towards the bottom of the YML file, which describes how to setup the testing container. Currently we are using the docker image provided by cypress and note currently using a Xvfb (X Virtual Framebuffer) as the display that performs graphical operations without a physical display. Currently we do not know how and if there's an option to display what's running in the cypress container. 

# Limitations: 
Currently there is no way of showing the browser while the test is running (--headed) or showing the cypress testing application (npx cypress open) within the containerized cypress image . For now all testing must be done through the cli and to utilize Cypress’s screenshot feature in order to check what testing is occuring (refer to cypress screenshot documentation).

All testing must refer to web:3000 like cy.visits(‘http://web:3000”) or cy.visits(“\”) the default url set in the YML file (under environment as ‘- CYPRESS_BASE_URL=http://web:3000’).

### Notes:
For all cypress testing scenarios is visited the webpage web:3000 is the only page
The cypress container nicely interacts with the web container.

install_args="--skip_db_initialize" docker compose --profile ui-testing up
Running the command above skips initializing the database container which saves time during testing. Run the command only if the database hasn’t been altered.

### Know Errors:
Error response from daemon: network 6c6712650678a8a6aa53d3a085404410fe64b2dfe2c4e132939beeec1dbef6dc not found


##### Solution: Delete the all or the cypress  docker  container and the image and rerun 
‘docker compose --profile ui-testing up’

There might be something wrong with a Docker container during initialization. When in doubt try to delete the docker containers and rerun.

“Failed to connect. Is Docker installed?” (On VSCode Docker Extension)
Solution: Reboot System