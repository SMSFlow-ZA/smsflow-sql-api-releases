# SMSFlow SQL API Client Implementation Guide

This guide is written for client developers who need to integrate their system with SMSFlow SQL API.

The goal is to explain the process step by step in plain language, even if you are new to the project.

## 1. What this integration does

This integration lets your system send SMS messages by writing rows into a SQL Server table.

You do not call the SMS portal directly from your client application.

Instead, the flow works like this:

1. Your application inserts a message into the SQL outbox table.
2. The SMSFlow SQL API worker reads the queued message.
3. The worker validates the row and sends it to the SMS Flow portal.
4. The worker updates the message state in SQL.
5. The worker also pulls delivery statuses and replies from the portal.
6. Those statuses and replies are written back into SQL for your application to read.

This means your application only needs to know how to:

- insert outbound messages into SQL
- read message progress from SQL
- read replies and status updates from SQL

## 2. The main components

These are the main parts of the solution:

- `sms_flow_portal.sql_integration.v2.App`
  - the background worker that reads from SQL and talks to the portal
- `sql_integration_v2.sql`
  - the SQL script that creates the required schemas, tables, procedures, views, and roles
- `sms_flow_portal.sql_integration.v2.Management.Agent`
  - optional diagnostics and load-test API
- `sms_flow_portal.sql_integration.v2.Management`
  - optional Windows desktop operator app

For client implementation, the two most important parts are:

- the SQL script
- the worker host

## 3. Before you start

Make sure you have the following:

- a SQL Server database where the integration objects will be created
- the SMSFlow SQL API worker installed or available to run
- a SQL connection string for the integration database
- a deployment decision:
  - Windows host
  - Linux host
  - Docker host
- if running in `Live` mode:
  - the portal base URL
  - the portal API key

Important safety rule:

- use `PortalMode = Simulated` while developing and testing
- only switch to `Live` when you are ready to send real traffic

## 4. Understand the database objects

When you run the SQL script, it creates two schemas:

- `sms_flow`
  - live operational objects
- `sms_flow_archive`
  - archive objects

The most important live tables are:

- `sms_flow.Integration_OutboxMessage`
  - your application inserts messages here
- `sms_flow.Integration_InboundStatus`
  - the worker stores status updates here
- `sms_flow.Integration_InboundReply`
  - the worker stores customer replies here
- `sms_flow.Integration_RuntimeState`
  - stores worker progress such as last processed event ids and last known balance
- `sms_flow.Integration_OperationalEvent`
  - stores warnings, errors, and informational events

The most important read surfaces are:

- `sms_flow.vw_Messages`
- `sms_flow.vw_Attention`
- `sms_flow.vw_InboundActivity`
- `sms_flow.vw_Health`
- `sms_flow.Dashboard_Snapshot_Get`
- `sms_flow.Queue_Summary_Get`
- `sms_flow.Failures_List`
- `sms_flow.Message_GetByClientMessageId`

## 5. Step 1: Apply the SQL script

Run the SQL script below against the client database:

- [sql_integration.sql](../examples/sql/sql_integration.sql)

This script creates:

- tables
- indexes
- stored procedures
- views
- SQL roles

Suggested approach:

1. Create or choose a SQL Server database for the integration.
2. Open SQL Server Management Studio or Azure Data Studio.
3. Open `sql_integration_v2.sql`.
4. Execute the script.
5. Confirm that these objects now exist:
   - `sms_flow.Integration_OutboxMessage`
   - `sms_flow.Integration_InboundStatus`
   - `sms_flow.Integration_InboundReply`
   - `sms_flow.vw_Messages`
   - `sms_flow.vw_InboundActivity`

## 6. Step 2: Create SQL access for the client application

The SQL script creates database roles for you.

The most important ones are:

- `sms_flow_enqueue`
  - can insert into `sms_flow.Integration_OutboxMessage`
- `sms_flow_readonly`
  - can read approved views and execute read procedures

Recommended pattern:

1. Create one SQL login or database user for the client application that writes messages.
2. Add that user to `sms_flow_enqueue`.
3. Create a separate read user if needed.
4. Add the read user to `sms_flow_readonly`.

