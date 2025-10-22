# Liquibase Changelog Best Practices

## 📖 Overview

This guide provides best practices for creating and managing Liquibase changesets in this project.

## 🎯 Core Principles

### 1. One Logical Change Per Changeset

**Good:**
```sql
--changeset john_doe:add-email-column
ALTER TABLE users ADD COLUMN email VARCHAR(255);
--rollback ALTER TABLE users DROP COLUMN email;
```

**Bad:**
```sql
--changeset john_doe:multiple-changes
ALTER TABLE users ADD COLUMN email VARCHAR(255);
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
ALTER TABLE orders ADD COLUMN status VARCHAR(50);
-- Multiple unrelated changes in one changeset
```

### 2. Always Include Rollback Statements

**Good:**
```sql
--changeset jane_doe:create-audit-table
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    action VARCHAR(50),
    timestamp TIMESTAMP
);
--rollback DROP TABLE audit_log;
```

**Bad:**
```sql
--changeset jane_doe:create-audit-table
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    action VARCHAR(50),
    timestamp TIMESTAMP
);
-- No rollback statement!
```

### 3. Use Unique, Descriptive Changeset IDs

Our project uses dynamic IDs:
```sql
--changeset ${author}:${changesetId}-1
```

Where:
- `${author}` = Sanitized commit author name
- `${changesetId}` = Git commit SHA

This ensures:
- ✅ Unique IDs across all commits
- ✅ Traceable to specific commits
- ✅ Clear ownership
- ✅ No ID conflicts

### 4. Add Meaningful Comments

**Good:**
```sql
--changeset ${author}:${changesetId}-1
--comment: Add email column to support user notifications feature (JIRA-123)
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);
--rollback ALTER TABLE users DROP COLUMN IF EXISTS email;
```

**Bad:**
```sql
--changeset ${author}:${changesetId}-1
--comment: Add column
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);
--rollback ALTER TABLE users DROP COLUMN IF EXISTS email;
```

## 🔧 Technical Best Practices

### 1. Make Changes Idempotent

Use `IF EXISTS` and `IF NOT EXISTS` clauses:

**Creating Tables:**
```sql
--changeset ${author}:${changesetId}-1
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL
);
--rollback DROP TABLE IF EXISTS users;
```

**Adding Columns:**
```sql
--changeset ${author}:${changesetId}-2
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);
--rollback ALTER TABLE users DROP COLUMN IF EXISTS email;
```

**Creating Indexes:**
```sql
--changeset ${author}:${changesetId}-3
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
--rollback DROP INDEX IF EXISTS idx_users_email;
```

### 2. Use Labels and Contexts

Organize changesets with labels and contexts:

```sql
--changeset ${author}:${changesetId}-1 labels:schema-change context:production
--comment: Add email column for notification feature
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);
--rollback ALTER TABLE users DROP COLUMN IF EXISTS email;

--changeset ${author}:${changesetId}-2 labels:data-migration context:production
--comment: Set default email for existing users
UPDATE users SET email = 'noreply@example.com' WHERE email IS NULL;
--rollback UPDATE users SET email = NULL;
```

**Common Labels:**
- `schema-change` - DDL changes
- `data-migration` - Data updates
- `index-creation` - Performance improvements
- `security-update` - Security-related changes
- `refactoring` - Code cleanup

**Common Contexts:**
- `production` - Production environment
- `staging` - Staging environment
- `development` - Development environment
- `test` - Test environment

### 3. Handle Data Migrations Carefully

**Safe Data Migration:**
```sql
--changeset ${author}:${changesetId}-1 labels:data-migration
--comment: Migrate old status values to new format
UPDATE orders 
SET status = 'COMPLETED' 
WHERE status = 'complete' AND status != 'COMPLETED';
--rollback UPDATE orders SET status = 'complete' WHERE status = 'COMPLETED';
```

**For Large Tables:**
```sql
--changeset ${author}:${changesetId}-1 labels:data-migration runOnChange:false
--comment: Add index before data migration to improve performance
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
--rollback DROP INDEX IF EXISTS idx_orders_status;

--changeset ${author}:${changesetId}-2 labels:data-migration
--comment: Batch update for large table (use WHERE clause to process in chunks)
UPDATE orders 
SET status = 'COMPLETED' 
WHERE status = 'complete' 
  AND id < 100000;  -- Process in batches
--rollback UPDATE orders SET status = 'complete' WHERE status = 'COMPLETED' AND id < 100000;
```

### 4. Use runOnChange Appropriately

