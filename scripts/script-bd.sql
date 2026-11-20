-- CityTech — DDL dos objetos de banco da API .NET (SQL Server / Azure SQL).
-- Gerado a partir das migrations EF Core versionadas em
-- backend-dotnet/src/CityTech.Infrastructure/Persistence/Migrations.
--
-- Origem real deste arquivo (não editar manualmente):
--   cd backend-dotnet
--   dotnet ef migrations script --idempotent --project src/CityTech.Infrastructure
--     --startup-project src/CityTech.Api --configuration Release --output ../scripts/script-bd.sql
--
-- O script é idempotente: pode ser aplicado em banco vazio (cria __EFMigrationsHistory,
-- accounts, idempotency_records, follow_ups, índices e a FK) ou em banco já migrado
-- (não repete DDL e registra somente migrations pendentes).
-- Tabelas relacionadas: follow_ups.user_id -> accounts.id (FK) e
-- follow_ups.occurrence_id -> ocorrência do Java/Oracle (referência por ID, sem FK cruzada).
-- A pipeline aplica este mesmo DDL no Azure SQL antes de publicar o pacote da aplicação.

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
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117072823_InitialCreate'
)
BEGIN
    CREATE TABLE [accounts] (
        [id] uniqueidentifier NOT NULL,
        [name] nvarchar(120) NOT NULL,
        [email] nvarchar(254) NOT NULL,
        [email_normalized] nvarchar(254) NOT NULL,
        [password_hash] nvarchar(512) NOT NULL,
        [role] nvarchar(20) NOT NULL,
        [active] bit NOT NULL,
        [created_at] datetime2(7) NOT NULL,
        [updated_at] datetime2(7) NOT NULL,
        [version] bigint NOT NULL,
        CONSTRAINT [PK_accounts] PRIMARY KEY ([id]),
        CONSTRAINT [CK_accounts_email_normalized_lowercase] CHECK ([email_normalized] = LOWER([email_normalized])),
        CONSTRAINT [CK_accounts_name_length] CHECK (LEN([name]) >= 2),
        CONSTRAINT [CK_accounts_role] CHECK ([role] IN ('CIDADAO', 'GESTOR')),
        CONSTRAINT [CK_accounts_version] CHECK ([version] >= 0)
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117072823_InitialCreate'
)
BEGIN
    CREATE TABLE [idempotency_records] (
        [id] uniqueidentifier NOT NULL,
        [scope] nvarchar(120) NOT NULL,
        [idempotency_key] nvarchar(128) NOT NULL,
        [request_hash] nvarchar(64) NOT NULL,
        [status_code] int NOT NULL,
        [response_body] nvarchar(max) NOT NULL,
        [created_at] datetime2(7) NOT NULL,
        [expires_at] datetime2(7) NOT NULL,
        CONSTRAINT [PK_idempotency_records] PRIMARY KEY ([id]),
        CONSTRAINT [CK_idempotency_records_expiry] CHECK ([expires_at] > [created_at]),
        CONSTRAINT [CK_idempotency_records_key_length] CHECK (LEN([idempotency_key]) BETWEEN 8 AND 128),
        CONSTRAINT [CK_idempotency_records_request_hash] CHECK (LEN([request_hash]) = 64 AND [request_hash] = LOWER([request_hash])),
        CONSTRAINT [CK_idempotency_records_scope_length] CHECK (LEN([scope]) BETWEEN 1 AND 120),
        CONSTRAINT [CK_idempotency_records_status_code] CHECK ([status_code] BETWEEN 100 AND 599)
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117072823_InitialCreate'
)
BEGIN
    CREATE TABLE [follow_ups] (
        [id] uniqueidentifier NOT NULL,
        [user_id] uniqueidentifier NOT NULL,
        [occurrence_id] uniqueidentifier NOT NULL,
        [note] nvarchar(500) NULL,
        [created_at] datetime2(7) NOT NULL,
        [updated_at] datetime2(7) NOT NULL,
        [version] bigint NOT NULL,
        CONSTRAINT [PK_follow_ups] PRIMARY KEY ([id]),
        CONSTRAINT [CK_follow_ups_note_not_blank] CHECK ([note] IS NULL OR LEN(LTRIM(RTRIM([note]))) > 0),
        CONSTRAINT [CK_follow_ups_version] CHECK ([version] >= 0),
        CONSTRAINT [FK_follow_ups_accounts_user_id] FOREIGN KEY ([user_id]) REFERENCES [accounts] ([id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117072823_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [UX_accounts_email_normalized] ON [accounts] ([email_normalized]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117072823_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [UX_follow_ups_user_id_occurrence_id] ON [follow_ups] ([user_id], [occurrence_id]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117072823_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_idempotency_records_expires_at] ON [idempotency_records] ([expires_at]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117072823_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [UX_idempotency_records_scope_key] ON [idempotency_records] ([scope], [idempotency_key]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117072823_InitialCreate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117072823_InitialCreate', N'10.0.15');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117125534_AddIdempotencyResponseLocation'
)
BEGIN
    ALTER TABLE [idempotency_records] ADD [response_location] nvarchar(2048) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117125534_AddIdempotencyResponseLocation'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117125534_AddIdempotencyResponseLocation', N'10.0.15');
END;

COMMIT;
GO

