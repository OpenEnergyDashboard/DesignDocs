
// Read a required  variable (user name and secrets)
function requiredEnv(name) {
    const value = process.env[name];
    if (!value) {
        console.error(`Missing required environment variable: ${name}`);
        process.exit(1);
    }
    return value;
}

// Normalize GitHub usernames.
function normalize(value) {
    return String(value || "").trim().toLowerCase().replace(/^@/, "");
}

// Escape text before inserting it into a regular expression.
function escapeRegex(value) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// Check whether the CLA acknowledgment checkbox is selected in the PR body.
function hasCheckedBox(prBody, label) {
    const escapedLabel = escapeRegex(label);

    // Normalize checkbox spacing so [x], [ x ], and [X] work.
    const normalizedPrBody = prBody.replace(
        /\[\s*([xX])\s*\]/g, "[$1]");

    const regex = new RegExp(
        `^[ \\t]*-[ \\t]+\\[[xX]\\][ \\t]+${escapedLabel}[ \\t]*$`, "im");

    return regex.test(normalizedPrBody);
}

// This handles common answers like "N/A" or "none" in The PR template.
function isIgnoredContributorValue(value) {
    const ignoredValues = new Set([
        "n/a", "none", "no additional contributors",]);
    return ignoredValues.has(normalize(value));
}

// Validate GitHub username format.
function isValidGitHubUsername(username) {
    return /^[a-z\d](?:[a-z\d-]{0,37}[a-z\d])?$/i.test(username);
}

// Extracts usernames from the "Additional contributor GitHub username(s):" field.
// Ignores the template's parenthetical instruction line so contributors
// don't have to delete it before submitting.
function parseAdditionalContributors(prBody) {
    const label = "Additional contributor GitHub username(s):";
    const escapedLabel = escapeRegex(label);

    const regex = new RegExp(`\\*\\*${escapedLabel}\\*\\*\\s*([\\s\\S]*?)(?=\\r?\\n##|$)`, "i");
    const match = prBody.match(regex);
    if (!match) {
        return [];
    }

    // If someone accidentally repeats the field label, Additional contributor GitHub username(s):
    const repeatedLabelRegex = new RegExp(
        `^\\*{0,2}${escapedLabel}\\*{0,2}\\s*`, "i"
    );

    const rawValue = match[1]
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean)
        // Ignore the template instruction line.
        .filter((line) => !line.startsWith("("))
        // Ignore example lines if examples are added later.
        .filter((line) => !/^example:/i.test(line))
        // Remove repeated label text if it was accidentally copied into the field.
        .map((line) => line.replace(repeatedLabelRegex, "").trim())
        .filter(Boolean)
        .join(" ")
        .trim();

    if (!rawValue || isIgnoredContributorValue(rawValue)) return [];

    // Allow usernames to be separated by commas, spaces, or new lines.
    const usernames = rawValue
        .split(/[,\s]+/)
        .map((username) => normalize(username))
        .filter(Boolean)
        .filter((username) => !isIgnoredContributorValue(username));

    const invalidUsernames = usernames.filter((username) => !isValidGitHubUsername(username));

    if (invalidUsernames.length > 0) {
        console.error("Invalid additional contributor GitHub username(s):");

        for (const username of invalidUsernames) {
            console.error(`- ${username}`);
        }

        console.error("Use GitHub usernames only, separated by commas.");
        process.exit(1);
    }

    return usernames;
}

