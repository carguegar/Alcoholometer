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
VALUES ('20260305200047_InitialCreate', '10.0.3');

COMMIT;

