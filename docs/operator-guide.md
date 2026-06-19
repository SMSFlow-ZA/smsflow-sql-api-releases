# Operator Guide

## Introduction

SMSFlow SQL API is a host-side SMS integration that reads work from a SQL database, sends messages through SMSFlow, and writes replies and statuses back into the local integration database.

The suite is made up of a few simple parts:

- the worker host
- the optional management agent
- the optional Windows desktop management app
- the optional load-test tool

The worker is the important part. The other pieces exist to help you monitor it, diagnose problems, and safely test it.

## Before you use it

There are three common deployment models:

- Windows host install
- Linux host install
- Docker host deployment

Use the matching install guide first:

- [Windows install](install-windows.md)
- [Linux install](install-linux.md)
- [Docker install](install-docker.md)

## Normal operating model

In normal use:

- the worker keeps running in the background
- outbound messages are read from the integration database
- sent messages move through the normal reporting flow
- replies and statuses come back into the integration database
- archiving runs automatically based on the configured retention settings

If you install the management agent and use the Windows management app, you also get:

- a live overview dashboard
- configuration and preflight diagnostics
- host-side log access
- safe load-test controls

If you do not install the agent, the worker still runs normally. The management app just stays in SQL-only mode and hides the agent-backed pages.

## What needs to be checked

There are four main things to check during setup or support work:

- sending messages
- retrying failed or blocked messages
- retrieving statuses
- retrieving replies

On top of that, operators should also keep an eye on:

- queue depth
- failures and attention items
- archive health
- worker process health

## First-day usage and test script

If you are setting up a new environment, this is the safest practical flow.

1. Confirm the worker is installed and running.
2. Open the management app if you are on Windows.
3. Create a connection profile in `Configuration`.
4. Check `Overview` and confirm SQL is reachable.
5. Confirm the queue is empty or at least understood before testing.
6. Insert or enqueue a small known test message.
7. Confirm the message appears in the queue.
8. Confirm it moves through send processing.
9. Confirm a status appears.
10. If you are in simulated mode and replies are expected, confirm a reply appears.
11. Check that no unexpected failures or attention items remain behind.

For a safe end-to-end test environment:

- use a dedicated test database
- keep the worker in `PortalMode = Simulated`
- only use load tests after the small single-message flow is working

## Example SQL queries for sending messages

Messages are injected by inserting rows into:

- `sms_flow.Integration_OutboxMessage`

This is the queue table the worker reads from.

### Important safety notes

Before inserting test messages:

- make sure you are using the correct database
- use a unique `ClientMessageId` for every message
- prefer a dedicated test database
- keep the worker in `PortalMode = Simulated` for test and support work unless you are intentionally running a controlled live exercise

### Minimal single-message insert

This is the simplest example for a one-off test message:

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
    'manual-test-20260322-0001',
    'manual-ref-0001',
    '+27790001111',
    'Manual SQL integration test message',
    'Support',
    0,
    SYSUTCDATETIME()
);
```

### Single-message insert with delayed requested send time

Use this when you want the row to exist now but only become eligible a little later:

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
    'manual-test-20260322-0002',
    'manual-ref-0002',
    '+27790002222',
    'Delayed SQL integration test message',
    'Support',
    0,
    DATEADD(MINUTE, 5, SYSUTCDATETIME())
);
```

### Insert a small batch of messages

Use this when you want a controlled burst without using the load driver:

```sql
DECLARE @Now DATETIME2 = SYSUTCDATETIME();

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
('manual-batch-20260322-0001', 'manual-batch-ref-0001', '+27790010001', 'Batch test message 1', 'Support', 0, @Now),
('manual-batch-20260322-0002', 'manual-batch-ref-0002', '+27790010002', 'Batch test message 2', 'Support', 0, @Now),
('manual-batch-20260322-0003', 'manual-batch-ref-0003', '+27790010003', 'Batch test message 3', 'Support', 0, @Now);
```

### Confirm the message is in the queue

