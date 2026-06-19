# SMSFlow SQL API 0.3.0

SMSFlow SQL API 0.3.0 improves schema upgrade safety, package validation, and customer-facing install confidence for SQL Server based SMS integrations.

## Download

Download these assets from the [GitHub release](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/tag/v0.3.0):

| Asset | Use |
| --- | --- |
| [`smsflow-sql-api-0.3.0-windows-host.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-windows-host.zip) | Windows worker service, guided installer, schema tools, validator, and support tools. |
| [`smsflow-sql-api-0.3.0-windows-manager.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-windows-manager.zip) | Optional Windows desktop manager for operations and support users. |
| [`smsflow-sql-api-0.3.0-linux-host.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-linux-host.zip) | Linux worker service and supporting command-line tools. |
| [`smsflow-sql-api-0.3.0-docker-host.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-docker-host.zip) | Docker, Kubernetes, Helm, and Azure Container Instances deployment assets. |
| [`CHECKSUMS-SHA256.txt`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/CHECKSUMS-SHA256.txt) | SHA-256 checksums for the ZIP assets. |

## What's New

- Added a schema migrator for dry-run schema planning and controlled schema application.
- Added package validation for generated Windows, Linux, and Docker release bundles.
- First-run validator output now includes machine-readable error codes and next-step guidance.
- Release bundles include `schema-manifest.json` beside the SQL schema script.
- Docker release bundle includes a schema migrator payload for container-based deployment workflows.

## Schema Version

The SQL schema version remains `0.2.0`. The `0.3.0` release improves installation, validation, and upgrade tooling around that schema.

## Recommended Install Path

For Windows installations, start with the guided installer:

```text
Installers/artifacts/publish/InstallerWizard/sms_flow_portal.sql_integration.v2.WindowsInstaller.exe
```

For schema upgrade planning, run the schema migrator first without `--apply`, then rerun with `--apply` after reviewing the plan.

```powershell
.\Installers\artifacts\publish\Support\sms_flow_portal.sql_integration.v2.SchemaMigrator.exe `
  --connection-string "Server=.;Database=SmsFlow;Trusted_Connection=True;TrustServerCertificate=True"
```

## Checksums

```text
db343101a3eff9e87878835e0374880fdc3448ed773dce7992d056295b6fd6bc  smsflow-sql-api-0.3.0-docker-host.zip
f066a8b246db7867bf1af99ddd8c19dec58ee78f56ee14a91a9bc210e4d61375  smsflow-sql-api-0.3.0-linux-host.zip
db0677fba8b8872f7197e2f77da6f1a6f644129f94b82e36799ff9180bde55f3  smsflow-sql-api-0.3.0-windows-host.zip
5c18174b412d5adda9d00d34b7d055ce057ac229593828f7be574cf1146b8036  smsflow-sql-api-0.3.0-windows-manager.zip
```

Windows verification example:

```powershell
Get-FileHash .\smsflow-sql-api-0.3.0-windows-host.zip -Algorithm SHA256
```

Linux or macOS verification example:

```bash
sha256sum smsflow-sql-api-0.3.0-linux-host.zip
```

## Safety Notes

- Start in `Simulated` mode.
- Back up the target database before applying schema changes.
- Use the schema migrator dry run before `--apply`.
- Use a dedicated test database for first validation.
- Use unique test message text when validating live sending.
- Do not put live API keys or production SQL passwords into source control.
