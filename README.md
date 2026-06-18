# SMSFlow SQL API Releases

This repository is the public release home for SMSFlow SQL API client materials.

It is intentionally separate from the private Azure DevOps source repository. The worker source code, management source code, tests, and internal contract packages are not open source and must not be committed here.

## What Belongs Here

- Public installation guides
- Public release notes
- Checksums for release artifacts
- Reviewed installer bundles
- Sample SQL usage scripts
- Deployment examples for Windows, Linux, Docker, Kubernetes, Helm, and Azure

## What Does Not Belong Here

- Worker or management application source code
- Internal DTO or contract package source code
- Private Azure DevOps implementation details
- Credentials, API keys, customer data, private URLs, or environment-specific secrets

## Release Flow

1. Build and test the private source in Azure DevOps.
2. Produce reviewed release artifacts from the private `smsflow-sql-api` repository.
3. Run the public release checklist in `docs/public-release-checklist.md`.
4. Publish only sanitized client-facing material here.
5. Create a GitHub release with notes and checksums.

## Latest Release

Current release: `0.1.0`

Start here:

- [Release notes and checksums](releases/0.1.0/README.md)
- [Windows install guide](docs/install-windows.md)
- [Linux install guide](docs/install-linux.md)
- [Docker install guide](docs/install-docker.md)
- [Client implementation guide](docs/client-implementation-guide.md)
- [SQL schema script](examples/sql/sql_integration.sql)

Deployment examples:

- [Docker Compose with existing SQL Server](deploy/docker/docker-compose.existing-sql.yml)
- [Fully contained local demo](deploy/demo/README.md)
- [Kubernetes manifest](deploy/kubernetes/worker.yaml)
- [Helm chart](deploy/helm/smsflow-sql-api)
- [Azure Container Instances Bicep](deploy/azure-container-instances/aci-worker.bicep)

Container deployment examples use `YOUR_REGISTRY` as a placeholder. Build images from the Docker release bundle and push them to your own registry before deploying to Kubernetes, Helm, or Azure Container Instances.

## Source Boundary

This repository contains public release materials only. The SMSFlow SQL API implementation source remains private.
