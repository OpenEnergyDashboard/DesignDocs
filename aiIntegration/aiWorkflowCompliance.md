# AI Workflow and Compliance


## Overview


This project focuses on creating AI usage guidelines, issue-tracking workflow recommendations, and a pull request compliance prototype for OpenEnergyDashboard. The issue-tracking prototype explores how existing AI tools can support contributors, while the compliance prototype uses GitHub Actions to validate AI disclosure and Contributor License Agreement requirements.


The separate OED AI Usage Policy for Contributors defines the contributor-facing requirements for AI use, while this design document explains the workflows, prototypes, testing, and design decisions developed during the project.


## Introduction


OpenEnergyDashboard is an open-source project that helps users monitor and understand resource usage data, including energy and other measurable resources. Since OED is maintained by human maintainers and supported by developers and contributors, clear issue tracking is important for organizing bugs, feature requests, documentation tasks, and beginner-friendly contributions.


AI can help support this process by summarizing GitHub issues, recommending next steps, and generating risk-based questions.


## Students and OED


Students are an important part of the OED project because they may contribute to development, testing, documentation, and issue resolution through coursework or project-based learning. Because students may have different levels of experience with open-source development, the project considered how AI-assisted tools could make issues easier to understand and support contributors with different experience levels.


## AI Use Cases Considered


Although this document focuses mainly on issue tracking, AI may also be useful in other parts of the OED workflow. Possible use cases include summarizing GitHub issues, generating clarifying questions for maintainers, assisting with pull request summaries, helping reviewers identify risky code changes, and checking whether a contribution may need closer human review. Issue tracking provides a lower-risk area for testing AI assistance before expanding to higher-risk areas such as pull request analysis. Other AI use cases can be considered later after the team evaluates whether AI-generated issue summaries are accurate and useful.


These use cases should be introduced carefully. OED should begin with low-risk uses, such as issue summaries and internal review support, before considering more automated or public-facing AI features. Any AI-assisted workflow should include human review before it affects contributors, maintainers, or project decisions.


## Reviewing GitHub Issues


The AI-assisted issue tracking workflow begins with selecting existing issues from the OED GitHub repository [4]. Each issue is reviewed by an AI tool to identify the main problem, the type of task, and any missing information. The AI may produce a short summary of the issue, suggest possible next steps, and generate risk-based questions for contributors. The purpose of this step is to make issues easier to understand, especially for new contributors. The AI does not change the issue directly. Instead, it provides recommendations that a human maintainer can review before making any decisions.


## Issue-Tracking Prototype Plan


The issue-tracking prototype was tested using a small sample of existing OED GitHub issues. The team selected several issues from the OED repository, and for each issue, the AI generated a short issue summary, suggested next steps, and risk-based questions.


After the AI output was generated, the team reviewed the results manually. Each output was checked for accuracy, usefulness, clarity, and whether it correctly reflected the original GitHub issue. The team also identified AI mistakes such as incorrect assumptions, vague recommendations, missing technical details, or suggestions that did not match OED’s project goals.


The results of this review helped inform the development of the separate OED AI Usage Policy for Contributors.


## Issue-Tracking Prototype Testing Results


The prototype was tested using three user roles: student contributor, developer contributor, and maintainer. The goal was to determine whether the AI could adjust its issue-tracking output based on the user’s role and experience level. In all three tests, the AI recognized the selected role and followed the expected structure by providing an issue summary, suggested next steps, and risk-based questions.


However, the responses remained very similar across all three roles and did not clearly adjust the language or level of detail based on experience. This indicates that the prototype can recognize a user role and follow the required output structure, but it does not yet provide sufficiently different guidance for each type of contributor. Stronger role-based prompts or more specific instructions may be needed to improve this behavior.


### AI Evaluation Checklist


The prototype outputs were reviewed using the following checklist:


1. Did the AI recognize the user role correctly?
2. Did the AI adjust its language and level of detail based on the user role?
3. Did the AI keep the human-in-the-loop rule?


## Pull Request Compliance Prototype


As a practical extension of the OED AI Usage Policy for Contributors, the team created a pull request compliance prototype. The prototype includes automated GitHub Actions that support contributor responsibility and project policy requirements.


The prototype includes:


- AI disclosure validation, which checks whether contributors completed the required AI Assistance Disclosure section.
- Signed CLA verification, which checks the pull request author and any listed contributor GitHub usernames against OED’s CLA response records.
- CLA date verification, which checks whether the recorded CLA submission satisfies the required date condition.


These checks provide contributors with clear feedback, but they do not replace human maintainer review or determine whether the information submitted by a contributor is truthful.


### Prototype Workflow


When the configured pull request events occur, GitHub Actions starts the relevant compliance workflows.


1. The AI disclosure workflow reads the pull request description.
2. The AI disclosure script checks the disclosure options, required fields, and human-review acknowledgments.
3. The signed CLA workflow reads the pull request author’s GitHub username and any additional contributor usernames listed in the pull request description.
4. The CLA script compares those usernames with the CLA response records stored in the Google Sheet.
5. The CLA date workflow checks the applicable CLA submission date information.
6. Each workflow passes when its requirements are satisfied or fails and displays feedback explaining what must be corrected.