```sql
SELECT TOP 20
    Id,
    ClientMessageId,
    ReferenceNumber,
    Destination,
    State,
    AttemptCount,
    RequestedSendUtc,
    NextAttemptUtc,
    UpdatedUtc
FROM sms_flow.Integration_OutboxMessage
WHERE ClientMessageId LIKE 'manual-%'
ORDER BY Id DESC;
```

### Confirm statuses and replies arrived

```sql
SELECT TOP 20 *
FROM sms_flow.vw_InboundActivity
WHERE ClientMessageId LIKE 'manual-%'
ORDER BY ActivityUtc DESC;
```

### Quick reminder on key outbox fields

The most important insert columns are:

- `ClientMessageId`
  - must be unique per message
- `ReferenceNumber`
  - optional business reference used for lookup and support
- `Destination`
  - the target mobile number
- `Body`
  - the message text
- `CostCentre`
  - optional reporting bucket
- `Priority`
  - higher values are processed sooner
- `RequestedSendUtc`
  - when the worker is allowed to send the message

## Main monitoring surfaces

The main SQL surfaces are:

- `sms_flow.vw_Health`
- `sms_flow.vw_Messages`
- `sms_flow.vw_Attention`
- `sms_flow.vw_InboundActivity`

The main non-SQL surfaces are:

- worker log files
- management app `Overview`
- management app `Diagnostics` when the agent is installed

## Using the management app

The management app is the easiest way to operate the integration when you are on Windows.

### Configuration

Use `Configuration` to create and manage connection profiles.

Each profile can contain:

- a SQL connection string
- optionally, a management agent URL
- optionally, the management shared secret

If the profile has only SQL configured:

- the app stays in SQL-only mode
- `Overview` remains available
- agent-backed pages are hidden

If the profile also has a valid agent URL:

- `Diagnostics` becomes available
- `Load Tests` becomes available

### Overview

Use `Overview` for day-to-day monitoring.

This is where you watch:

- SQL connectivity
- agent, worker, and load-test connectivity state
- queue depth
- rolling throughput
- inbound activity
- attention items
- recent operational health

When someone asks “is it moving?” or “is it healthy?”, this is the first page to check.

### Diagnostics

Use `Diagnostics` when something looks wrong.

This page is for:

- checking sanitized effective configuration
- running preflight checks
- seeing recent failures
- seeing recent operational events
- tailing worker and load-test logs

Typical things to diagnose here:

- bad SQL connection strings
- missing or invalid agent configuration
- worker process not running
- load-test executable not found
- worker not in simulated mode when load testing is needed

### Load Tests

Use `Load Tests` only in a dedicated test environment.

This page starts and stops the existing load driver against the same database the real worker uses.

The two main modes are:

- `Enqueue`
  - inject a fixed amount of work and stop
- `Sustain`
  - keep topping the queue back up for a fixed duration

The management agent refuses to start a load test unless the worker is explicitly configured with:

- `SqlIntegrationV2:PortalMode = Simulated`

That is intentional and should not be worked around in normal client operation.

## Overview reference

### Status chips

The status chips at the top of the app tell you whether the main moving parts are reachable.

Typical meanings:

- `SQL`
  - whether the app can reach the SQL database for the selected profile
- `Agent`
  - whether the optional management agent is reachable
- `Worker`
  - whether the worker process appears to be running from the agent’s point of view
- `Load test`
  - whether a load-test process is currently running from the agent’s point of view

### System pulse area

The large balance and snapshot area is a quick health summary.

Fields:

- `SYSTEM PULSE`
  - the current balance and billing model seen by the worker
- `SNAPSHOT`
  - the time the current dashboard snapshot was taken
- `SEND / MIN`
  - how many messages reached submitted state in the last minute
- `STATUS / MIN`
  - how many status events arrived in the last minute
- `REPLIES / MIN`
  - how many reply events arrived in the last minute
- `FAILURES / MIN`
  - how many new failure events were observed in the last minute
