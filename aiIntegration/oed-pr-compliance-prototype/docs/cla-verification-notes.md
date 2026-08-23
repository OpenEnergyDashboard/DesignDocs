# Signed CLA Verification Notes

## Purpose

This prototype adds a GitHub Action that checks whether the pull request author and any additional contributors listed in the pull request description have signed the Contributor License Agreement.

The goal is to reduce manual CLA checking and give contributors clearer feedback when their CLA status cannot be verified.

## How It Works

When a pull request is opened, edited, synchronized, or reopened, the workflow runs the `scripts/check-cla.js` script.

The script:

1. Reads the pull request author's GitHub username.
2. Reads any additional contributor GitHub usernames listed in the pull request description.
3. Checks whether the CLA acknowledgment checkbox is selected.
4. If the checkbox is not selected, the check stops and asks the contributor to acknowledge that the CLA has been signed.
5. Connects to the Google Sheet that stores CLA form responses.
6. Looks for the column containing GitHub usernames.
7. Checks the pull request author and each listed additional contributor against the CLA records.
8. Passes only if a matching CLA record is found for every contributor.
9. Fails and identifies any contributor whose CLA record cannot be found.

## Files Added

- `.github/workflows/check-cla.yml`
- `scripts/check-cla.js`

## Current Behavior

The current version verifies:

- The pull request author.
- Any additional contributors listed in the **Additional contributor GitHub username(s)** field.
- That the CLA acknowledgment checkbox has been selected before CLA records are checked.

Additional contributor usernames may be separated by commas, spaces, or new lines. Duplicate usernames are checked only once.

The current version does not automatically identify contributors from commit history. Additional contributors must be listed in the pull request description.

## Testing Notes

Tests:

- Missing Google service account secret - failed as expected.
- Missing Sheet ID - failed as expected.
- Google Sheet not shared with the service account - failed as expected.
- CLA box unchecked, contributor unsigned - failed as expected.
- CLA box unchecked, contributor signed - failed as expected because acknowledgment is required.
- CLA box checked, contributor unsigned - failed as expected.
- CLA box checked, PR author signed - passed.
- CLA box checked, PR author and additional contributor signed - passed.
- CLA box checked, PR author signed but additional contributor unsigned - failed and identified the missing contributor.

## Limitations

- The GitHub username in the CLA records must match the contributor's GitHub username.

- Additional contributors must be listed correctly in the pull request description.

- The prototype does not automatically identify contributors from commit history.

- The prototype does not prevent a pull request from being opened.

- First-time outside contributors may require maintainer approval before the workflow runs.

- It provides a status check that can be used as part of the pull request review and merge process.

- Production use would require OED maintainer approval for secrets, Google Sheet access, and workflow security.