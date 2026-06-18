# Linux Install Guide

This guide is for the Linux worker-host path.

## What gets installed

The extracted Linux release bundle contains these scripts:

- `Installers/Install-SMSFlowSqlIntegrationHost.sh`
- `Installers/Uninstall-SMSFlowSqlIntegrationHost.sh`

The install script installs:
- the SQL integration worker
- optionally, the management agent and bundled load driver

The desktop management app is not installed on Linux. It remains Windows-only.

## Prerequisites

- Run as `root` or through `sudo`.
- Ensure `dotnet` is available if you are using `--publish-from-source`.
- Ensure `python3` is available. The script uses it to write JSON config safely.
- Have the SQL connection string ready.
- If using `Live` portal mode, have the portal base URL and API key ready.
- If installing the management agent, have an agent URL and shared secret ready.

## Install the host

Basic install:

```bash
sudo bash ./Installers/Install-SMSFlowSqlIntegrationHost.sh
```

Worker plus optional management host tools:

```bash
sudo bash ./Installers/Install-SMSFlowSqlIntegrationHost.sh \
  --connection-string "Server=sql.example.local;Database=SmsFlow;User Id=smsflow;Password=replace-me;TrustServerCertificate=true" \
  --portal-mode Simulated \
  --install-management-host-tools \
  --agent-url "http://127.0.0.1:5842" \
  --agent-shared-secret "replace-me"
```

What the host script does:
- publishes from source when requested
- copies the worker into `/opt/sms-flow-sql-integration-v2/worker`
- optionally copies the management agent into `/opt/sms-flow-sql-integration-v2/management-agent`
- optionally copies the load driver into `/opt/sms-flow-sql-integration-v2/tools`
- writes local `appsettings.json` files into the installed directories
- creates or updates the `systemd` services
- starts the services unless `--skip-service-start` is passed

## Uninstall

Remove the Linux host install:

```bash
sudo bash ./Installers/Uninstall-SMSFlowSqlIntegrationHost.sh
```

Remove the Linux host install and also purge logs:

```bash
sudo bash ./Installers/Uninstall-SMSFlowSqlIntegrationHost.sh --purge-data
```

Optionally remove the dedicated service account as well:

```bash
sudo bash ./Installers/Uninstall-SMSFlowSqlIntegrationHost.sh --purge-data --remove-service-account
```

By default, uninstall removes `systemd` services and installed files but keeps the log directory unless `--purge-data` is used.

## Installed layout

- worker binaries: `/opt/sms-flow-sql-integration-v2/worker`
- optional agent binaries: `/opt/sms-flow-sql-integration-v2/management-agent`
- optional load driver: `/opt/sms-flow-sql-integration-v2/tools`
- worker config: `/opt/sms-flow-sql-integration-v2/worker/appsettings.json`
- optional agent config: `/opt/sms-flow-sql-integration-v2/management-agent/appsettings.json`
- logs: `/var/log/sms-flow-sql-integration-v2/...`

## Services

The Linux host install manages these `systemd` services:
- `sms-flow-sql-integration-v2`
- optional `sms-flow-sql-integration-v2-management-agent`

## Recommended next step

After install, continue with the [Operator guide](operator-guide.md).
