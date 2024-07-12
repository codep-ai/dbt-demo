create database datapai;
go

USE datapai;
go

create schema sales;
go

CREATE TABLE sales.customers (
  customer_id INT IDENTITY (1, 1) PRIMARY KEY,
  first_name VARCHAR (255) NOT NULL,
  last_name VARCHAR (255) NOT NULL,
  phone VARCHAR (25),
  email VARCHAR (255) NOT NULL,
  street VARCHAR (255),
  city VARCHAR (50),
  state VARCHAR (25),
  zip_code VARCHAR (5)
);

CREATE TABLE sales.stores (
  store_id INT IDENTITY (1, 1) PRIMARY KEY,
  store_name VARCHAR (255) NOT NULL,
  phone VARCHAR (25),
  email VARCHAR (255),
  street VARCHAR (255),
  city VARCHAR (255),
  state VARCHAR (10),
  zip_code VARCHAR (5)
);

go