- `OLDEST PENDING`
  - the oldest message still waiting in the pending queue
- `LAST EVENT`
  - the latest operational event code and message raised by the worker

### Archive and cursors area

This tells you whether the reporting and archive loops are still advancing.

Fields:

- `Last archive`
  - the last successful archive run time
- `Last archive error`
  - the latest archive error message, if any
- `STATUS CURSOR`
  - the latest processed status event id
- `REPLY CURSOR`
  - the latest processed reply event id
- `ARCHIVED LAST RUN`
  - how many rows were archived in the last archive pass
- `PURGED LAST RUN`
  - how many archived rows were purged in the last cleanup pass

### Metric cards

These cards show the live shape of the queue.

- `Pending queue`
  - messages waiting to become ready or waiting on their next processing time
- `Ready queue`
  - messages immediately eligible for processing
- `Leased`
  - messages currently claimed by a worker loop
- `Blocked credit`
  - messages paused because sending was blocked by insufficient credit or balance
- `Retry pending`
  - messages scheduled for another retry after a recoverable failure
- `Permanent failures`
  - messages that have failed in a terminal way and will not retry again

### Charts

The overview charts are rolling 60-second operator views.

- `Queue depth`
  - how the total queue size has moved over the last minute
- `Send TPS`
  - send throughput trend over the last minute
- `Status rate`
  - status arrival trend over the last minute
- `Reply and failure rate`
  - reply and failure trends over the last minute

## Table column reference

### Overview: Attention queue

This table highlights messages that likely need human attention.

Columns:

- `ClientMessageId`
  - the client-side unique message identifier
- `State`
  - the current worker state for the message
- `Action`
  - the suggested next operator action based on the message state
- `Updated`
  - the last time the message row changed

### Overview: Inbound activity

This table shows recent statuses and replies coming back into the system.

Columns:

- `Type`
  - whether the row is a status or a reply event
- `ClientMessageId`
  - the message identifier tied to the inbound event
- `Summary`
  - the short human-readable status or reply summary
- `When`
  - when the event occurred

### Diagnostics: Preflight checks

The preflight list is not a data grid, but it is still a user-facing table of checks.

Fields per check:

- `Name`
  - what is being checked
- `Message`
  - the result explanation in plain language
- `IsSuccess`
  - whether that check passed

### Diagnostics: Failed messages

This table is the quick triage list for recent failed or terminal messages.

Columns:

- `ClientMessageId`
  - the message identifier
- `State`
  - the current failure-related state
- `Error`
  - the last error code recorded on the message
- `Updated`
  - the last time the row changed

### Diagnostics: Operational events

This table shows recent worker events and errors.

Columns:

- `When`
  - when the event was written
- `Level`
  - the event severity, such as information, warning, or error
- `Code`
  - the structured event code
- `Message`
  - the human-readable event message

## Message details reference

The message details pane is for quick drill-in on a specific message.

Fields:

- `CLIENT MESSAGE ID`
  - the unique client-side message id
- `STATE`
  - the current processing state
- `ATTEMPTS`
  - how many times the worker has tried to process the message
- `READY`
  - whether the message is currently eligible for immediate processing
- `REFERENCE`
  - the reference number associated with the message
- `DESTINATION`
  - the target mobile number
- `NEXT PROCESSING`
  - when the worker expects to try the message next
- `REQUESTED SEND`
  - the requested send time stored on the message
- `CREATED`
  - when the message row was created
- `UPDATED`
  - when the message row last changed
- `BODY`
  - the message content
- `LAST ERROR`
  - the last error code and message recorded against the message

## Load test reference

### Scenario parameters

Fields:

- `MODE`
  - the load-test mode, either `Enqueue` or `Sustain`
- `MESSAGE COUNT (MESSAGES)`
  - the total number of messages to inject in `Enqueue` mode
- `BATCH SIZE (MESSAGES)`
  - how many rows are inserted per bulk batch
- `PARALLEL WRITERS (COUNT)`
  - how many writer tasks the load driver uses
