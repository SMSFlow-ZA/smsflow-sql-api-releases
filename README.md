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

1. Download the latest release from [GitHub Releases](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases).
2. Choose your install path:
   - [Windows install guide](docs/install-windows.md)
   - [Linux install guide](docs/install-linux.md)
   - [Docker install guide](docs/install-docker.md)
3. Apply the SQL schema to your integration database.
4. Start in `Simulated` mode and send a test message.
5. Switch to live credentials only after the simulated flow is working.

## Latest Release

Current release: `0.1.0`

- [Release notes and checksums](releases/0.1.0/README.md)
- [SQL schema script](examples/sql/sql_integration.sql)
- [Client implementation guide](docs/client-implementation-guide.md)
- [Client setup guide](docs/client-setup-guide.md)
- [Operator guide](docs/operator-guide.md)

The Windows host bundle includes:

- a guided installer wizard
- a first-run validator
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
- [Fully contained local demo](deploy/demo/README.md)
- [Kubernetes manifest](deploy/kubernetes/worker.yaml)
- [Helm chart](deploy/helm/smsflow-sql-api)
- [Azure Container Instances Bicep](deploy/azure-container-instances/aci-worker.bicep)

Container deployment examples use `YOUR_REGISTRY` as a placeholder. Build images from the Docker release bundle and push them to your own registry before deploying to Kubernetes, Helm, or Azure Container Instances.

## Security

- Do not commit live API keys, SQL passwords, connection strings, certificates, or customer data.
- Use unique test messages when validating live sending.
- Use `Simulated` mode for load testing.
- Use a dedicated test database for trials and demos.

## License

See [LICENSE](LICENSE).
