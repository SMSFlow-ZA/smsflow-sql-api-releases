# SMSFlow SQL API First Install Checklist

Use this checklist for a new customer installation before switching the worker to live sending.

## 1. Choose the package

| Environment | Download |
| --- | --- |
| Windows worker service | `smsflow-sql-api-0.3.0-windows-host.zip` |
| Windows desktop manager | `smsflow-sql-api-0.3.0-windows-manager.zip` |
| Linux worker service | `smsflow-sql-api-0.3.0-linux-host.zip` |
| Docker, Kubernetes, Helm, or Azure Container Instances | `smsflow-sql-api-0.3.0-docker-host.zip` |

Download packages from the [SMSFlow SQL API 0.3.0 release](https://github.com/SMSFlow-ZA/smsflow-sql-api-releases/releases/tag/v0.3.0).

## 2. Verify the download

Download `CHECKSUMS-SHA256.txt` from the same release page and confirm the ZIP file hash before installation.

Windows:

```powershell
Get-FileHash .\smsflow-sql-api-0.3.0-windows-host.zip -Algorithm SHA256
```

Linux:

```bash
sha256sum smsflow-sql-api-0.3.0-linux-host.zip
```

## 3. Prepare SQL Server

Confirm that you have:

- a dedicated database or approved existing database
- permission to run the supplied SQL schema script
- a worker service account or SQL login
- an application user that can insert outbound messages
- a read user for reporting or support access

Use least-privilege roles:

| Role | Grant to |
| --- | --- |
| `sms_flow_enqueue` | Application user that queues SMS messages. |
| `sms_flow_readonly` | Support users, reporting users, and dashboards. |
| `sms_flow_runtime` | Worker service account only. |

## 4. Install in simulated mode

Keep the worker in `Simulated` mode for first validation.

Do not add live API keys until:

- the schema has been applied
- the worker can connect to SQL
- one test message can be queued
- message state moves away from `Queued`
- health and troubleshooting queries return expected results

## 5. Run validation

Use the first-run validator included in the Windows host bundle where available.

Also run these SQL checks:

```sql
EXEC sms_flow.SchemaVersion_Get;
EXEC sms_flow.Health_Get;
EXEC sms_flow.Queue_Summary_Get;
```

For package `0.3.0`, the SQL schema version should report `0.2.0`.

## 6. Queue the first test message

Use a unique `ClientMessageId`.

```sql
INSERT INTO sms_flow.Integration_OutboxMessage
(
    ClientMessageId,
    ReferenceNumber,
    Destination,
    Body,
    CostCentre,
    Priority,
    RequestedSendUtc
)
VALUES
(
    CONCAT('first-install-', CONVERT(varchar(36), NEWID())),
    'FIRST-INSTALL',
    '27820000000',
    CONCAT('SMSFlow SQL API simulated install test ', CONVERT(varchar(36), NEWID())),
    'InstallTest',
    0,
    SYSUTCDATETIME()
);
```

Then check recent messages:

```sql
SELECT TOP (20)
    ClientMessageId,
    Destination,
    State,
    AttemptCount,
    LastErrorCode,
    LastErrorMessage,
    CreatedUtc,
    UpdatedUtc
FROM sms_flow.vw_Messages
ORDER BY CreatedUtc DESC;
```

## 7. Go live carefully

Before switching to `Live` mode:

- confirm the SMSFlow account is active
- confirm the API key is valid
- confirm outbound HTTPS access from the worker host
- confirm the production SQL connection string
- confirm support users know where logs and health checks are
- back up the target database before applying schema changes

When sending a live test SMS, use a controlled recipient and unique body text. Duplicate message protection can block identical messages sent to the same number in a short period.

## 8. Support handoff

Record these details for support:

- package version
- deployment model
- SQL schema version
- worker service account type
- log folder path
- first successful `ClientMessageId`
- any known network or firewall restrictions

Do not record SQL passwords, API keys, full recipient lists, or message bodies containing personal information.
