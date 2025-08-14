# Overview

This Postman collection contains API endpoints for the new UI functionality that allows admin users to manage time-varying conversions and patterns over days and weeks.
It can be used to simplify verification and troubleshooting of API functionality, and as a foundation for future documentation of all OED (Open Energy Dashboard) APIs.

Postman OED Collection & API Documentation: [https://documenter.getpostman.com/view/37855775/2sB3BDLXa7](https://documenter.getpostman.com/view/37855775/2sB3BDLXa7)

The [current JSON version of the Postman API documentation](OED.postman_collection.json) in this repository.

## Folder Structure

The collection is organized into folders corresponding to database tables:

**login** (root-level): Generate a fresh admin token (expires every 24 hours).

**conversions**: Define relationships between units.

**conversion_segments**: Manage time-varying behavior for conversions. Each conversion spans from `-infinity` to `infinity`.

**day_patterns**: Each pattern is made up of one or more day_segments that together span from 0 to 24.

**day_segments**: Manage time-varying behavior for day segments.

**week_patterns**: Manage week patterns, comprised of multiple day patterns.

Each request includes:

- URL, HTTP method, and headers
- Example request body
- Example response

## How to Use the Collection

1. Open the [latest OED API collection](https://documenter.getpostman.com/view/37855775/2sB3BDLXa7) and click **Run in Postman** (upper right corner).
2. Select run in Postman for Web or for Desktop.
3. Log in or create a free Postman account.
4. Import the collection into your workspace.
5. Send the login request with admin credentials to get a temporary admin token (valid for 24 hours).
6. Copy the returned token, open the collection's parent folder (**OED**), go to the **Variables** tab, and set the value for `token_val`.
7. All requests use this value in the header: `token: {{token_val}}`.
8. Browse folders to view and send example requests.
9. Check response data to verify API behavior or troubleshoot issues.

## Adding a New API Endpoint Request

**Access Requirements**: To update the OED collection in Postman, you'll need to be added to the **OED API** workspace. Access can only be granted by current workspace members.

1. Complete steps 1-6 from **How to Use the Collection**.
2. Select the appropriate folder, or create a new one if needed.
3. Right-click the folder and select **Add Request**.
4. Name the request after the API endpoint.
5. Set the HTTP method, URL, and any required headers.
6. Add a JSON request body (if applicable).
7. Send the request, then click **Save Response** and give it a descriptive name.
8. In the **Documentation** tab, add:

    - The purpose of this request
    - Any query parameters
    - Example request body
    - Example response

Follow the instructions below to contribute your changes to the OED Collection.

## Contribute to the OED Collection

**Access Requirements**: To update the OED collection in Postman, you'll need to be added to the **OED API** workspace. Access can only be granted by current workspace members.

1. Export the latest OED API collection from the link above, or pull the latest version from GitHub.
2. Use a personal workspace so as not to affect the live OED collection.
3. After saving all changes, export as **Collection v2.1 JSON**.
4. Add the updated JSON file to the correct location in the git branch.
5. Open a pull request for review.
