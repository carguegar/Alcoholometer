CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;
CREATE TABLE "Users" (
    "Id" uuid NOT NULL,
    "FirstName" text NOT NULL,
    "LastName" text NOT NULL,
    "SecondLastName" text NOT NULL,
    "Email" text NOT NULL,
    "PasswordHash" text NOT NULL,
    "BirthDate" date NOT NULL,
    "WeightKg" double precision NOT NULL,
    "HeightCm" double precision NOT NULL,
    "BiologicalSex" text NOT NULL,
    "DriverLicenseDate" date,
    CONSTRAINT "PK_Users" PRIMARY KEY ("Id")
);

CREATE TABLE "Measurements" (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "AlcoholLevel" double precision NOT NULL,
    "Timestamp" timestamp with time zone NOT NULL,
    "Latitude" double precision NOT NULL,
    "Longitude" double precision NOT NULL,
    CONSTRAINT "PK_Measurements" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Measurements_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id") ON DELETE CASCADE
);

CREATE INDEX "IX_Measurements_UserId" ON "Measurements" ("UserId");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260311183842_AddDriverLicenseDate', '10.0.3');

COMMIT;

START TRANSACTION;
ALTER TABLE "Users" ADD "DevicePushToken" text;

CREATE TABLE "Groups" (
    "Id" uuid NOT NULL,
    "Name" character varying(100) NOT NULL,
    "Description" text NOT NULL,
    "InvitationCode" character varying(20) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "Configuration_IsAlertActive" boolean NOT NULL,
    "AlertThresholdLevel" double precision NOT NULL,
    "IsMandatoryMeasurementActive" boolean NOT NULL,
    "MandatoryStartTime" interval,
    "MandatoryEndTime" interval,
    CONSTRAINT "PK_Groups" PRIMARY KEY ("Id")
);

CREATE TABLE "UserGroups" (
    "UserId" uuid NOT NULL,
    "GroupId" uuid NOT NULL,
    "Role" integer NOT NULL,
    "JoinedAt" timestamp with time zone NOT NULL,
    CONSTRAINT "PK_UserGroups" PRIMARY KEY ("UserId", "GroupId"),
    CONSTRAINT "FK_UserGroups_Groups_GroupId" FOREIGN KEY ("GroupId") REFERENCES "Groups" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_UserGroups_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_Groups_InvitationCode" ON "Groups" ("InvitationCode");

CREATE INDEX "IX_UserGroups_GroupId" ON "UserGroups" ("GroupId");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260320094008_AgregarSistemaDeGrupos', '10.0.3');

COMMIT;

START TRANSACTION;
ALTER TABLE "Users" ADD "RefreshToken" text;

ALTER TABLE "Users" ADD "RefreshTokenExpiryTime" timestamp with time zone;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260326104550_AddRefreshTokens', '10.0.3');

COMMIT;

