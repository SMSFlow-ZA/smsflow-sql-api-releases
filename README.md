# SMSFlow SQL API

SMSFlow SQL API lets your application send and track SMS messages through a SQL Server database.

Instead of integrating directly with an HTTP API from every application, you install the SMSFlow worker close to your database. Your system inserts messages into a SQL outbox table, and the worker handles sending, delivery statuses, replies, retries, health data, and operational logs.

## Who This Is For

This repository is for:

- developers integrating SMS into an existing SQL Server-backed application
- technical teams that prefer a database integration pattern
- operators installing the SMSFlow worker on Windows, Linux, Docker, Kubernetes, Helm, or Azure Container Instances
- support teams validating an installation or collecting diagnostics

## Get Started

1. Download the latest release from [GitHub Releases](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/tag/v0.3.0).
2. Choose the bundle that matches your environment.
3. Verify the file against the release checksum manifest.
4. Start in `Simulated` mode and send a test message.
5. Switch to live credentials only after the simulated flow is working.

| Bundle | Choose this when |
| --- | --- |
| [`smsflow-sql-api-0.3.0-windows-host.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-windows-host.zip) | You want the Windows worker service, guided installer, schema tools, validator, and support-bundle tools. |
| [`smsflow-sql-api-0.3.0-windows-manager.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-windows-manager.zip) | You want the optional Windows desktop manager for operations and support users. |
| [`smsflow-sql-api-0.3.0-linux-host.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-linux-host.zip) | You want to run the worker as a Linux service. |
| [`smsflow-sql-api-0.3.0-docker-host.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-docker-host.zip) | You want Docker, Kubernetes, Helm, or Azure Container Instances deployment files. |
| [`CHECKSUMS-SHA256.txt`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/CHECKSUMS-SHA256.txt) | Use this to verify downloaded ZIP files before installation. |

Install guides:

- [Windows install guide](docs/install-windows.md)
- [Linux install guide](docs/install-linux.md)
- [Docker install guide](docs/install-docker.md)

## First SMS Path

For a new integration, follow this sequence:

1. Download the [0.3.0 release](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/tag/v0.3.0).
2. Verify the downloaded ZIP with [release notes and checksums](releases/0.3.0/README.md).
3. Apply the [SQL schema script](examples/sql/sql_integration.sql).
4. Install the worker with the [Windows](docs/install-windows.md), [Linux](docs/install-linux.md), or [Docker](docs/install-docker.md) guide.
5. Keep the worker in `Simulated` mode for the first test.
6. Insert the first message using the [client implementation guide](docs/client-implementation-guide.md).
7. Check message progress in `sms_flow.vw_Messages` or `sms_flow.Message_GetByClientMessageId`.

## Latest Release

Current release: `0.3.0`

- [Release notes and checksums](releases/0.3.0/README.md)
- [SQL schema script](examples/sql/sql_integration.sql)
- [Sample SQL scripts](examples/sql)
- [Client implementation guide](docs/client-implementation-guide.md)
- [Client setup guide](docs/client-setup-guide.md)
- [First install checklist](docs/first-install-checklist.md)
- [Operator guide](docs/operator-guide.md)

The Windows host bundle includes:

- a guided installer wizard
- a first-run validator
- a schema migrator for dry-run and applied schema upgrades
- a support-bundle collector for sanitized diagnostics

## Integration Model

Your application writes outbound messages to:

```text
sms_flow.Integration_OutboxMessage
```

The SMSFlow worker:

- validates and sends queued messages
- updates message state
- records delivery statuses
- stores inbound replies
- exposes health and attention views
- archives older operational data

Useful SQL surfaces include:

- `sms_flow.vw_Messages`
- `sms_flow.vw_Attention`
- `sms_flow.vw_InboundActivity`
- `sms_flow.vw_Health`
- `sms_flow_archive.vw_ArchivedMessages`

## Deployment Examples

- [Docker Compose with existing SQL Server](deploy/docker/docker-compose.existing-sql.yml)
- [Try SMSFlow SQL API in 10 minutes](deploy/demo/try-it-in-10-minutes/README.md)
- [Fully contained local demo notes](deploy/demo/README.md)
- [Kubernetes manifest](deploy/kubernetes/worker.yaml)
- [Helm chart](deploy/helm/smsflow-sql-api)
- [Azure Container Instances Bicep](deploy/azure-container-instances/aci-worker.bicep)

Container deployment examples use `YOUR_REGISTRY` as a placeholder. Build images from the Docker release bundle and push them to your own registry before deploying to Kubernetes, Helm, or Azure Container Instances.

## Release Validation

Run these checks before publishing or changing public examples:

```bash
npm run release:validate
npm run release:verify-github
npm run release:smoke-assets
npm run release:smoke-demo
```

`release:smoke-assets` expects the published ZIP files and checksum manifest under `artifacts/smoke/v0.3.0`.

`release:smoke-demo` downloads the Docker release bundle when it is not already present, builds the worker image locally, starts the 10-minute SQL Server demo, seeds simulated messages, and runs validation queries.

## Security

- Do not commit live API keys, SQL passwords, connection strings, certificates, or customer data.
- Use unique test messages when validating live sending.
- Use `Simulated` mode for load testing.
- Use a dedicated test database for trials and demos.

## Support Handoff

When raising a support request, include the package version, deployment model, sanitized worker logs, affected `ClientMessageId` values, and output from the health and queue summary procedures. Do not include SQL passwords, API keys, complete recipient lists, or message bodies containing personal information.

## License

See [LICENSE](LICENSE).
