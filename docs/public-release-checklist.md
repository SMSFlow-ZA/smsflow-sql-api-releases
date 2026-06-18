# Public Release Checklist

Complete this checklist before publishing SQL API materials to GitHub.

## Source Boundary

- Worker source code is not included.
- Management source code is not included.
- Internal contracts package source code is not included.
- Private Azure DevOps implementation details are not included.

## Secret And Data Review

- No API keys, tokens, passwords, certificates, or connection strings are present.
- No customer data or customer identifiers are present.
- No private hostnames, internal URLs, or environment-specific values are present.
- Example values use obvious placeholders.

## Artifact Review

- Installer bundles were produced from the private Azure DevOps `smsflow-sql-api` source repository.
- Release notes identify the version and supported platforms.
- Checksums are included for downloadable artifacts.
- Windows artifacts are signed where signing is required.
- Scripts have been reviewed for destructive commands and environment-specific assumptions.

## Documentation Review

- Public docs use customer-facing wording: "SMSFlow SQL API".
- Internal version labels are only used where they are literal configuration keys, service names, or file names.
- Setup guides explain simulated mode before live mode.
- Go-live steps warn users not to use test credentials in production.
