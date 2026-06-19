DECLARE @BatchId nvarchar(36) = CONVERT(nvarchar(36), NEWID());

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
    CONCAT(N'demo-single-', @BatchId),
    N'DEMO-SINGLE',
    N'27820000000',
    CONCAT(N'SMSFlow SQL API simulated demo ', @BatchId),
    N'Demo',
    0,
    SYSUTCDATETIME()
),
(
    CONCAT(N'demo-bulk-', @BatchId, N'-001'),
    CONCAT(N'DEMO-BULK-', @BatchId),
    N'27820000001',
    CONCAT(N'SMSFlow SQL API simulated bulk demo 1 ', @BatchId),
    N'DemoBulk',
    0,
    SYSUTCDATETIME()
),
(
    CONCAT(N'demo-bulk-', @BatchId, N'-002'),
    CONCAT(N'DEMO-BULK-', @BatchId),
    N'27820000002',
    CONCAT(N'SMSFlow SQL API simulated bulk demo 2 ', @BatchId),
    N'DemoBulk',
    0,
    SYSUTCDATETIME()
);

EXEC sms_flow.Queue_Summary_Get;
GO
