# 🍺 Alcoholímetro IoT - Backend API

Esta es la API central del sistema IoT del Alcoholímetro. Actúa como el cerebro del ecosistema, recibiendo las mediciones de los usuarios a través de una App Móvil (la cual recopila los datos físicos mediante un microcontrolador ESP32) y sirviendo la información para su visualización en un Portal Web de gestión.

## 🏗 Arquitectura y Patrones de Diseño

El proyecto está construido en **.NET 10** y sigue estrictamente los principios de **Clean Architecture** y **Domain-Driven Design (DDD)**:

* **Dominio (`Alcoholimetro.Domain`):** Contiene el corazón del negocio. Entidades (`User`, `Measurement`), **Value Objects** (`Email`, `Coordinates`, `Latitude`, `Longitude`) para evitar la "obsesión por los primitivos", y Excepciones de negocio personalizadas.
* **Aplicación (`Alcoholimetro.Application`):** Implementa el patrón **CQRS** (Command Query Responsibility Segregation). Las operaciones que modifican la base de datos están en la carpeta `Commands` y las que solo leen están en `Queries`.
* **Infraestructura (`Alcoholimetro.Infrastructure`):** Contiene la implementación de los repositorios y la conexión a la base de datos PostgreSQL usando Entity Framework Core.
* **API (`Alcoholimetro.Api`):** Los controladores RESTful que actúan como "recepcionistas" de las peticiones HTTP y la configuración de Inyección de Dependencias.

---

## 🔒 Seguridad y Encriptación

Para garantizar la seguridad de los datos de los usuarios:
* **Contraseñas:** Nunca se guardan en texto plano. Utilizamos la librería **BCrypt (`BCrypt.Net-Next`)** en la capa de Aplicación para aplicar un *hash* criptográfico unidireccional (Salting + Hashing) antes de guardar el usuario en la base de datos.
* **Credenciales de Base de Datos:** Se omiten del código fuente utilizando el **Secret Manager** de .NET para evitar fugas de información en repositorios Git.

---

## 🚀 Guía de Configuración Local (Para un nuevo PC)

Sigue estos pasos para arrancar el proyecto en cualquier ordenador desde cero.

### 1. Prerrequisitos
* [.NET 10 SDK](https://dotnet.microsoft.com/download) instalado.
* Una cuenta en [Supabase](https://supabase.com/) con un proyecto PostgreSQL activo.

### 2. Clonar el repositorio
```bash
git clone [URL_DEL_REPOSITORIO]
cd alcoholimetro
dotnet restore
```

### 3. Configurar los Secretos Locales (¡Paso Crítico!)

Por seguridad, el archivo `appsettings.json` solo contiene un valor falso para la base de datos. .NET utiliza una jerarquía de configuración donde los **User Secrets** (guardados de forma segura en una carpeta oculta de tu disco duro local) sobrescriben los valores del `appsettings.json` al arrancar en memoria RAM.

Para enlazar la clave `ConnectionStrings:DefaultConnection` con tu base de datos real, ejecuta los siguientes comandos en la raíz del proyecto:

```bash
# Inicializa el almacén de secretos para la API
dotnet user-secrets init --project Alcoholimetro.Api

# Guarda tu cadena de conexión real de Supabase
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=aws-1-eu-central-1.pooler.supabase.com;Port=6543;Database=postgres;User Id=postgres.[TU_ID];Password=[TU_CONTRASEÑA_REAL];Pooling=false;Max Auto Prepare=0;No Reset On Close=true;Include Error Detail=true;" --project Alcoholimetro.Api
```
> **Nota de Infraestructura:** Es vital usar el **Puerto 6543** (Transaction Pooler) y el parámetro `No Reset On Close=true` para evitar que el PgBouncer de Supabase corte la conexión asíncrona de C#.

### 4. Arrancar la API
Una vez configurado el secreto, levanta el servidor:
```bash
dotnet run --project Alcoholimetro.Api
```
Abre tu navegador en `http://localhost:5231/swagger` (el puerto puede variar según tu terminal) para acceder a la interfaz gráfica de Swagger y probar los endpoints.

*Para que dispositivos externos (como el ESP32 o la App Móvil) puedan acceder a esta API localmente durante el desarrollo, se recomienda usar una herramienta de túneles como **Ngrok** (`ngrok http 5231`).*

---

## 🗄 Gestión de la Base de Datos (Migraciones en la Nube)

Debido a que utilizamos el Connection Pooler de Supabase para optimizar el rendimiento de la API, la ejecución directa de migraciones desde C# (`dotnet ef database update`) fallará por bloqueos de red. 

**El flujo de trabajo correcto y seguro para modificar la base de datos es generar scripts SQL.**

Si añades, eliminas o modificas alguna Entidad o Value Object en tu código, sigue estos pasos:

**Paso 1: Crear la migración en C#**
Esto leerá tu código, detectará los cambios y creará un archivo de migración en la carpeta `Migrations`.
```bash
dotnet ef migrations add NombreDescriptivoDeTuCambio --project Alcoholimetro.Infrastructure --startup-project Alcoholimetro.Api
```

**Paso 2: Generar el Script SQL**
Esto traduce los cambios detectados a instrucciones exactas para PostgreSQL.
```bash
dotnet ef migrations script --project Alcoholimetro.Infrastructure --startup-project Alcoholimetro.Api -o actualizacion.sql
```

**Paso 3: Ejecutar en Supabase**
1. Abre el archivo `actualizacion.sql` generado en la raíz de tu proyecto.
2. Copia todo su contenido de texto.
3. Ve al panel web de tu proyecto en Supabase y abre el **SQL Editor**.
4. Pega el código y haz clic en **Run**.
5. (Opcional) Ya puedes borrar el archivo `actualizacion.sql` de tu ordenador local, ya que C# guarda su propio historial internamente.