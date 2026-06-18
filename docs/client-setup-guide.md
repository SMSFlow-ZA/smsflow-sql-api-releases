# SMSFlow SQL API: A Step-by-Step Client Setup Guide

This guide shows you how to install, configure, test, and verify SMSFlow SQL API from start to finish.

It is written for client engineers and support teams who want a practical guide they can follow line by line.

## What this integration does

SMSFlow SQL API lets your application send SMS messages by writing rows into a SQL Server table.

Your application does not need to call the SMS portal directly.

Instead, the flow is:

1. Your application inserts a message into the SQL outbox table.
2. The SQL API worker reads the message.
3. The worker sends the message to the portal.
4. The worker writes delivery statuses and replies back into SQL.
5. Your application reads those results from SQL.

## What gets installed

There are three main parts:

- `Worker`
  - the actual background service that processes messages
- `Management Agent` (optional)
  - a local diagnostics and load-test API
- `Manager` (optional, Windows only)
  - a desktop UI for operators and support users

For message processing, the **worker** is the important part. The manager is optional.

## What you need before you start

Make sure you have:

- a SQL Server database
- the SMSFlow SQL API host package
- the SQL schema script
- PowerShell access on the Windows host
- administrator rights on the Windows host
- a SQL login or Windows-auth plan for the worker service

For testing, use:

- `PortalMode = Simulated`

That lets you test safely without sending real live traffic.

## Files you should give the client

For a Windows client, the normal handoff is:

- `windows-host.zip`
- `sql_integration_v2.sql`
- installation guide
- optional `windows-manager.zip` if they want the desktop operator app

## Step 1: Run the SQL script

Before the worker can do anything, the SQL objects must exist.

Run `sql_integration_v2.sql` against the target database.

This creates:

- `sms_flow.Integration_OutboxMessage`
- `sms_flow.Integration_InboundStatus`
- `sms_flow.Integration_InboundReply`
- `sms_flow.Integration_RuntimeState`
- `sms_flow.Integration_OperationalEvent`
- archive tables
- helper procedures
- helper views
- database roles

### What to verify after the script runs

Run:

```sql
SELECT name, type_desc
FROM sys.objects
WHERE name IN
(
    'Integration_OutboxMessage',
    'Integration_InboundStatus',
    'Integration_InboundReply',
    'Dashboard_Snapshot_Get',
    'Message_GetByClientMessageId'
)
ORDER BY name;
```

If those objects exist, the SQL side is ready.

## Step 2: Install the worker on Windows

Extract the Windows host package to a folder on the target server.

Then open **PowerShell as Administrator**.

Go to the extracted package folder and run:

```powershell
pwsh .\Installers\Install-SMSFlowSqlIntegrationHost.ps1 `
  -ConnectionString "Server=YOURSERVER;Database=YOURDATABASE;Integrated Security=True;Encrypt=True;TrustServerCertificate=True;Command Timeout=30" `
  -PortalMode Simulated
```

If PowerShell 7 is not installed, use Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\Installers\Install-SMSFlowSqlIntegrationHost.ps1 `
  -ConnectionString "Server=YOURSERVER;Database=YOURDATABASE;Integrated Security=True;Encrypt=True;TrustServerCertificate=True;Command Timeout=30" `
  -PortalMode Simulated
```

### What the installer does

The host installer:

- copies the worker files into `Program Files`
- writes the worker config into `ProgramData`
- creates the Windows service
- starts the worker service

### Installed paths on Windows

- binaries:
  - `C:\Program Files\SMSFlow\SqlIntegration\Worker`
- config:
  - `C:\ProgramData\SMSFlow\SqlIntegration\config\worker\appsettings.json`
- logs:
  - `C:\ProgramData\SMSFlow\SqlIntegration\logs\worker`

## Step 3: Confirm the worker configuration

Open the worker config file:

```text
C:\ProgramData\SMSFlow\SqlIntegration\config\worker\appsettings.json
```

For a safe test environment, it should look like this:

```json
{
  "SqlIntegrationV2": {
    "ConnectionString": "Server=YOURSERVER;Database=YOURDATABASE;Integrated Security=True;Encrypt=True;TrustServerCertificate=True;Command Timeout=30",
    "PortalMode": "Simulated",
    "PortalBaseUrl": "",
    "ApiKey": "",
    "ChannelType": "Marketing"
  }
}
```

Recommended in `Simulated` mode:

- leave `PortalBaseUrl` blank
- leave `ApiKey` blank

## Step 4: Make sure the worker can log into SQL

This is the most common first-time setup issue.

If you use `Integrated Security=True`, then SQL Server will authenticate the **Windows account that runs the service**.

By default, the Windows service may run as:

- `NT AUTHORITY\SYSTEM`

That account must be able to access the target database.

### Example SQL permission setup for the default Windows service account

Run this in SQL Server:

```sql
USE [master];
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE name = N'NT AUTHORITY\SYSTEM'
)
BEGIN
    CREATE LOGIN [NT AUTHORITY\SYSTEM] FROM WINDOWS;
