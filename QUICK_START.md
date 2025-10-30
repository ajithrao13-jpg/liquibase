# Quick Start Guide for Developers

This is a condensed guide to get you started quickly. For comprehensive details, see [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md).

## Prerequisites

- Git installed
- Access to the repository
- Text editor or IDE

## Step-by-Step Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd liquibase

# Checkout develop branch
git checkout develop
git pull origin develop

# Create your feature branch
git checkout -b feature/add-customer-table
```

### 2. Create Your SQL File

Choose the appropriate folder based on what you're creating:

```bash
# For a table
touch objects/tables/create_customer_table.sql

# For a stored procedure
touch objects/sp/get_customer_by_id.sql

# For a view
touch objects/views/customer_summary_view.sql
```

### 3. Write Your SQL (Use This Template)

**For Tables:**
```sql
--liquibase formatted sql

--changeset your_name:customer_table_001 labels:tables,customer context:dev,cert,prod runOnChange:true
--comment: Create customer table to store customer information
CREATE TABLE IF NOT EXISTS customer (
    customer_id INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE
);
--rollback DROP TABLE IF EXISTS customer;
```

**For Stored Procedures:**
```sql
--liquibase formatted sql

--changeset your_name:get_customer_sp_001 labels:stored_procedures,customer context:dev,cert,prod runOnChange:true
--comment: Stored procedure to get customer by ID
CREATE OR REPLACE PROCEDURE get_customer_by_id(
    IN cust_id INT,
    OUT cust_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT CONCAT(first_name, ' ', last_name)
    INTO cust_name
    FROM customer 
    WHERE customer_id = cust_id;
END;
$$;
--rollback DROP PROCEDURE IF EXISTS get_customer_by_id(INT, OUT VARCHAR);
```

**For Views:**
```sql
--liquibase formatted sql

--changeset your_name:customer_view_001 labels:views,customer context:dev,cert,prod runOnChange:true
--comment: View to display customer information
CREATE OR REPLACE VIEW v_customer_summary AS
SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email
FROM customer;
--rollback DROP VIEW IF EXISTS v_customer_summary;
```

### 4. Update the XML File

Add your SQL file reference to the appropriate XML file:

**For tables** - Edit `objects/tables.xml`:
```xml
<include file="objects/tables/create_customer_table.sql" relativeToChangelogFile="true"/>
```

**For stored procedures** - Edit `objects/sp.xml`:
```xml
<include file="objects/sp/get_customer_by_id.sql" relativeToChangelogFile="true"/>
```

**For views** - Edit `objects/views.xml`:
```xml
<include file="objects/views/customer_summary_view.sql" relativeToChangelogFile="true"/>
```

### 5. Commit and Push

```bash
# Check your changes
git status

# Add your files
git add objects/tables/create_customer_table.sql
git add objects/tables.xml

# Or add all
git add .

# Commit with meaningful message
git commit -m "Add customer table with basic fields"

# Push to your feature branch
git push origin feature/add-customer-table
```

### 6. Create Pull Request

1. Go to your Git repository (GitHub/GitLab)
2. Create a Pull Request from your feature branch to `develop`
3. Add a clear title and description
4. Wait for automatic lint checks to complete

### 7. Monitor Lint Stage

The CI/CD pipeline will automatically:
- Validate your changelog syntax
- Check database connectivity
- Run quality checks
- Generate SQL preview

**If lint passes:** ✓ Your PR is ready for review

**If lint fails:** ❌ Review the error messages, fix issues, and push again

### 8. After PR Approval and Merge

Once your PR is merged to `develop`:
1. Deployment job becomes available (requires manual approval)
2. Authorized person approves deployment
3. Changes are applied to development database
4. Rollback is available if needed

## Critical Format Requirements

Every SQL file MUST have:

1. **First line:** `--liquibase formatted sql`
2. **Changeset line:** `--changeset author:id labels:label context:context runOnChange:true`
3. **Comment:** `--comment: Description`
4. **SQL code** with `IF NOT EXISTS` or `CREATE OR REPLACE`
5. **Rollback:** `--rollback SQL_TO_UNDO_CHANGE`

## Common Mistakes to Avoid

❌ **DON'T:**
- Forget the `--liquibase formatted sql` header
- Use duplicate changeset IDs
- Skip the rollback statement
- Forget to update the XML file
- Create SQL files without proper structure

✅ **DO:**
- Always use `IF NOT EXISTS` for tables
- Always use `CREATE OR REPLACE` for SPs and views
- Use `runOnChange:true` for SPs and views
- Include meaningful comments
- Use descriptive file names

## File Checklist

Before committing, verify:

- [ ] SQL file created in correct folder (`objects/tables/`, `objects/sp/`, or `objects/views/`)
- [ ] First line is `--liquibase formatted sql`
- [ ] Changeset has unique ID
- [ ] Comment explains the change
- [ ] SQL uses `IF NOT EXISTS` or `CREATE OR REPLACE`
- [ ] Rollback statement is included
- [ ] XML file updated (`tables.xml`, `sp.xml`, or `views.xml`)
- [ ] Committed with meaningful message
- [ ] Pushed to feature branch

## Need Help?

- **Comprehensive Guide:** [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md)
- **Workflow Diagram:** [WORKFLOW_DIAGRAM.md](WORKFLOW_DIAGRAM.md)
- **Architecture:** [architecture.md](architecture.md)
- **Examples:** See `objects/tables/create_employee_table.sql` and similar files

## Support

If you have issues:
1. Check [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md) troubleshooting section
2. Review pipeline logs for specific errors
3. Look at existing SQL files for examples
4. Ask your team lead or senior developer

---

**Remember:** The lint stage will catch most common mistakes automatically!
