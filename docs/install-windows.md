# Windows Install Guide

This guide is for the Windows worker-host path.

## What gets installed

The supported Windows scripts are:

- [Install-SMSFlowSqlIntegrationHost.ps1](../Installers/Install-SMSFlowSqlIntegrationHost.ps1)
- [Uninstall-SMSFlowSqlIntegrationHost.ps1](../Installers/Uninstall-SMSFlowSqlIntegrationHost.ps1)
- [Collect-SMSFlowSqlIntegrationSupportBundle.ps1](../Installers/Collect-SMSFlowSqlIntegrationSupportBundle.ps1)
- [Install-SMSFlowSqlIntegrationManager.ps1](../Installers/Install-SMSFlowSqlIntegrationManager.ps1)
- [Uninstall-SMSFlowSqlIntegrationManager.ps1](../Installers/Uninstall-SMSFlowSqlIntegrationManager.ps1)

The host install script installs:
- the SQL integration worker
- optionally, the management agent and bundled load driver

The manager install script installs:
- the Windows desktop management app

## Prerequisites

- Run from an elevated PowerShell session.
- Ensure the target machine can run the published .NET binaries.
- Have the SQL connection string ready.
- If using `Live` portal mode, have the portal base URL and API key ready.
- If installing the management agent, have an agent URL and shared secret ready.

## Guided host install

The Windows host release bundle includes a guided installer wizard:

```text
Installers/artifacts/publish/InstallerWizard/sms_flow_portal.sql_integration.v2.WindowsInstaller.exe
```

Use the wizard when an installer wants a form-based setup flow.

The wizard can:

- collect SQL, portal, and optional management-agent settings
- apply or upgrade the bundled SQL schema
- run first-run validation
- start the existing elevated PowerShell installer

## Script host install

Basic install:

```powershell
pwsh .\Installers\Install-SMSFlowSqlIntegrationHost.ps1
```

Worker plus optional management host tools:

```powershell
pwsh .\Installers\Install-SMSFlowSqlIntegrationHost.ps1 `
  -ConnectionString "Server=.;Database=SmsFlow;Trusted_Connection=True;TrustServerCertificate=True" `
  -PortalMode Simulated `
  -ApplyDatabaseSchema `
  -InstallManagementHostTools `
  -AgentUrl "http://127.0.0.1:5842" `
  -AgentSharedSecret "replace-me"
```

What the host script does:
- publishes from source when requested
- copies the worker into `%ProgramFiles%\SMSFlow\SqlIntegration\Worker`
- optionally copies the management agent into `%ProgramFiles%\SMSFlow\SqlIntegration\ManagementAgent`
- optionally copies the load driver into `%ProgramFiles%\SMSFlow\SqlIntegration\Tools`
- runs the host setup utility to write `%ProgramData%` config
- creates or updates the Windows services
- optionally applies or upgrades the SQL schema when `-ApplyDatabaseSchema` is passed
- runs first-run validation unless `-SkipValidation` is passed
- starts the services unless `-SkipServiceStart` is passed

Use `-SkipValidation` only for a staged install where SQL access is intentionally unavailable.

## First-run validation

The host bundle includes:

```text
Installers/artifacts/publish/Support/sms_flow_portal.sql_integration.v2.FirstRunValidator.exe
```

Run it directly when you need to validate SQL access, schema version, required objects, config files, and Windows service registration:

```powershell
.\Installers\artifacts\publish\Support\sms_flow_portal.sql_integration.v2.FirstRunValidator.exe `
  --connection-string "Server=.;Database=SmsFlow;Trusted_Connection=True;TrustServerCertificate=True"
```

To apply the bundled schema first:

```powershell
.\Installers\artifacts\publish\Support\sms_flow_portal.sql_integration.v2.FirstRunValidator.exe `
  --connection-string "Server=.;Database=SmsFlow;Trusted_Connection=True;TrustServerCertificate=True" `
  --apply-schema-script ".\Installers\artifacts\publish\Worker\Scripts\sql_integration_v2.sql"
```

## Install the desktop manager

```powershell
pwsh .\Installers\Install-SMSFlowSqlIntegrationManager.ps1
```

This installs the desktop app into `%ProgramFiles%\SMSFlow\SqlIntegration Manager`.

## Uninstall

Remove the worker host installation:

```powershell
pwsh .\Installers\Uninstall-SMSFlowSqlIntegrationHost.ps1
```

Remove the worker host installation and purge `%ProgramData%` config and logs as well:

```powershell
pwsh .\Installers\Uninstall-SMSFlowSqlIntegrationHost.ps1 -PurgeData
```

Remove the desktop manager:

```powershell
pwsh .\Installers\Uninstall-SMSFlowSqlIntegrationManager.ps1
```

By default, host uninstall removes services and binaries but keeps `%ProgramData%` config and logs unless `-PurgeData` is used.

## Support bundle

To collect sanitized logs, service state, install summary, and redacted config for SMSFlow support:

```powershell
pwsh .\Installers\Collect-SMSFlowSqlIntegrationSupportBundle.ps1
```

Use `-IncludeEventLogs` when support asks for recent Windows application events.

## Installed layout

- worker binaries: `%ProgramFiles%\SMSFlow\SqlIntegration\Worker`
- optional agent binaries: `%ProgramFiles%\SMSFlow\SqlIntegration\ManagementAgent`
- optional load driver: `%ProgramFiles%\SMSFlow\SqlIntegration\Tools`
- worker config: `%ProgramData%\SMSFlow\SqlIntegration\config\worker\appsettings.json`
- agent config: `%ProgramData%\SMSFlow\SqlIntegration\config\agent\appsettings.json`
- logs: `%ProgramData%\SMSFlow\SqlIntegration\logs\...`

## Services

The Windows host install manages these services:
- `SMSFlowSqlIntegrationV2`
- optional `SMSFlowSqlIntegrationV2ManagementAgent`

## Recommended next step

After install, continue with the [Operator guide](OPERATOR.md).
