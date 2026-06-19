# Try SMSFlow SQL API in 10 Minutes

This demo starts SQL Server and the SMSFlow SQL API worker in `Simulated` mode. It is for local evaluation only.

The demo does not send live SMS traffic and does not require an SMSFlow API key.

## What You Need

- Docker Desktop or Docker Engine with Docker Compose.
- The public `smsflow-sql-api-0.3.0-docker-host.zip` release bundle.
- A locally built worker image tagged `smsflow-sql-api-worker:0.3.0`.

## 1. Build the Worker Image

Download and extract [`smsflow-sql-api-0.3.0-docker-host.zip`](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/download/v0.3.0/smsflow-sql-api-0.3.0-docker-host.zip).

From the extracted Docker bundle, build the worker image using the Dockerfile included in the package:

```bash
docker build -t smsflow-sql-api-worker:0.3.0 .
```

The Docker bundle places the worker image files in the `worker` folder, so this command is normally run from that folder.

For a fully automated smoke test from this repository, run:

```bash
npm run release:smoke-demo
```

## 2. Start SQL Server and Apply the Schema

From this demo folder:

```bash
docker compose up -d sqlserver
docker compose run --rm schema
```

The schema step:

- creates the `SmsFlowDemo` database
- applies the public SQL API schema
- verifies the schema version

For package `0.3.0`, the SQL schema version should report `0.2.0`.

## 3. Start the Worker

```bash
docker compose up -d worker
```

The worker reads `config/worker/appsettings.json`, connects to `SmsFlowDemo`, and runs in `Simulated` mode.

## 4. Queue Sample Messages

```bash
docker compose run --rm seed
```

This inserts one single-message example and one small bulk batch.

## 5. Validate the Demo

```bash
docker compose run --rm validate
```

Use this command more than once if the worker has not processed the rows yet.

The validation step shows:

- queue summary
- recent messages
- health snapshot
- inbound status and reply activity
- attention/failure rows

For automated validation, the repository smoke test also runs an assertion that seeded demo messages are processed and are no longer left in `Queued`.

## 6. View Logs

```bash
docker compose logs -f worker
```

## 7. Stop the Demo

```bash
docker compose down
```

To remove the SQL Server data volume as well:

```bash
docker compose down -v
```

## Safety Notes

- This demo password is for local evaluation only.
- Do not reuse the demo SQL password in production.
- Do not switch this demo to `Live` mode.
- Use a dedicated SQL Server and production-grade secrets for real deployments.
