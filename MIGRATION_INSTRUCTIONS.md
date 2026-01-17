# SSMS'e Message ve Notification Tablolarını Eklemek İçin Migration Adımları

## 🎯 Yöntem 1: Entity Framework Core Migration (Önerilen)

### Adım 1: Terminal/Command Prompt'ta ZoozyApi klasörüne gidin

```bash
cd ZoozyApi
```

### Adım 2: Yeni migration oluşturun

```bash
dotnet ef migrations add AddMessagesAndNotifications
```

Bu komut, `ZoozyApi/Migrations/` klasöründe yeni bir migration dosyası oluşturur.

### Adım 3: Migration'ı veritabanına uygulayın

```bash
dotnet ef database update
```

Bu komut, migration'ı SQL Server veritabanına uygular ve `Messages` ve `Notifications` tablolarını oluşturur.

---

## 🎯 Yöntem 2: Manuel SQL Script (Alternatif)

Eğer EF Core migration kullanamıyorsanız, aşağıdaki SQL script'ini SSMS'te çalıştırabilirsiniz:

```sql
-- Messages tablosu
CREATE TABLE [Messages] (
    [Id] INT PRIMARY KEY IDENTITY(1,1),
    [SenderId] INT NOT NULL,
    [ReceiverId] INT NOT NULL,
    [JobId] INT NOT NULL,
    [MessageText] NVARCHAR(2000) NOT NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    -- Foreign Keys
    CONSTRAINT [FK_Messages_Users_Sender] FOREIGN KEY ([SenderId]) REFERENCES [Users]([Id]),
    CONSTRAINT [FK_Messages_Users_Receiver] FOREIGN KEY ([ReceiverId]) REFERENCES [Users]([Id]),
    CONSTRAINT [FK_Messages_UserRequests_Job] FOREIGN KEY ([JobId]) REFERENCES [UserRequests]([Id])
);

-- Notifications tablosu
CREATE TABLE [Notifications] (
    [Id] INT PRIMARY KEY IDENTITY(1,1),
    [UserId] INT NOT NULL,
    [Type] NVARCHAR(50) NOT NULL,
    [Title] NVARCHAR(200) NOT NULL,
    [RelatedUserId] INT NULL,
    [RelatedJobId] INT NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [IsRead] BIT NOT NULL DEFAULT 0,
    
    -- Foreign Keys
    CONSTRAINT [FK_Notifications_Users_User] FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Notifications_Users_RelatedUser] FOREIGN KEY ([RelatedUserId]) REFERENCES [Users]([Id]),
    CONSTRAINT [FK_Notifications_UserRequests_RelatedJob] FOREIGN KEY ([RelatedJobId]) REFERENCES [UserRequests]([Id])
);

-- Index'ler (performans için)
CREATE INDEX [IX_Messages_SenderId] ON [Messages]([SenderId]);
CREATE INDEX [IX_Messages_ReceiverId] ON [Messages]([ReceiverId]);
CREATE INDEX [IX_Messages_JobId] ON [Messages]([JobId]);
CREATE INDEX [IX_Messages_CreatedAt] ON [Messages]([CreatedAt]);

CREATE INDEX [IX_Notifications_UserId] ON [Notifications]([UserId]);
CREATE INDEX [IX_Notifications_Type] ON [Notifications]([Type]);
CREATE INDEX [IX_Notifications_CreatedAt] ON [Notifications]([CreatedAt]);
CREATE INDEX [IX_Notifications_IsRead] ON [Notifications]([IsRead]);
```

---

## ✅ Kontrol

Migration uygulandıktan sonra SSMS'te şu komutu çalıştırarak tabloların oluşturulduğunu kontrol edebilirsiniz:

```sql
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
AND TABLE_NAME IN ('Messages', 'Notifications');
```

Her iki tablo da listede görünmelidir.

---

## ⚠️ Önemli Notlar

1. **Veritabanı bağlantısı**: Migration çalıştırmadan önce `appsettings.json` veya environment variable'da `ConnectionStrings:DefaultConnection` ayarının doğru olduğundan emin olun.

2. **EF Core Tools**: Eğer `dotnet ef` komutu çalışmıyorsa, şu komutu çalıştırın:
   ```bash
   dotnet tool install --global dotnet-ef
   ```

3. **Backup**: Production veritabanında çalıştırmadan önce mutlaka backup alın!