### Main Implementation Files


- `.github/workflows/check-ai-disclosure.yml` — Runs the AI disclosure validation workflow.
- `.github/workflows/check-cla.yml` — Runs the signed CLA verification workflow.
- `.github/workflows/check-cla-date.yml` — Runs the CLA date verification workflow.
- `scripts/check-ai-disclosure.js` — Validates the AI disclosure fields and human-review checkboxes.
- `scripts/check-cla.js` — Compares contributor GitHub usernames with the CLA response records.
- `scripts/check-cla-date.js` — Validates the relevant CLA submission date requirements.
- `pull_request_template.md` — Collects AI disclosure, human-review, CLA, and contributor information.


### Setup and Integration Requirements


To use the prototype in OED:


1. Add the workflow files to the repository’s `.github/workflows` directory.
2. Add the validation scripts to the `scripts` directory.
3. Add or update the pull request template.
4. Configure the required GitHub repository secrets for Google Sheets access.
5. Share the CLA response Sheet with the Google service account.
6. Confirm that each workflow has only the permissions required to perform its checks.
7. Confirm that the CLA verification and CLA date verification workflows use the correct Google Sheet columns and ranges.
8. Test the checks in a fork or separate test repository before enabling them in the main OED repository.


### Security Considerations


The signed CLA workflow uses `pull_request_target` because it needs access to repository secrets used for the Google Sheets connection. Since this event can run with access to trusted repository resources, the workflow must not execute code taken directly from an untrusted contributor branch.


To reduce this risk, the workflow checks out the trusted base-branch version of the validation script rather than the contributor’s pull request branch. This helps prevent a contributor from modifying the script in a pull request and using it to expose repository secrets.


Sensitive information must be stored in GitHub Actions secrets and must not be written directly into the workflow, source code, documentation, or workflow logs. This includes the Google Sheet ID, service account email, and service account private key.


The Google service account should have access only to the CLA response Sheet required by the workflow. Repository workflow permissions should also remain limited to the read access needed to inspect the pull request and repository contents.


Before the workflows are enabled in the main OED repository, OED maintainers should review the workflow files, secret configuration, Google Sheet permissions, checked-out Git reference, and use of `pull_request_target`. The workflows should first be tested in a fork or separate prototype repository.


### Testing and Current Limitations


The AI disclosure validation script was manually tested from the command line by providing sample pull request descriptions through the `PR_BODY` environment variable.


The following AI disclosure cases were tested:


- “No AI assistance was used” selected — Pass
- “AI assistance was used” selected with all required information completed — Pass
- Neither AI assistance option selected — Fail
- Both AI assistance options selected — Fail
- AI tool entered but the explanation of how AI was used left blank — Fail
- Explanation entered but the AI tool field left blank — Fail


The human-review acknowledgments were also tested:


- Human review checkbox left blank — Fail
- Project requirements verification checkbox left blank — Fail
- Responsibility checkbox left blank — Fail
- All three human-review checkboxes left blank — Fail
- Updated responsibility checkbox selected — Pass
- Updated responsibility checkbox left blank — Fail


The improved error message was tested with both failing and passing cases. When required information was missing, the script listed the incomplete item and provided instructions for editing the pull request description from the Conversation tab. When “No AI assistance was used” was selected correctly, the validation passed.


All of the AI disclosure tests described above produced the expected results.


Current limitations include:


- The AI disclosure tests described above were performed manually using local command-line commands.
- The AI disclosure script checks only the text contained in the pull request description.
- It cannot determine whether a contributor’s disclosure or human-review acknowledgment is truthful.
- Validation depends on the expected section headings, field labels, and checkbox wording remaining consistent with the pull request template.
- Changes to the pull request template may require corresponding changes to the validation script.
- The AI disclosure tests do not test the Google Sheets connection used by the CLA workflows.
- CLA verification depends on correct GitHub secret configuration, Google Sheet access, and correct GitHub usernames in the CLA response records.
- CLA date verification depends on the expected date information being present and correctly formatted in the Google Sheet.
- The workflows do not prevent a pull request from being opened. They provide status checks that OED may configure as merge requirements.
- First-time outside contributors may require maintainer approval before a workflow runs.
- Additional integration testing should be completed in a GitHub fork before the workflows are proposed for use in the main OED repository.


### Compliance Prototype Repository and Documentation

- [OED Pull Request Compliance Prototype](oed-pr-compliance-prototype/)


The repository contains the complete prototype, including:


- GitHub Actions workflows
- AI disclosure validation script
- Signed CLA verification script
- CLA date verification script
- Pull request template
- Testing and implementation notes
- Secrets and API setup documentation


**Key documentation:**

