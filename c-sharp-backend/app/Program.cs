using App.Config;
using App.Middleware;
using Npgsql;
using System.Text.Json;
using System.Text.Json.Serialization;



var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter());
});

var app = builder.Build();



app.UseMiddleware<JwtMiddleware>();



string? connectionString = Environment.GetEnvironmentVariable("DATABASE_URL");
NpgsqlConnection connection = Database.GetConnection(connectionString);
app.MapAuthRoutes(connection);
app.MapUserRoutes(connection);



app.Run();
