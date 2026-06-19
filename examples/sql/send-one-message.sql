DECLARE @ClientMessageId nvarchar(128) = CONCAT(N'demo-single-', CONVERT(nvarchar(36), NEWID()));

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
    @ClientMessageId,
    N'DEMO-SINGLE',
    N'27820000000',
    CONCAT(N'SMSFlow SQL API single-message demo ', CONVERT(nvarchar(36), NEWID())),
    N'Demo',
    0,
    SYSUTCDATETIME()
);

EXEC sms_flow.Message_GetByClientMessageId
    @ClientMessageId = @ClientMessageId;