- `TARGET OUTSTANDING (MESSAGES)`
  - the desired outstanding queue depth in `Sustain` mode
- `MAX INSERT PER CYCLE (MESSAGES)`
  - the maximum refill amount for one sustain cycle
- `DURATION (SECONDS)`
  - how long the sustain loop should run
- `POLL INTERVAL (SECONDS)`
  - how often sustain mode checks queue depth
- `REQUESTED SEND OFFSET (SECONDS)`
  - how far into the future the injected messages should be stamped for requested send

### Current run

Fields:

- `Running`
  - whether the load driver is currently running
- `Process ID`
  - the operating system process id for the load driver
- `Started`
  - when the current or last run started
- `Exited`
  - when the run exited, if it has already stopped
- `Exit code`
  - the process exit code, if the run has stopped
- `Log path`
  - the log file path for the run
- `Arguments`
  - the sanitized launch arguments used for the run

## Message flow at a high level

The local database is the source of truth for the integration flow.

At a high level:

1. outbound messages are inserted into the outbox table
2. the worker claims and sends them
3. statuses and replies are written back into inbound tables
4. the dashboard and SQL views reflect the current state
5. terminal data is archived later according to retention settings

So if something looks wrong, the fastest question to ask is:

- did the outbox move?
- did statuses arrive?
- did replies arrive?
- did attention or failures grow?

## What to watch in a healthy environment

A healthy environment should normally show:

- SQL reachable
- worker reachable or running
- queue depth changing when work exists
- statuses appearing after sends when the simulator or live portal should be producing them
- replies appearing when expected
- no steadily growing attention or failure backlog

## Common situations

### No agent configured

Expected behavior:

- the worker still runs
- SQL-only monitoring still works
- the management app hides `Diagnostics` and `Load Tests`

This is normal and supported.

### Need to investigate a message

Use the management app message search and details pane, or query the SQL views directly by:

- client message id
- reference number

### Need to confirm statuses or replies are working

Check:

- `sms_flow.vw_InboundActivity`
- recent rows in the inbound status and reply tables
- worker logs
- the `Overview` page in the management app

### Need to understand why nothing is archiving

Archiving is driven by retention settings. Newly processed rows will not archive immediately unless retention windows are intentionally shortened for testing.

### Need to load test safely

Only do this when all of the following are true:

- the database is a dedicated test database
- the worker is in `Simulated` mode
- you understand the expected queue size and throughput

Do not use load testing against a live worker/database combination.

## Practical support checklist

When a client says the integration is not working, the support flow should usually be:

1. confirm SQL connectivity
2. confirm the worker process or service is running
3. check queue depth and attention items
4. check whether statuses or replies are arriving
5. inspect recent failures and operational events
6. inspect worker logs
7. use load testing only in a dedicated simulated test environment if you need to exercise the full flow

## First-run validator and support bundles

The Windows host bundle includes a first-run validator:

```powershell
.\Installers\artifacts\publish\Support\sms_flow_portal.sql_integration.v2.FirstRunValidator.exe `
  --connection-string "Server=.;Database=SmsFlow;Trusted_Connection=True;TrustServerCertificate=True"
```

Use it after install and before handover to confirm:

- SQL connectivity
- required schemas, roles, tables, views, and procedures
- schema version
- worker config
- Windows service registration

For new databases, add `--apply-schema-script` and point it at the bundled `sql_integration_v2.sql`.

When escalation to SMSFlow support is needed, collect a sanitized support bundle:

```powershell
pwsh .\Installers\Collect-SMSFlowSqlIntegrationSupportBundle.ps1
```

The bundle redacts connection strings, API keys, secrets, passwords, and tokens from JSON config.

## When to use which document

- install or reinstall on Windows: [Windows install](INSTALL-Windows.md)
- install or reinstall on Linux: [Linux install](INSTALL-Linux.md)
- install or run in containers: [Docker install](INSTALL-Docker.md)
- engineer or modify the system: [Developer guide](developer-guide.md)

