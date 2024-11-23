Requirements:
If you don’t have Docker installed please refer to the getting started page and installation directions for details on Docker installation and installation of an OED site for production use.

Setup/Running Test:

Testing Methodology
Testing environment:
Cypress testing is installed using the Docker containerization tool, allowing for it to be segregated from the rest of the system. This approach makes updates easier, since docker uses the latest image tag provided by cypress to create the container (Note: you have to delete the docker container and image and then rerun “docker compose --profile ui-testing up” to create the cypress docker container with the latest updates). Dependences are also all taken care of through the container definitions. Testing within a standardized Docker Container ensures best practice and results consistency. 

For most users looking to get the OED site for production docker compose up is used, however to do UI testing, “docker compose --profile ui-testing up” must be used to set up the cypress container (if the container isn’t already initialized) and start. The flag --profile specifies a profile must be passed and then ui-testing is passed as the argument as the profile. This tells docker to run the cypress service within the docker-compose.yml file alongside the web and database services.

When all containers are finished initializing, attach the cypress shell and there you can run cypress commands.

Testing Strategy:
Currently when we want to look at a UI element we must manually navigate the page, inspect the page, and copy as selector on the element that you want to test. Once we have this, cypress is able to get elements based on their selector. We decided to do this since the alternative of iteratively looping through the elements would be less precise and less strict testing. Testing using selectors should work well enough for this, as there are little to no dynamically rendered components. In the case of dynamically rendered components the ability to manipulate them may involve more logic and cypress steps in order to work as intended. 

Testing Scenarios:


Limitations: 
Currently there is no way of showing the browser while the test is running (--headed) or showing the cypress testing application (npx cypress open) within the containerized cypress image . For now all testing must be done through the cli and to utilize Cypress’s screenshot feature in order to check what testing is occuring (refer to cypress screenshot documentation).

All testing must refer to web:3000 like cy.visits(‘http://web:3000”) or cy.visits(“\”) the default url set in the YML file (under environment as ‘- CYPRESS_BASE_URL=http://web:3000’).



Notes:
For all cypress testing scenarios is visited the webpage web:3000 is the only page
The cypress container nicely interacts with the web container.

install_args="--skip_db_initialize" docker compose --profile ui-testing up
Running the command above skips initializing the database container which saves time during testing. Run the command only if the database hasn’t been altered.

Know Errors:
Error response from daemon: network 6c6712650678a8a6aa53d3a085404410fe64b2dfe2c4e132939beeec1dbef6dc not found

Solution: Delete the all or the cypress  docker  container and the image and rerun 
‘docker compose --profile ui-testing up’

There might be something wrong with a Docker container during initialization. When in doubt try to delete the docker containers and rerun.

“Failed to connect. Is Docker installed?” (On VSCode Docker Extension)
Solution: Reboot System