async function main() {
    const githubLogin = normalize(requiredEnv("GITHUB_LOGIN"));
    const prBody = process.env.PR_BODY || "";
    const claAcknowledgment =
        "I acknowledge that I have signed the OED Contributor License Agreement.";

    // Require the contributor to acknowledge the CLA before checking CLA records.
    if (!hasCheckedBox(prBody, claAcknowledgment)) {
        console.error("Signed CLA verification cannot run yet.");
        console.error("");
        console.error(
            'Check "I acknowledge that I have signed the OED Contributor License Agreement."'
        );
        console.error(
            "After checking the box, save the pull request description. The CLA verification will run again."
        );
        console.error(
            "::error title=CLA Acknowledgment Required::Check the Contributor License Agreement acknowledgment box in the pull request description before CLA verification can run."
        );
        process.exit(1);
    }
    // Load the Google Sheets client only after the CLA acknowledgment is confirmed.
    const { google } = require("googleapis");
    // Google Sheet info.
    const spreadsheetId = requiredEnv("CLA_SHEET_ID");
    const range = process.env.CLA_RANGE || "Form Responses 1!A:Z";
    // Google Service account credentials.
    const credentials = JSON.parse(requiredEnv("GOOGLE_SERVICE_ACCOUNT_JSON"));
    // Fix private key formatting if GitHub stores newline characters as "\n".
    if (credentials.private_key) {
        credentials.private_key = credentials.private_key.replace(/\\n/g, "\n");
    }
    // Authenticate with Google Sheets.
    const auth = new google.auth.GoogleAuth({
        credentials,
        scopes: ["https://www.googleapis.com/auth/spreadsheets.readonly"],
    });
    const sheets = google.sheets({ version: "v4", auth });
    // Read the CLA response Sheet.
    const response = await sheets.spreadsheets.values.get({
        spreadsheetId,
        range,
    });
    const rows = response.data.values || [];
    if (rows.length === 0) {
        console.error("CLA sheet is empty or could not be read.");
        process.exit(1);
    }
    const headers = rows[0];
    const dataRows = rows.slice(1);

    // Column header must contain both "github" and "username" (case-insensitive).
    const githubColumnIndex = headers.findIndex((header) => {
        const normalizedHeader = normalize(header);
        return (
            normalizedHeader.includes("github") &&
            normalizedHeader.includes("username")
        );
    });

    if (githubColumnIndex === -1) {
        console.error("Could not find a GitHub username column in the CLA sheet.");
        console.error("Add a required Google Form field named: GitHub username.");
        process.exit(1);
    }

    // Build a set of all GitHub usernames found in the CLA records.
    const signedUsers = new Set();
    for (const row of dataRows) {
        const username = normalize(row[githubColumnIndex]);

        if (username) {
            signedUsers.add(username);
        }
    }

    // Build a set of everyone who needs to be checked.
    const contributorsToCheck = new Set();

    contributorsToCheck.add(githubLogin);

    const additionalContributors = parseAdditionalContributors(prBody);

    for (const contributor of additionalContributors) {
        contributorsToCheck.add(contributor);
    }

    // Find any required contributor who is not listed in the CLA records.
    const missingUsers = [...contributorsToCheck].filter(
        (username) => !signedUsers.has(username)
    );

    if (missingUsers.length > 0) {
        console.error("Signed CLA verification failed.");
        console.error("");
        console.error("No matching CLA submission was found for the following GitHub username(s):");

        for (const username of missingUsers) {
            console.error(`- ${username}`);
        }

        console.error("");
        console.error("How to fix this:");
        console.error("1. Open the OED Contributor License Agreement link in the pull request description.");
        console.error("2. Each contributor listed above must complete and submit the CLA form.");
        console.error("3. Each contributor must enter their exact GitHub username in the CLA form.");
        console.error("4. Check the Additional contributor GitHub username(s) field and correct any missing or incorrect usernames.");
        console.error("5. After the CLA is submitted or contributor usernames are corrected, edit and save the pull request description to run the verification again.");

        const annotationMessage =
            `No matching CLA submission was found for: ${missingUsers.join(", ")}. ` +
            "Each listed contributor must submit the OED CLA using their exact GitHub username. " +
            "After signing or correcting contributor usernames, edit and save the pull request description to rerun verification.";
        console.error(`::error title=Signed CLA Verification Failed::${annotationMessage}`);
        process.exit(1);
    }

    console.log("Signed CLA verification passed.");
    console.log(`Verified contributor username(s): ${[...contributorsToCheck].join(", ")}`);
}

main().catch((error) => {
    console.error("Unexpected error while checking signed CLA verification.");
    console.error(error);
    process.exit(1);
});