/*this script checks if pull request AI assistant disclosure section was completed correctly*/


//constant variable that will contain full pull request description
const prBody = process.env.PR_BODY || "";

//normalize checkbox spacing before validation, so [x], [x ], [ x], [ x ], [   x   ] are accepted.
const normalizedPrBody = prBody.replace(/\[\s*([xX])\s*\]/g, "[$1]");

//empty array to store the names of any required items that are missing or incomplete
const missing = [];


/**
 *escape regex function allows labels containing characters such as parentheses or periods
 * to be safely inserted into a regular expression.
 * @param {string} value The text to escape.
 * @returns {string} The escaped text.
 */
function escapeRegex(value) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 *checks whether the pull request body contains a level-two Markdown heading.
 * @param {string} title The section title to find.
 * @returns {boolean} True when the section exists.
 */
function hasSection(title) {
    const escapedTitle = escapeRegex(title);

    const regex = new RegExp(
        `^##[ \\t]+${escapedTitle}[ \\t]*$`,
        "im"
    );

    return regex.test(prBody);
}

/**
 *checks whether a specific Markdown checkbox is checked.
 * @param {string} label The exact text following the checkbox.
 * @returns {boolean} True when the checkbox is checked.
 */
function hasCheckedBox(label) {
    const escapedLabel = escapeRegex(label);

    const regex = new RegExp(
        `^[ \\t]*-[ \\t]+\\[[xX]\\][ \\t]+${escapedLabel}[ \\t]*$`,
        "im"
    );

    return regex.test(normalizedPrBody);
}
/**
 *gets the text entered after a bold Markdown field label.
 * The value continues until the next section heading, bold field,
 * or the end of the pull request body.
 * @param {string} label The field label without Markdown or a colon.
 * @returns {string} The entered value, or an empty string if none exists.
 */
function getFieldValue(label) {
    const escapedLabel = escapeRegex(label);

    const regex = new RegExp(
        `\\*\\*${escapedLabel}:\\*\\*[ \\t]*([\\s\\S]*?)(?=\\r?\\n##|\\r?\\n\\*\\*|$)`,
        "i"
    );

    const match = prBody.match(regex);

    return match ? match[1].trim() : "";
}

//AI Assistance Disclosure

//confirm required AI disclosure section exists
if (!hasSection("AI Assistance Disclosure")) {
    missing.push("AI Assistance Disclosure section");
}

//check if checkbox was selected
const noAiChecked = hasCheckedBox("No AI assistance was used.");
const aiUsedChecked = hasCheckedBox("AI assistance was used.");

//makes sure contributor selects one option
if (!noAiChecked && !aiUsedChecked) {
    missing.push(
        'Check either "No AI assistance was used" or "AI assistance was used"'
    );
}

//contributor cannot select both options
if (noAiChecked && aiUsedChecked) {
    missing.push("Do not check both AI disclosure options");
}

//additional checks if AI is used
if (aiUsedChecked) {
    const toolsUsed = getFieldValue("AI tool(s) used");
    const howUsed = getFieldValue("How AI was used");

    //requires ai tool name
    if (!toolsUsed) {
        missing.push("AI tool(s) used field");
    }

    //require explanation of how AI was used
    if (!howUsed) {
        missing.push("How AI was used field");
    }

    //Human Review of AI-Assisted Work

    //checks if reviewed all AI-assisted output before submitting this pull request box was checked.
    if (
        !hasCheckedBox(
            "I reviewed all AI-assisted output before submitting this pull request."
        )
    ) {
        missing.push("Human review checkbox");
    }

    //checks if I verified that the AI-assisted work follows OED project requirements box was checked.
    if (
        !hasCheckedBox(
            "I verified that the AI-assisted work follows OED project requirements."
        )
    ) {
        missing.push("Project requirements verification checkbox");
    }

    //Checks that the pull request author and any listed contributors
    //reviewed their work and followed OED quality and licensing requirements.
    if (
        !hasCheckedBox(
            "I confirm that I and any listed contributors reviewed our work and followed OED quality and licensing requirements."
        )
    ) {
        missing.push("Responsibility checkbox");
    }
}
//AI disclosure error message
//returns number of items in the array missing. If one error exist then error is printed.
//fails github action if any required information is missing
if (missing.length > 0) {
    console.error("AI disclosure check failed.");
    console.error("The pull request description is missing or has incomplete AI disclosure information:");

    //goes through every item in the array missing and prints each error
    for (const item of missing) {
        console.error(`- ${item}`);
    }

    console.error("");
    console.error("How to fix the pull request:");
    console.error("1. Open the pull request Conversation tab.");
    console.error("2. Click the three-dot menu (...) on the pull request description.");
    console.error("3. Select Edit.");
    console.error("4. Complete the missing AI disclosure information.");
    console.error("5. Click Update comment.");
    console.error("");
    console.error("The AI disclosure check will run again after the description is updated.");

    //ends loop
    process.exit(1);
}

//if no required items are missing, allow the GitHub Action to pass.
console.log("AI disclosure check passed.");