SELECT TOP (50)
    ClientMessageId,
    ActivityType,
    Summary,
    Detail,
    ActivityUtc,
    CreatedUtc
FROM sms_flow.vw_InboundActivity
WHERE ActivityType = N'Reply'
ORDER BY CreatedUtc DESC;
