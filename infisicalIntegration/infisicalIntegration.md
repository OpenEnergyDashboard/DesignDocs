# OED Secure Vault for Sensitive Information

## Late May 2026 Update

There is a [draft pull request 1609](https://github.com/OpenEnergyDashboard/OED/pull/1609) that demonstrated this can work and did initial integration with OED. The next section about setup came from the developer that did that work. What follows in this section is some information to move this forward so it can be integrated into OED.

### PR listed limitation

The description of the PR has:

> Currently Infisical can only host the passwords for the database, in future this could be expanded to also host user passwords.

It is unclear that is needed. The database passwords and some other information is needed at OED startup and before OED is fully running. Also, this information is sensitive and could possibly be used to try to exploit an OED setup. Keeping it unencrypted in the same files as the OED source code means anyone with access to the files can learn these secrets. This is why it is desired to move them into a secure vault as a good way to mitigate this situation.

The OED user passwords are only needed once OED is fully running. OED stores them in an encrypted form in the database. This is a standard technique since any provided password is encrypted and then compared to the value in the database for authentication. Many systems do this and it is believed it is secure against any reasonable attempt to learn the unencrypted password. Given this, it is unclear OED should transition these to a secure vault.

### Possible improvements to the section below

Here are a few comments that were suggested about modifying the documentation below that should be considered.

#### Sections 2. (Create Secrets in Infisical) & 3. (Collect Infisical Credentials)

Is it possible to add a link to easy directions for each of these steps or put the info directly into this doc?

Are there best practices to document for how to secure the vault from malicious usage? I'm thinking about if the .env were compromised then how to stop people from using the exposed tokens, etc. to get the info from the vault on a different machine. Is there actually a way to protect on the machine running OED? The .env is available to anyone with access to the OED source directory or the running web container.

#### Section 6. (Self-Hosted Infisical URL Notes)

I'm thinking about port 80. I'm assuming this would not conflict if someone maps the OED port to port 80 to serve outside the Docker container - is that correct? I'm just curious if there are any other/better choices than port 80 that is used for other things.

### Why a secure vault and why Infisical?

Some research was done to look into best practices on doing this and a secure vault was a good choice. People then looked into options that allowed for:

- Free for anyone including developers
- Allow for local hosting with online (possibly for a fee) as an option if at all possible
- An OSS license that was compatible with OED but since it is used as a complete package that is less of an issue
- Reliable, supported, believed to be supported for a extended period of time and has a reasonable size group doing that support
- Fairly easy for a new OED instance to set this up since it will be needed by developers

Several options were considered. The developer in communication with OED selected Infisical. Since this appears to meet all the criteria and works, this is considered settled unless someone raises concerns or other ideas.

### What items should OED store in the vault?

See the section on work to do. Basically it should include any sensitive information that is currently stored in OED files. If someone thinks there are missing items or more information should be included then they are welcome to bring this up.

### Work to do

Though the order of work is open, these are listed in the order that might likely be done. Clearly getting this fully integrated is the first step. Even if not completed, anyone working on this should update this document so any follow-on people know what you know.

- Integrate this fully into OED. In addition to the two database passwords mentioned in the previous work, the OED_TOKEN_SECRET should also be incorporated. In addition, all the OED_MAIL_... items should be added. The values in the vault must be used correctly by OED during install an when the software is running.
  - Once this is done, the use of .env might be phased out as unnecessary for these values. Its use for the vault is a separate question.
- Carefully test the software for different uses such as a site & developer. Also do with online system if that is free to try.
- Update the documentation based on previous comments and the final setup. Ultimately this needs to be integrated into the OED website so site and developers can both readily use this system. It should include how to self-host, use the online system, any advise on doing this securely, how to create/update items and clear instructions. It should also take into account the items above on the current documentation.
- Consider if it is possible to easily allow for the current system of storing values in the OED directories for developers while still guaranteeing it will not be used by sites so they are secure. The rationale is it would be simpler for many developers to use known, provided values since they are not targets of attack (in general). Note [PR 1554](https://github.com/OpenEnergyDashboard/OED/pull/1554) decouples site and developer values when desired and may help in considering this. If setup of the secure vault could be automated for developers and it is lightweight then this might not be needed.

## Infisical Integration Setup for OED

This guide explains how to run OED with optional Infisical-backed database passwords using the current `password-vault` branch changes.

### What This Integration Does

When enabled, OED will load these two values from Infisical at startup and override local environment values:

- `POSTGRES_PASSWORD`
- `OED_DB_PASSWORD`

All other config values still come from local environment variables.

### 1. Prerequisites

- OED running with Docker Compose
- Infisical instance reachable from the OED web container (Self-hosting instructions here: https://infisical.com/docs/self-hosting/overview)
- A Machine Identity in Infisical with at least read access to the required secrets
- `@infisical/sdk` installed locally in this repository (optional dependency)

Install SDK:

```bash
npm install @infisical/sdk
```

### 2. Create Secrets in Infisical

In your Infisical project, create these exact secret names:

- `POSTGRES_PASSWORD`
- `OED_DB_PASSWORD`

Put them in the environment/path your OED config will reference.

### 3. Collect Infisical Credentials

From Infisical, get:

- `INFISICAL_CLIENT_ID` (Universal Auth client ID)
- `INFISICAL_CLIENT_SECRET` (Universal Auth client secret)
- `INFISICAL_PROJECT_ID`

### 4. Configure OED Environment Variables

Set these in your `.env`:

```env
INFISICAL_CLIENT_ID=...
INFISICAL_CLIENT_SECRET=...
INFISICAL_PROJECT_ID=...
INFISICAL_SITE_URL=...
INFISICAL_ENVIRONMENT=dev
INFISICAL_PATH=/
```

Notes:

- `INFISICAL_SITE_URL` defaults to `https://app.infisical.com` if not set.
- `INFISICAL_ENVIRONMENT` defaults to `dev` if not set.
- `INFISICAL_PATH` defaults to `/` if not set.

### 5. Enable Vault Loading in Docker Compose

In the web service environment, set:

```yaml
- PASSWORD_VAULT=yes
```

Keep this as `no` to disable vault loading and use only local env values.

### 6. Self-Hosted Infisical URL Notes

If Infisical is self-hosted and exposed on the Docker host, set:

```env
INFISICAL_SITE_URL=http://host.docker.internal:80
```

Validate connectivity from OED web container:

```bash
docker compose run --rm web sh -lc "curl -sS -I --max-time 8 http://host.docker.internal:80 | head -n 1"
```

Expected: HTTP response line (for example `HTTP/1.1 200 OK`).

### 7. Rebuild and Start

```bash
docker compose down
docker compose up
```

### 8. Verify OED Is Actually Using Vault Values

Run this override check. It intentionally injects wrong local password values and confirms they are replaced by Infisical values:

```bash
set -a && . ./.env && set +a

docker compose run --rm \
  -e PASSWORD_VAULT=yes \
  -e INFISICAL_CLIENT_ID \
  -e INFISICAL_CLIENT_SECRET \
  -e INFISICAL_PROJECT_ID \
  -e INFISICAL_SITE_URL \
  -e INFISICAL_ENVIRONMENT \
  -e INFISICAL_PATH \
  -e OED_DB_PASSWORD=__definitely_wrong_local_value__ \
  -e POSTGRES_PASSWORD=__definitely_wrong_local_value__ \
  web node -e "
    const localOed = process.env.OED_DB_PASSWORD;
    const localPg = process.env.POSTGRES_PASSWORD;
    require('./src/server/util/loadInfisicalSecrets')();
    console.log('OED_DB_PASSWORD=' + (process.env.OED_DB_PASSWORD === localOed ? 'NOT_OVERRIDDEN' : 'OVERRIDDEN_FROM_VAULT'));
    console.log('POSTGRES_PASSWORD=' + (process.env.POSTGRES_PASSWORD === localPg ? 'NOT_OVERRIDDEN' : 'OVERRIDDEN_FROM_VAULT'));
  "
```

Expected:

- `OED_DB_PASSWORD=OVERRIDDEN_FROM_VAULT`
- `POSTGRES_PASSWORD=OVERRIDDEN_FROM_VAULT`

### 9. Troubleshooting

#### `@infisical/sdk is not installed`

Install SDK in repo root:

```bash
npm install @infisical/sdk
```

#### `StatusCode=401 Invalid credentials`

Usually caused by bad Universal Auth pair.

- Regenerate client ID/client secret for the Machine Identity.
- Ensure you copied Universal Auth credentials, not some other identifier.

#### `spawnSync ... ETIMEDOUT`

Network/path to Infisical is not reachable from OED web container.

- Fix `INFISICAL_SITE_URL` to a reachable endpoint.
- Confirm with `curl` from a `docker compose run --rm web ...` command.

### 10. Operational Note for Password Rotation

The existing `changePostgresPassword` script updates DB and local `.env` values; it does not automatically write back to Infisical.

If `PASSWORD_VAULT=yes`, update Infisical secrets after rotating passwords so startup values stay in sync.