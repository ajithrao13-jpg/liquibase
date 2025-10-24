--liquibase formatted sql

--changeset ${author}:${changesetId}-1 labels:label1 context:context1 runOnChange:true
--comment: Create person table if not exists
create table if not exists person (
    id int primary key not null,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
);
--rollback DROP TABLE IF EXISTS person;

--changeset ${author}:${changesetId}-2 labels:label2 context:context2 runOnChange:true
--comment: Create company table if not exists
create table if not exists company (
    id int primary key not null,
    name varchar(50) not null,
    address1 varchar(50),
    address2 varchar(50),
    city varchar(30)
);
--rollback DROP TABLE IF EXISTS company;

--changeset ${author}:${changesetId}-3 labels:label3 context:context3 runOnChange:true
--comment: Add country column to person if not exists
ALTER TABLE person ADD COLUMN IF NOT EXISTS country varchar(2);
--rollback ALTER TABLE person DROP COLUMN IF EXISTS country;

--changeset ${author}:${changesetId}-4 labels:label4 context:context4 runOnChange:true
--comment: Add dynamic country_india column if not exists
ALTER TABLE person ADD COLUMN IF NOT EXISTS country_india5 varchar(2);
--rollback ALTER TABLE person DROP COLUMN IF EXISTS country_india5;

ALTER TABLE person ADD COLUMN IF NOT EXISTS country_india6 varchar(2);
































--liquibase formatted sql

--changeset siva:create_person_view
--comment: Creates a view to show person names and their city
CREATE VIEW v_person_city AS
SELECT id, name, city, country FROM person;
--rollback DROP VIEW v_person_city;
.









--liquibase formatted sql

--changeset siva:create_get_person_by_id_procedure endDelimiter://
--comment: Creates a stored procedure to get a person by ID
CREATE OR REPLACE PROCEDURE get_person_by_id(
   IN person_id INT, 
   OUT person_name VARCHAR, 
   OUT person_city VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
   SELECT name, city INTO person_name, person_city FROM person WHERE id = person_id;
END;
$$;
--rollback DROP PROCEDURE get_person_by_id(INT, OUT VARCHAR, OUT VARCHAR);












