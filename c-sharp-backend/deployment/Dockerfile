### Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

COPY app/*.csproj ./
RUN dotnet restore

COPY app/. ./
RUN dotnet publish -c Release -o out



### Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

RUN apt-get update && apt-get install -y libgssapi-krb5-2 && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/out .
EXPOSE 8080

ENTRYPOINT ["dotnet", "app.dll"]
