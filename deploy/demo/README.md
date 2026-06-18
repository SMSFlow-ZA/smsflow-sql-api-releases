# Fully Contained Demo

This demo layout is for local evaluation only. It runs SQL Server and the SMSFlow SQL API worker in simulated mode.

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
