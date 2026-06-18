# SMSFlow SQL API 0.2.0

SMSFlow SQL API 0.2.0 improves installation, validation, and support workflows for customer-hosted SQL API deployments.

## Download

Download these assets from the GitHub release:

- `smsflow-sql-api-0.2.0-windows-host.zip`
- `smsflow-sql-api-0.2.0-windows-manager.zip`
- `smsflow-sql-api-0.2.0-linux-host.zip`
- `smsflow-sql-api-0.2.0-docker-host.zip`
- `CHECKSUMS-SHA256.txt`

## What's New

- Windows host bundle now includes a guided installer wizard.
- Windows and Linux host bundles include a first-run validator.
- The Windows host installer can apply or upgrade the bundled SQL schema.
- The SQL schema now records a version in `sms_flow.Integration_SchemaVersion`.
- `sms_flow.SchemaVersion_Get` exposes the active schema version.
- Health outputs include `SchemaVersion`.
- Windows host bundle includes a sanitized support-bundle collector.
- Release bundles include generated SHA-256 checksums.

## Recommended Install Path

For Windows installations, start with the guided installer:

```text
Installers/artifacts/publish/InstallerWizard/sms_flow_portal.sql_integration.v2.WindowsInstaller.exe
```

For scripted Windows installs:

```powershell
pwsh .\Installers\Install-SMSFlowSqlIntegrationHost.ps1 -ApplyDatabaseSchema
```

For Linux installs:

```bash
sudo bash ./Installers/Install-SMSFlowSqlIntegrationHost.sh
```

For Docker, start from the Docker host bundle and follow:

- [Docker install guide](../../docs/install-docker.md)

## Checksums

```text
49c9cb9c9209df1ecfa48838b84e13940f9b0b585fc90c08551aa3b2f20dde7b  smsflow-sql-api-0.2.0-docker-host.zip
fbfe3c0dc27ac5a4f07b98f474ddb6b6d0026eaeb0c1b88ffa569c4f7e44cd39  smsflow-sql-api-0.2.0-linux-host.zip
8cc7dadc0a2710cbbc68bcd469875002bcd3e9828f88efa1005e9bf05b3935bf  smsflow-sql-api-0.2.0-windows-host.zip
01cb9af1c3a84a41754c954a5253fcbcad264fb23ba3f2969a7ade02361fd208  smsflow-sql-api-0.2.0-windows-manager.zip
```

## Safety Notes

- Start in `Simulated` mode.
- Use a dedicated test database for first validation.
- Use unique test message text when validating live sending.
- Do not put live API keys or production SQL passwords into source control.
- Run a controlled single-message production test before broad go-live.
