# Release Artifact Policy

SMSFlow release artifacts are published here to make installation, testing, and operation straightforward for customers and integration partners.

## Published Materials

This repository may contain:

- installation guides
- release notes
- checksums
- reviewed release bundles
- sample SQL scripts
- Docker Compose, Kubernetes, Helm, and Azure deployment examples

## Excluded Materials

This repository must not contain:

- credentials, API keys, certificates, connection strings, or customer data
- environment-specific hostnames or non-public URLs
- unreleased or unreviewed binaries
- source files that are not required for customer installation or examples

## Customer Safety Expectations

Before publishing a release:

- examples must use obvious placeholders
- downloadable files must have checksums
- install instructions must work from an extracted release bundle
- docs must explain simulated mode before live mode
- go-live guidance must warn against storing live credentials in source control
