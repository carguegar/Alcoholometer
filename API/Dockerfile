# 1. Usamos la imagen del SDK de .NET 10 para compilar
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# 2. Copiamos los archivos de proyecto y restauramos dependencias
# (Ajusta los nombres de las carpetas si las llamaste distinto)
COPY ["Alcoholimetro.Api/Alcoholimetro.Api.csproj", "Alcoholimetro.Api/"]
COPY ["Alcoholimetro.Application/Alcoholimetro.Application.csproj", "Alcoholimetro.Application/"]
COPY ["Alcoholimetro.Domain/Alcoholimetro.Domain.csproj", "Alcoholimetro.Domain/"]
COPY ["Alcoholimetro.Infrastructure/Alcoholimetro.Infrastructure.csproj", "Alcoholimetro.Infrastructure/"]
RUN dotnet restore "Alcoholimetro.Api/Alcoholimetro.Api.csproj"

# 3. Copiamos todo el código y compilamos
COPY . .
WORKDIR "/src/Alcoholimetro.Api"
RUN dotnet publish "Alcoholimetro.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# 4. Usamos una imagen ligera solo con el Runtime para ejecutar la app (ahorra memoria)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Cloud Run inyecta el puerto dinámicamente en la variable $PORT
ENV ASPNETCORE_URLS=http://+:${PORT:-8080}

ENTRYPOINT ["dotnet", "Alcoholimetro.Api.dll"]