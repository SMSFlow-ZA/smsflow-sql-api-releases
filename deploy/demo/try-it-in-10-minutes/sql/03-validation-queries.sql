EXEC sms_flow.Health_Get;
GO

EXEC sms_flow.Queue_Summary_Get;
GO

SELECT TOP (20)
    ClientMessageId,
    ReferenceNumber,
    Destination,
    State,
    AttemptCount,
    LastErrorCode,
    LastErrorMessage,
    CreatedUtc,
    UpdatedUtc
FROM sms_flow.vw_Messages
ORDER BY CreatedUtc DESC;
GO

SELECT TOP (20)
    ClientMessageId,
    ActivityType,
    Summary,
    Detail,
    ActivityUtc,
    CreatedUtc
FROM sms_flow.vw_InboundActivity
ORDER BY CreatedUtc DESC;
GO

SELECT TOP (20)
    *
FROM sms_flow.vw_Attention
ORDER BY UpdatedUtc DESC;
GO
