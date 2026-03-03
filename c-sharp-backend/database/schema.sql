CREATE DATABASE App;

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    firstname VARCHAR(100) NOT NULL,
    lastname VARCHAR(100) NOT NULL UNIQUE
);


INSERT INTO users (firstname, lastname) VALUES
('Anthony', 'Stark'),
('Natasha', 'Romanova');
