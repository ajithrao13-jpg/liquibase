--liquibase formatted sql

--changeset siva:create_person_view
--comment: Creates a view to show person names and their city
CREATE VIEW v_person_city AS
SELECT id, name, city, country FROM person;
--rollback DROP VIEW v_person_city;
