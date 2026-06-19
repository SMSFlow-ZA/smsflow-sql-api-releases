EXEC sms_flow.Health_Get;
EXEC sms_flow.Dashboard_Snapshot_Get;
EXEC sms_flow.Queue_Summary_Get;

SELECT TOP (20)
    *
FROM sms_flow.vw_Attention
ORDER BY UpdatedUtc DESC;
