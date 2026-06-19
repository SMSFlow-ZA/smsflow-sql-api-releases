# Demo Options

Use the [try it in 10 minutes demo](try-it-in-10-minutes/README.md) for the recommended local evaluation path.

The older compose file in this folder remains as a minimal reference layout for teams that already have their own schema apply and seed process.

## Steps

1. Start SQL Server:

```bash
docker compose -f docker-compose.full-demo.yml up -d sqlserver
```

2. Apply `examples/sql/sql_integration.sql` to the demo database.

3. Review `config/worker/appsettings.json` and keep `PortalMode` set to `Simulated`.

4. Start the worker:

```bash
docker compose -f docker-compose.full-demo.yml up -d worker
```

5. Insert a sample row into `sms_flow.Integration_OutboxMessage` and read progress from `sms_flow.vw_InboundActivity`.

Do not use the demo SQL password or simulated configuration in production.