END
GO

USE [YOURDATABASE];
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'NT AUTHORITY\SYSTEM'
)
BEGIN
    CREATE USER [NT AUTHORITY\SYSTEM] FOR LOGIN [NT AUTHORITY\SYSTEM];
END
GO

ALTER ROLE [sms_flow_runtime] ADD MEMBER [NT AUTHORITY\SYSTEM];
GO
```

The `sms_flow_runtime` role is created by the SQL script and is the role used by the worker service.

### If you prefer SQL username/password

You can also use a SQL login instead of Windows auth:

```json
"ConnectionString": "Server=YOURSERVER;Database=YOURDATABASE;User Id=YOUR_SQL_USER;Password=YOUR_SQL_PASSWORD;Encrypt=True;TrustServerCertificate=True;Command Timeout=30"
```

That is often the quickest option when server-level Windows permissions are hard to change.

## Step 5: Confirm the worker service is running

In PowerShell, run:

```powershell
Get-Service SMSFlowSqlIntegrationV2
```

You want to see:

- `Status : Running`

If the service is not running, check the worker log:

```text
C:\ProgramData\SMSFlow\SqlIntegration\logs\worker
```

## Step 6: Send a test message

Now test the full flow.

Insert one message into the outbox table:

```sql
INSERT INTO [sms_flow].[Integration_OutboxMessage]
(
    [ClientMessageId],
    [ReferenceNumber],
    [Destination],
    [Body],
    [CostCentre],
    [Priority],
    [RequestedSendUtc]
)
VALUES
(
    'test-msg-001',
    'ref-001',
    '27821234567',
    'Hello from SMSFlow SQL API test',
    'Testing',
    0,
    NULL
);
```

### What this means

You are not calling an HTTP API yourself.

You are placing a row into the SQL outbox so the worker can process it.

## Step 7: Check whether the worker processed the row

Run:

```sql
EXEC [sms_flow].[Message_GetByClientMessageId]
    @ClientMessageId = 'test-msg-001';
