DECLARE @TotalDemoMessages int =
(
    SELECT COUNT(*)
    FROM sms_flow.Integration_OutboxMessage
    WHERE CostCentre IN (N'Demo', N'DemoBulk')
);

DECLARE @QueuedDemoMessages int =
(
    SELECT COUNT(*)
    FROM sms_flow.Integration_OutboxMessage
    WHERE CostCentre IN (N'Demo', N'DemoBulk')
      AND State = N'Queued'
);

DECLARE @FailedDemoMessages int =
(
    SELECT COUNT(*)
    FROM sms_flow.Integration_OutboxMessage
    WHERE CostCentre IN (N'Demo', N'DemoBulk')
      AND State IN (N'FailedValidation', N'FailedPermanent')
);

IF @TotalDemoMessages < 3
BEGIN
    THROW 51000, 'Expected at least three seeded demo messages.', 1;
END;

IF @FailedDemoMessages > 0
BEGIN
    THROW 51001, 'One or more demo messages failed validation or permanent processing.', 1;
END;

IF @QueuedDemoMessages > 0
BEGIN
    THROW 51002, 'One or more demo messages are still queued. The worker did not process the simulated demo messages yet.', 1;
END;

SELECT
    @TotalDemoMessages AS TotalDemoMessages,
    @QueuedDemoMessages AS QueuedDemoMessages,
    @FailedDemoMessages AS FailedDemoMessages;
GO