This is safer than giving broad table permissions.

## 7. Step 3: Install and configure the worker

The worker is the service that makes the integration work.

Without the worker:

- messages stay in the outbox table
- no sends happen
- no status updates are collected
- no replies are collected

Use one of the supported install guides:

- [Windows install](install-windows.md)
- [Linux install](install-linux.md)
- [Docker install](install-docker.md)

### 7.1 Recommended developer setup

For local or client test environments, start with:

- `PortalMode = Simulated`
- a test SQL database
- no live credentials

This lets you test the full worker and SQL flow without sending real SMS traffic.

### 7.2 Required worker settings

The worker reads settings from the `SqlIntegrationV2` section.

The most important settings are:

- `ConnectionString`
  - SQL Server connection string for the integration database
- `PortalMode`
  - `Simulated` for safe testing
  - `Live` for real portal traffic
- `PortalBaseUrl`
  - required only in `Live` mode
- `ApiKey`
  - required only in `Live` mode
- `ChannelType`
  - usually `Marketing` unless your deployment uses another channel
- `LogDirectory`
  - where logs are written

### 7.3 What happens when the worker starts

When the worker starts, it does a few important checks:

1. It validates that required stored procedures exist in SQL.
2. It validates that the portal registration works.
3. It reads runtime state from SQL.
4. It starts three background loops:
   - send loop
   - reporting loop
   - archive loop

If the portal registration check fails in `Live` mode, the worker will not initialize correctly.

## 8. Step 4: Learn the outbound message contract

To send a message, your application inserts one row into:

- `sms_flow.Integration_OutboxMessage`

### 8.1 Required columns

These columns matter most to client developers:

- `ClientMessageId`
  - required
  - must be unique
  - max length `128`
- `Destination`
  - required
  - max length `64`
  - must be a valid mobile number
- `Body`
  - required
  - max length `1600`

### 8.2 Optional columns

- `ReferenceNumber`
  - optional
  - max length `128`
- `CostCentre`
  - optional
  - max length `128`
- `Priority`
  - optional
  - defaults to `0`
- `RequestedSendUtc`
  - optional
  - if supplied, the worker waits until this time before sending

### 8.3 Fields the client should not manage directly

These are worker-managed fields:

- `State`
- `AttemptCount`
- `LastErrorCode`
- `LastErrorMessage`
- `LockedUntilUtc`
- `NextAttemptUtc`
- `CreatedUtc`
- `UpdatedUtc`

Your application should normally insert the business fields only.

## 9. Step 5: Insert a test message

Use a simple insert like this:

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
    'client-msg-0001',
    'order-1001',
    '27821234567',
    'Hello from SMSFlow SQL API',
    'Sales',
    0,
    NULL
);
```

What this does:

1. creates one outbound message
2. places it in the queue
3. lets the worker pick it up automatically

## 10. Step 6: Understand the message state flow

The worker moves each message through states.

These are the important ones:

- `Queued`
  - newly inserted and waiting to be picked up
- `Leased`
  - the worker has claimed the row and is processing it
- `Submitted`
  - the worker successfully submitted it to the portal
- `RetryPending`
  - a temporary issue happened and the worker will retry later
- `BlockedCredit`
  - the portal reported insufficient credits
- `FailedValidation`
  - the row data was invalid
- `FailedPermanent`
  - the portal rejected the message permanently

### 10.1 What causes validation failures

The worker validates each claimed row before sending.

Common validation failures include:

- missing `clientMessageId`
- missing `destination`
- missing `body`
- field lengths that exceed the allowed maximum
- invalid mobile number format
- invalid `requestedSendUtc`

### 10.2 What causes retries

Retries usually happen because of temporary failures such as:

- network errors
- service interruptions
- temporary downstream problems

The worker sets:

- `State = RetryPending`
- `LastErrorCode = TRANSIENT`
- `NextAttemptUtc` to a future retry time

## 11. Step 7: Check whether the message was accepted

The easiest way is to query the approved message view:

```sql
SELECT *
FROM [sms_flow].[vw_Messages]
WHERE [ClientMessageId] = 'client-msg-0001';
```

You can also use the stored procedure:

```sql
EXEC [sms_flow].[Message_GetByClientMessageId]
    @ClientMessageId = 'client-msg-0001';
