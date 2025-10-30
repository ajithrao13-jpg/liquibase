# Developer Workflow Guide - Liquibase Database Change Management

This guide provides step-by-step instructions for developers working with Liquibase for database change management in this project.

---

## Table of Contents

1. [Overview](#overview)
2. [Project Structure](#project-structure)
3. [Getting Started](#getting-started)
4. [Creating Database Changes](#creating-database-changes)
5. [Git Workflow](#git-workflow)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Examples](#examples)

---

## Overview

This project uses **Liquibase** to manage database schema changes in a version-controlled, repeatable, and trackable manner. All database changes (tables, stored procedures, views) are written as SQL files with Liquibase formatting.

### Key Benefits:
- Version-controlled database changes
- Automated deployment through CI/CD
- Rollback capabilities for failed deployments
- Validation and quality checks before deployment

---

## Project Structure

```
liquibase/
├── objects/                      # Database objects folder
│   ├── tables/                   # Table SQL files
│   │   └── *.sql
│   ├── sp/                       # Stored procedure SQL files
│   │   └── *.sql
│   └── views/                    # View SQL files
│       └── *.sql
├── objects/                      # Child XML changelogs
│   ├── tables.xml               # References all table SQL files
│   ├── sp.xml                   # References all stored procedure SQL files
│   └── views.xml                # References all view SQL files
├── master_objects.xml           # Master changelog (includes child XMLs)
├── db.changelog-master.xml      # Root changelog file
├── .gitlab-ci.yml               # CI/CD pipeline configuration
└── liquibase.properties         # Liquibase configuration
```

### File Organization:
- **objects/tables/**: Store all table creation/modification SQL files
- **objects/sp/**: Store all stored procedure SQL files
- **objects/views/**: Store all view SQL files
- **objects/tables.xml**: Master file that includes all table SQL files
- **objects/sp.xml**: Master file that includes all stored procedure SQL files
- **objects/views.xml**: Master file that includes all view SQL files
- **master_objects.xml**: Root file that includes all child XML files in correct order

---

## Getting Started

### Prerequisites

1. **Git** installed on your machine
2. **Database access** credentials for development environment
3. **Text editor** or IDE (VS Code, IntelliJ, etc.)
4. Basic understanding of **SQL** and **Git**

### Initial Setup

1. Clone the repository from the `develop` branch:
   ```bash
   git clone <repository-url>
   cd liquibase
   git checkout develop
   ```

2. Create your feature/work branch:
   ```bash
   git checkout -b feature/<your-feature-name>
   # Example: git checkout -b feature/add-customer-table
   ```

---

## Creating Database Changes

### Step 1: Determine the Type of Change

Identify what type of database object you're creating/modifying:
- **Table**: Use `objects/tables/` folder
- **Stored Procedure**: Use `objects/sp/` folder
- **View**: Use `objects/views/` folder

### Step 2: Create the SQL File

Create a new `.sql` file in the appropriate folder with a descriptive name:

```bash
# For tables
touch objects/tables/create_customer_table.sql

# For stored procedures
touch objects/sp/get_customer_by_id.sql

# For views
touch objects/views/customer_summary_view.sql
```

### Step 3: Write the SQL with Liquibase Formatting

Every SQL file **MUST** start with the Liquibase formatted SQL header and changeset definition.

#### Required Format:

```sql
--liquibase formatted sql

--changeset <author>:<changeset-id> labels:<label> context:<context> runOnChange:<true/false>
--comment: <Description of what this changeset does>
<YOUR SQL CODE HERE>
--rollback <ROLLBACK SQL CODE>
```

#### Format Breakdown:

1. **First Line**: Always `--liquibase formatted sql`
2. **Changeset Line**: Contains metadata
   - `author`: Your name or username (e.g., john_doe)
   - `changeset-id`: Unique identifier (e.g., table_name_001)
   - `labels`: Tags for categorization (e.g., tables, views, feature-x)
   - `context`: Environment context (e.g., dev, cert, prod or dev,cert,prod)
   - `runOnChange`: Set to `true` for SPs and Views (re-runs if file changes)
3. **Comment**: Brief description of the change
4. **SQL Code**: Your actual SQL statements
5. **Rollback**: SQL to undo the change

#### Example - Creating a Table:

```sql
--liquibase formatted sql

--changeset john_doe:customer_table_001 labels:tables,customer context:dev,cert,prod runOnChange:true
--comment: Create customer table to store customer information
CREATE TABLE IF NOT EXISTS customer (
    customer_id INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
--rollback DROP TABLE IF EXISTS customer;
```

#### Example - Creating a Stored Procedure:

```sql
--liquibase formatted sql

--changeset john_doe:get_customer_sp_001 labels:stored_procedures,customer context:dev,cert,prod runOnChange:true
--comment: Stored procedure to retrieve customer details by ID
CREATE OR REPLACE PROCEDURE get_customer_by_id(
    IN cust_id INT,
    OUT cust_name VARCHAR,
    OUT cust_email VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT 
        CONCAT(first_name, ' ', last_name),
        email
    INTO 
        cust_name,
        cust_email
    FROM customer 
    WHERE customer_id = cust_id;
END;
$$;
--rollback DROP PROCEDURE IF EXISTS get_customer_by_id(INT, OUT VARCHAR, OUT VARCHAR);
```

#### Example - Creating a View:

```sql
--liquibase formatted sql

--changeset john_doe:customer_view_001 labels:views,customer context:dev,cert,prod runOnChange:true
--comment: View to display customer summary information
CREATE OR REPLACE VIEW v_customer_summary AS
SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    phone,
    created_date
FROM customer;
--rollback DROP VIEW IF EXISTS v_customer_summary;
```

### Step 4: Update the Appropriate Child XML File

After creating your SQL file, you **MUST** add a reference to it in the corresponding XML file.

#### For Tables - Update `objects/tables.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">

    <!-- Include all table SQL files here -->
    <include file="objects/tables/create_employee_table.sql" relativeToChangelogFile="true"/>
    <include file="objects/tables/create_customer_table.sql" relativeToChangelogFile="true"/> <!-- ADD THIS LINE -->

</databaseChangeLog>
```

#### For Stored Procedures - Update `objects/sp.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">

    <!-- Include all stored procedure SQL files here -->
    <include file="objects/sp/get_employee_details.sql" relativeToChangelogFile="true"/>
    <include file="objects/sp/get_customer_by_id.sql" relativeToChangelogFile="true"/> <!-- ADD THIS LINE -->

</databaseChangeLog>
```

#### For Views - Update `objects/views.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">

    <!-- Include all view SQL files here -->
    <include file="objects/views/employee_summary_view.sql" relativeToChangelogFile="true"/>
    <include file="objects/views/customer_summary_view.sql" relativeToChangelogFile="true"/> <!-- ADD THIS LINE -->

</databaseChangeLog>
```

### Step 5: Verify master_objects.xml (Usually No Change Needed)

The `master_objects.xml` file should already include references to all child XML files. You typically **do not need to modify** this file unless you're adding a completely new category of objects.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">

    <!-- Master changelog file for all database objects -->
    
    <!-- 1. Tables - Create tables first -->
    <include file="objects/tables.xml" relativeToChangelogFile="true"/>
    
    <!-- 2. Views - Create views after tables -->
    <include file="objects/views.xml" relativeToChangelogFile="true"/>
    
    <!-- 3. Stored Procedures - Create stored procedures last -->
    <include file="objects/sp.xml" relativeToChangelogFile="true"/>

</databaseChangeLog>
```

---

## Git Workflow

Follow this Git workflow to ensure smooth collaboration and proper CI/CD execution.

### Step 1: Work on Your Feature Branch

```bash
# Ensure you're on your feature branch
git checkout feature/<your-feature-name>

# Make your changes (create SQL files, update XML files)
```

### Step 2: Stage and Commit Your Changes

```bash
# Check status of your changes
git status

# Add your files
git add objects/tables/create_customer_table.sql
git add objects/tables.xml

# Or add all changes
git add .

# Commit with a meaningful message
git commit -m "Add customer table with basic fields"
```

### Step 3: Push Changes to Your Feature Branch

```bash
# Push to your remote feature branch
git push origin feature/<your-feature-name>
```

### Step 4: Create a Pull Request (PR) to Develop Branch

1. Go to your Git repository (GitHub/GitLab/Bitbucket)
2. Create a **Pull Request** from your feature branch to the `develop` branch
3. Add a clear title and description
4. Request reviewers if required

### Step 5: CI/CD Pipeline Execution

Once you create the PR, the CI/CD pipeline will automatically trigger:

#### Automatic Stages:
1. **Lint Stage** - Runs on PR creation and updates
   - Validates changelog syntax
   - Checks database connectivity
   - Runs quality checks
   - Generates validation reports

2. You'll see validation checks and reports in the PR

#### What Happens on PR Merge to Develop:
1. **Deployment to Dev** - Manual approval job runs
   - Waits for manual approval
   - Applies database changes to development environment
   - Creates a deployment tag for rollback

2. **Rollback Jobs** - Available after deployment (Manual)
   - Standard rollback to previous pipeline tag
   - Custom rollback with flexible options

---

## CI/CD Pipeline

### Pipeline Stages Overview

```
┌─────────────────┐
│  Push to Branch │
│  or Create PR   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Lint Stage    │ ◄── Automatic on Push/PR/MR
│   - Validate    │
│   - Checks      │
│   - Reports     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Merge to       │
│  Develop Branch │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Deploy to Dev   │ ◄── Manual Approval Required
│   - Tag DB      │
│   - Run Update  │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌──────────────┐  ┌──────────────┐
│   Rollback   │  │   Rollback   │ ◄── Manual Trigger Only
│   Standard   │  │   Custom     │
└──────────────┘  └──────────────┘
```

### Lint Stage (Automated)

Runs automatically on:
- Push to any branch
- Pull Request creation
- Merge Request creation
- Commit updates to PR/MR

**What it does:**
- Validates Liquibase changelog files (XML and SQL syntax)
- Checks database connectivity
- Runs Liquibase quality checks
- Generates validation reports visible in PR/MR

**Developer Action Required:**
- Review validation reports
- Fix any errors or warnings
- Push fixes to the same branch (pipeline re-runs automatically)

### Deploy Stage (Manual Approval)

Triggers when code is merged to `develop` branch.

**What it does:**
1. **Tags the current database state** with pipeline ID (for rollback)
2. **Previews SQL** that will be executed (update-sql)
3. **Executes database changes** (update)
4. **Creates deployment tag** for easy rollback

**Developer Action Required:**
- Wait for manual approval from designated approver
- Monitor deployment logs
- Verify deployment success

### Rollback Stage (Manual Trigger Only)

Available after deployment if issues are detected.

#### Option 1: Standard Rollback
- Quick rollback to the previous pipeline tag
- One-click rollback to last known good state

#### Option 2: Custom Rollback
- Rollback to specific tag
- Rollback by count (last N changesets)
- Rollback to specific date
- Generate rollback SQL without executing

---

## Best Practices

### 1. SQL File Naming Conventions

Use descriptive, action-based names:
```
✅ Good:
- create_customer_table.sql
- add_email_column_to_user.sql
- get_order_details_by_id.sql
- customer_summary_view.sql

❌ Bad:
- table1.sql
- sp.sql
- new_file.sql
- fix.sql
```

### 2. Changeset ID Conventions

Use a consistent pattern:
```
Format: <object_name>_<sequence_number>
Examples:
- customer_table_001
- customer_table_002
- get_customer_sp_001
- customer_view_001
```

### 3. Always Use `IF NOT EXISTS` / `IF EXISTS`

Prevent errors on re-runs:
```sql
-- For tables
CREATE TABLE IF NOT EXISTS customer (...);
DROP TABLE IF EXISTS customer;

-- For procedures
CREATE OR REPLACE PROCEDURE get_customer(...);
DROP PROCEDURE IF EXISTS get_customer;

-- For views
CREATE OR REPLACE VIEW v_customer AS ...;
DROP VIEW IF EXISTS v_customer;
```

### 4. Use `runOnChange:true` for SP and Views

Stored procedures and views should always use `runOnChange:true`:
```sql
--changeset author:sp_001 labels:sp context:dev runOnChange:true
```

This ensures they're updated when the SQL file changes.

### 5. Always Include Rollback Statements

Every changeset should have a rollback:
```sql
--rollback DROP TABLE IF EXISTS customer;
--rollback DROP PROCEDURE IF EXISTS get_customer;
--rollback DROP VIEW IF EXISTS v_customer;
```

### 6. Use Meaningful Comments

Explain what the changeset does:
```sql
--comment: Create customer table with basic contact information and audit fields
```

### 7. Keep Changesets Small and Focused

- One logical change per SQL file
- Don't mix tables, SPs, and views in one file
- Separate DDL from DML when possible

### 8. Test Locally Before Pushing (If Possible)

If you have local Liquibase setup:
```bash
# Validate changelog
liquibase validate

# Preview SQL
liquibase update-sql

# Test update (on local DB)
liquibase update
```

### 9. Use Labels for Organization

Group related changes:
```sql
labels:tables,customer,phase1
labels:stored_procedures,reporting
labels:views,dashboard
```

### 10. Set Appropriate Contexts

Control where changes deploy:
```sql
context:dev,cert,prod  -- Deploys to all environments
context:dev            -- Dev only
context:cert,prod      -- Skip dev
```

---

## Troubleshooting

### Issue: Validation fails in Lint stage

**Solution:**
1. Check the pipeline logs for specific error messages
2. Common issues:
   - Missing `--liquibase formatted sql` header
   - Invalid XML syntax in child XML files
   - Incorrect file path in XML includes
   - SQL syntax errors
3. Fix the errors and push again

### Issue: Changeset already exists error

**Solution:**
1. Each changeset ID must be unique across all files
2. If you see "Changeset already exists", change your changeset ID:
   ```sql
   --changeset john_doe:customer_table_002  (increment the number)
   ```

### Issue: Rollback fails

**Solution:**
1. Ensure rollback SQL is correct
2. Test rollback SQL manually if possible
3. For complex rollbacks, consider using `--rollback <empty>` and manual intervention

### Issue: File not found in pipeline

**Solution:**
1. Verify file path in XML is correct
2. Ensure file is committed to Git
3. Check file path is relative to changelog file:
   ```xml
   <include file="objects/tables/create_customer_table.sql" relativeToChangelogFile="true"/>
   ```

### Issue: Merge conflicts

**Solution:**
1. Pull latest `develop` branch:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout feature/<your-feature-name>
   git merge develop
   ```
2. Resolve conflicts manually
3. Commit and push

---

## Examples

### Example 1: Creating a New Table

**Step-by-step:**

1. Create the SQL file:
   ```bash
   touch objects/tables/create_department_table.sql
   ```

2. Write the SQL:
   ```sql
   --liquibase formatted sql
   
   --changeset jane_smith:department_table_001 labels:tables,department context:dev,cert,prod runOnChange:true
   --comment: Create department table to store organizational departments
   CREATE TABLE IF NOT EXISTS department (
       dept_id INT PRIMARY KEY NOT NULL,
       dept_name VARCHAR(100) NOT NULL,
       dept_head VARCHAR(100),
       budget DECIMAL(12,2),
       created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   --rollback DROP TABLE IF EXISTS department;
   ```

3. Update `objects/tables.xml`:
   ```xml
   <include file="objects/tables/create_department_table.sql" relativeToChangelogFile="true"/>
   ```

4. Commit and push:
   ```bash
   git add objects/tables/create_department_table.sql
   git add objects/tables.xml
   git commit -m "Add department table"
   git push origin feature/add-department-table
   ```

5. Create PR to `develop` branch

### Example 2: Adding a Stored Procedure

**Step-by-step:**

1. Create the SQL file:
   ```bash
   touch objects/sp/update_employee_salary.sql
   ```

2. Write the SQL:
   ```sql
   --liquibase formatted sql
   
   --changeset bob_johnson:update_salary_sp_001 labels:stored_procedures,employee context:dev,cert,prod runOnChange:true
   --comment: Stored procedure to update employee salary with percentage increase
   CREATE OR REPLACE PROCEDURE update_employee_salary(
       IN emp_id INT,
       IN increase_percent DECIMAL
   )
   LANGUAGE plpgsql
   AS $$
   BEGIN
       UPDATE employee
       SET salary = salary * (1 + increase_percent / 100)
       WHERE employee_id = emp_id;
   END;
   $$;
   --rollback DROP PROCEDURE IF EXISTS update_employee_salary(INT, DECIMAL);
   ```

3. Update `objects/sp.xml`:
   ```xml
   <include file="objects/sp/update_employee_salary.sql" relativeToChangelogFile="true"/>
   ```

4. Commit and push:
   ```bash
   git add objects/sp/update_employee_salary.sql
   git add objects/sp.xml
   git commit -m "Add stored procedure to update employee salary"
   git push origin feature/add-salary-update-sp
   ```

5. Create PR to `develop` branch

### Example 3: Creating a View

**Step-by-step:**

1. Create the SQL file:
   ```bash
   touch objects/views/department_employee_view.sql
   ```

2. Write the SQL:
   ```sql
   --liquibase formatted sql
   
   --changeset alice_williams:dept_emp_view_001 labels:views,department,employee context:dev,cert,prod runOnChange:true
   --comment: View to show departments with employee count and total salary
   CREATE OR REPLACE VIEW v_department_employees AS
   SELECT 
       d.dept_id,
       d.dept_name,
       COUNT(e.employee_id) AS employee_count,
       SUM(e.salary) AS total_salary
   FROM department d
   LEFT JOIN employee e ON d.dept_id = e.department_id
   GROUP BY d.dept_id, d.dept_name;
   --rollback DROP VIEW IF EXISTS v_department_employees;
   ```

3. Update `objects/views.xml`:
   ```xml
   <include file="objects/views/department_employee_view.sql" relativeToChangelogFile="true"/>
   ```

4. Commit and push:
   ```bash
   git add objects/views/department_employee_view.sql
   git add objects/views.xml
   git commit -m "Add department employee summary view"
   git push origin feature/add-dept-emp-view
   ```

5. Create PR to `develop` branch

---

## Quick Reference Card

### File Creation Checklist

- [ ] Create `.sql` file in appropriate folder (`objects/tables/`, `objects/sp/`, or `objects/views/`)
- [ ] Add `--liquibase formatted sql` as first line
- [ ] Define changeset with author, ID, labels, context, and runOnChange
- [ ] Add comment describing the change
- [ ] Write SQL code with `IF NOT EXISTS` / `CREATE OR REPLACE`
- [ ] Add rollback statement
- [ ] Update corresponding child XML file (`tables.xml`, `sp.xml`, or `views.xml`)
- [ ] Verify `master_objects.xml` includes the child XML (usually already done)
- [ ] Commit changes with meaningful message
- [ ] Push to feature branch
- [ ] Create PR to `develop` branch
- [ ] Monitor lint stage results
- [ ] Address any validation errors

### Git Commands Quick Reference

```bash
# Start work
git checkout develop
git pull origin develop
git checkout -b feature/<name>

# Save work
git add .
git commit -m "Descriptive message"
git push origin feature/<name>

# Update branch with latest develop
git checkout develop
git pull origin develop
git checkout feature/<name>
git merge develop
```

---

## Support and Questions

If you encounter issues or have questions:
1. Check this guide first
2. Review pipeline logs for specific errors
3. Check existing SQL files for examples
4. Consult with team lead or senior developer
5. Review Liquibase documentation: https://docs.liquibase.com/

---

**Last Updated:** 2025-10-30  
**Version:** 1.0
