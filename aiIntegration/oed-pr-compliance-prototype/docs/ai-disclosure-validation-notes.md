# AI Disclosure Validation Notes

## Purpose

This prototype adds a GitHub Action that checks whether a pull request author completed the required AI Assistance Disclosure section.

The goal is to provide contributors with clear feedback when the AI disclosure is missing or incomplete and to support consistent human review of AI-assisted work.

## How It Works

When a pull request is opened, edited, synchronized, or reopened, the workflow runs the `scripts/check-ai-disclosure.js` script.

The script:

1. Reads the pull request description.
2. Checks for the AI Assistance Disclosure section.
3. Verifies that exactly one AI-assistance option is selected.
4. If AI assistance was used, checks that the AI tool is identified.
5. Checks that the contributor explains how AI was used.
6. Verifies the required human-review acknowledgments.
7. Passes when the required disclosure is complete.
8. Fails and lists missing or incomplete items when validation is unsuccessful.

## Files Added

- `.github/workflows/check-ai-disclosure.yml`
- `scripts/check-ai-disclosure.js`

## Current Behavior

The current version validates the AI disclosure information entered in the pull request description.

## Testing Notes

The script was manually tested with the following cases:

- No AI assistance selected — Pass
- AI assistance selected with complete details — Pass
- Neither option selected — Fail
- Both options selected — Fail
- AI tool entered, usage explanation blank — Fail
- AI tool blank, usage explanation entered — Fail
- AI output review box unchecked — Fail
- Project requirements box unchecked — Fail
- Responsibility box unchecked — Fail
- All human-review boxes unchecked — Fail

All tests produced the expected results.

## Limitations

- The Action checks only the contents of the pull request description.
- It cannot determine whether a contributor's disclosure is truthful.
- The current tests were performed manually.