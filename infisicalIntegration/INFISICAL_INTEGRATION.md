# Infisical Integration Setup for OED

This guide explains how to run OED with optional Infisical-backed database passwords using the current `password-vault` branch changes.

## What This Integration Does

When enabled, OED will load these two values from Infisical at startup and override local environment values:

- `POSTGRES_PASSWORD`
- `OED_DB_PASSWORD`

All other config values still come from local environment variables.

## 1. Prerequisites

- OED running with Docker Compose
- Infisical instance reachable from the OED web container (Self-hosting instructions here: https://infisical.com/docs/self-hosting/overview)
- A Machine Identity in Infisical with at least read access to the required secrets
- `@infisical/sdk` installed locally in this repository (optional dependency)

Install SDK:

```bash
npm install @infisical/sdk
```

## 2. Create Secrets in Infisical

In your Infisical project, create these exact secret names:

- `POSTGRES_PASSWORD`
- `OED_DB_PASSWORD`

Put them in the environment/path your OED config will reference.

## 3. Collect Infisical Credentials

From Infisical, get:

- `INFISICAL_CLIENT_ID` (Universal Auth client ID)
- `INFISICAL_CLIENT_SECRET` (Universal Auth client secret)
- `INFISICAL_PROJECT_ID`

## 4. Configure OED Environment Variables

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

## 5. Enable Vault Loading in Docker Compose

In the web service environment, set:

```yaml
- PASSWORD_VAULT=yes
```

Keep this as `no` to disable vault loading and use only local env values.

## 6. Self-Hosted Infisical URL Notes

If Infisical is self-hosted and exposed on the Docker host, set:

```env
INFISICAL_SITE_URL=http://host.docker.internal:80
```

Validate connectivity from OED web container:

```bash
docker compose run --rm web sh -lc "curl -sS -I --max-time 8 http://host.docker.internal:80 | head -n 1"
```

Expected: HTTP response line (for example `HTTP/1.1 200 OK`).

## 7. Rebuild and Start

```bash
docker compose down
docker compose up
```

## 8. Verify OED Is Actually Using Vault Values

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

## 9. Troubleshooting

### `@infisical/sdk is not installed`

Install SDK in repo root:

```bash
npm install @infisical/sdk
```

### `StatusCode=401 Invalid credentials`

Usually caused by bad Universal Auth pair.

- Regenerate client ID/client secret for the Machine Identity.
- Ensure you copied Universal Auth credentials, not some other identifier.

### `spawnSync ... ETIMEDOUT`

Network/path to Infisical is not reachable from OED web container.

- Fix `INFISICAL_SITE_URL` to a reachable endpoint.
- Confirm with `curl` from a `docker compose run --rm web ...` command.

## 10. Operational Note for Password Rotation

The existing `changePostgresPassword` script updates DB and local `.env` values; it does not automatically write back to Infisical.

If `PASSWORD_VAULT=yes`, update Infisical secrets after rotating passwords so startup values stay in sync.