# Enhancement to Github Action Testing

The initial problem described is that the testing within the ``travis.yml`` file there are variables stored in plain text. **Issue 553** would like to replace these with github actions and later have them stored within secrets on github.

The owner on OED would need to be the one to store the individual values as secrets among testing because secrets can only be stored by the creator of the repository. You must have admin access to create and store these secrets, so that the rest of the users are able to run OED without any problems.

Below is the converted ``travis.yml`` file to a github action that can be used within OED on github. This file will also be included in the issue.


In this first portion of the code, we define where we are going to target this to be included within. In this case, we want to include it within the ``development`` file. We then define where we are funning this repository on and we are using postgres as the database in the project. For the environment we need to set the user name and password so that when this program builds, we can get logged in to teh database without issues

```yml
name: CI

on: [development]

jobs:

    build:
    runs-on: ubuntu-18.04
    services:
    postgres:
        image: postgres:10
        env:
        POSTGRES_USER: \${{ secrets.OED_DB_TEST_POSTGRES_USER}}
        POSTGRES_PASSWORD: \${{ secrets.OED_DB_TEST_POSTGRES_PASSWORD}}
        POSTGRES_DB: \${{ secrets.OED_DB_TEST_POSTGRES_DB}}
        ports:
        - 5432:5432
        options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
```

You will also notice that <b>usernames, passwords, database, etc</b> are all stored as secrets. This is the root of the issue that was defined before. This is done to ensure the security of OED so that this information is not available in plain text. These would <b>all need to then be stores as a secret</b> within the OED github repository, and this file can then read them and parse them as needed.

```yml
env:
    OED_DB_USER: \${{ secrets.OED_DB_TEST_OED_DB_USER}}
    OED_DB_PASSWORD: \${{ secrets.OED_DB_TEST_OED_DB_PASSWORD}}
    OED_DB_DATABASE: \${{ secrets.OED_DB_TEST_OED_DB_DATABASE}}
    OED_DB_TEST_DATABASE: \${{ secrets.OED_DB_TEST_OED_DB_TEST_DATABASE}}
    OED_DB_HOST: \${{ secrets.OED_DB_TEST_OED_DB_TEST_OED_DB_HOST}}
    OED_DB_PORT: \${{ secrets.OED_DB_TEST_OED_DB_TEST_OED_DB_OED_DB_PORT}}
    OED_TOKEN_SECRET: \${{ secrets.OED_DB_TEST_OED_TOKEN_SECRET}}
    OED_SERVER_PORT: \${{ secrets.OED_DB_TEST_OED_OED_SERVER_PORT}}
    OED_TEST_SITE_READING_RATE: 00:15:00
    DOCKER_COMPOSE_VERSION: 1.27.4
    POSTGRES_PASSWORD: \${{ secrets.OED_DB_TEST_POSTGRES_PASSWORD}}
```

The steps below demonstrate where this program will be runnning, and in this case we will be running it through docker. Following that, the database will be built and will check a series of tests to ensure the build is correct.

```yml
steps:
- uses: actions/checkout@v2
- name: Set up Docker Compose
    run: |
    sudo rm /usr/local/bin/docker-compose
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-\$(uname -s)-\$(uname -m)" > docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
- name: Install Node.js
    uses: actions/setup-node@v2
    with:
    node-version: '14'
- name: Set up database
    run: |
    psql -c 'CREATE DATABASE travis_ci_test;' -U postgres
    psql -c "CREATE USER test WITH PASSWORD 'test';" -U postgres
    psql -c 'CREATE EXTENSION IF NOT EXISTS btree_gist;' -U postgres -d travis_ci_test
- name: Run docker-compose for setup
    run: docker-compose run --rm web src/scripts/installOED.sh --nostart
- name: Check source headers
    run: npm run check:header
- name: Check TypeScript annotations
    run: npm run check:typescript
- name: Check internal type consistency
    run: npm run check:types
- name: Lint check
    run: npm run check:lint
- name: Run tests without Docker
    run: npm test
- name: Run tests in Docker
    run: docker-compose run --service-ports --rm web npm test 
```


This file will be able to be placed in OEDs repository and taken forth from there. This idea is not be completely finished, but gives the genral idea on why and how to convert from ``travis.yml`` to github action. For more information - follow the link [here](https://docs.github.com/en/actions/migrating-to-github-actions/manually-migrating-to-github-actions/migrating-from-travis-ci-to-github-actions). For information on how to store this within a secret follow this [link](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions).
