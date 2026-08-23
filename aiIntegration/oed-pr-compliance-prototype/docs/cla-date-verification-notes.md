# CLA Date Verification Notes

## Purpose

This prototype adds a GitHub Action that verifies the date entered on an OED Contributor License Agreement submission.

The goal is to help detect CLA submissions where the manually entered signing date does not reasonably match the Google Form submission timestamp.

## How It Works

When a pull request is opened, edited, synchronized, or reopened, the workflow runs the `scripts/check-cla-date.js` script.

The script:

1. Reads the pull request author's GitHub username.
2. Reads any additional contributor GitHub usernames listed in the pull request description.
3. Checks whether the CLA acknowledgment checkbox is selected.
4. If the checkbox is not selected, the check stops and asks the contributor to acknowledge that the CLA has been signed.
5. Connects to the Google Sheet containing CLA form responses.
6. Locates the following columns:
   - `Timestamp`
   - `GitHub Username (the Username shown in your profile/used for login)`
   - `Enter today's date (not your birthday)`
7. Finds the CLA submission records for each contributor.
8. Compares the manually entered date with the automatic Google Form timestamp.
9. Allows a difference of up to one day to account for possible time-zone differences.
10. Passes only if every contributor has at least one CLA submission with a valid date.
11. Fails and identifies contributors whose CLA record is missing or whose date is invalid.

## Files Added

- `.github/workflows/check-cla-date.yml`
- `scripts/check-cla-date.js`

## Current Behavior

The current version verifies the pull request author and any additional contributors listed in the **Additional contributor GitHub username(s)** field.

The CLA acknowledgment checkbox must be checked before the script queries the CLA records.

For each contributor, the script compares:

- the automatic Google Form submission timestamp, and
- the date manually entered by the contributor.

The manually entered date is accepted when it is:

- the same calendar day as the submission timestamp,
- one day before the timestamp, or
- one day after the timestamp.

If a contributor has submitted the CLA more than once, the contributor passes if at least one matching submission contains a valid date.

## Testing Notes

Tests should include:

- CLA acknowledgment box unchecked - fails before checking CLA records.
- CLA acknowledgment box checked with valid CLA date - passes.
- CLA acknowledgment box checked with date matching the timestamp exactly - passes.
- Manual date one day before the timestamp - passes.
- Manual date one day after the timestamp - passes.
- Manual date more than one day from the timestamp - fails.
- Contributor not found in CLA records - fails.
- Additional contributor with valid CLA date - passes.
- Additional contributor with invalid CLA date - fails.
- Multiple CLA submissions where one record has a valid date - passes.
- Missing required Google Sheet column - fails.
- Missing Google Sheet or service account configuration - fails.

## Limitations

- GitHub usernames in the CLA records must match the usernames used in the pull request.

- Additional contributors must be listed correctly in the pull request description.

- The script does not automatically identify contributors from commit history.

- The one-day tolerance assumes that a difference of up to one calendar day is sufficient to account for time-zone differences.

- The script supports the date formats currently expected from the Google Form and Sheet. Unexpected date formats may fail validation.

- The check verifies consistency between the manually entered date and the Google Form timestamp; it does not independently prove the contributor's identity.

- The prototype does not prevent a pull request from being opened.

- First-time outside contributors may require maintainer approval before the workflow runs.

- Production use would require OED maintainer approval for GitHub Actions secrets, Google Sheet access, and workflow security.