```sql
--changeset ${author}:${changesetId}-1 runOnChange:true
--comment: Update view definition when source tables change
CREATE OR REPLACE VIEW v_active_users AS
SELECT id, username, email FROM users WHERE active = true;
--rollback DROP VIEW IF EXISTS v_active_users;
```

**When to use `runOnChange:true`:**
- Views (that might need updates)
- Stored procedures
- Functions
- Triggers

**When NOT to use `runOnChange:true`:**
- Table creations
- Column additions
- Data migrations

## 🚫 Common Mistakes to Avoid

### 1. Modifying Executed Changesets

**❌ Never Do This:**
```sql
-- Changeset already executed in production
--changeset john:create-users-table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50)  -- Changed from VARCHAR(100) - DON'T DO THIS!
);
```

**✅ Instead, Create a New Changeset:**
```sql
--changeset john:modify-users-name-column
ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(50);
--rollback ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(100);
```

### 2. Missing Rollback Statements

**❌ Avoid:**
```sql
--changeset jane:add-column
ALTER TABLE users ADD COLUMN email VARCHAR(255);
-- Missing rollback!
```

**✅ Always Include:**
```sql
--changeset jane:add-column
ALTER TABLE users ADD COLUMN email VARCHAR(255);
--rollback ALTER TABLE users DROP COLUMN email;
```

### 3. Not Testing Rollbacks

**✅ Always Test:**
```bash
# Test the rollback SQL
liquibase rollback-sql "tag-name"

# Execute rollback in test environment first
liquibase rollback "tag-name"

# Verify database state
# Then re-apply changes
liquibase update
```

### 4. Forgetting IF NOT EXISTS

**❌ Non-Idempotent:**
```sql
--changeset john:add-index
CREATE INDEX idx_users_email ON users(email);
-- Fails if index already exists
```

**✅ Idempotent:**
```sql
--changeset john:add-index
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
--rollback DROP INDEX IF EXISTS idx_users_email;
```

## 📋 Changeset Checklist

Before committing a new changeset:

- [ ] Contains only one logical change
- [ ] Has a unique, descriptive changeset ID
- [ ] Includes a meaningful comment
- [ ] Has a rollback statement
- [ ] Uses IF EXISTS / IF NOT EXISTS where appropriate
- [ ] Includes appropriate labels and contexts
- [ ] Has been tested locally
- [ ] Rollback has been tested
- [ ] Performance impact assessed (for large tables)
- [ ] Follows project naming conventions
- [ ] Does not modify previously executed changesets

## 🎨 File Organization

### Current Structure
```
code/
├── tables.sql      # Table definitions and modifications
├── views.sql       # View definitions
└── procedures.sql  # Stored procedures and functions
```

### Guidelines
1. **Tables**: All table-related changes (CREATE, ALTER, DROP)
2. **Views**: All view definitions (CREATE OR REPLACE VIEW)
3. **Procedures**: Stored procedures, functions, triggers

### When to Create New Files
Consider creating new files when:
- A file exceeds 500 lines
- A major feature requires multiple related changes
- Changes are for a specific module or subsystem

Example:
```
code/
├── tables.sql
├── views.sql
├── procedures.sql
├── indexes.sql          # If you have many indexes
└── security.sql         # For security-related changes
```

Then include in `db.changelog-master.xml`:
```xml
<include file="code/tables.sql" relativeToChangelogFile="true"/>
<include file="code/views.sql" relativeToChangelogFile="true"/>
<include file="code/procedures.sql" relativeToChangelogFile="true"/>
<include file="code/indexes.sql" relativeToChangelogFile="true"/>
<include file="code/security.sql" relativeToChangelogFile="true"/>
```

## 🔍 Review Checklist

For code reviewers:

- [ ] Changeset follows naming convention
- [ ] Comment explains the "why" not just "what"
- [ ] Rollback statement is correct and tested
- [ ] Change is idempotent
- [ ] No existing changesets were modified
- [ ] Labels and contexts are appropriate
- [ ] Performance impact is acceptable
- [ ] No hard-coded values (use parameters)
- [ ] SQL syntax is correct for target database
- [ ] Change is backwards compatible (if required)

## 📚 Additional Resources

- [Liquibase Best Practices](https://docs.liquibase.com/concepts/bestpractices.html)
- [Liquibase Changelog Parameters](https://docs.liquibase.com/concepts/changelogs/property-substitution.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🆘 Getting Help

If you're unsure about a changeset:
1. Review this guide
2. Check existing changesets for examples
3. Ask the team lead for review
4. Test thoroughly in development environment

---

**Remember**: A well-written changeset today saves hours of debugging tomorrow!