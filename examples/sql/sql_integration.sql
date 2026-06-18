/*
    
    ----------------------- SCHEMA -----------------------
    Live operational objects live under an sms_flow schema, and archive objects live under an sms_flow_archive schema.
    
    ----------------------- TABLES -----------------------
    [Integration_OutboxMessage] - Messages to be sent are inserted here. 
                                  A background process will claim messages from this table, attempt to send them, 
                                  and update the status and other details.
    [Integration_InboundStatus] - Status updates received from the provider are inserted here.
    [Integration_InboundReply] - Replies received from the provider are inserted here.
    [Integration_RuntimeState] - A singleton table to hold runtime state such as last known balance and last processed event ids.
    [Integration_SchemaVersion] - Applied schema versions for first-run validation and future upgrades.
    [Integration_OperationalEvent] - Operational events such as errors, warnings, and informational messages are logged here for monitoring and troubleshooting purposes.
    
    [Integration_ArchiveLease] - A singleton table used to coordinate archive jobs across multiple instances. 
                                 It holds the lease information for which instance is currently performing archiving, when the lease expires, 
                                 and when the last archive job started and finished.

    [Integration_OutboxMessageArchive], 
    [Integration_InboundStatusArchive], 
    [Integration_InboundReplyArchive], 
    [Integration_OperationalEventArchive] - Archive tables for the above entities. Records are moved to these tables after a configurable retention period for historical/audit purposes.
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sms_flow')
BEGIN
    EXEC('CREATE SCHEMA [sms_flow]');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sms_flow_archive')
BEGIN
    EXEC('CREATE SCHEMA [sms_flow_archive]');
END
GO

IF OBJECT_ID('[sms_flow].[Integration_SchemaVersion]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow].[Integration_SchemaVersion]
    (
        [Id] INT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_sms_flow_Integration_SchemaVersion] PRIMARY KEY,
        [Version] NVARCHAR(32) NOT NULL,
        [Description] NVARCHAR(256) NOT NULL,
        [AppliedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_SchemaVersion_AppliedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM [sms_flow].[Integration_SchemaVersion] WHERE [Version] = N'0.2.0')
BEGIN
    INSERT INTO [sms_flow].[Integration_SchemaVersion] ([Version], [Description])
    VALUES (N'0.2.0', N'Initial versioned SMSFlow SQL API schema with installer validation support.');
END
GO

IF OBJECT_ID('[sms_flow].[Integration_OutboxMessage]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow].[Integration_OutboxMessage]
    (
        [Id] BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_sms_flow_Integration_OutboxMessage] PRIMARY KEY,
        [ClientMessageId] NVARCHAR(128) NOT NULL,
        [ReferenceNumber] NVARCHAR(128) NULL,
        [Destination] NVARCHAR(64) NOT NULL,
        [Body] NVARCHAR(1600) NOT NULL,
        [CostCentre] NVARCHAR(128) NULL,
        [Priority] INT NOT NULL CONSTRAINT [DF_sms_flow_Integration_OutboxMessage_Priority] DEFAULT (0),
        [RequestedSendUtc] DATETIME2 NULL,
        [State] NVARCHAR(32) NOT NULL CONSTRAINT [DF_sms_flow_Integration_OutboxMessage_State] DEFAULT ('Queued'),
        [AttemptCount] INT NOT NULL CONSTRAINT [DF_sms_flow_Integration_OutboxMessage_AttemptCount] DEFAULT (0),
        [LastErrorCode] NVARCHAR(64) NULL,
        [LastErrorMessage] NVARCHAR(1000) NULL,
        [LockedUntilUtc] DATETIME2 NULL,
        [NextAttemptUtc] DATETIME2 NULL,
        [CreatedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_OutboxMessage_CreatedUtc] DEFAULT SYSUTCDATETIME(),
        [UpdatedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_OutboxMessage_UpdatedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_sms_flow_Integration_OutboxMessage_ClientMessageId' AND object_id = OBJECT_ID('[sms_flow].[Integration_OutboxMessage]'))
BEGIN
    CREATE UNIQUE INDEX [UX_sms_flow_Integration_OutboxMessage_ClientMessageId]
        ON [sms_flow].[Integration_OutboxMessage]([ClientMessageId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_OutboxMessage_Lease' AND object_id = OBJECT_ID('[sms_flow].[Integration_OutboxMessage]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_OutboxMessage_Lease]
        ON [sms_flow].[Integration_OutboxMessage]([State], [NextAttemptUtc], [RequestedSendUtc], [Priority], [LockedUntilUtc]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_OutboxMessage_Claim' AND object_id = OBJECT_ID('[sms_flow].[Integration_OutboxMessage]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_OutboxMessage_Claim]
        ON [sms_flow].[Integration_OutboxMessage]([State], [Priority] DESC, [RequestedSendUtc], [Id])
        INCLUDE ([NextAttemptUtc], [LockedUntilUtc]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_OutboxMessage_Archive' AND object_id = OBJECT_ID('[sms_flow].[Integration_OutboxMessage]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_OutboxMessage_Archive]
        ON [sms_flow].[Integration_OutboxMessage]([State], [UpdatedUtc], [Id]);
END
GO

IF OBJECT_ID('[sms_flow].[Integration_InboundStatus]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow].[Integration_InboundStatus]
    (
        [Id] BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_sms_flow_Integration_InboundStatus] PRIMARY KEY,
        [EventId] BIGINT NOT NULL,
        [ClientMessageId] NVARCHAR(128) NOT NULL,
        [ReferenceNumber] NVARCHAR(128) NULL,
        [Status] NVARCHAR(64) NOT NULL,
        [RawStatus] NVARCHAR(256) NOT NULL,
        [StatusDateTimeUtc] DATETIME2 NOT NULL,
        [CreatedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_InboundStatus_CreatedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_sms_flow_Integration_InboundStatus_EventId' AND object_id = OBJECT_ID('[sms_flow].[Integration_InboundStatus]'))
BEGIN
    CREATE UNIQUE INDEX [UX_sms_flow_Integration_InboundStatus_EventId]
        ON [sms_flow].[Integration_InboundStatus]([EventId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_InboundStatus_CreatedUtc' AND object_id = OBJECT_ID('[sms_flow].[Integration_InboundStatus]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_InboundStatus_CreatedUtc]
        ON [sms_flow].[Integration_InboundStatus]([CreatedUtc], [Id]);
END
GO

IF OBJECT_ID('[sms_flow].[Integration_InboundReply]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow].[Integration_InboundReply]
    (
        [Id] BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_sms_flow_Integration_InboundReply] PRIMARY KEY,
        [EventId] BIGINT NOT NULL,
        [ClientMessageId] NVARCHAR(128) NOT NULL,
        [ReferenceNumber] NVARCHAR(128) NULL,
        [Reply] NVARCHAR(1600) NOT NULL,
        [ReceivedDateTimeUtc] DATETIME2 NOT NULL,
        [IsOptOut] BIT NOT NULL CONSTRAINT [DF_sms_flow_Integration_InboundReply_IsOptOut] DEFAULT (0),
        [CreatedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_InboundReply_CreatedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_sms_flow_Integration_InboundReply_EventId' AND object_id = OBJECT_ID('[sms_flow].[Integration_InboundReply]'))
BEGIN
    CREATE UNIQUE INDEX [UX_sms_flow_Integration_InboundReply_EventId]
        ON [sms_flow].[Integration_InboundReply]([EventId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_InboundReply_CreatedUtc' AND object_id = OBJECT_ID('[sms_flow].[Integration_InboundReply]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_InboundReply_CreatedUtc]
        ON [sms_flow].[Integration_InboundReply]([CreatedUtc], [Id]);
END
GO

IF OBJECT_ID('[sms_flow].[Integration_RuntimeState]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow].[Integration_RuntimeState]
    (
        [Id] INT NOT NULL CONSTRAINT [PK_sms_flow_Integration_RuntimeState] PRIMARY KEY,
        [LastKnownBalance] DECIMAL(18,2) NOT NULL CONSTRAINT [DF_sms_flow_Integration_RuntimeState_LastKnownBalance] DEFAULT (0),
        [BillingType] NVARCHAR(32) NOT NULL CONSTRAINT [DF_sms_flow_Integration_RuntimeState_BillingType] DEFAULT (''),
        [LastStatusEventId] BIGINT NOT NULL CONSTRAINT [DF_sms_flow_Integration_RuntimeState_LastStatusEventId] DEFAULT (0),
        [LastReplyEventId] BIGINT NOT NULL CONSTRAINT [DF_sms_flow_Integration_RuntimeState_LastReplyEventId] DEFAULT (0),
        [BalanceCheckedUtc] DATETIME2 NULL,
        [LastArchiveStartedUtc] DATETIME2 NULL,
        [LastArchiveSucceededUtc] DATETIME2 NULL,
        [LastArchiveError] NVARCHAR(2000) NULL,
        [LastArchiveArchivedCount] INT NOT NULL CONSTRAINT [DF_sms_flow_Integration_RuntimeState_LastArchiveArchivedCount] DEFAULT (0),
        [LastArchivePurgedCount] INT NOT NULL CONSTRAINT [DF_sms_flow_Integration_RuntimeState_LastArchivePurgedCount] DEFAULT (0),
        [UpdatedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_RuntimeState_UpdatedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF OBJECT_ID('[sms_flow_archive].[Integration_OutboxMessageArchive]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow_archive].[Integration_OutboxMessageArchive]
    (
        [Id] BIGINT NOT NULL CONSTRAINT [PK_sms_flow_Integration_OutboxMessageArchive] PRIMARY KEY,
        [ClientMessageId] NVARCHAR(128) NOT NULL,
        [ReferenceNumber] NVARCHAR(128) NULL,
        [Destination] NVARCHAR(64) NOT NULL,
        [Body] NVARCHAR(1600) NOT NULL,
        [CostCentre] NVARCHAR(128) NULL,
        [Priority] INT NOT NULL,
        [RequestedSendUtc] DATETIME2 NULL,
        [State] NVARCHAR(32) NOT NULL,
        [AttemptCount] INT NOT NULL,
        [LastErrorCode] NVARCHAR(64) NULL,
        [LastErrorMessage] NVARCHAR(1000) NULL,
        [LockedUntilUtc] DATETIME2 NULL,
        [NextAttemptUtc] DATETIME2 NULL,
        [CreatedUtc] DATETIME2 NOT NULL,
        [UpdatedUtc] DATETIME2 NOT NULL,
        [ArchivedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_OutboxMessageArchive_ArchivedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_OutboxMessageArchive_ArchivedUtc' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_OutboxMessageArchive]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_OutboxMessageArchive_ArchivedUtc]
        ON [sms_flow_archive].[Integration_OutboxMessageArchive]([ArchivedUtc], [State], [UpdatedUtc]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_OutboxMessageArchive_Purge' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_OutboxMessageArchive]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_OutboxMessageArchive_Purge]
        ON [sms_flow_archive].[Integration_OutboxMessageArchive]([ArchivedUtc], [Id]);
END
GO

IF OBJECT_ID('[sms_flow_archive].[Integration_InboundStatusArchive]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow_archive].[Integration_InboundStatusArchive]
    (
        [Id] BIGINT NOT NULL CONSTRAINT [PK_sms_flow_Integration_InboundStatusArchive] PRIMARY KEY,
        [EventId] BIGINT NOT NULL,
        [ClientMessageId] NVARCHAR(128) NOT NULL,
        [ReferenceNumber] NVARCHAR(128) NULL,
        [Status] NVARCHAR(64) NOT NULL,
        [RawStatus] NVARCHAR(256) NOT NULL,
        [StatusDateTimeUtc] DATETIME2 NOT NULL,
        [CreatedUtc] DATETIME2 NOT NULL,
        [ArchivedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_InboundStatusArchive_ArchivedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_sms_flow_Integration_InboundStatusArchive_EventId' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_InboundStatusArchive]'))
BEGIN
    CREATE UNIQUE INDEX [UX_sms_flow_Integration_InboundStatusArchive_EventId]
        ON [sms_flow_archive].[Integration_InboundStatusArchive]([EventId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_InboundStatusArchive_ArchivedUtc' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_InboundStatusArchive]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_InboundStatusArchive_ArchivedUtc]
        ON [sms_flow_archive].[Integration_InboundStatusArchive]([ArchivedUtc], [CreatedUtc]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_InboundStatusArchive_Purge' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_InboundStatusArchive]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_InboundStatusArchive_Purge]
        ON [sms_flow_archive].[Integration_InboundStatusArchive]([ArchivedUtc], [Id]);
END
GO

IF OBJECT_ID('[sms_flow_archive].[Integration_InboundReplyArchive]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow_archive].[Integration_InboundReplyArchive]
    (
        [Id] BIGINT NOT NULL CONSTRAINT [PK_sms_flow_Integration_InboundReplyArchive] PRIMARY KEY,
        [EventId] BIGINT NOT NULL,
        [ClientMessageId] NVARCHAR(128) NOT NULL,
        [ReferenceNumber] NVARCHAR(128) NULL,
        [Reply] NVARCHAR(1600) NOT NULL,
        [ReceivedDateTimeUtc] DATETIME2 NOT NULL,
        [IsOptOut] BIT NOT NULL,
        [CreatedUtc] DATETIME2 NOT NULL,
        [ArchivedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_InboundReplyArchive_ArchivedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_sms_flow_Integration_InboundReplyArchive_EventId' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_InboundReplyArchive]'))
BEGIN
    CREATE UNIQUE INDEX [UX_sms_flow_Integration_InboundReplyArchive_EventId]
        ON [sms_flow_archive].[Integration_InboundReplyArchive]([EventId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_InboundReplyArchive_ArchivedUtc' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_InboundReplyArchive]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_InboundReplyArchive_ArchivedUtc]
        ON [sms_flow_archive].[Integration_InboundReplyArchive]([ArchivedUtc], [CreatedUtc]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_InboundReplyArchive_Purge' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_InboundReplyArchive]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_InboundReplyArchive_Purge]
        ON [sms_flow_archive].[Integration_InboundReplyArchive]([ArchivedUtc], [Id]);
END
GO

IF OBJECT_ID('[sms_flow_archive].[Integration_OperationalEventArchive]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow_archive].[Integration_OperationalEventArchive]
    (
        [Id] BIGINT NOT NULL CONSTRAINT [PK_sms_flow_Integration_OperationalEventArchive] PRIMARY KEY,
        [Level] NVARCHAR(32) NOT NULL,
        [Category] NVARCHAR(64) NOT NULL,
        [Code] NVARCHAR(64) NOT NULL,
        [Message] NVARCHAR(2000) NOT NULL,
        [ClientMessageId] NVARCHAR(128) NULL,
        [CreatedUtc] DATETIME2 NOT NULL,
        [ArchivedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_OperationalEventArchive_ArchivedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_OperationalEventArchive_ArchivedUtc' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_OperationalEventArchive]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_OperationalEventArchive_ArchivedUtc]
        ON [sms_flow_archive].[Integration_OperationalEventArchive]([ArchivedUtc], [CreatedUtc]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_OperationalEventArchive_Purge' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_OperationalEventArchive]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_OperationalEventArchive_Purge]
        ON [sms_flow_archive].[Integration_OperationalEventArchive]([ArchivedUtc], [Id]);
END
GO

IF OBJECT_ID('[sms_flow_archive].[Integration_ArchiveLease]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow_archive].[Integration_ArchiveLease]
    (
        [Id] INT NOT NULL CONSTRAINT [PK_sms_flow_Integration_ArchiveLease] PRIMARY KEY,
        [LeaseName] NVARCHAR(128) NOT NULL,
        [LeaseOwnerId] NVARCHAR(256) NOT NULL,
        [LeaseExpiresUtc] DATETIME2 NULL,
        [LastStartedUtc] DATETIME2 NULL,
        [LastFinishedUtc] DATETIME2 NULL
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_sms_flow_Integration_ArchiveLease_LeaseName' AND object_id = OBJECT_ID('[sms_flow_archive].[Integration_ArchiveLease]'))
BEGIN
    CREATE UNIQUE INDEX [UX_sms_flow_Integration_ArchiveLease_LeaseName]
        ON [sms_flow_archive].[Integration_ArchiveLease]([LeaseName]);
END
GO

IF OBJECT_ID('[sms_flow].[Integration_OperationalEvent]', 'U') IS NULL
BEGIN
    CREATE TABLE [sms_flow].[Integration_OperationalEvent]
    (
        [Id] BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT [PK_sms_flow_Integration_OperationalEvent] PRIMARY KEY,
        [Level] NVARCHAR(32) NOT NULL,
        [Category] NVARCHAR(64) NOT NULL,
        [Code] NVARCHAR(64) NOT NULL,
        [Message] NVARCHAR(2000) NOT NULL,
        [ClientMessageId] NVARCHAR(128) NULL,
        [CreatedUtc] DATETIME2 NOT NULL CONSTRAINT [DF_sms_flow_Integration_OperationalEvent_CreatedUtc] DEFAULT SYSUTCDATETIME()
    );
END
GO

IF TYPE_ID(N'[sms_flow].[ClientMessageIdTableType]') IS NULL
BEGIN
    CREATE TYPE [sms_flow].[ClientMessageIdTableType] AS TABLE
    (
        [ClientMessageId] NVARCHAR(128) NOT NULL PRIMARY KEY
    );
END
GO

IF TYPE_ID(N'[sms_flow].[ClientMessageErrorTableType]') IS NULL
BEGIN
    CREATE TYPE [sms_flow].[ClientMessageErrorTableType] AS TABLE
    (
        [ClientMessageId] NVARCHAR(128) NOT NULL PRIMARY KEY,
        [Reason] NVARCHAR(1000) NOT NULL
    );
END
GO

IF TYPE_ID(N'[sms_flow].[StatusEventTableType]') IS NULL
BEGIN
    CREATE TYPE [sms_flow].[StatusEventTableType] AS TABLE
    (
        [EventId] BIGINT NOT NULL PRIMARY KEY,
        [ClientMessageId] NVARCHAR(128) NOT NULL,
        [ReferenceNumber] NVARCHAR(128) NULL,
        [Status] NVARCHAR(64) NOT NULL,
        [RawStatus] NVARCHAR(256) NOT NULL,
        [StatusDateTimeUtc] DATETIME2 NOT NULL
    );
END
GO

IF TYPE_ID(N'[sms_flow].[ReplyEventTableType]') IS NULL
BEGIN
    CREATE TYPE [sms_flow].[ReplyEventTableType] AS TABLE
    (
        [EventId] BIGINT NOT NULL PRIMARY KEY,
        [ClientMessageId] NVARCHAR(128) NOT NULL,
        [ReferenceNumber] NVARCHAR(128) NULL,
        [Reply] NVARCHAR(1600) NOT NULL,
        [ReceivedDateTimeUtc] DATETIME2 NOT NULL,
        [IsOptOut] BIT NOT NULL
    );
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_Claim]
    @Take INT
AS
BEGIN

    -- Claims messages that are ready to be sent, and marks them as 'Leased' so that other processes won't pick them up.

    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();

    -- Find claimable messages and lease them.
    ;WITH claimable AS
    (
        SELECT TOP (@Take) [Id]
        FROM [sms_flow].[Integration_OutboxMessage] WITH (UPDLOCK, READPAST, ROWLOCK)
        WHERE [State] IN ('Queued', 'RetryPending', 'BlockedCredit')
          AND ([NextAttemptUtc] IS NULL OR [NextAttemptUtc] <= @Now)
          AND ([LockedUntilUtc] IS NULL OR [LockedUntilUtc] < @Now)
          AND ([RequestedSendUtc] IS NULL OR [RequestedSendUtc] <= @Now)
        ORDER BY [Priority] DESC, [RequestedSendUtc] ASC, [Id] ASC
    )
    UPDATE target
        SET [State] = 'Leased',
            [AttemptCount] = [AttemptCount] + 1,
            [LockedUntilUtc] = DATEADD(MINUTE, 5, @Now),
            [UpdatedUtc] = @Now
    OUTPUT 
        inserted.[Id], 
        inserted.[ClientMessageId], 
        inserted.[ReferenceNumber], 
        inserted.[Destination], 
        inserted.[Body], 
        inserted.[CostCentre], 
        inserted.[Priority], 
        inserted.[AttemptCount], 
        inserted.[RequestedSendUtc]
    FROM [sms_flow].[Integration_OutboxMessage] target
    INNER JOIN claimable ON claimable.[Id] = target.[Id];
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkSubmitted]
    @ClientMessageId NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [sms_flow].[Integration_OutboxMessage]
    SET [State] = 'Submitted',
        [LockedUntilUtc] = NULL,
        [LastErrorCode] = NULL,
        [LastErrorMessage] = NULL,
        [UpdatedUtc] = SYSUTCDATETIME()
    WHERE [ClientMessageId] = @ClientMessageId;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkBlockedCredit]
    @ClientMessageId NVARCHAR(128),
    @Reason NVARCHAR(1000),
    @DelaySeconds INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Whoops, we've run out of credits, wait a bit before we try again.
    DECLARE @Now DATETIME2 = SYSUTCDATETIME();

    UPDATE [sms_flow].[Integration_OutboxMessage]
    SET [State] = 'BlockedCredit',
        [LockedUntilUtc] = NULL,
        [NextAttemptUtc] = DATEADD(SECOND, @DelaySeconds, @Now),
        [LastErrorCode] = 'INSUFFICIENT_CREDITS',
        [LastErrorMessage] = @Reason,
        [UpdatedUtc] = @Now
    WHERE [ClientMessageId] = @ClientMessageId;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkFailedValidation]
    @ClientMessageId NVARCHAR(128),
    @Reason NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [sms_flow].[Integration_OutboxMessage]
    SET [State] = 'FailedValidation',
        [LockedUntilUtc] = NULL,
        [LastErrorCode] = 'VALIDATION',
        [LastErrorMessage] = @Reason,
        [UpdatedUtc] = SYSUTCDATETIME()
    WHERE [ClientMessageId] = @ClientMessageId;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkFailedPermanent]
    @ClientMessageId NVARCHAR(128),
    @Reason NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [sms_flow].[Integration_OutboxMessage]
    SET [State] = 'FailedPermanent',
        [LockedUntilUtc] = NULL,
        [LastErrorCode] = 'PERMANENT',
        [LastErrorMessage] = @Reason,
        [UpdatedUtc] = SYSUTCDATETIME()
    WHERE [ClientMessageId] = @ClientMessageId;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkRetry]
    @ClientMessageId NVARCHAR(128),
    @Reason NVARCHAR(1000),
    @DelaySeconds INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();
    -- Something went wrong we may be able to recover from with a retry.
    -- Wait a bit and try again.
    UPDATE [sms_flow].[Integration_OutboxMessage]
    SET [State] = 'RetryPending',
        [LockedUntilUtc] = NULL,
        [NextAttemptUtc] = DATEADD(SECOND, @DelaySeconds, @Now),
        [LastErrorCode] = 'TRANSIENT',
        [LastErrorMessage] = @Reason,
        [UpdatedUtc] = @Now
    WHERE [ClientMessageId] = @ClientMessageId;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkSubmittedBatch]
    @Items [sms_flow].[ClientMessageIdTableType] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE target
    SET [State] = 'Submitted',
        [LockedUntilUtc] = NULL,
        [LastErrorCode] = NULL,
        [LastErrorMessage] = NULL,
        [UpdatedUtc] = SYSUTCDATETIME()
    FROM [sms_flow].[Integration_OutboxMessage] target
    INNER JOIN @Items items ON items.[ClientMessageId] = target.[ClientMessageId];
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkBlockedCreditBatch]
    @Items [sms_flow].[ClientMessageIdTableType] READONLY,
    @Reason NVARCHAR(1000),
    @DelaySeconds INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();

    UPDATE target
    SET [State] = 'BlockedCredit',
        [LockedUntilUtc] = NULL,
        [NextAttemptUtc] = DATEADD(SECOND, @DelaySeconds, @Now),
        [LastErrorCode] = 'INSUFFICIENT_CREDITS',
        [LastErrorMessage] = @Reason,
        [UpdatedUtc] = @Now
    FROM [sms_flow].[Integration_OutboxMessage] target
    INNER JOIN @Items items ON items.[ClientMessageId] = target.[ClientMessageId];
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkFailedPermanentBatch]
    @Items [sms_flow].[ClientMessageErrorTableType] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE target
    SET [State] = 'FailedPermanent',
        [LockedUntilUtc] = NULL,
        [LastErrorCode] = 'PERMANENT',
        [LastErrorMessage] = items.[Reason],
        [UpdatedUtc] = SYSUTCDATETIME()
    FROM [sms_flow].[Integration_OutboxMessage] target
    INNER JOIN @Items items ON items.[ClientMessageId] = target.[ClientMessageId];
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Outbox_MarkRetryBatch]
    @Items [sms_flow].[ClientMessageIdTableType] READONLY,
    @Reason NVARCHAR(1000),
    @DelaySeconds INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();

    UPDATE target
    SET [State] = 'RetryPending',
        [LockedUntilUtc] = NULL,
        [NextAttemptUtc] = DATEADD(SECOND, @DelaySeconds, @Now),
        [LastErrorCode] = 'TRANSIENT',
        [LastErrorMessage] = @Reason,
        [UpdatedUtc] = @Now
    FROM [sms_flow].[Integration_OutboxMessage] target
    INNER JOIN @Items items ON items.[ClientMessageId] = target.[ClientMessageId];
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[RuntimeState_Get]
AS
BEGIN
    SET NOCOUNT ON;
    -- This table is a singleton, so only select the single row in it.
    SELECT TOP (1)
        [LastKnownBalance],
        [BillingType],
        [LastStatusEventId],
        [LastReplyEventId],
        [BalanceCheckedUtc],
        [LastArchiveStartedUtc],
        [LastArchiveSucceededUtc],
        [LastArchiveError],
        [LastArchiveArchivedCount],
        [LastArchivePurgedCount]
    FROM [sms_flow].[Integration_RuntimeState]
    WHERE [Id] = 1;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[RuntimeState_Upsert]
    @LastKnownBalance DECIMAL(18,2),
    @BillingType NVARCHAR(32),
    @LastStatusEventId BIGINT,
    @LastReplyEventId BIGINT,
    @BalanceCheckedUtc DATETIME2 = NULL,
    @LastArchiveStartedUtc DATETIME2 = NULL,
    @LastArchiveSucceededUtc DATETIME2 = NULL,
    @LastArchiveError NVARCHAR(2000) = NULL,
    @LastArchiveArchivedCount INT = 0,
    @LastArchivePurgedCount INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    MERGE [sms_flow].[Integration_RuntimeState] AS target
    USING (SELECT 1 AS [Id]) AS source
    ON target.[Id] = source.[Id]
    WHEN MATCHED THEN
        UPDATE SET
            [LastKnownBalance] = @LastKnownBalance,
            [BillingType] = @BillingType,
            [LastStatusEventId] = @LastStatusEventId,
            [LastReplyEventId] = @LastReplyEventId,
            [BalanceCheckedUtc] = @BalanceCheckedUtc,
            [LastArchiveStartedUtc] = @LastArchiveStartedUtc,
            [LastArchiveSucceededUtc] = @LastArchiveSucceededUtc,
            [LastArchiveError] = @LastArchiveError,
            [LastArchiveArchivedCount] = @LastArchiveArchivedCount,
            [LastArchivePurgedCount] = @LastArchivePurgedCount,
            [UpdatedUtc] = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT ([Id], [LastKnownBalance], [BillingType], [LastStatusEventId], [LastReplyEventId], [BalanceCheckedUtc], [LastArchiveStartedUtc], [LastArchiveSucceededUtc], [LastArchiveError], [LastArchiveArchivedCount], [LastArchivePurgedCount], [UpdatedUtc])
        VALUES (1, @LastKnownBalance, @BillingType, @LastStatusEventId, @LastReplyEventId, @BalanceCheckedUtc, @LastArchiveStartedUtc, @LastArchiveSucceededUtc, @LastArchiveError, @LastArchiveArchivedCount, @LastArchivePurgedCount, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sms_flow_Integration_OperationalEvent_CreatedUtc' AND object_id = OBJECT_ID('[sms_flow].[Integration_OperationalEvent]'))
BEGIN
    CREATE INDEX [IX_sms_flow_Integration_OperationalEvent_CreatedUtc]
        ON [sms_flow].[Integration_OperationalEvent]([CreatedUtc], [Id]);
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Status_Upsert]
    @EventId BIGINT,
    @ClientMessageId NVARCHAR(128),
    @ReferenceNumber NVARCHAR(128) = NULL,
    @Status NVARCHAR(64),
    @RawStatus NVARCHAR(256),
    @StatusDateTimeUtc DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [sms_flow].[Integration_InboundStatus] WHERE [EventId] = @EventId)
    BEGIN
        INSERT INTO [sms_flow].[Integration_InboundStatus]
        (
            [EventId],
            [ClientMessageId],
            [ReferenceNumber],
            [Status],
            [RawStatus],
            [StatusDateTimeUtc]
        )
        VALUES
        (
            @EventId,
            @ClientMessageId,
            @ReferenceNumber,
            @Status,
            @RawStatus,
            @StatusDateTimeUtc
        );
    END
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Status_UpsertBatch]
    @Items [sms_flow].[StatusEventTableType] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [sms_flow].[Integration_InboundStatus]
    (
        [EventId],
        [ClientMessageId],
        [ReferenceNumber],
        [Status],
        [RawStatus],
        [StatusDateTimeUtc]
    )
    SELECT
        items.[EventId],
        items.[ClientMessageId],
        items.[ReferenceNumber],
        items.[Status],
        items.[RawStatus],
        items.[StatusDateTimeUtc]
    FROM @Items items
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [sms_flow].[Integration_InboundStatus] existing WITH (UPDLOCK, HOLDLOCK)
        WHERE existing.[EventId] = items.[EventId]
    );
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Reply_Upsert]
    @EventId BIGINT,
    @ClientMessageId NVARCHAR(128),
    @ReferenceNumber NVARCHAR(128) = NULL,
    @Reply NVARCHAR(1600),
    @ReceivedDateTimeUtc DATETIME2,
    @IsOptOut BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [sms_flow].[Integration_InboundReply] WHERE [EventId] = @EventId)
    BEGIN
        INSERT INTO [sms_flow].[Integration_InboundReply]
        (
            [EventId],
            [ClientMessageId],
            [ReferenceNumber],
            [Reply],
            [ReceivedDateTimeUtc],
            [IsOptOut]
        )
        VALUES
        (
            @EventId,
            @ClientMessageId,
            @ReferenceNumber,
            @Reply,
            @ReceivedDateTimeUtc,
            @IsOptOut
        );
    END
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Reply_UpsertBatch]
    @Items [sms_flow].[ReplyEventTableType] READONLY
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [sms_flow].[Integration_InboundReply]
    (
        [EventId],
        [ClientMessageId],
        [ReferenceNumber],
        [Reply],
        [ReceivedDateTimeUtc],
        [IsOptOut]
    )
    SELECT
        items.[EventId],
        items.[ClientMessageId],
        items.[ReferenceNumber],
        items.[Reply],
        items.[ReceivedDateTimeUtc],
        items.[IsOptOut]
    FROM @Items items
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM [sms_flow].[Integration_InboundReply] existing WITH (UPDLOCK, HOLDLOCK)
        WHERE existing.[EventId] = items.[EventId]
    );
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[OperationalEvent_Add]
    @Level NVARCHAR(32),
    @Category NVARCHAR(64),
    @Code NVARCHAR(64),
    @Message NVARCHAR(2000),
    @ClientMessageId NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [sms_flow].[Integration_OperationalEvent]
    (
        [Level],
        [Category],
        [Code],
        [Message],
        [ClientMessageId]
    )
    VALUES
    (
        @Level,
        @Category,
        @Code,
        @Message,
        @ClientMessageId
    );
END
GO

CREATE OR ALTER PROCEDURE [sms_flow_archive].[Archive_Run]
    @LeaseOwnerId NVARCHAR(256),
    @LeaseDurationSeconds INT,
    @BatchSize INT,
    @OutboxRetentionDays INT,
    @InboundRetentionDays INT,
    @OperationalEventRetentionDays INT,
    @ArchiveRetentionDays INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();
    DECLARE @LeaseName NVARCHAR(128) = N'archive';
    DECLARE @ArchivedCount INT = 0;
    DECLARE @PurgedCount INT = 0;
    DECLARE @OutboxArchiveBeforeUtc DATETIME2 = DATEADD(DAY, -@OutboxRetentionDays, @Now);
    DECLARE @InboundArchiveBeforeUtc DATETIME2 = DATEADD(DAY, -@InboundRetentionDays, @Now);
    DECLARE @OperationalArchiveBeforeUtc DATETIME2 = DATEADD(DAY, -@OperationalEventRetentionDays, @Now);
    DECLARE @PurgeArchiveBeforeUtc DATETIME2 = DATEADD(DAY, -@ArchiveRetentionDays, @Now);

    BEGIN TRY
        BEGIN TRANSACTION;
        -------------------------------------------------------------------------------------------------
        -- Acquire a archive lease for this instance
        -- Only one instance can acquire the lease at a time, and the lease will automatically expire after a configured duration 
        -- to allow other instances to take over if the current holder fails
        -- We try to update an existing lease row first, otherwise create one.
        -------------------------------------------------------------------------------------------------
        UPDATE [sms_flow_archive].[Integration_ArchiveLease]
        SET [LeaseOwnerId] = @LeaseOwnerId,
            [LeaseExpiresUtc] = DATEADD(SECOND, @LeaseDurationSeconds, @Now),
            [LastStartedUtc] = @Now
        WHERE [LeaseName] = @LeaseName
          AND ([LeaseExpiresUtc] IS NULL OR [LeaseExpiresUtc] < @Now OR [LeaseOwnerId] = @LeaseOwnerId);

        IF @@ROWCOUNT = 0
        BEGIN
            BEGIN TRY
                INSERT INTO [sms_flow_archive].[Integration_ArchiveLease]
                (
                    [Id],
                    [LeaseName],
                    [LeaseOwnerId],
                    [LeaseExpiresUtc],
                    [LastStartedUtc],
                    [LastFinishedUtc]
                )
                VALUES
                (
                    1,
                    @LeaseName,
                    @LeaseOwnerId,
                    DATEADD(SECOND, @LeaseDurationSeconds, @Now),
                    @Now,
                    NULL
                );
            END TRY
            BEGIN CATCH
                IF ERROR_NUMBER() NOT IN (2601, 2627) -- Ignore unique constraint violations
                BEGIN
                    THROW;
                END
            END CATCH;
        END

        -- Check the lease hit and fail if not.
        IF NOT EXISTS
        (
            SELECT 1
            FROM [sms_flow_archive].[Integration_ArchiveLease]
            WHERE [LeaseName] = @LeaseName
              AND [LeaseOwnerId] = @LeaseOwnerId
              AND ([LeaseExpiresUtc] IS NULL OR [LeaseExpiresUtc] >= @Now)
        )
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN;
        END

     -------------------------------------------------------------------------------------------------
     -- Record this archive run in the runtime state
     -------------------------------------------------------------------------------------------------
        MERGE [sms_flow].[Integration_RuntimeState] AS target
        USING (SELECT 1 AS [Id]) AS source
        ON target.[Id] = source.[Id]
        WHEN MATCHED THEN
            UPDATE SET
                [LastArchiveStartedUtc] = @Now,
                [LastArchiveError] = NULL,
                [UpdatedUtc] = @Now
        WHEN NOT MATCHED THEN
            INSERT ([Id], [LastKnownBalance], [BillingType], [LastStatusEventId], [LastReplyEventId], [BalanceCheckedUtc], [LastArchiveStartedUtc], [LastArchiveSucceededUtc], [LastArchiveError], [LastArchiveArchivedCount], [LastArchivePurgedCount], [UpdatedUtc])
            VALUES (1, 0, N'', 0, 0, NULL, @Now, NULL, NULL, 0, 0, @Now);

        DECLARE @OutboxToArchive TABLE ([Id] BIGINT PRIMARY KEY);
        DECLARE @StatusToArchive TABLE ([Id] BIGINT PRIMARY KEY);
        DECLARE @ReplyToArchive TABLE ([Id] BIGINT PRIMARY KEY);
        DECLARE @OperationalToArchive TABLE ([Id] BIGINT PRIMARY KEY);
        DECLARE @OutboxToPurge TABLE ([Id] BIGINT PRIMARY KEY);
        DECLARE @StatusToPurge TABLE ([Id] BIGINT PRIMARY KEY);
        DECLARE @ReplyToPurge TABLE ([Id] BIGINT PRIMARY KEY);
        DECLARE @OperationalToPurge TABLE ([Id] BIGINT PRIMARY KEY);

        
        -------------------------------------------------------------------------------------------------
        -- Archive outbox messages
        -------------------------------------------------------------------------------------------------

        INSERT INTO @OutboxToArchive ([Id])
        SELECT TOP (@BatchSize) [Id]
        FROM [sms_flow].[Integration_OutboxMessage]
        WHERE [State] IN (N'Submitted', N'FailedValidation', N'FailedPermanent')
          AND [UpdatedUtc] <= @OutboxArchiveBeforeUtc
        ORDER BY [UpdatedUtc], [Id];

        INSERT INTO [sms_flow_archive].[Integration_OutboxMessageArchive]
        (
            [Id], [ClientMessageId], [ReferenceNumber], [Destination], [Body], [CostCentre], [Priority], [RequestedSendUtc],
            [State], [AttemptCount], [LastErrorCode], [LastErrorMessage],
            [LockedUntilUtc], [NextAttemptUtc], [CreatedUtc], [UpdatedUtc], [ArchivedUtc]
        )
        SELECT
            source.[Id], source.[ClientMessageId], source.[ReferenceNumber], source.[Destination], source.[Body], source.[CostCentre], source.[Priority], source.[RequestedSendUtc],
            source.[State], source.[AttemptCount], source.[LastErrorCode], source.[LastErrorMessage],
            source.[LockedUntilUtc], source.[NextAttemptUtc], source.[CreatedUtc], source.[UpdatedUtc], @Now
        FROM [sms_flow].[Integration_OutboxMessage] source
        INNER JOIN @OutboxToArchive selection ON selection.[Id] = source.[Id]
        WHERE NOT EXISTS (SELECT 1 FROM [sms_flow_archive].[Integration_OutboxMessageArchive] archive WHERE archive.[Id] = source.[Id]);

        DELETE target
        FROM [sms_flow].[Integration_OutboxMessage] target
        INNER JOIN @OutboxToArchive selection ON selection.[Id] = target.[Id];
        SET @ArchivedCount += @@ROWCOUNT;

        -------------------------------------------------------------------------------------------------
        -- Archive statuses
        -------------------------------------------------------------------------------------------------
        INSERT INTO @StatusToArchive ([Id])
        SELECT TOP (@BatchSize) [Id]
        FROM [sms_flow].[Integration_InboundStatus]
        WHERE [CreatedUtc] <= @InboundArchiveBeforeUtc
        ORDER BY [CreatedUtc], [Id];

        INSERT INTO [sms_flow_archive].[Integration_InboundStatusArchive]
        (
            [Id], [EventId], [ClientMessageId], [ReferenceNumber], [Status], [RawStatus], [StatusDateTimeUtc], [CreatedUtc], [ArchivedUtc]
        )
        SELECT
            source.[Id], source.[EventId], source.[ClientMessageId], source.[ReferenceNumber], source.[Status], source.[RawStatus], source.[StatusDateTimeUtc], source.[CreatedUtc], @Now
        FROM [sms_flow].[Integration_InboundStatus] source
        INNER JOIN @StatusToArchive selection ON selection.[Id] = source.[Id]
        WHERE NOT EXISTS (SELECT 1 FROM [sms_flow_archive].[Integration_InboundStatusArchive] archive WHERE archive.[Id] = source.[Id]);

        DELETE target
        FROM [sms_flow].[Integration_InboundStatus] target
        INNER JOIN @StatusToArchive selection ON selection.[Id] = target.[Id];
        SET @ArchivedCount += @@ROWCOUNT;

        -------------------------------------------------------------------------------------------------
        -- Archive replies
        -------------------------------------------------------------------------------------------------
        INSERT INTO @ReplyToArchive ([Id])
        SELECT TOP (@BatchSize) [Id]
        FROM [sms_flow].[Integration_InboundReply]
        WHERE [CreatedUtc] <= @InboundArchiveBeforeUtc
        ORDER BY [CreatedUtc], [Id];

        INSERT INTO [sms_flow_archive].[Integration_InboundReplyArchive]
        (
            [Id], [EventId], [ClientMessageId], [ReferenceNumber], [Reply], [ReceivedDateTimeUtc], [IsOptOut], [CreatedUtc], [ArchivedUtc]
        )
        SELECT
            source.[Id], source.[EventId], source.[ClientMessageId], source.[ReferenceNumber], source.[Reply], source.[ReceivedDateTimeUtc], source.[IsOptOut], source.[CreatedUtc], @Now
        FROM [sms_flow].[Integration_InboundReply] source
        INNER JOIN @ReplyToArchive selection ON selection.[Id] = source.[Id]
        WHERE NOT EXISTS (SELECT 1 FROM [sms_flow_archive].[Integration_InboundReplyArchive] archive WHERE archive.[Id] = source.[Id]);

        DELETE target
        FROM [sms_flow].[Integration_InboundReply] target
        INNER JOIN @ReplyToArchive selection ON selection.[Id] = target.[Id];
        SET @ArchivedCount += @@ROWCOUNT;

        -------------------------------------------------------------------------------------------------
        -- Archive operational events
        -------------------------------------------------------------------------------------------------
        INSERT INTO @OperationalToArchive ([Id])
        SELECT TOP (@BatchSize) [Id]
        FROM [sms_flow].[Integration_OperationalEvent]
        WHERE [CreatedUtc] <= @OperationalArchiveBeforeUtc
        ORDER BY [CreatedUtc], [Id];

        INSERT INTO [sms_flow_archive].[Integration_OperationalEventArchive]
        (
            [Id], [Level], [Category], [Code], [Message], [ClientMessageId], [CreatedUtc], [ArchivedUtc]
        )
        SELECT
            source.[Id], source.[Level], source.[Category], source.[Code], source.[Message], source.[ClientMessageId], source.[CreatedUtc], @Now
        FROM [sms_flow].[Integration_OperationalEvent] source
        INNER JOIN @OperationalToArchive selection ON selection.[Id] = source.[Id]
        WHERE NOT EXISTS (SELECT 1 FROM [sms_flow_archive].[Integration_OperationalEventArchive] archive WHERE archive.[Id] = source.[Id]);

        DELETE target
        FROM [sms_flow].[Integration_OperationalEvent] target
        INNER JOIN @OperationalToArchive selection ON selection.[Id] = target.[Id];
        SET @ArchivedCount += @@ROWCOUNT;

        -------------------------------------------------------------------------------------------------
        -- Purge outbox messages
        -------------------------------------------------------------------------------------------------
        INSERT INTO @OutboxToPurge ([Id])
        SELECT TOP (@BatchSize) [Id]
        FROM [sms_flow_archive].[Integration_OutboxMessageArchive]
        WHERE [ArchivedUtc] <= @PurgeArchiveBeforeUtc
        ORDER BY [ArchivedUtc], [Id];

        DELETE target
        FROM [sms_flow_archive].[Integration_OutboxMessageArchive] target
        INNER JOIN @OutboxToPurge selection ON selection.[Id] = target.[Id];
        SET @PurgedCount += @@ROWCOUNT;

        -------------------------------------------------------------------------------------------------
        -- Purge statuses
        -------------------------------------------------------------------------------------------------
        INSERT INTO @StatusToPurge ([Id])
        SELECT TOP (@BatchSize) [Id]
        FROM [sms_flow_archive].[Integration_InboundStatusArchive]
        WHERE [ArchivedUtc] <= @PurgeArchiveBeforeUtc
        ORDER BY [ArchivedUtc], [Id];

        DELETE target
        FROM [sms_flow_archive].[Integration_InboundStatusArchive] target
        INNER JOIN @StatusToPurge selection ON selection.[Id] = target.[Id];
        SET @PurgedCount += @@ROWCOUNT;

        -------------------------------------------------------------------------------------------------
        -- Purge replies
        -------------------------------------------------------------------------------------------------
        INSERT INTO @ReplyToPurge ([Id])
        SELECT TOP (@BatchSize) [Id]
        FROM [sms_flow_archive].[Integration_InboundReplyArchive]
        WHERE [ArchivedUtc] <= @PurgeArchiveBeforeUtc
        ORDER BY [ArchivedUtc], [Id];

        DELETE target
        FROM [sms_flow_archive].[Integration_InboundReplyArchive] target
        INNER JOIN @ReplyToPurge selection ON selection.[Id] = target.[Id];
        SET @PurgedCount += @@ROWCOUNT;

        -------------------------------------------------------------------------------------------------
        -- Purge operational events
        -------------------------------------------------------------------------------------------------
        INSERT INTO @OperationalToPurge ([Id])
        SELECT TOP (@BatchSize) [Id]
        FROM [sms_flow_archive].[Integration_OperationalEventArchive]
        WHERE [ArchivedUtc] <= @PurgeArchiveBeforeUtc
        ORDER BY [ArchivedUtc], [Id];

        DELETE target
        FROM [sms_flow_archive].[Integration_OperationalEventArchive] target
        INNER JOIN @OperationalToPurge selection ON selection.[Id] = target.[Id];
        SET @PurgedCount += @@ROWCOUNT;

        -------------------------------------------------------------------------------------------------
        -- Update the runtime state with the result
        -------------------------------------------------------------------------------------------------
        UPDATE [sms_flow].[Integration_RuntimeState]
        SET [LastArchiveSucceededUtc] = @Now,
            [LastArchiveError] = NULL,
            [LastArchiveArchivedCount] = @ArchivedCount,
            [LastArchivePurgedCount] = @PurgedCount,
            [UpdatedUtc] = @Now
        WHERE [Id] = 1;

        -------------------------------------------------------------------------------------------------
        -- Release the lease
        -------------------------------------------------------------------------------------------------
        UPDATE [sms_flow_archive].[Integration_ArchiveLease]
        SET [LeaseExpiresUtc] = @Now,
            [LastFinishedUtc] = @Now
        WHERE [LeaseName] = @LeaseName
          AND [LeaseOwnerId] = @LeaseOwnerId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(2000) = ERROR_MESSAGE();

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        MERGE [sms_flow].[Integration_RuntimeState] AS target
        USING (SELECT 1 AS [Id]) AS source
        ON target.[Id] = source.[Id]
        WHEN MATCHED THEN
            UPDATE SET
                [LastArchiveError] = @ErrorMessage,
                [UpdatedUtc] = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
            INSERT ([Id], [LastKnownBalance], [BillingType], [LastStatusEventId], [LastReplyEventId], [BalanceCheckedUtc], [LastArchiveStartedUtc], [LastArchiveSucceededUtc], [LastArchiveError], [LastArchiveArchivedCount], [LastArchivePurgedCount], [UpdatedUtc])
            VALUES (1, 0, N'', 0, 0, NULL, NULL, NULL, @ErrorMessage, 0, 0, SYSUTCDATETIME());

        UPDATE [sms_flow_archive].[Integration_ArchiveLease]
        SET [LeaseExpiresUtc] = SYSUTCDATETIME(),
            [LastFinishedUtc] = SYSUTCDATETIME()
        WHERE [LeaseName] = @LeaseName
          AND [LeaseOwnerId] = @LeaseOwnerId;

        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Health_Get]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT TOP (1) [Version] FROM [sms_flow].[Integration_SchemaVersion] ORDER BY [AppliedUtc] DESC, [Id] DESC) AS [SchemaVersion],
        rs.[LastKnownBalance],
        rs.[BillingType],
        rs.[LastStatusEventId],
        rs.[LastReplyEventId],
        rs.[BalanceCheckedUtc],
        rs.[LastArchiveStartedUtc],
        rs.[LastArchiveSucceededUtc],
        rs.[LastArchiveError],
        rs.[LastArchiveArchivedCount],
        rs.[LastArchivePurgedCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] IN ('Queued', 'RetryPending', 'BlockedCredit', 'Leased')) AS [PendingCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'FailedValidation') AS [FailedValidationCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'FailedPermanent') AS [FailedPermanentCount],
        (SELECT MIN([UpdatedUtc]) FROM [sms_flow].[Integration_OutboxMessage]) AS [OldestUnarchivedOutboxUtc],
        (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_InboundStatus]) AS [OldestUnarchivedStatusUtc],
        (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_InboundReply]) AS [OldestUnarchivedReplyUtc],
        (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_OperationalEvent]) AS [OldestUnarchivedOperationalEventUtc],
        (SELECT MAX([CreatedUtc]) FROM [sms_flow].[Integration_OperationalEvent]) AS [LastOperationalEventUtc]
    FROM [sms_flow].[Integration_RuntimeState] rs
    WHERE rs.[Id] = 1;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[SchemaVersion_Get]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1)
        [Version],
        [Description],
        [AppliedUtc]
    FROM [sms_flow].[Integration_SchemaVersion]
    ORDER BY [AppliedUtc] DESC, [Id] DESC;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Dashboard_Snapshot_Get]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = SYSUTCDATETIME();

    SELECT
        @Now AS [SnapshotUtc],
        rs.[LastKnownBalance],
        rs.[BillingType],
        rs.[LastStatusEventId],
        rs.[LastReplyEventId],
        rs.[BalanceCheckedUtc],
        rs.[LastArchiveStartedUtc],
        rs.[LastArchiveSucceededUtc],
        rs.[LastArchiveError],
        rs.[LastArchiveArchivedCount],
        rs.[LastArchivePurgedCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] IN ('Queued', 'RetryPending', 'BlockedCredit', 'Leased')) AS [PendingCount],
        (SELECT COUNT(1)
         FROM [sms_flow].[Integration_OutboxMessage]
         WHERE [State] IN ('Queued', 'RetryPending', 'BlockedCredit')
           AND ([NextAttemptUtc] IS NULL OR [NextAttemptUtc] <= @Now)
           AND ([LockedUntilUtc] IS NULL OR [LockedUntilUtc] < @Now)
           AND ([RequestedSendUtc] IS NULL OR [RequestedSendUtc] <= @Now)) AS [ReadyCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'BlockedCredit') AS [BlockedCreditCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'RetryPending') AS [RetryPendingCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'FailedPermanent') AS [FailedPermanentCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'FailedValidation') AS [FailedValidationCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'Leased') AS [LeasedCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'Submitted' AND [UpdatedUtc] >= DATEADD(SECOND, -60, @Now)) AS [SubmittedLastMinuteCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_InboundStatus] WHERE [CreatedUtc] >= DATEADD(SECOND, -60, @Now)) AS [StatusLastMinuteCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_InboundReply] WHERE [CreatedUtc] >= DATEADD(SECOND, -60, @Now)) AS [ReplyLastMinuteCount],
        (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] IN ('FailedValidation', 'FailedPermanent') AND [UpdatedUtc] >= DATEADD(SECOND, -60, @Now)) AS [FailureLastMinuteCount],
        (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] IN ('Queued', 'RetryPending', 'BlockedCredit', 'Leased')) AS [OldestPendingMessageUtc],
        (SELECT MIN([UpdatedUtc]) FROM [sms_flow].[Integration_OutboxMessage]) AS [OldestUnarchivedOutboxUtc],
        (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_InboundStatus]) AS [OldestUnarchivedStatusUtc],
        (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_InboundReply]) AS [OldestUnarchivedReplyUtc],
        (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_OperationalEvent]) AS [OldestUnarchivedOperationalEventUtc],
        latest.[CreatedUtc] AS [LastOperationalEventUtc],
        COALESCE(latest.[Level], '') AS [LastOperationalEventLevel],
        COALESCE(latest.[Code], '') AS [LastOperationalEventCode],
        COALESCE(latest.[Message], '') AS [LastOperationalEventMessage]
    FROM [sms_flow].[Integration_RuntimeState] rs
    OUTER APPLY
    (
        SELECT TOP (1)
            [Level],
            [Code],
            [Message],
            [CreatedUtc]
        FROM [sms_flow].[Integration_OperationalEvent]
        ORDER BY [CreatedUtc] DESC, [Id] DESC
    ) latest
    WHERE rs.[Id] = 1;
END
GO
CREATE OR ALTER PROCEDURE [sms_flow].[Queue_Summary_Get]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [State], COUNT(1) AS [MessageCount]
    FROM [sms_flow].[Integration_OutboxMessage]
    GROUP BY [State]
    ORDER BY [State];
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Failures_List]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (200)
        [Id],
        [ClientMessageId],
        [ReferenceNumber],
        [State],
        [AttemptCount],
        [LastErrorCode],
        [LastErrorMessage],
        [UpdatedUtc]
    FROM [sms_flow].[Integration_OutboxMessage]
    WHERE [State] IN ('FailedValidation', 'FailedPermanent', 'BlockedCredit', 'RetryPending')
    ORDER BY [UpdatedUtc] DESC, [Id] DESC;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[Message_GetByClientMessageId]
    @ClientMessageId NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1) *
    FROM [sms_flow].[Integration_OutboxMessage]
    WHERE [ClientMessageId] = @ClientMessageId;
END
GO

CREATE OR ALTER PROCEDURE [sms_flow].[OperationalEvent_List]
    @Take INT = 200,
    @BeforeId BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EffectiveTake INT = CASE
        WHEN @Take IS NULL OR @Take < 1 THEN 1
        WHEN @Take > 500 THEN 500
        ELSE @Take
    END;

    SELECT TOP (@EffectiveTake)
        [Id],
        [Level],
        [Category],
        [Code],
        [Message],
        [ClientMessageId],
        [CreatedUtc]
    FROM [sms_flow].[Integration_OperationalEvent]
    WHERE (@BeforeId IS NULL OR [Id] < @BeforeId)
    ORDER BY [CreatedUtc] DESC, [Id] DESC;
END
GO
CREATE OR ALTER VIEW [sms_flow].[vw_Messages]
AS
SELECT
    m.[Id],
    m.[ClientMessageId],
    m.[ReferenceNumber],
    m.[Destination],
    m.[Body],
    m.[CostCentre],
    m.[Priority],
    m.[RequestedSendUtc],
    m.[State],
    m.[AttemptCount],
    m.[LastErrorCode],
    m.[LastErrorMessage],
    m.[LockedUntilUtc],
    m.[NextAttemptUtc],
    m.[CreatedUtc],
    m.[UpdatedUtc],
    CASE
        WHEN m.[State] IN ('Queued', 'RetryPending', 'BlockedCredit')
             AND (m.[NextAttemptUtc] IS NULL OR m.[NextAttemptUtc] <= SYSUTCDATETIME())
             AND (m.[LockedUntilUtc] IS NULL OR m.[LockedUntilUtc] < SYSUTCDATETIME())
             AND (m.[RequestedSendUtc] IS NULL OR m.[RequestedSendUtc] <= SYSUTCDATETIME())
            THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS [IsReadyToProcess],
    COALESCE(m.[NextAttemptUtc], m.[RequestedSendUtc], m.[CreatedUtc]) AS [NextProcessingUtc]
FROM [sms_flow].[Integration_OutboxMessage] m;
GO

CREATE OR ALTER VIEW [sms_flow].[vw_Attention]
AS
SELECT
    m.[Id],
    m.[ClientMessageId],
    m.[ReferenceNumber],
    m.[Destination],
    m.[State],
    m.[AttemptCount],
    m.[LastErrorCode],
    m.[LastErrorMessage],
    m.[RequestedSendUtc],
    m.[NextAttemptUtc],
    m.[LockedUntilUtc],
    m.[UpdatedUtc],
    CASE
        WHEN m.[State] = 'FailedValidation' THEN 'Fix message data'
        WHEN m.[State] = 'FailedPermanent' THEN 'Review permanent send failure'
        WHEN m.[State] = 'BlockedCredit' THEN 'Add credits or wait for retry'
        WHEN m.[State] = 'RetryPending' THEN 'Waiting for automatic retry'
        WHEN m.[State] = 'Leased' THEN 'Currently being processed'
        ELSE 'Review'
    END AS [SuggestedAction]
FROM [sms_flow].[Integration_OutboxMessage] m
WHERE m.[State] IN ('FailedValidation', 'FailedPermanent', 'BlockedCredit', 'RetryPending', 'Leased');
GO

CREATE OR ALTER VIEW [sms_flow].[vw_InboundActivity]
AS
SELECT
    'Status' AS [ActivityType],
    s.[EventId],
    s.[ClientMessageId],
    s.[ReferenceNumber],
    s.[Status] AS [Summary],
    s.[RawStatus] AS [Detail],
    s.[StatusDateTimeUtc] AS [ActivityUtc],
    s.[CreatedUtc]
FROM [sms_flow].[Integration_InboundStatus] s
UNION ALL
SELECT
    'Reply' AS [ActivityType],
    r.[EventId],
    r.[ClientMessageId],
    r.[ReferenceNumber],
    CASE WHEN r.[IsOptOut] = 1 THEN 'OPT_OUT' ELSE 'REPLY' END AS [Summary],
    r.[Reply] AS [Detail],
    r.[ReceivedDateTimeUtc] AS [ActivityUtc],
    r.[CreatedUtc]
FROM [sms_flow].[Integration_InboundReply] r;
GO

CREATE OR ALTER VIEW [sms_flow].[vw_Health]
AS
SELECT
    (SELECT TOP (1) [Version] FROM [sms_flow].[Integration_SchemaVersion] ORDER BY [AppliedUtc] DESC, [Id] DESC) AS [SchemaVersion],
    rs.[LastKnownBalance],
    rs.[BillingType],
    rs.[LastStatusEventId],
    rs.[LastReplyEventId],
    rs.[BalanceCheckedUtc],
    rs.[LastArchiveStartedUtc],
    rs.[LastArchiveSucceededUtc],
    rs.[LastArchiveError],
    rs.[LastArchiveArchivedCount],
    rs.[LastArchivePurgedCount],
    (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] IN ('Queued', 'RetryPending', 'BlockedCredit', 'Leased')) AS [PendingCount],
    (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'FailedValidation') AS [FailedValidationCount],
    (SELECT COUNT(1) FROM [sms_flow].[Integration_OutboxMessage] WHERE [State] = 'FailedPermanent') AS [FailedPermanentCount],
    (SELECT MIN([UpdatedUtc]) FROM [sms_flow].[Integration_OutboxMessage]) AS [OldestUnarchivedOutboxUtc],
    (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_InboundStatus]) AS [OldestUnarchivedStatusUtc],
    (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_InboundReply]) AS [OldestUnarchivedReplyUtc],
    (SELECT MIN([CreatedUtc]) FROM [sms_flow].[Integration_OperationalEvent]) AS [OldestUnarchivedOperationalEventUtc],
    (SELECT MAX([CreatedUtc]) FROM [sms_flow].[Integration_OperationalEvent]) AS [LastOperationalEventUtc]
FROM [sms_flow].[Integration_RuntimeState] rs
WHERE rs.[Id] = 1;
GO

CREATE OR ALTER VIEW [sms_flow_archive].[vw_ArchivedMessages]
AS
SELECT
    m.[Id],
    m.[ClientMessageId],
    m.[ReferenceNumber],
    m.[Destination],
    m.[Body],
    m.[CostCentre],
    m.[Priority],
    m.[RequestedSendUtc],
    m.[State],
    m.[AttemptCount],
    m.[LastErrorCode],
    m.[LastErrorMessage],
    m.[CreatedUtc],
    m.[UpdatedUtc],
    m.[ArchivedUtc]
FROM [sms_flow_archive].[Integration_OutboxMessageArchive] m;
GO

/*
    ----------------------- ROLES -----------------------
    [sms_flow_runtime] - Used by the local SMSFlow worker/service. This role can execute the stored procedures that drive sending, reporting sync, health, and archiving.
    [sms_flow_enqueue] - Used by client-side systems that insert outbound messages into the local outbox table.
    [sms_flow_readonly] - Used by support or reporting users/tools that only need the client-facing views and read-only helper procedures.
*/

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = 'sms_flow_runtime' AND [type] = 'R')
BEGIN
    CREATE ROLE [sms_flow_runtime];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = 'sms_flow_enqueue' AND [type] = 'R')
