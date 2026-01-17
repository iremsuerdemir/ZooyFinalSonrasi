IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

CREATE TABLE [FirebaseSyncLogs] (
    [Id] uniqueidentifier NOT NULL,
    [PayloadSource] nvarchar(128) NOT NULL,
    [PetsProcessed] int NOT NULL,
    [ProvidersProcessed] int NOT NULL,
    [RequestsProcessed] int NOT NULL,
    [SyncedAt] datetime2 NOT NULL,
    [Notes] nvarchar(max) NULL,
    CONSTRAINT [PK_FirebaseSyncLogs] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [PetProfiles] (
    [Id] uniqueidentifier NOT NULL,
    [FirebaseId] nvarchar(450) NOT NULL,
    [Name] nvarchar(256) NOT NULL,
    [Species] nvarchar(128) NOT NULL,
    [Breed] nvarchar(128) NULL,
    [Age] int NULL,
    [VaccinationStatus] nvarchar(256) NULL,
    [HealthNotes] nvarchar(max) NULL,
    [OwnerName] nvarchar(256) NOT NULL,
    [OwnerContact] nvarchar(256) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_PetProfiles] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [ServiceProviders] (
    [Id] uniqueidentifier NOT NULL,
    [FirebaseId] nvarchar(450) NOT NULL,
    [Name] nvarchar(256) NOT NULL,
    [ServiceType] nvarchar(128) NOT NULL,
    [Description] nvarchar(max) NULL,
    [Location] nvarchar(256) NOT NULL,
    [ContactInfo] nvarchar(256) NULL,
    [Rating] decimal(3,2) NULL,
    [OffersLiveTracking] bit NOT NULL,
    [OffersVideoCall] bit NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_ServiceProviders] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [Users] (
    [Id] int NOT NULL IDENTITY,
    [FirebaseUid] nvarchar(450) NULL,
    [Email] nvarchar(450) NOT NULL,
    [PasswordHash] nvarchar(max) NULL,
    [DisplayName] nvarchar(max) NOT NULL,
    [PhotoUrl] nvarchar(max) NULL,
    [Provider] nvarchar(max) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NULL,
    [IsActive] bit NOT NULL,
    [PasswordResetToken] nvarchar(max) NULL,
    [PasswordResetTokenExpiry] datetime2 NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY ([Id])
);
GO

CREATE TABLE [ServiceRequests] (
    [Id] uniqueidentifier NOT NULL,
    [FirebaseId] nvarchar(450) NOT NULL,
    [PetProfileId] uniqueidentifier NOT NULL,
    [ServiceProviderId] uniqueidentifier NOT NULL,
    [ServiceType] nvarchar(128) NOT NULL,
    [PreferredDate] datetime2 NOT NULL,
    [Status] nvarchar(64) NOT NULL,
    [Notes] nvarchar(max) NULL,
    [LiveTrackingUrl] nvarchar(512) NULL,
    [VideoCallEnabled] bit NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_ServiceRequests] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_ServiceRequests_PetProfiles_PetProfileId] FOREIGN KEY ([PetProfileId]) REFERENCES [PetProfiles] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_ServiceRequests_ServiceProviders_ServiceProviderId] FOREIGN KEY ([ServiceProviderId]) REFERENCES [ServiceProviders] ([Id]) ON DELETE NO ACTION
);
GO

CREATE TABLE [UserComments] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [CardId] nvarchar(200) NOT NULL,
    [Message] nvarchar(2000) NOT NULL,
    [Rating] int NOT NULL,
    [AuthorName] nvarchar(200) NOT NULL,
    [AuthorAvatar] nvarchar(max) NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_UserComments] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_UserComments_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [UserFavorites] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [Title] nvarchar(200) NOT NULL,
    [Subtitle] nvarchar(500) NULL,
    [ImageUrl] nvarchar(1000) NULL,
    [ProfileImageUrl] nvarchar(1000) NULL,
    [Tip] nvarchar(50) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_UserFavorites] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_UserFavorites_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [UserRequests] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [PetName] nvarchar(200) NOT NULL,
    [ServiceName] nvarchar(100) NOT NULL,
    [UserPhoto] nvarchar(max) NULL,
    [StartDate] datetime2 NOT NULL,
    [EndDate] datetime2 NOT NULL,
    [DayDiff] int NOT NULL,
    [Note] nvarchar(1000) NULL,
    [Location] nvarchar(500) NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_UserRequests] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_UserRequests_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [UserServices] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [ServiceName] nvarchar(200) NOT NULL,
    [ServiceIcon] nvarchar(100) NULL,
    [Price] nvarchar(50) NULL,
    [Description] nvarchar(1000) NULL,
    [Address] nvarchar(500) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    [UpdatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_UserServices] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_UserServices_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);
