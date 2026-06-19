EXEC sms_flow.Health_Get;
EXEC sms_flow.Queue_Summary_Get;
EXEC sms_flow.Failures_List;
EXEC sms_flow.OperationalEvent_List;

SELECT TOP (50)
    ClientMessageId,
    Destination,
    State,
    AttemptCount,
    LastErrorCode,
    LastErrorMessage,
    NextAttemptUtc,
    UpdatedUtc
FROM sms_flow.vw_Attention
ORDER BY UpdatedUtc DESC;
