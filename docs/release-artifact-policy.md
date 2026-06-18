# Release Artifact Policy

The public GitHub repository exists to make client installation and operation easier without exposing private SMSFlow implementation code.

## Public Repository

The public repository may contain:

- install guides
- release notes
- checksums
- reviewed release bundles
- sample SQL scripts for client usage
- deployment examples that do not contain private source code

## Private Azure DevOps Repository

The private Azure DevOps repository remains the source of truth for:

- worker source code
- management application source code
- test projects
- build pipelines
- internal contracts
- package publishing to Azure Artifacts

## Internal Contracts

Internal SMSFlow packages and implementation contracts are not part of this public release repository.
