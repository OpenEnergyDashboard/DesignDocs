# AI Usage Guidance for Contributors

*This document is informational and does not establish binding requirements. See the AI Usage Policy Draft for the governing rules.*

## Principle

AI tools are most appropriate when they support a contributor’s own understanding, judgment, and review. They are not appropriate when they replace the contributor’s work or produce a contribution that the contributor has not reviewed, tested where applicable, or cannot explain it yourself.

Examples of appropriate supportive use include:

- Understanding OED code or documentation
- Brainstorming possible approaches
- Debugging errors or explaining error messages
- Drafting documentation or improving wording
- Suggesting tests or edge cases
- Summarizing issues or pull requests
- Translation support
- Self-review before submitting work

## AI Tools

As of July 2026, the following tools were reviewed against OED code and issues and found generally reputable, with reliable output quality:

- GitHub Copilot / Microsoft Copilot
- Anthropic Claude
- OpenAI, including ChatGPT and OpenAI API models
- Amazon Web Services AI tools, including Kiro
- Google AI tools, including Gemini

This list will change as tools evolve — untested tools aren't excluded; any tool used in good faith, per Reputable Tool Use, is acceptable.

## Higher-Risk Changes

Areas that often warrant extra care include:

- Database migrations
- Authentication
- Authorization
- Security
- Unit conversions
- Readings logic
- Graphing calculations
- Docker
- CI
- Dependencies
- Production configuration

This list is illustrative, not exhaustive — other areas may also require extra care.

## Student Learning

**Example of assistive use:** asking AI to explain an error message or an unfamiliar concept while you work through a good-first-issue yourself.

**Example of generative use (not permitted here):** asking AI to write the fix or implementation for you.
