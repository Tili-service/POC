namespace App.Config;

using Npgsql;
using System.Data;



public static class Database
{
    public static NpgsqlConnection GetConnection(string connectionString)
    {
        var connection = new NpgsqlConnection(connectionString);
        connection.Open();
        return connection;
    }
}
