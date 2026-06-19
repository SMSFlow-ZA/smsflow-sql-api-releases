DECLARE @ClientMessageId nvarchar(128) = N'YOUR_CLIENT_MESSAGE_ID';

EXEC sms_flow.Message_GetByClientMessageId
    @ClientMessageId = @ClientMessageId;

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
WHERE ClientMessageId = @ClientMessageId
ORDER BY UpdatedUtc DESC;
