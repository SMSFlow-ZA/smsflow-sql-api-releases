# Release Quality Checklist

Use this checklist before publishing SMSFlow SQL API materials.

## Security Review

- No API keys, tokens, passwords, certificates, connection strings, or customer data are present.
- Example values use obvious placeholders.
- No environment-specific hostnames or non-public URLs are present.

## Artifact Review

- Release notes identify the version and supported platforms.
- Checksums are included for downloadable artifacts.
- Windows host bundles include the installer wizard, first-run validator, and support-bundle collector.
- Scripts have been reviewed for destructive commands and environment-specific assumptions.
- Public ZIP assets are uploaded by the approved release pipeline, not by ad-hoc browser upload.

## Documentation Review

- The README explains SMSFlow SQL API from a customer/developer point of view.
- Setup guides use paths that make sense from an extracted release bundle.
- Setup guides explain `Simulated` mode before live mode.
- Go-live steps warn users not to commit production credentials.

## Publishing Review

- GitHub release assets match the reviewed pipeline artifact.
- `CHECKSUMS-SHA256.txt` is attached to the GitHub release.
- The release page contains Windows, Linux, Docker, and Windows manager bundles.
- The public repository README links to the current GitHub release.
