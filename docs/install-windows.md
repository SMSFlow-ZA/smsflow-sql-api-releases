# Windows Install Guide

This guide is for the Windows worker-host path.

## What gets installed

The supported Windows scripts are:

- [Install-SMSFlowSqlIntegrationHost.ps1](../Installers/Install-SMSFlowSqlIntegrationHost.ps1)
- [Uninstall-SMSFlowSqlIntegrationHost.ps1](../Installers/Uninstall-SMSFlowSqlIntegrationHost.ps1)
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

## Install the host

Basic install:

```powershell
pwsh ./z_Integrations/SqlAppV2/Installers/Install-SMSFlowSqlIntegrationHost.ps1 -PublishFromSource
```

Worker plus optional management host tools:

```powershell
pwsh ./z_Integrations/SqlAppV2/Installers/Install-SMSFlowSqlIntegrationHost.ps1 `
  -PublishFromSource `
  -ConnectionString "Server=.;Database=SmsFlow;Trusted_Connection=True;TrustServerCertificate=True" `
  -PortalMode Simulated `
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
- starts the services unless `-SkipServiceStart` is passed

## Install the desktop manager

```powershell
pwsh ./z_Integrations/SqlAppV2/Installers/Install-SMSFlowSqlIntegrationManager.ps1 -PublishFromSource
```

This installs the desktop app into `%ProgramFiles%\SMSFlow\SqlIntegration Manager`.

## Uninstall

Remove the worker host installation:

```powershell
pwsh ./z_Integrations/SqlAppV2/Installers/Uninstall-SMSFlowSqlIntegrationHost.ps1
```

Remove the worker host installation and purge `%ProgramData%` config and logs as well:

```powershell
pwsh ./z_Integrations/SqlAppV2/Installers/Uninstall-SMSFlowSqlIntegrationHost.ps1 -PurgeData
```

Remove the desktop manager:

```powershell
pwsh ./z_Integrations/SqlAppV2/Installers/Uninstall-SMSFlowSqlIntegrationManager.ps1
```

By default, host uninstall removes services and binaries but keeps `%ProgramData%` config and logs unless `-PurgeData` is used.

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