```

### Message states you may see

- `Queued`
  - waiting to be picked up
- `Leased`
  - currently being processed
- `Submitted`
  - successfully accepted for sending
- `RetryPending`
  - temporary error, worker will retry
- `BlockedCredit`
  - no credits available
- `FailedValidation`
  - the row data is invalid
- `FailedPermanent`
  - message rejected permanently

### What success looks like

For a healthy test, the row should move to:

- `Submitted`

## Step 8: Check delivery status and replies

After submission, the reporting worker fetches statuses and replies and writes them back into SQL.

Use:

```sql
SELECT *
FROM [sms_flow].[vw_InboundActivity]
WHERE [ClientMessageId] = 'test-msg-001'
ORDER BY [CreatedUtc] DESC;
```

### What you expect in `Simulated` mode

You should normally see:

- a `Status` activity, often `Delivered`
- possibly a `Reply` activity, depending on simulation settings

### Example success result

If you see something like:

- `ActivityType = Status`
- `Summary = Delivered`

then the end-to-end worker flow is working.

## Step 9: Check the overall health dashboard

Run:

```sql
EXEC [sms_flow].[Dashboard_Snapshot_Get];
```

This gives a high-level snapshot of:

- pending messages
- ready messages
- blocked credit count
- retry count
- failed validation count
- failed permanent count
- last known balance
- last status event id
- last reply event id
- most recent operational event

This is one of the best quick checks for support teams.

## Step 10: Check failures

If anything looks wrong, run:

```sql
EXEC [sms_flow].[Failures_List];
```

And:

```sql
SELECT *
FROM [sms_flow].[vw_Attention]
ORDER BY [UpdatedUtc] DESC;
```

These help you understand which messages need attention.

## Step 11: Check worker logs

If the service won’t start, or messages do not move, check the worker logs:

```text
C:\ProgramData\SMSFlow\SqlIntegration\logs\worker
```

Common issues include:

- invalid connection string
- SQL login failure
- missing SQL objects
- live portal URL returning an error

## Real examples of common startup issues

### Example 1: malformed connection string

Symptom in log:

```text
Format of the initialization string does not conform to specification
```

Meaning:

- the connection string in `appsettings.json` is incomplete or broken

Fix:

- correct the full connection string
- restart the service

### Example 2: Windows-auth SQL login failure

Symptom in log:

```text
Login failed for user 'NT AUTHORITY\SYSTEM'
```

Meaning:

- the service account does not have access to the SQL database

Fix:

- create the login and user
- add the account to `sms_flow_runtime`
- restart the service

### Example 3: live portal unreachable

Symptom in log:

```text
Portal request to 'api/sql-integration/v2/registration/validate' failed with status 403
```

Meaning:

- the worker is in `Live` mode
- the portal endpoint is unavailable, stopped, wrong, or rejecting requests

Fix:

- confirm `PortalMode`
- confirm `PortalBaseUrl`
- confirm `ApiKey`
- use `Simulated` mode during testing

## What the manager does

The manager is optional.

The worker can run perfectly without it.

The manager exists for operators and support teams.

It is useful for:

- diagnostics
- monitoring
- configuration checks
- load testing
- viewing logs through the management agent

So:

- the **worker** does the real integration work
- the **manager** helps humans monitor and operate it

## What the client application still needs to do

Once the worker is working, the client application still needs to:

1. insert outbound messages into `sms_flow.Integration_OutboxMessage`
2. keep its own copy of `ClientMessageId`
3. read message progress from SQL
4. read delivery statuses from SQL
5. read replies from SQL
6. decide how their support team will monitor the integration

## Best practice for client applications

Always store `ClientMessageId` in your own business system.

That gives you a stable way to match:

- your internal record
- the SQL outbox row
- delivery status events
- reply events

## Go-live checklist

Before going live:

1. make sure the SQL script is applied to the production database
2. make sure the worker service account has production SQL access
3. switch `PortalMode` from `Simulated` to `Live`
4. set the real `PortalBaseUrl`
5. set the real `ApiKey`
6. restart the service
7. insert one controlled production test message
8. confirm the message becomes `Submitted`
9. confirm a real status event comes back
10. confirm support teams know how to use the health and failure checks

## Quick validation script

Here is a simple test flow you can run in order.

### Insert a message

```sql
INSERT INTO [sms_flow].[Integration_OutboxMessage]
(
    [ClientMessageId],
    [Destination],
    [Body]
)
VALUES
(
    'test-msg-quick-001',
    '27821234567',
    'Quick SQL API test'
);
```

### Check the row state

```sql
EXEC [sms_flow].[Message_GetByClientMessageId]
    @ClientMessageId = 'test-msg-quick-001';
```

### Check inbound activity

```sql
SELECT *
FROM [sms_flow].[vw_InboundActivity]
WHERE [ClientMessageId] = 'test-msg-quick-001'
ORDER BY [CreatedUtc] DESC;
```

### Check dashboard health

```sql
EXEC [sms_flow].[Dashboard_Snapshot_Get];
```

## What “working correctly” looks like

The integration is healthy when:

- the Windows service is running
- test messages leave `Queued`
- test messages reach `Submitted`
- `vw_InboundActivity` shows delivery activity
- the worker log has no new fatal startup errors

## Final summary

If you remember only one thing, remember this:

SMSFlow SQL API works by writing outbound messages into SQL and letting the worker do the rest.

The client’s responsibilities are:

- run the SQL script
- install and configure the worker
- give the worker SQL access
- insert outbound rows correctly
- monitor statuses, replies, and failures

Once those pieces are in place, the integration is straightforward to support and scale.
