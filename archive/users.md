# Adding user types to OED

## Introduction

When OED was created, we considered having different user types to control access to data. Potential sites did not seem to need this so we did not do it. Instead, we assumed any logged in user was an admin. Now that we are adding URL requests, we need to protect them with passwords. Thus, we will augment the users in OED to allow for this.

## User roles

At this time we should add these roles:

- admin: what the current user login can do. Note admin can also do any other action included in other roles. (done)
- obvius: allows login for obvius URL requests (done)
- csv: allows login for cvs file URL requests. (done)

We could add this role to enhance the current code:

- export: this would allow the user to download files that exceed the size limit for someone not logged in as admin

Future roles might be used to control access to some data but sites have not yet asked for that.

## Areas needing changes:

1. We need to decide how to define the user roles. If it is TS then an enum would work. Since a lot of code is JS we may need to something else that mimics enum. Steve has ideas found from web searches and we can mimic what was done for Meter types.
2. The user table in the DB needs a new column called role. We need to update the following to do this
    1. Files in src/server/sql/user/ to fix DB code. (done)
    2. src/server/models/User.js to add the role feature and be compatible with DB changes. (done)
    3. The DB migration files need ones added for the DB changes. (**no-sure how to do**)
3. The code needs to be modified to work with the user role. (Many of the needed changes were found by searching for User and login in code.)
    1. src/server/services/user/createUser.js (done), editUser.js (done)
    2. src/scripts/installOED.sh when it creates the user to make it an admin (done)
    3. src/server/routes/login.js so role is part of the process. (This was not done in the end to avoid stale roles.)
    4. src/server/routes//user.js probably needs changes (done)
    5. src/server/test/common.js to fix up user created for testing. (done)
    6. src/server/test/web/groups.js, maps.js, meters.js uses a user but it may be okay. (done)
    7. src/server/test/web/login.js needs to be expanded to verify new login items/procedures. (I did not need to expand this test.)
    8. src/client/app/components/RouteComponent.tsx that validates login (I did not use the role on the client-side so this did not need to be changed. However, we did add a new route to access the users management page.)
4. We need to find all the current uses of login and change so they are the admin role. (done)
5. Modify the obvius login to check its role. (By login we ‘obvius login’, we mean ‘obvius route right?, done)
6. Modify the csv login to check its role. (same as step 5 for obvious, done)
7. If we do download then need to modify that code for the role.
8. Files that are likely okay but should check
    1. src/client/app/component.tsx where create login setup (file not found)
    2. src/client/app/utils/api/VerificationApi.ts (not changed)
    3. src/server/app.js that does login routes (added users route for managing users, done)
9. USAGE.md needs update (Is this necessary? To create a user, the admin would use the app; they wouldn’t use the command line.)
10. There will need to be an admin page to edit users. We really should already have this but now is the time. It should list all users and allow the values to be changed. This can be done once the other changes are in place and might be a future enhancement for release 1.0. I think it is okay at this point if only the admin can do the changes and not anyone with that user role login. (done)

## Outline of Process

1. Modify SQL scripts so that the role column is added to the database. (done)
2. Modify the User Model to have an enum for the three roles. (done)
3. Modify startup script so that the test user has the Admin role. (done)
4. Modify server requests to consider user roles. The admin role is a subset of all other roles.
    1. Only Admins can
        1. Modify roles and delete users (done)
        2. Edit meters (done)
        3. Modify site preferences (done)
    2. Only Obvius users can
        1. Make an obvius post request (done)
    3. Only CSV users can
        1. Upload csv data (done)
    4. Only Export users can
        1. Download data over the limit (We added the export role authentication to this action. However, since checking whether the user is requesting data over the limit occurs on the client-side rather than on the server, we could not properly use the export role so that only Export users can download data over the limit. Instead, the implementation is that only export users can download data at all.)
5. Create a page for admins to view, edit, and delete users in the database. (done)
6. Create a page for admins to create new users. (done)
7. Migration files (not sure)