```

What to look for:

- `State`
  - should move from `Queued` to `Leased` to `Submitted`
- `AttemptCount`
  - shows how many send attempts were made
- `LastErrorCode`
  - set when something went wrong
- `LastErrorMessage`
  - readable error detail

## 12. Step 8: Read inbound statuses

After the message is submitted, the reporting worker polls the portal and writes statuses into:

- `sms_flow.Integration_InboundStatus`

The recommended read surface is:

- `sms_flow.vw_InboundActivity`

Example:

```sql
SELECT *
FROM [sms_flow].[vw_InboundActivity]
WHERE [ClientMessageId] = 'client-msg-0001'
ORDER BY [CreatedUtc] DESC;
```

If the row is a status event, you will see:

- `ActivityType = Status`
- `Summary`
  - normalized status such as `DELIVERED`
- `Detail`
  - raw provider status text
- `ActivityUtc`
  - the status event timestamp

## 13. Step 9: Read inbound replies

If the customer replies, the reporting worker writes the reply into:

- `sms_flow.Integration_InboundReply`

The same `vw_InboundActivity` view also exposes replies.

For replies, look for:

- `ActivityType = Reply`
- `Summary`
  - `REPLY` or `OPT_OUT`
- `Detail`
  - the actual reply message body

Example:

```sql
SELECT *
FROM [sms_flow].[vw_InboundActivity]
WHERE [ActivityType] = 'Reply'
  AND [ClientMessageId] = 'client-msg-0001'
ORDER BY [CreatedUtc] DESC;
```

## 14. Step 10: Monitor the health of the integration

The safest way for beginners is to use the provided views and procedures instead of reading raw tables directly.

### 14.1 Quick health snapshot

```sql
SELECT *
FROM [sms_flow].[vw_Health];
```

This shows useful runtime information such as:

- last known balance
- billing type
- last processed status event id
- last processed reply event id
- pending message count
- failed validation count
- failed permanent count

### 14.2 Dashboard snapshot

```sql
EXEC [sms_flow].[Dashboard_Snapshot_Get];
```

This gives a richer operator-style snapshot, including:

- pending count
- ready count
- blocked credit count
- retry count
- recent submission count
- recent status count
- recent reply count
- latest operational event

### 14.3 Queue summary

```sql
EXEC [sms_flow].[Queue_Summary_Get];
```

This is a simple grouped count by state.

## 15. Step 11: Troubleshoot failures

Use these read surfaces first:

```sql
EXEC [sms_flow].[Failures_List];
```

```sql
SELECT *
FROM [sms_flow].[vw_Attention]
ORDER BY [UpdatedUtc] DESC;
```

These are especially useful when messages are:

- stuck in `RetryPending`
- blocked for credits
- failing validation
- failing permanently

Also review operational events:

```sql
EXEC [sms_flow].[OperationalEvent_List];
```

This helps you see worker errors and warnings.

## 16. Step 12: Understand what the worker does over HTTP

Your client application does not call these HTTP endpoints directly in the normal SQL integration model.

The worker calls them on your behalf when `PortalMode = Live`:

- `POST api/sql-integration/v2/registration/validate`
- `POST api/sql-integration/v2/messages/send`
- `POST api/sql-integration/v2/reporting/statuses`
- `POST api/sql-integration/v2/reporting/replies`

That means your implementation responsibility is usually:

- write outbound rows into SQL
- read results from SQL
- monitor failures and replies in SQL

Not:

- call the SMS portal directly

## 17. Step 13: Recommended implementation pattern for client apps

For most client systems, this is the cleanest pattern:

1. When your business process decides to send an SMS, generate a unique `ClientMessageId`.
2. Insert a row into `sms_flow.Integration_OutboxMessage`.
3. Save that same `ClientMessageId` in your own business table.
4. Use `ClientMessageId` later to query send progress.
5. Read statuses and replies using `vw_InboundActivity`.
6. Build your own reconciliation or reporting screens using the provided views and procedures.

Why this matters:

- `ClientMessageId` is your main tracking key
- it links your application record to the integration record
- it is also how the worker and inbound activities stay correlated

## 18. Step 14: Example end-to-end workflow

Here is a simple beginner-friendly flow.

### 18.1 Prepare the environment

1. Apply `sql_integration_v2.sql`.
2. Install the worker.
3. Configure the worker to use `PortalMode = Simulated`.
4. Start the worker.

### 18.2 Queue a message

Run:

```sql
INSERT INTO [sms_flow].[Integration_OutboxMessage]
(
    [ClientMessageId],
    [Destination],
    [Body]
)
VALUES
(
    'demo-0001',
    '27821234567',
    'This is a demo SMS'
);
```

### 18.3 Confirm the worker saw the message

Run:

```sql
EXEC [sms_flow].[Message_GetByClientMessageId]
    @ClientMessageId = 'demo-0001';