- [AI Disclosure Validation Notes](oed-pr-compliance-prototype/docs/ai-disclosure-validation-notes.md)
- [Signed CLA Verification Notes](oed-pr-compliance-prototype/docs/cla-verification-notes.md)
- [CLA Date Verification Notes](oed-pr-compliance-prototype/docs/cla-date-verification-notes.md)
- [Secrets and API Setup](oed-pr-compliance-prototype/docs/secrets-and-api-setup.md)


## Issue-Tracking Risks and Limitations


One risk of using AI for issue tracking is that the AI may misunderstand the issue. The AI may also miss important technical details, assign incorrect priority levels, or suggest next steps that are not appropriate for the OED project. Another limitation is that AI tools do not fully understand the project history, maintainer decisions, or all parts of the OED codebase. Because of this, AI-generated recommendations should only be used as support. Human maintainers must review all suggestions before making decisions about an issue. Furthermore, AI tools may not be equally effective for all contributors, since their benefits can vary depending on experience level and familiarity with the project.


One additional risk is that AI tools may not understand the specific domain or project context of OED. In the ZoomInfo GitHub Copilot case study, developers reported that the tool struggled with domain-specific logic and sometimes produced inconsistent results. This is important for OED because GitHub issues may involve project-specific decisions, energy data concepts, database design, or maintainer preferences that an AI tool may not fully understand. As a result, AI-generated issue summaries or suggested next steps may be incomplete, too general, or incorrect.


## Research Support


A BIS field experiment found that generative AI improved coding productivity, with the largest gains observed among less experienced developers. However, the benefits varied across skill levels and were less pronounced for senior engineers [1].


Research on GitHub Copilot at ZoomInfo provides useful support for using AI as an assistant in software development workflows. In the study, GitHub Copilot was deployed across more than 400 developers, and the researchers measured both quantitative usage data and developer feedback. The results showed an average suggestion acceptance rate of 33%, a line acceptance rate of 20%, and a developer satisfaction score of 72%. Developers also reported time savings of around 20%, especially for repetitive coding tasks, documentation, comments, and unit test generation [2].


Another issue with AI is that it can create extra work for developers by producing low-quality, unclear, or untested suggestions. For OED, this is a risk because maintainers may spend more time reviewing AI-generated output than benefiting from useful work. There is also a risk that contributors may submit low-quality code generated by AI without fully understanding or testing it. Open-source AI contribution policies show that AI can increase the burden on maintainers when contributors submit AI-generated work without proper review [3].


## Future Work


Future work may include addressing how AI can adjust its recommendations based on a contributor’s experience level. One possible solution is to allow contributors to choose their level of expertise, such as beginner, intermediate, or advanced. Based on that selection, the AI could adjust the detail and complexity of its summaries, explanations, and suggested next steps. If the AI output is too complicated or too simple, contributors could provide feedback so the recommendations better fit their needs.


Another area for future work is determining how much AI assistance should be used in the OED project. Current research shows that AI can be helpful, but it should be applied carefully so that it does not encourage contributors to take shortcuts or rely too heavily on AI-generated suggestions. One of the main challenges for OED is finding the right balance between useful AI support and responsible human decision-making. This is why the proposed workflow uses AI in a limited but practical way. The AI can assist with issue summaries, possible next steps, and risk-based questions, but human maintainers still make the final decisions.


Future work may also include testing the AI-assisted issue tracking workflow with more OED GitHub issues. This would help determine whether the AI suggestions are useful, accurate, and consistent across different types of issues. Maintainers and contributors could also provide feedback on whether the summaries and beginner-friendly recommendations are helpful. In the future, the workflow could be expanded to support other areas of the OED project, such as code review and pull request summaries.


## References


[1] L. Gambacorta, H. Qiu, S. Shan, and D. M. Rees,
"Generative AI and labour productivity: a field experiment on coding,"
BIS Working Papers, no. 1208, Bank for International Settlements,
Sep. 2024. [Online]. Available:
https://www.bis.org/publ/work1208.pdf
[Accessed: May. 27, 2026].


[2] G. Bakal, A. Dasdan, Y. Katz, M. Kaufman, and G. Levin,
"Experience with GitHub Copilot for Developer Productivity at ZoomInfo,"
arXiv preprint arXiv:2501.13282, Jan. 2025. [Online].
Available: https://arxiv.org/pdf/2501.13282
[Accessed: Jun. 5, 2026].


[3] M. Weber, “open-source-ai-contribution-policies,” GitHub repository. [Online]. Available: https://github.com/melissawm/open-source-ai-contribution-policies [Accessed: Jun. 14, 2026].


[4] OpenEnergyDashboard, “Issues · OpenEnergyDashboard/OED,” GitHub. [Online]. Available: https://github.com/OpenEnergyDashboard/OED/issues?page=2 [Accessed: Jun. 14, 2026].


[5] OpenEnergyDashboard, “OED Pull Request Compliance Prototype.” [Online]. Available: [oed-pr-compliance-prototype](oed-pr-compliance-prototype/).





