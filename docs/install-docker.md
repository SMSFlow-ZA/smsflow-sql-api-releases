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

The extracted Docker release bundle contains:

- worker Dockerfile
- optional management-agent Dockerfile
- Docker Compose files
- worker config sample
- agent config sample

This public repository also includes deployment examples:

- [Docker Compose with existing SQL Server](../deploy/docker/docker-compose.existing-sql.yml)
- [Fully contained local demo](../deploy/demo/README.md)
- [Kubernetes manifest](../deploy/kubernetes/worker.yaml)
- [Helm chart](../deploy/helm/smsflow-sql-api)
- [Azure Container Instances Bicep](../deploy/azure-container-instances/aci-worker.bicep)

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

From the extracted Docker release bundle:

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

After container deployment, continue with the [Operator guide](operator-guide.md).
