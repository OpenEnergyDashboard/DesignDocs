# Secrets and API Setup

## Purpose

The Signed CLA Verification workflow needs access to the Google Sheet that stores CLA form responses. To keep credentials secure, the workflow uses GitHub Actions secrets instead of storing private information in the repository.

## Creating the Google Service Account JSON Key

1. Go to the Google Cloud Console.

2. Create a new project or select an existing project.

3. In the left menu, go to:

   `APIs & Services → Library`

4. Search for:

   `Google Sheets API`

5. Click **Google Sheets API**, then click **Enable**.

6. Go to:

   `APIs & Services → Credentials`

7. Click **Create credentials**.

8. Choose **Service account**.

9. Give the service account a name, such as:

   `cla-checker`

10. After the service account is created, go to:

    `IAM & Admin → Service Accounts`

11. Open the service account you created.

    Example:

    `cla-checker@your-project-id.iam.gserviceaccount.com`

12. Click the **Keys** tab.

13. Click:

    `Add key → Create new key`

14. Choose **JSON**.

15. Click **Create**.

16. Download the JSON file.

The contents of this JSON file will be stored in the GitHub secret named:

`GOOGLE_SERVICE_ACCOUNT_JSON`

Do not commit the JSON file to the repository.

## Sharing the Google Sheet with the Service Account

Open the downloaded JSON file and find the `client_email` value.

Example:

```json
{
  "client_email": "cla-checker@your-project-id.iam.gserviceaccount.com"
}
```

Copy that email address.

Open the Google Sheet connected to the CLA form. Click **Share** and give the service account email **Viewer** access.

The workflow needs this access so it can read the CLA response sheet.

## Adding GitHub Repository Secrets

In the GitHub repository, go to:

`Settings → Secrets and variables → Actions → New repository secret`

Add the following secrets.

### `GOOGLE_SERVICE_ACCOUNT_JSON`

For the value, paste the entire contents of the downloaded JSON file.

Do not paste only part of the file.

Do not commit the JSON file to the repository or include its contents in workflow logs.

### `CLA_SHEET_ID`

For the value, paste only the Google Sheet ID from the Sheet URL.

Example Google Sheet URL:

```text
https://docs.google.com/spreadsheets/d/thisPart123/edit#gid=0
```

The Sheet ID is:

```text
thisPart123
```

Do not paste the complete Google Sheet URL.

## GitHub Username Column

`scripts/check-cla.js` looks for a Google Sheet column whose header contains both `GitHub` and `username` (case-insensitive).

For example:

- `GitHub username`
- `Contributor GitHub Username`

If the Sheet uses a different column name, the script must be updated accordingly.