GO

CREATE TABLE [Messages] (
    [Id] int NOT NULL IDENTITY,
    [SenderId] int NOT NULL,
    [ReceiverId] int NOT NULL,
    [JobId] int NOT NULL,
    [MessageText] nvarchar(2000) NOT NULL,
    [CreatedAt] datetime2 NOT NULL,
    CONSTRAINT [PK_Messages] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Messages_UserRequests_JobId] FOREIGN KEY ([JobId]) REFERENCES [UserRequests] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Messages_Users_ReceiverId] FOREIGN KEY ([ReceiverId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Messages_Users_SenderId] FOREIGN KEY ([SenderId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
);
GO

CREATE TABLE [Notifications] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [Type] nvarchar(50) NOT NULL,
    [Title] nvarchar(200) NOT NULL,
    [RelatedUserId] int NULL,
    [RelatedJobId] int NULL,
    [CreatedAt] datetime2 NOT NULL,
    [IsRead] bit NOT NULL,
    CONSTRAINT [PK_Notifications] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Notifications_UserRequests_RelatedJobId] FOREIGN KEY ([RelatedJobId]) REFERENCES [UserRequests] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Notifications_Users_RelatedUserId] FOREIGN KEY ([RelatedUserId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Notifications_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);
GO

CREATE INDEX [IX_Messages_JobId] ON [Messages] ([JobId]);
GO

CREATE INDEX [IX_Messages_ReceiverId] ON [Messages] ([ReceiverId]);
GO

CREATE INDEX [IX_Messages_SenderId] ON [Messages] ([SenderId]);
GO

CREATE INDEX [IX_Notifications_RelatedJobId] ON [Notifications] ([RelatedJobId]);
GO

CREATE INDEX [IX_Notifications_RelatedUserId] ON [Notifications] ([RelatedUserId]);
GO

CREATE INDEX [IX_Notifications_UserId] ON [Notifications] ([UserId]);
GO

CREATE UNIQUE INDEX [IX_PetProfiles_FirebaseId] ON [PetProfiles] ([FirebaseId]);
GO

CREATE UNIQUE INDEX [IX_ServiceProviders_FirebaseId] ON [ServiceProviders] ([FirebaseId]);
GO

CREATE UNIQUE INDEX [IX_ServiceRequests_FirebaseId] ON [ServiceRequests] ([FirebaseId]);
GO

CREATE INDEX [IX_ServiceRequests_PetProfileId] ON [ServiceRequests] ([PetProfileId]);
GO

CREATE INDEX [IX_ServiceRequests_ServiceProviderId] ON [ServiceRequests] ([ServiceProviderId]);
GO

CREATE INDEX [IX_UserComments_UserId] ON [UserComments] ([UserId]);
GO

CREATE INDEX [IX_UserFavorites_UserId] ON [UserFavorites] ([UserId]);
GO

CREATE INDEX [IX_UserRequests_UserId] ON [UserRequests] ([UserId]);
GO

CREATE UNIQUE INDEX [IX_Users_Email] ON [Users] ([Email]);
GO

CREATE UNIQUE INDEX [IX_Users_FirebaseUid] ON [Users] ([FirebaseUid]) WHERE [FirebaseUid] IS NOT NULL;
GO

CREATE INDEX [IX_UserServices_UserId] ON [UserServices] ([UserId]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20251230083628_InitialCreate', N'8.0.8');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

ALTER TABLE [PetProfiles] ADD [UserId] int NOT NULL DEFAULT 0;
GO

CREATE INDEX [IX_PetProfiles_UserId] ON [PetProfiles] ([UserId]);
GO

ALTER TABLE [PetProfiles] ADD CONSTRAINT [FK_PetProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE;
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20251230104819_AddUserIdToPetProfile', N'8.0.8');
GO

COMMIT;
GO

BEGIN TRANSACTION;
GO

CREATE TABLE [PetWalks] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NOT NULL,
    [DurationSeconds] int NOT NULL,
    [DistanceKm] float NOT NULL,
    [PathJson] nvarchar(max) NOT NULL,
    [PetsJson] nvarchar(max) NOT NULL,
    [Date] datetime2 NOT NULL,
    CONSTRAINT [PK_PetWalks] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PetWalks_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);
GO

CREATE INDEX [IX_PetWalks_UserId] ON [PetWalks] ([UserId]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260116202505_AddPetWalks', N'8.0.8');
GO

COMMIT;
GO

