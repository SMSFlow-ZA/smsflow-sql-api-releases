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

## Package Boundary

`SmsFlow.SqlIntegration.Contracts` is an internal NuGet package for private SMSFlow repositories. It must be published only to the private SigniFlow Azure Artifacts feed, not to public NuGet and not to this repository.
