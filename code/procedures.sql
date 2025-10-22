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




