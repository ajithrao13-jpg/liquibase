--liquibase formatted sql

--changeset john_doe:employee_table_001 labels:tables,employee context:dev,cert,prod runOnChange:true
--comment: Create employee table to store employee information
CREATE TABLE IF NOT EXISTS employee (
    employee_id INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    department VARCHAR(50),
    hire_date DATE,
    salary DECIMAL(10,2)
);
--rollback DROP TABLE IF EXISTS employee;
