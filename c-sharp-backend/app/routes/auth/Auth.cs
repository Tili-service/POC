using App.Config;
using App.Models;
using App.Middleware;
using Npgsql;
using System.Collections.Generic;



public static class Auth
{
    public static void MapAuthRoutes(this WebApplication app, NpgsqlConnection connection)
    {
        app.MapPost("/login", (UserLogin userLogin, IConfiguration configuration) =>
        {
            try
            {
                using var cmd = new NpgsqlCommand();
                cmd.Connection = connection;
                cmd.CommandText = "SELECT id FROM users WHERE firstname = @firstname AND lastname = @lastname";
                cmd.Parameters.AddWithValue("firstname", userLogin.Firstname);
                cmd.Parameters.AddWithValue("lastname", userLogin.Lastname);

                using var reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    var token = JwtManager.GenerateToken(reader.GetInt32(0), configuration);

                    return Results.Ok(new
                    {
                        Token = token
                    });
                }

                return Results.Unauthorized();
            }
            catch (Exception ex)
            {
                return Results.Problem(
                    detail: ex.Message,
                    statusCode: 500,
                    title: "Internal Server Error"
                );
            }
        });

        app.MapPost("/register", (UserRegister userRegister, IConfiguration configuration) =>
        {
            try
            {
                using var cmd = new NpgsqlCommand();
                cmd.Connection = connection;
                cmd.CommandText = "INSERT INTO users (firstname, lastname) VALUES (@firstname, @lastname) RETURNING id";
                cmd.Parameters.AddWithValue("firstname", userRegister.Firstname);
                cmd.Parameters.AddWithValue("lastname", userRegister.Lastname);

                int id = (int)cmd.ExecuteScalar()!;
                var token = JwtManager.GenerateToken(id, configuration);

                return Results.Created($"/users/{id}", new
                {
                    Token = token
                });
            }
            catch (Npgsql.PostgresException ex) when (ex.SqlState == "23505")
            {
                return Results.Conflict(new { error = "User already exists" });
            }
            catch (Exception ex)
            {
                return Results.Problem(
                    detail: ex.Message,
                    statusCode: 500,
                    title: "Internal Server Error"
                );
            }
        });
    }
}
