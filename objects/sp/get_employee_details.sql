--liquibase formatted sql

--changeset john_doe:get_employee_details_sp_001 labels:stored_procedures,employee context:dev,cert,prod runOnChange:true
--comment: Stored procedure to get employee details by ID
CREATE OR REPLACE PROCEDURE get_employee_details(
    IN emp_id INT,
    OUT emp_name VARCHAR,
    OUT emp_dept VARCHAR,
    OUT emp_salary DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT 
        CONCAT(first_name, ' ', last_name),
        department,
        salary
    INTO 
        emp_name, 
        emp_dept, 
        emp_salary
    FROM employee 
    WHERE employee_id = emp_id;
END;
$$;
--rollback DROP PROCEDURE IF EXISTS get_employee_details(INT, OUT VARCHAR, OUT VARCHAR, OUT DECIMAL);
