EXEC sms_flow.SchemaVersion_Get;
GO

SELECT name, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID(N'sms_flow')
  AND name IN
  (
      N'Integration_OutboxMessage',
      N'Integration_InboundStatus',
      N'Integration_InboundReply',
      N'Message_GetByClientMessageId',
      N'Queue_Summary_Get'
  )
ORDER BY name;
GO
