# Client Developer Guide

This guide explains how to integrate an application with SMSFlow SQL API using the public release bundles.

## How The Integration Works

Your application writes outbound SMS messages into the SQL outbox table. The SMSFlow worker reads that queue, sends messages through SMSFlow, and writes back message state, delivery statuses, replies, and operational health.

You do not need to host an HTTP client in every application. The database is the integration boundary.

## Core Tables And Views

Write outbound messages to:

```text
sms_flow.Integration_OutboxMessage
```

Read operational state from:

```text
sms_flow.vw_Messages
sms_flow.vw_Attention
sms_flow.vw_InboundActivity
sms_flow.vw_Health
sms_flow_archive.vw_ArchivedMessages
```

## Minimal Send Example

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
    'order-10001-confirmation',
    'order-10001',
    '+27790001111',
    'Your order has been received.',
    'Orders',
    0,
    SYSUTCDATETIME()
);
```

Use a unique `ClientMessageId` for every SMS.

## Check Message Progress

```sql
SELECT TOP 20
    ClientMessageId,
    ReferenceNumber,
    Destination,
    State,
    AttemptCount,
    LastErrorCode,
    LastErrorMessage,
    UpdatedUtc
FROM sms_flow.vw_Messages
ORDER BY UpdatedUtc DESC;
```

## Read Statuses And Replies

```sql
SELECT TOP 20
    ActivityType,
    ClientMessageId,
    ReferenceNumber,
    Summary,
    Detail,
    ActivityUtc
FROM sms_flow.vw_InboundActivity
ORDER BY ActivityUtc DESC;
```

## Recommended Development Flow

1. Install the worker in `Simulated` mode.
2. Apply the SQL schema to a dedicated test database.
3. Insert one test message.
4. Confirm the message appears in `sms_flow.vw_Messages`.
5. Confirm statuses or simulated replies appear in `sms_flow.vw_InboundActivity`.
6. Test retry and failure handling with controlled test data.
7. Move to live credentials only after the simulated flow is stable.

## More Detail

- [Client implementation guide](client-implementation-guide.md)
- [Client setup guide](client-setup-guide.md)
- [Operator guide](operator-guide.md)