BEGIN
    CREATE ROLE [sms_flow_enqueue];
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = 'sms_flow_readonly' AND [type] = 'R')
BEGIN
    CREATE ROLE [sms_flow_readonly];
END
GO

GRANT EXECUTE ON SCHEMA::[sms_flow] TO [sms_flow_runtime];
GRANT EXECUTE ON SCHEMA::[sms_flow_archive] TO [sms_flow_runtime];
GRANT REFERENCES ON TYPE::[sms_flow].[ClientMessageIdTableType] TO [sms_flow_runtime];
GRANT REFERENCES ON TYPE::[sms_flow].[ClientMessageErrorTableType] TO [sms_flow_runtime];
GRANT REFERENCES ON TYPE::[sms_flow].[StatusEventTableType] TO [sms_flow_runtime];
GRANT REFERENCES ON TYPE::[sms_flow].[ReplyEventTableType] TO [sms_flow_runtime];
GO

GRANT INSERT ON OBJECT::[sms_flow].[Integration_OutboxMessage] TO [sms_flow_enqueue];
GO

GRANT SELECT ON OBJECT::[sms_flow].[vw_Messages] TO [sms_flow_readonly];
GRANT SELECT ON OBJECT::[sms_flow].[vw_Attention] TO [sms_flow_readonly];
GRANT SELECT ON OBJECT::[sms_flow].[vw_InboundActivity] TO [sms_flow_readonly];
GRANT SELECT ON OBJECT::[sms_flow].[vw_Health] TO [sms_flow_readonly];
GRANT SELECT ON OBJECT::[sms_flow_archive].[vw_ArchivedMessages] TO [sms_flow_readonly];
GRANT EXECUTE ON OBJECT::[sms_flow].[SchemaVersion_Get] TO [sms_flow_readonly];
GRANT EXECUTE ON OBJECT::[sms_flow].[Health_Get] TO [sms_flow_readonly];
GRANT EXECUTE ON OBJECT::[sms_flow].[Dashboard_Snapshot_Get] TO [sms_flow_readonly];
GRANT EXECUTE ON OBJECT::[sms_flow].[Queue_Summary_Get] TO [sms_flow_readonly];
GRANT EXECUTE ON OBJECT::[sms_flow].[Failures_List] TO [sms_flow_readonly];
GRANT EXECUTE ON OBJECT::[sms_flow].[OperationalEvent_List] TO [sms_flow_readonly];
GRANT EXECUTE ON OBJECT::[sms_flow].[Message_GetByClientMessageId] TO [sms_flow_readonly];
GO

