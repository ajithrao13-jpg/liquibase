--liquibase formatted sql

--changeset john_doe:employee_summary_view_001 labels:views,employee context:dev,cert,prod runOnChange:true
--comment: View to show employee summary information
CREATE OR REPLACE VIEW v_employee_summary AS
SELECT 
    employee_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    department,
    hire_date,
    salary
FROM employee;
--rollback DROP VIEW IF EXISTS v_employee_summary;
