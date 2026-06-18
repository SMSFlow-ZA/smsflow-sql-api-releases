# SMSFlow SQL API 0.1.0

Initial public release of SMSFlow SQL API client installation materials.

## Release Assets

Download these assets from the GitHub release:

- `smsflow-sql-api-0.1.0-windows-host.zip`
- `smsflow-sql-api-0.1.0-windows-manager.zip`
- `smsflow-sql-api-0.1.0-linux-host.zip`
- `smsflow-sql-api-0.1.0-docker-host.zip`
- `CHECKSUMS-SHA256.txt`

## Included Capabilities

- Windows worker host bundle
- Windows desktop manager bundle
- Linux worker host bundle
- Docker host bundle
- SQL schema script
- Windows, Linux, and Docker install guides
- Kubernetes, Helm, and Azure Container Instances deployment examples
- Fully contained demo layout for SQL Server plus SQL API worker testing

## Checksums

```text
a4562c3e56190c17fa9ff99d3a03d15959dad59212b3729f1b3166e0d92ba898  smsflow-sql-api-0.1.0-docker-host.zip
15f47d8717d64bf6455060528afab5cfcf6e5c3d42a7084280067abc9646d150  smsflow-sql-api-0.1.0-linux-host.zip
4fdbfc663a04b00d8528371c38802405e547f0e07f80c5868c8d914472b448d5  smsflow-sql-api-0.1.0-windows-host.zip
04d5a643cff0f27eb82aeda9e9e9e52718099c9b57a0a990224da811f250008a  smsflow-sql-api-0.1.0-windows-manager.zip
```

## Safety Notes

- Start in `Simulated` mode.
- Do not put live API keys or production SQL passwords into source control.
- Use a controlled single-message production test before broad go-live.

## Container Images

The Docker host bundle includes Dockerfiles and release payloads for the worker and management agent. Build those images from the Docker bundle and push them to your own registry, then replace `YOUR_REGISTRY` in the Kubernetes, Helm, and Azure Container Instances examples.