```

You should see the state change after the worker processes it.

### 18.4 Check for inbound activity

Run:

```sql
SELECT *
FROM [sms_flow].[vw_InboundActivity]
WHERE [ClientMessageId] = 'demo-0001'
ORDER BY [CreatedUtc] DESC;
```

In `Simulated` mode, statuses and replies can be generated based on the simulation settings.

### 18.5 Review health

Run:

```sql
EXEC [sms_flow].[Dashboard_Snapshot_Get];
```

This confirms whether the worker is actively processing rows.

## 19. Common mistakes to avoid

- Do not insert duplicate `ClientMessageId` values.
- Do not write directly into inbound status or inbound reply tables.
- Do not manually update worker-managed state columns unless you are doing controlled support work.
- Do not run load tests in `Live` mode.
- Do not point test tooling at a live database and live worker combination.
- Do not skip monitoring `FailedValidation`, `FailedPermanent`, and `BlockedCredit`.

## 20. Recommended Stoplight documentation structure

If you are publishing this in Stoplight, a good beginner-friendly structure is:

1. Overview
   - what SMSFlow SQL API is
   - who should use it
2. Architecture
   - app writes to SQL
   - worker sends to portal
   - worker writes statuses and replies back
3. Prerequisites
   - SQL Server
   - worker install
   - test vs live credentials
4. Installation
   - Windows
   - Linux
   - Docker
5. Database setup
   - apply SQL script
   - create users and roles
6. Sending messages
   - required fields
   - sample insert
   - expected state flow
7. Reading delivery statuses
   - `vw_InboundActivity`
8. Reading replies
   - `vw_InboundActivity`
9. Monitoring and health
   - `vw_Health`
   - `Dashboard_Snapshot_Get`
   - `Queue_Summary_Get`
10. Troubleshooting
   - `Failures_List`
   - `vw_Attention`
   - `OperationalEvent_List`
11. Go-live checklist
   - switch from `Simulated` to `Live`
   - verify API key
   - verify portal URL
   - verify SQL permissions

## 21. Go-live checklist

Before moving to production:

1. Confirm the SQL script is applied in the target database.
2. Confirm the worker service is installed and running.
3. Confirm the worker connection string points to the correct database.
4. Confirm the portal API key is valid.
5. Confirm `PortalBaseUrl` is correct.
6. Confirm `PortalMode` is changed from `Simulated` to `Live`.
7. Confirm the client application can insert rows into `Integration_OutboxMessage`.
8. Confirm support users can read health and message views.
9. Send one controlled test message.
10. Confirm status and reply ingestion works as expected.

## 22. Suggested “first success” test for a new client developer

If you are brand new to the integration, do this first:

1. Set the worker to `Simulated`.
2. Start the worker.
3. Insert one message into `Integration_OutboxMessage`.
4. Query `Message_GetByClientMessageId`.
5. Query `vw_InboundActivity`.
6. Query `Dashboard_Snapshot_Get`.

If those steps work, your core integration is working.

After that, move on to:

- batch sending
- application-side tracking
- operator monitoring
- production hardening
