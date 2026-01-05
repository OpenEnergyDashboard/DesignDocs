# OED Software Update & Site Management

## Introduction

So far this proposal presents maintainable update-notification and patch-management approach for OED, based on research on how other open-source systems notify users about updates. The goal is to suggest a solution that fits OED’s existing architecture and avoids major changes such as servers, or intrusive tracking.

**At this point it is a draft and further updates are expected.**

## Current status

- OED tends to have outdated images (PostgreSQL, Node, ..) in released versions and development for the next release.
- OED tends to have outdated Node packages in released versions and development for the next release.
  - Currently released versions are not patched so sites must upgrade versions to get fixes.
- No structured patch-management process.
- Sites only know when a new OED version is available via the website.
- Optional email configuration (not guaranteed).
- No policy defining when a version becomes “unsupported” or “obsolete”.

Without a process, sites may continue using insecure or unsupported versions.

## How other OSS projects handle update notifications

### Home Assistant

- Hosts a latest.json file on GitHub
- Local app checks the file and shows update alerts to admins
- No user tracking

### VS Code (OSS version)

- Client checks a public JSON endpoint on GitHub
- Admin/UI-only notification

### OpenCart / WordPress

- Pull a version file from a public endpoint
- Show admin-only notification

### React-based OSS dashboards

- Most use a simple “fetch version metadata from GitHub on admin login” approach

### Common pattern

- Publish version metadata on GitHub
- The client checks it occasionally
- Only admins see update notices
- No server tracking
- No login-screen exposure

This aligns well with OED’s architecture.

## Proposed Solution

### Patch-Level Base Image Updates

- In containers/web/Dockerfile it sets the Node version.

  ```js
  FROM node:18.17.1
  ```

  - If did ``FROM node:18``then minor patch updates would be done but OED would no longer know the exact version. This may not be an issue but needs to be checked/settled.
  - OED needs to regularly check/update node. It also needs to specify how to do a major update to verify all works correctly.
- containers/database/Dockerfile controls the PostgreSQL version and has similar considerations to the node version above.

For major upgrades, OED might:

- Review quarterly
- Test manually for compatibility
- Only adopt after confirming stability

### How the Update Check Will Work

Since OED does not communicate with any server, here is a non-invasive solution:

#### Step 1: Host Version Metadata Publicly (GitHub Pages)

Example file → latestVersion.json:
{
  "latest\_version": "3.7.0",
  "obsolete\_after": "3.4.0",
  "support\_window": "12 months"
}

- Requires no backend
- No tracking
- Fits open-source norms

#### Step 2:  Check Only When an Admin Logs In

- OED performs this fetch:  GET https://oed-project.github.io/latestVersion.json
  - The exact location might be better in a specified directory for this purpose.

#### Step 3: Compare Versions

OED checks:

- Local OED version
- Latest version
- Whether current version is obsolete

#### Step 4: Admin-Only Banner

Examples:

- If outdated:  “New OED version 3.7.0 is available.”
- If obsolete: “Your OED version is no longer supported. Please upgrade soon.”
  - Specifying the current version in all messages might be be better even though it is in the OED footer.
  - The best and minimum upgrade would also be helpful.
  - OED should probably tell if this is a security update and the severity involved.
- No messages on the login page
- No information leaked to regular users
- Avoids advertising security issues

A nicer (maybe future) system would store information in the OED DB about the latest, time of last notification of admin where the site could set the frequency of reminders and allow for dismissal of banner.

### Version Support Policy

This is a first-cut thoughts and subject to discussion before finalized.

| Version Age      | Status      | Action                                                |
| :--------------: | :---------: | :---------------------------------------------------: |
| 0–12 months      | Supported   | Notify about new versions                             |
| 12–18 months     | Warning     | Show “upgrade recommended”                            |
| 18+ months       | Obsolete    | Show “this version is no longer supported”            |

This gives sites clarity and prevents infinite notifications for abandoned versions.

### Email Notification (Secondary Channel)

Because many sites choose not to configure an outgoing email server (SMTP), OED will not depend on email for critical updates.

- **Primary Alert:** The Admin Login Banner is the mandatory notification channel.
- **Secondary Alert:** If email *is* configured, OED will send an administrative notification as a supplementary alert.
  - As with the banner, OED may need to track when an email is sent and resend as desired.

### Digital Signature / Integrity Verification (Optional)

   To improve safety when downloading from GitHub:

- Add SHA-256 checksums to every release tag
- Sites can verify downloads without needing new infrastructure
- Fits GitHub’s security model

### Long-Term Improvement: Easier Upgrades

To reduce manual steps, OED can explore a future script:

./oed-upgrade.sh

The script could:

- Pull latest release
- Apply migrations
- Restart containers

OED already has an [update process for admins](https://openenergydashboard.org/helpV1_0_0/adminUpgrading/) and the goal is to improve that.

### Package (NPM) Vulnerability Checks

Since OED exposes third-party packages (like Plotly) to users

- Add a recommended monthly check: npm audit –production
- Document how to record & patch vulnerabilities
- Update packages during minor releases, not just majors

This is a proposal that is open for discussion.

## Research Sources

Some information found from basic researching how open-source web apps notify users:

- [https://www.magicbell.com/blog/best-open-source-notification-systems](https://www.magicbell.com/blog/best-open-source-notification-systems) has information on how OSS projects send general notifications, but most tools listed focus on in-app user messaging, not software update notification.
- Home Assistant  Public version manifest (JSON API)
[https://version.home-assistant.io/stable.json](https://version.home-assistant.io/stable.json)
- Visual Studio Code (OSS) – API-based update channel
[https://code.visualstudio.com/docs/supporting/faq\#\_how-do-i-opt-out-of-vs-code-auto-updates](https://code.visualstudio.com/docs/supporting/faq#_how-do-i-opt-out-of-vs-code-auto-updates)
- OpenCart – GitHub-based version distribution
[https://docs.opencart.com/en-gb/upgrading/](https://docs.opencart.com/en-gb/upgrading/)
- Community Best Practices (StackOverflow discussion)
[https://stackoverflow.com/questions/6329396/check-update-available-app-store](https://stackoverflow.com/questions/6329396/check-update-available-app-store)
