using App.Middleware;
using App.Models;
using Npgsql;
using System.Collections.Generic;

public static class UserRoutes
{
    public static void MapUserRoutes(this WebApplication app, NpgsqlConnection connection)
    {
        app.MapGet("/users", () =>
        {
            try
            {
                using var cmd = new NpgsqlCommand();
                cmd.Connection = connection;
                cmd.CommandText = "SELECT * FROM users";

                using var reader = cmd.ExecuteReader();
                var users = new List<User>();
                while (reader.Read())
                {
                    users.Add(new User
                    {
                        Id = reader.GetInt32(0),
                        Firstname = reader.GetString(1),
                        Lastname = reader.GetString(2),
                    });
                }

                return Results.Ok(users);
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

        app.MapGet("/users/{id}", (int id) =>
        {
            try
            {
                using var cmd = new NpgsqlCommand();
                cmd.Connection = connection;
                cmd.CommandText = "SELECT * FROM users WHERE id = @id";
                cmd.Parameters.AddWithValue("id", id);

                using var reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    return Results.Ok(new User
                    {
                        Id = reader.GetInt32(0),
                        Firstname = reader.GetString(1),
                        Lastname = reader.GetString(2),
                    });
                }
                return Results.NotFound();
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

        app.MapPut("/users/{id}", (int id, User user) =>
        {
            try
            {
                using var cmd = new NpgsqlCommand();
                cmd.Connection = connection;
                cmd.CommandText = "UPDATE users SET firstname = @firstname, lastname = @lastname WHERE id = @id";
                cmd.Parameters.AddWithValue("id", id);
                cmd.Parameters.AddWithValue("firstname", user.Firstname);
                cmd.Parameters.AddWithValue("lastname", user.Lastname);

                var rowsAffected = cmd.ExecuteNonQuery();
                if (rowsAffected > 0)
                {
                    user.Id = id;
                    return Results.Ok(user);
                }
                return Results.NotFound();
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

        app.MapDelete("/users/{id}", (int id) =>
        {
            try
            {
                using var cmd = new NpgsqlCommand();
                cmd.Connection = connection;
                cmd.CommandText = "DELETE FROM users WHERE id = @id";
                cmd.Parameters.AddWithValue("id", id);

                var rowsAffected = cmd.ExecuteNonQuery();
                if (rowsAffected > 0)
                {
                    return Results.Ok();
                }
                return Results.NotFound();
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
