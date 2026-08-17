# =========================
# Build stage
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# Copy solution and project files
COPY ["Event Managment System/Event Managment System.csproj", "Event Managment System/"]
COPY ["BLL/BLL.csproj", "BLL/"]
COPY ["DAL/DAL.csproj", "DAL/"]
COPY ["Areeb.BLL/Areeb.BLL.csproj", "Areeb.BLL/"]
COPY ["Areeb.DAL/Areeb.DAL.csproj", "Areeb.DAL/"]

# Restore dependencies
RUN dotnet restore "Event Managment System/Event Managment System.csproj"

# Copy source
COPY . .

# Build and publish
RUN dotnet publish \
    "Event Managment System/Event Managment System.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore \
    --no-self-contained

# =========================
# Runtime stage
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0.0:5000
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 5000

ENTRYPOINT ["dotnet", "Event Managment System.dll"]
