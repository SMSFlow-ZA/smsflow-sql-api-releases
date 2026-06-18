# smsflow-sql-api-releases Agent Instructions

This repository is the public release surface for SMSFlow SQL API client materials.

Do not add private SMSFlow source code here.

Allowed content:

- sanitized public documentation
- release notes
- checksums
- reviewed installer bundles or installer entry scripts
- sample SQL usage scripts
- Docker Compose, Kubernetes, Helm, and Azure deployment examples that contain no private implementation code

Forbidden content:

- worker or management source code
- internal contract package source code
- private Azure DevOps build configuration that exposes internal implementation details
- credentials, API keys, private URLs, customer data, or environment-specific secrets
- compiled artifacts that have not passed release review

Before adding a release artifact, verify that it was produced from the private Azure DevOps `smsflow-sql-api` source repository and that the release checklist in `docs/public-release-checklist.md` has been completed.
