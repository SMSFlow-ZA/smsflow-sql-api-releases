# Developer Guide

This guide is for engineers working on SQL Integration V2 in the repository.

## Main projects

- [sms_flow_portal.sql_integration.v2.App](../src/Runtime/sms_flow_portal.sql_integration.v2.App)
  - the real worker host
- [sms_flow_portal.sql_integration.v2.Management.Agent](../src/Management/sms_flow_portal.sql_integration.v2.Management.Agent)
  - optional host-side diagnostics and load-test agent
- [sms_flow_portal.sql_integration.v2.Management](../src/Management/sms_flow_portal.sql_integration.v2.Management)
  - Windows desktop operator console
- [sms_flow_portal.sql_integration.v2.LoadTest](../src/Runtime/sms_flow_portal.sql_integration.v2.LoadTest)
  - standalone queue injection tool
- [sql_integration_v2.sql](../src/Runtime/sms_flow_portal.sql_integration.v2.App/Scripts/sql_integration_v2.sql)
  - SQL schema, views, procedures, archiving, and dashboard surfaces

## Local development model

Typical local flow:
1. Apply the SQL script to a test database.
2. Run the worker against that database.
3. Prefer `PortalMode = Simulated` while developing worker, agent, UI, or load-test behavior.
4. Run the management app separately if you are working on operator workflows.

## Configuration behavior

Worker:
- on Windows packaged installs, prefers `%ProgramData%` config and falls back to local `appsettings.json`
- on Linux/manual installs, the supported script writes local installed `appsettings.json`
- in Docker, prefers `/smsflow/config/worker/appsettings.json`

Agent:
- follows the same pattern as the worker
- path settings can be blank in packaged installs because the installed-layout defaults are inferred automatically
- in Docker, defaults resolve under `/smsflow`

## Safety rules

- Use `Simulated` mode for load testing and most development.
- The management agent intentionally refuses to start a load test unless `PortalMode = Simulated`.
- Keep test and client environments isolated. Do not point the load driver at a live worker/database combination.

## Useful areas to inspect

- worker host and loops:
  - [Program.cs](../src/Runtime/sms_flow_portal.sql_integration.v2.App/Program.cs)
  - [SqlIntegrationSendWorker.cs](../src/Runtime/sms_flow_portal.sql_integration.v2.App/SqlIntegrationSendWorker.cs)
  - [SqlIntegrationReportingWorker.cs](../src/Runtime/sms_flow_portal.sql_integration.v2.App/SqlIntegrationReportingWorker.cs)
  - [SqlIntegrationArchiveWorker.cs](../src/Runtime/sms_flow_portal.sql_integration.v2.App/SqlIntegrationArchiveWorker.cs)
- management agent API and orchestration:
  - [Program.cs](../src/Management/sms_flow_portal.sql_integration.v2.Management.Agent/Program.cs)
  - [Services.cs](../src/Management/sms_flow_portal.sql_integration.v2.Management.Agent/Services.cs)
- management UI:
  - [MainWindow.xaml](../src/Management/sms_flow_portal.sql_integration.v2.Management/MainWindow.xaml)
  - [ViewModels.cs](../src/Management/sms_flow_portal.sql_integration.v2.Management/ViewModels.cs)
- load driver:
  - [Program.cs](../src/Runtime/sms_flow_portal.sql_integration.v2.LoadTest/Program.cs)

## Docker assets

- compose example: [docker-compose.yml](../docker/docker-compose.yml)
- worker config sample: [appsettings.json](../docker/config/worker/appsettings.json)
- agent config sample: [appsettings.json](../docker/config/agent/appsettings.json)

## Tests and verification

When changing the suite, prefer verifying the relevant app directly and then running the nearest tests. Useful checks include:
- worker app build
- management agent build
- management app build
- load-test build
- management tests
- worker tests

## Install docs

For client-facing installation, use:
- [Windows install](INSTALL-Windows.md)
- [Linux install](INSTALL-Linux.md)
- [Docker install](INSTALL-Docker.md)

## Release packaging

To build handoff-ready release bundles, run:

```powershell
pwsh ./z_Integrations/SqlAppV2/Installers/Package-SMSFlowSqlIntegrationRelease.ps1
```

By default the release packager uses a temporary public-only NuGet config for SqlAppV2, so unrelated private feeds are not queried. If you intentionally want to use the repo-level NuGet.config instead, rerun with:

```powershell
pwsh ./z_Integrations/SqlAppV2/Installers/Package-SMSFlowSqlIntegrationRelease.ps1 -UseRepoNuGetConfig -Interactive
```