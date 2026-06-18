# Docker Install Guide

This guide is for running the host-side SQL Integration V2 components in containers.

## What is supported

Supported in Docker:
- worker container
- optional management agent container
- bundled load driver inside the management agent image

Not supported in Docker:
- the Windows desktop management app

## Main files

- [worker Dockerfile](../src/Runtime/sms_flow_portal.sql_integration.v2.App/Dockerfile)
- [agent Dockerfile](../src/Management/sms_flow_portal.sql_integration.v2.Management.Agent/Dockerfile)
- [compose example](../docker/docker-compose.yml)
- [worker config sample](../docker/config/worker/appsettings.json)
- [agent config sample](../docker/config/agent/appsettings.json)

## Recommended model

Use bind-mounted config files and container-managed log volumes.

The worker reads its config from:
- `/smsflow/config/worker/appsettings.json`

The agent reads its config from:
- `/smsflow/config/agent/appsettings.json`

Logs go to:
- `/smsflow/logs/worker`
- `/smsflow/logs/agent`
- `/smsflow/Tools/logs`

## Start the worker only

From `z_Integrations/SqlAppV2/docker`:

```bash
docker compose up --build -d worker
```

## Start the worker and management agent

```bash
docker compose --profile management up --build -d
```

The agent will listen on port `5842` by default.

## Operator notes

- keep the worker config in `PortalMode = Simulated` when you want safe load testing
- the agent still refuses to start a load test unless the worker config says `Simulated`
- mount the same worker config into the agent so diagnostics and load-test safety checks read the real worker settings
- use the Windows desktop management app remotely against the agent if you want the full operator console

## Recommended next step

After container deployment, continue with the [Operator guide](OPERATOR.md).
