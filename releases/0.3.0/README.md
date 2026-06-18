# SMSFlow SQL API 0.3.0

SMSFlow SQL API 0.3.0 improves schema upgrade safety, package validation, and customer-facing install confidence for SQL Server based SMS integrations.

## Download

Download these assets from the GitHub release:

- `smsflow-sql-api-0.3.0-windows-host.zip`
- `smsflow-sql-api-0.3.0-windows-manager.zip`
- `smsflow-sql-api-0.3.0-linux-host.zip`
- `smsflow-sql-api-0.3.0-docker-host.zip`
- `CHECKSUMS-SHA256.txt`

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
0dea79bba8108a7bc2db19171c1f0b28426e89071278713b90e6772e273a98db  smsflow-sql-api-0.3.0-docker-host.zip
dd04e466bc342a51c08bd19bf8054ff3ea107126148622921914baeeab06c5e6  smsflow-sql-api-0.3.0-linux-host.zip
89a0360812c02e1f9f4259ea3ad077994e2c276a1c5f4efd73c67c9f601ed431  smsflow-sql-api-0.3.0-windows-host.zip
582bd07dec0e5601f32835c0b391f78e070d2d131930f5fa51b588187e2821a3  smsflow-sql-api-0.3.0-windows-manager.zip
```

## Safety Notes

- Start in `Simulated` mode.
- Back up the target database before applying schema changes.
- Use the schema migrator dry run before `--apply`.
- Use a dedicated test database for first validation.
- Use unique test message text when validating live sending.
- Do not put live API keys or production SQL passwords into source control.
