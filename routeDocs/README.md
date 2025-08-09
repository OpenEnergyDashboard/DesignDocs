## Overview

This Postman collection contains API endpoints for the new UI functionality that allows admin users to manage time-varying conversions and patterns over days and weeks. 
It can be used to simplify verification and troubleshooting of API functionality, and as a foundation for future documentation of all OED (Operational Energy Dashboard) APIs.

Postman OED Collection & API Documentation: https://documenter.getpostman.com/view/37855775/2sB3BDLXa7



## Folder Structure

The collection is organized into folders corresponding to database tables:

**login** (root-level): Generate a fresh admin token (expires every 24 hours).

**conversions**: Define relationships between units.

**conversion_segments**: Manage time-varying behavior for conversions. Each conversion spans from `-infinity` to `infinity`.
 
**day_patterns**: Each pattern is made up of one or more day_segments that together span from 0 to 24.
 
**day_segments**: Manage time-varying behavior for day segments.
 
**week_patterns**: Manage week patterns, comprised of multiple day patterns.

Each request includes:

	•	URL, HTTP method, and headers
	•	Example request body
	•	Example response



## How to Use the Collection

	1.	Run the login request with admin credentials to obtain a temporary admin token (valid for 24 hours).
	2.	Copy the returned token and update the `token_val` variable in the collection.
	3.	Each request uses this via `token: {{token_val}}` in the header.
	4.	Browse the folders to view and send example requests.
	5.	Review response data to verify API behavior or troubleshoot issues.



## Adding a New API Endpoint Request

**Access Requirements**: To update the OED collection in Postman, you'll need to be added to the **OED API** workspace. Access can only be granted by current workspace members.

  1.	Choose the appropriate folder (or create a new one if needed).
  2.	Right-click the folder and select **Add Request**.
  3.	Name the request after the API endpoint.
  4.	Set the HTTP method, URL, and any required headers.
  5.	Add a JSON request body (if applicable).
  6.  Send the request, then click **Save Response**, and give it a descriptive name.
  7.  In the **Documentation** tab, add:

    - The purpose of this request
    - Any query parameters
    - Example request body
    - Example response 
  8.	Save the request and commit/export your updated collection; however is appropriate to OED standards.
