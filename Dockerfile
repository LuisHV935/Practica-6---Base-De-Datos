# 1. IMAGEN BASE (Runtime)
FROM mcr.microsoft.com/dotnet/runtime:8.0 AS base
WORKDIR /app

# 2. CONSTRUCCIÓN (SDK)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# COPIA Y RESTAURA 
COPY ["Practica6.csproj", "."]
RUN dotnet restore "./Practica6.csproj"

# COPIA TODO Y COMPILA
COPY . .
WORKDIR "/src/."
RUN dotnet build "./Practica6.csproj" -c $BUILD_CONFIGURATION -o /app/build

# 3. PUBLICACIÓN
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./Practica6.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# 4. IMAGEN FINAL
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Practica6.dll"]