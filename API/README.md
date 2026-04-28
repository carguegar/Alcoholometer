# 🍺 Alcoholímetro IoT - Backend API

API REST central del sistema IoT del Alcoholímetro. Recibe mediciones de nivel de alcohol desde una App Móvil (que recopila datos de un sensor conectado a un microcontrolador ESP32) y expone la información para un Portal Web de gestión. Soporta autenticación JWT, gestión de usuarios, registro de mediciones con geolocalización y sistema de grupos colaborativos.

---

## Tabla de Contenidos

- [Arquitectura](#-arquitectura-y-patrones-de-diseño)
- [Stack Tecnológico](#-stack-tecnológico)
- [Seguridad](#-seguridad)
- [Guía de Setup](#-guía-de-configuración-en-un-nuevo-servidor)
- [Gestión de Base de Datos](#-gestión-de-la-base-de-datos-migraciones)
- [Endpoints de la API](#-endpoints-de-la-api)
- [Modelos de Datos](#-modelos-de-datos)
- [Flujo de Autenticación](#-flujo-de-autenticación)

---

## 🏗 Arquitectura y Patrones de Diseño

El proyecto sigue **Clean Architecture** con **CQRS** y **Domain-Driven Design (DDD)**, dividido en 4 capas:

```
┌─────────────────────────────────────┐
│         Alcoholimetro.Api           │  ← Controladores REST, DI, Middleware
├─────────────────────────────────────┤
│     Alcoholimetro.Application       │  ← Commands, Queries, DTOs, Handlers
├─────────────────────────────────────┤
│     Alcoholimetro.Infrastructure    │  ← EF Core, Repositorios, JWT Provider
├─────────────────────────────────────┤
│       Alcoholimetro.Domain          │  ← Entidades, Value Objects, Excepciones
└─────────────────────────────────────┘
```

| Capa | Responsabilidad |
|------|----------------|
| **Domain** | Entidades (`User`, `Measurement`, `Group`, `UserGroup`), Value Objects (`Email`, `Coordinates`, `Latitude`, `Longitude`), enums (`GroupRole`) y excepciones de negocio. Sin dependencias externas. |
| **Application** | Lógica de aplicación con patrón CQRS. `Commands/` para operaciones de escritura, `Queries/` para lectura. Contiene DTOs y la interfaz `IJwtProvider`. Hash de contraseñas con BCrypt. |
| **Infrastructure** | Implementación de repositorios, `AlcoholimetroDbContext` (EF Core + PostgreSQL), migraciones y `JwtProvider` con generación/validación de tokens. |
| **Api** | Controladores RESTful, configuración de Inyección de Dependencias, middleware de autenticación JWT Bearer y Swagger/OpenAPI. |

---

## 🛠 Stack Tecnológico

| Componente | Tecnología | Versión |
|------------|-----------|---------|
| Framework | .NET | 10.0 |
| ORM | Entity Framework Core | 10.0.3 |
| Base de Datos | PostgreSQL (Supabase) | — |
| Provider DB | Npgsql.EntityFrameworkCore.PostgreSQL | 10.0.0 |
| Autenticación | JWT Bearer (Microsoft.AspNetCore.Authentication.JwtBearer) | 10.0.4 |
| Hash de contraseñas | BCrypt.Net-Next | 4.1.0 |
| Documentación API | Swagger / OpenAPI (Scalar.AspNetCore) | 2.3.9 |
| Tokens JWT | System.IdentityModel.Tokens.Jwt | 8.16.0 |

---

## 🔒 Seguridad

| Aspecto | Implementación |
|---------|---------------|
| **Contraseñas** | Hash unidireccional con **BCrypt** (salting + hashing). Nunca se almacenan en texto plano. |
| **Tokens de acceso** | JWT firmado con HMAC-SHA256, expiración de **1 hora**. Claims: `sub` (userId), `email`, `isNovice`. |
| **Refresh tokens** | 64 bytes aleatorios codificados en Base64. Se almacenan hasheados con **SHA-256** en la BD. Expiración de **60 días**. |
| **Secretos** | Cadena de conexión y clave JWT almacenadas con **.NET User Secrets** (nunca en código fuente). |
| **Endpoints protegidos** | Todos los controladores llevan `[Authorize]` excepto registro (`POST /api/users`), login y refresh. |
| **Validación de dominio** | Value Objects validan formato de email (regex), rango de latitud (-90 a 90) y longitud (-180 a 180). |

---

## 🚀 Guía de Configuración en un Nuevo Servidor

### 1. Prerrequisitos

- [.NET 10 SDK](https://dotnet.microsoft.com/download) instalado
- [EF Core CLI tools](https://learn.microsoft.com/ef/core/cli/dotnet): `dotnet tool install --global dotnet-ef`
- Un proyecto PostgreSQL activo en [Supabase](https://supabase.com/) (u otro servidor PostgreSQL)

### 2. Clonar y restaurar dependencias

```bash
git clone [URL_DEL_REPOSITORIO]
cd alcoholimetro
dotnet restore
```

### 3. Configurar los Secretos Locales (Paso Crítico)

El archivo `appsettings.json` contiene valores placeholder. Los secretos reales se gestionan con **User Secrets** de .NET, que se almacenan de forma segura fuera del repositorio y sobrescriben la configuración en tiempo de ejecución.

```bash
# Inicializar el almacén de secretos
dotnet user-secrets init --project Alcoholimetro.Api

# Configurar la cadena de conexión a PostgreSQL
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=aws-1-eu-central-1.pooler.supabase.com;Port=6543;Database=postgres;User Id=postgres.[TU_ID];Password=[TU_CONTRASEÑA];Pooling=false;Max Auto Prepare=0;No Reset On Close=true;Include Error Detail=true;" --project Alcoholimetro.Api

# Configurar la clave secreta para firmar los JWT
dotnet user-secrets set "Jwt:Secret" "[TU_CLAVE_SECRETA_DE_AL_MENOS_32_CARACTERES]" --project Alcoholimetro.Api
```

> **Nota Supabase:** Es vital usar el **Puerto 6543** (Transaction Pooler) y `No Reset On Close=true` para evitar que PgBouncer corte conexiones asíncronas de .NET.


### 4. Arrancar la API

```bash
dotnet run --project Alcoholimetro.Api
```

| Perfil | URL |
|--------|-----|
| HTTP | `http://localhost:5231` |
| HTTPS | `https://localhost:7287` |
| Swagger UI | `http://localhost:5231/swagger` (solo en Development) |

### 5. Verificar el funcionamiento

Abre `http://localhost:5231/swagger` en el navegador. Deberías ver la interfaz de Swagger con todos los endpoints documentados.

### 6. Exponer la API para dispositivos externos (opcional)

Para que el ESP32 o la App Móvil accedan a la API durante desarrollo local, usa un túnel:

```bash
ngrok http 5231
```

---

## 🗄 Gestión de la Base de Datos (Migraciones)

Debido al Connection Pooler de Supabase, `dotnet ef database update` falla con errores de `ManualResetEventSlim disposed`. El flujo correcto es generar scripts SQL:

**Paso 1 — Crear la migración:**
```bash
dotnet ef migrations add NombreDescriptivo --project Alcoholimetro.Infrastructure --startup-project Alcoholimetro.Api
```

**Paso 2 — Generar el script SQL:**
```bash
dotnet ef migrations script --project Alcoholimetro.Infrastructure --startup-project Alcoholimetro.Api --idempotent -o nombre_script.sql
```

**Paso 3 — Ejecutar en Supabase:**
Copia el contenido del `.sql` generado y ejecútalo en el **SQL Editor** de Supabase.

---

## 📡 Endpoints de la API

Todos los endpoints están bajo el prefijo `/api`. Los marcados con 🔐 requieren header `Authorization: Bearer <token>`.

### Usuarios — `/api/users`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/api/users` | Público | Registrar nuevo usuario |
| `POST` | `/api/users/login` | Público | Iniciar sesión (devuelve tokens) |
| `POST` | `/api/users/refresh` | Público | Renovar tokens con refresh token |
| `GET` | `/api/users` | 🔐 | Listar todos los usuarios |
| `GET` | `/api/users/{id}` | 🔐 | Obtener usuario por ID |
| `PUT` | `/api/users/{id}` | 🔐 | Actualizar peso y altura |
| `DELETE` | `/api/users/{id}` | 🔐 | Eliminar usuario |

#### Registro — `POST /api/users`

**Request Body:**
```json
{
  "firstName": "Carlos",
  "lastName": "García",
  "secondLastName": "López",
  "emailRaw": "carlos@ejemplo.com",
  "password": "MiContraseña123",
  "birthDate": "1998-05-15",
  "weightKg": 75.5,
  "heightCm": 178.0,
  "biologicalSex": "Male",
  "drivingLicenseIssueDate": "2024-03-01"
}
```

**Respuesta:** `201 Created`

#### Login — `POST /api/users/login`

**Request Body:**
```json
{
  "emailRaw": "carlos@ejemplo.com",
  "password": "MiContraseña123"
}
```

**Respuesta:** `200 OK`
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "base64string..."
}
```

#### Refresh Token — `POST /api/users/refresh`

**Request Body:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "base64string..."
}
```

**Respuesta:** `200 OK` — Nuevos `accessToken` y `refreshToken`.

#### Obtener usuario — `GET /api/users/{id}` 🔐

**Respuesta:** `200 OK`
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "fullName": "Carlos García López",
  "email": "carlos@ejemplo.com",
  "age": 27,
  "weightKg": 75.5,
  "heightCm": 178.0,
  "biologicalSex": "Male",
  "isNoviceDriver": true
}
```

#### Actualizar usuario — `PUT /api/users/{id}` 🔐

**Request Body:**
```json
{
  "userId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "weightKg": 80.0,
  "heightCm": 178.0
}
```

---

### Mediciones — `/api/measurements`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/api/measurements` | 🔐 | Registrar nueva medición |
| `GET` | `/api/measurements/user/{userId}` | 🔐 | Obtener mediciones de un usuario |

#### Registrar medición — `POST /api/measurements` 🔐

**Request Body:**
```json
{ "measurementLevel": 0.25, "lat": 40.4168, "lng": -3.7038 }
```

> El `userId` se extrae del JWT (claim `sub` / `NameIdentifier`) y **no** se envía en el body. Una petición sin token válido devuelve `401 Unauthorized`.

**Respuesta:** `201 Created`

#### Obtener mediciones — `GET /api/measurements/user/{userId}` 🔐

**Respuesta:** `200 OK` — Lista ordenada por fecha (más reciente primero):
```json
[
  {
    "id": "...",
    "userId": "...",
    "alcoholLevel": 0.35,
    "timestamp": "2026-03-26T14:30:00Z",
    "latitude": 40.4168,
    "longitude": -3.7038
  }
]
```

---

### Grupos — `/api/groups`

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/api/groups` | 🔐 | Crear grupo (el creador es Admin) |
| `POST` | `/api/groups/join` | 🔐 | Unirse a grupo con código de invitación |

#### Crear grupo — `POST /api/groups` 🔐

**Request Body:**
```json
{
  "name": "Amigos del viernes",
  "description": "Grupo para controlar el consumo en las salidas"
}
```

**Respuesta:** `200 OK`
```json
{
  "groupId": "...",
  "invitationCode": "A1B2C3"
}
```

> El `invitationCode` es un código alfanumérico de 6 caracteres generado automáticamente.

#### Unirse a grupo — `POST /api/groups/join` 🔐

**Request Body:**
```json
{
  "invitationCode": "A1B2C3"
}
```

**Respuesta:** `200 OK`

---

## 📊 Modelos de Datos

### Esquema de Base de Datos

```
┌──────────────┐       ┌──────────────────┐       ┌──────────────┐
│    Users     │       │   Measurements   │       │    Groups    │
├──────────────┤       ├──────────────────┤       ├──────────────┤
│ Id (PK)      │──1:N─→│ Id (PK)          │       │ Id (PK)      │
│ FirstName    │       │ UserId (FK)      │       │ Name         │
│ LastName     │       │ AlcoholLevel     │       │ Description  │
│ SecondLastN. │       │ Timestamp        │       │ InvitationC. │
│ Email        │       │ Location_Lat     │       │ CreatedAt    │
│ PasswordHash │       │ Location_Lon     │       │ Config_*     │
│ BirthDate    │       └──────────────────┘       └──────┬───────┘
│ WeightKg     │                                         │
│ HeightCm     │       ┌──────────────────┐              │
│ BiologicalSex│       │   UserGroups     │              │
│ DriverLicDate│       ├──────────────────┤              │
│ DevicePushT. │       │ UserId (PK,FK)  │←─────────────┘
│ RefreshToken │       │ GroupId (PK,FK) │
│ RefreshTokExp│       │ Role (enum)      │
└──────────────┘──1:N─→│ JoinedAt         │
                       └──────────────────┘
```

### Entidades del Dominio

| Entidad | Descripción |
|---------|-------------|
| **User** | Usuario del sistema. Propiedades computadas: `Age` (calculada desde `BirthDate`) e `IsNoviceDriver` (licencia emitida hace menos de 2 años). |
| **Measurement** | Medición de alcohol con timestamp UTC y geolocalización (coordenadas como Value Object propio). |
| **Group** | Grupo colaborativo con código de invitación único. Incluye `GroupConfiguration` (umbrales de alerta, medición obligatoria). |
| **UserGroup** | Tabla de unión N:N entre Users y Groups. Incluye rol (`Member` = 0, `Admin` = 1) y fecha de unión. |

### Value Objects

| Value Object | Validación |
|-------------|-----------|
| **Email** | Regex: `^[^@\s]+@[^@\s]+\.[^@\s]+$` |
| **Latitude** | Rango: -90 a +90 |
| **Longitude** | Rango: -180 a +180 |
| **Coordinates** | Composición de Latitude + Longitude |

### GroupConfiguration (Configuración embebida en Group)

| Campo | Tipo | Default | Descripción |
|-------|------|---------|-------------|
| `IsAlertActive` | bool | false | Activar alertas de nivel |
| `AlertThresholdLevel` | double | — | Umbral para disparar alerta |
| `IsMandatoryMeasurementActive` | bool | false | Medición obligatoria |
| `MandatoryStartTime` | TimeSpan? | null | Inicio ventana obligatoria |
| `MandatoryEndTime` | TimeSpan? | null | Fin ventana obligatoria |

---

## 🔑 Flujo de Autenticación

```
┌──────┐                           ┌──────┐                    ┌────┐
│Client│                           │  API │                    │ DB │
└──┬───┘                           └──┬───┘                    └─┬──┘
   │  POST /api/users (registro)      │                          │
   │─────────────────────────────────→│  BCrypt hash password    │
   │                                  │─────────────────────────→│
   │                         201 Created                         │
   │←─────────────────────────────────│                          │
   │                                  │                          │
   │  POST /api/users/login           │                          │
   │─────────────────────────────────→│  Verify BCrypt hash      │
   │                                  │  Generate JWT (1h)       │
   │                                  │  Generate RefreshToken   │
   │                                  │  SHA256 hash → store     │
   │                                  │─────────────────────────→│
   │  { accessToken, refreshToken }   │                          │
   │←─────────────────────────────────│                          │
   │                                  │                          │
   │  GET /api/... [Bearer token]     │                          │
   │─────────────────────────────────→│  Validate JWT            │
   │                         200 OK   │                          │
   │←─────────────────────────────────│                          │
   │                                  │                          │
   │  POST /api/users/refresh         │                          │
   │  { accessToken, refreshToken }   │                          │
   │─────────────────────────────────→│  Extract claims from     │
   │                                  │  expired token           │
   │                                  │  Verify refresh hash     │
   │                                  │  Issue new tokens        │
   │  { accessToken, refreshToken }   │─────────────────────────→│
   │←─────────────────────────────────│                          │
```

### Claims del JWT

| Claim | Valor |
|-------|-------|
| `sub` | ID del usuario (Guid) |
| `email` | Email del usuario |
| `isNovice` | `true`/`false` — indica conductor novel |

### Configuración JWT (`appsettings.json` + User Secrets)

| Clave | Valor | Origen |
|-------|-------|--------|
| `Jwt:Issuer` | `AlcoholimetroApi` | appsettings.json |
| `Jwt:Audience` | `AlcoholimetroApp` | appsettings.json |
| `Jwt:ExpirationInHours` | `1` | appsettings.json |
| `Jwt:Secret` | (clave HMAC-SHA256 ≥32 chars) | **User Secrets** |

---

## 🧪 Códigos de Respuesta HTTP

| Código | Significado | Cuándo |
|--------|------------|--------|
| `200` | OK | Operación exitosa (lectura/actualización) |
| `201` | Created | Recurso creado (registro, medición) |
| `204` | No Content | Recurso eliminado |
| `400` | Bad Request | Error de validación de dominio (`DomainException`) |
| `401` | Unauthorized | Token ausente, expirado o credenciales incorrectas |
| `404` | Not Found | Recurso no encontrado |
| `500` | Server Error | Error interno no controlado |