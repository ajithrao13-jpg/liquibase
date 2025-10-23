# Liquibase Quick Reference Guide

## Quick Command Reference

### Update/Deploy Commands
```bash
# Check what changes will be applied
liquibase status

# Preview SQL that will be executed
liquibase updateSQL

# Apply all pending changes
liquibase update

# Apply changes and create a tag
liquibase update
liquibase tag <tagname>
```

### Rollback Commands
```bash
# Preview rollback SQL (doesn't execute)
liquibase rollbackSQL <tag>

# Rollback to a specific tag
liquibase rollback <tag>

# Rollback the last deployment
liquibase rollbackOneUpdate --force

# Rollback N changesets
liquibase rollbackCount <N>

# Rollback to a specific date
liquibase rollbackToDate "YYYY-MM-DD"
```

### Information Commands
```bash
# View deployment history
liquibase history

# View pending changesets
liquibase status --verbose

# Create a database snapshot
liquibase snapshot --snapshotFormat=json

# Compare two databases for drift
liquibase diff

# Generate changelog from existing database
liquibase generateChangeLog
```

### Quality & Security Commands
```bash
# Run quality checks
liquibase checks run

# Show configured checks
liquibase checks show

# Validate changelog syntax
liquibase validate
```

---

## Changeset Syntax Reference

### SQL Format Changeset

```sql
-- liquibase formatted sql

--changeset author:unique_id
CREATE TABLE MyTable (
    ID int PRIMARY KEY,
    Name varchar(100)
)
--rollback DROP TABLE MyTable
```

### XML Format Changeset

```xml
<changeSet author="author" id="unique_id">
    <createTable tableName="MyTable">
        <column name="ID" type="int">
            <constraints primaryKey="true"/>
        </column>
        <column name="Name" type="varchar(100)"/>
    </createTable>
    <rollback>
        <dropTable tableName="MyTable"/>
    </rollback>
</changeSet>
```

### Common Changeset Attributes

```sql
--changeset author:id runOnChange:true
--changeset author:id runAlways:true
--changeset author:id failOnError:false
--changeset author:id context:dev,test
--changeset author:id labels:version1
--changeset author:id runInTransaction:false
```

---

## Common Change Types

### Table Operations

```sql
-- Create table
--changeset author:create_table
CREATE TABLE MyTable (ID int, Name varchar(100))
--rollback DROP TABLE MyTable

-- Drop table
--changeset author:drop_table
DROP TABLE MyTable
--rollback CREATE TABLE MyTable (ID int, Name varchar(100))

-- Rename table
--changeset author:rename_table
EXEC sp_rename 'OldTable', 'NewTable'
--rollback EXEC sp_rename 'NewTable', 'OldTable'
```

### Column Operations

```sql
-- Add column
--changeset author:add_column
ALTER TABLE MyTable ADD NewColumn varchar(50)
--rollback ALTER TABLE MyTable DROP COLUMN NewColumn

-- Drop column (CAUTION: data loss)
--changeset author:drop_column
ALTER TABLE MyTable DROP COLUMN OldColumn
--rollback ALTER TABLE MyTable ADD OldColumn varchar(50)

-- Rename column
--changeset author:rename_column
EXEC sp_rename 'MyTable.OldName', 'NewName', 'COLUMN'
--rollback EXEC sp_rename 'MyTable.NewName', 'OldName', 'COLUMN'

-- Modify column type
--changeset author:modify_column
ALTER TABLE MyTable ALTER COLUMN MyColumn varchar(200)
--rollback ALTER TABLE MyTable ALTER COLUMN MyColumn varchar(100)
```

### Constraint Operations

```sql
-- Add primary key
--changeset author:add_pk
ALTER TABLE MyTable ADD CONSTRAINT pk_MyTable PRIMARY KEY (ID)
--rollback ALTER TABLE MyTable DROP CONSTRAINT pk_MyTable

-- Add foreign key
--changeset author:add_fk
ALTER TABLE Orders ADD CONSTRAINT fk_customer 
    FOREIGN KEY (CustomerID) REFERENCES Customers(ID)
--rollback ALTER TABLE Orders DROP CONSTRAINT fk_customer

-- Add unique constraint
--changeset author:add_unique
ALTER TABLE MyTable ADD CONSTRAINT uq_Email UNIQUE (Email)
--rollback ALTER TABLE MyTable DROP CONSTRAINT uq_Email

-- Add check constraint
--changeset author:add_check
ALTER TABLE MyTable ADD CONSTRAINT chk_Age CHECK (Age >= 18)
--rollback ALTER TABLE MyTable DROP CONSTRAINT chk_Age
```

### Index Operations

```sql
-- Create index
--changeset author:create_index
CREATE INDEX idx_Name ON MyTable (Name)
--rollback DROP INDEX idx_Name ON MyTable

-- Create unique index
--changeset author:create_unique_index
CREATE UNIQUE INDEX idx_Email ON MyTable (Email)
--rollback DROP INDEX idx_Email ON MyTable

-- Drop index
--changeset author:drop_index
DROP INDEX idx_OldIndex ON MyTable
--rollback CREATE INDEX idx_OldIndex ON MyTable (OldColumn)
```

### Data Operations

```sql
-- Insert data
--changeset author:insert_data
INSERT INTO MyTable (ID, Name) VALUES (1, 'Test')
--rollback DELETE FROM MyTable WHERE ID = 1

-- Update data
--changeset author:update_data
UPDATE MyTable SET Status = 'Active' WHERE ID = 1
--rollback UPDATE MyTable SET Status = 'Inactive' WHERE ID = 1

-- Delete data (CAUTION: data loss)
--changeset author:delete_data
DELETE FROM MyTable WHERE Status = 'Obsolete'
--rollback INSERT INTO MyTable SELECT * FROM MyTable_Backup WHERE Status = 'Obsolete'
```

### Stored Procedure Operations

```sql
-- Create stored procedure
--changeset author:create_proc
CREATE PROCEDURE MyProc @Param int
AS
    SELECT * FROM MyTable WHERE ID = @Param
--rollback DROP PROCEDURE MyProc

-- Alter stored procedure
--changeset author:alter_proc
ALTER PROCEDURE MyProc @Param int
AS
    SELECT ID, Name FROM MyTable WHERE ID = @Param
--rollback ALTER PROCEDURE MyProc @Param int AS
--rollback SELECT * FROM MyTable WHERE ID = @Param

-- Drop stored procedure
--changeset author:drop_proc
DROP PROCEDURE MyProc
--rollback CREATE PROCEDURE MyProc @Param int AS SELECT * FROM MyTable WHERE ID = @Param

-- Create/Alter with runOnChange
--changeset author:proc_with_runOnChange runOnChange:true
CREATE OR ALTER PROCEDURE MyProc @Param int
AS
    SELECT * FROM MyTable WHERE ID = @Param
--rollback DROP PROCEDURE MyProc
```

---

## Project-Specific Patterns

### Pattern 1: SQL File ChangeLog (changelog.sql)

This project uses SQL format with special comments:

```sql
-- liquibase formatted sql changeLogId:unique-id

--changeset author:change_id
SQL STATEMENTS HERE
--rollback ROLLBACK SQL HERE
```

### Pattern 2: XML File ChangeLog (changelog.xml)

References external SQL files:

```xml
<changeSet author="author" id="change_id">
    <sqlFile path="path/to/file.sql" endDelimiter="GO"/>
    <rollback>
        <sqlFile path="path/to/rollback_file.sql" endDelimiter="GO"/>
    </rollback>
</changeSet>
```

### Pattern 3: Stored Procedure Versioning

Maintain multiple versions in separate files:

```
objects/storedprocedures/
├── MyProc_v1.sql  (original version)
├── MyProc_v2.sql  (updated version)
└── MyProc_v3.sql  (latest version)
```

Reference in changelog:
```xml
<changeSet author="dev" id="myproc_v3">
    <sqlFile path="objects/storedprocedures/MyProc_v3.sql" endDelimiter="GO"/>
    <rollback>
        <sqlFile path="objects/storedprocedures/MyProc_v2.sql" endDelimiter="GO"/>
    </rollback>
</changeSet>
```

---

## CI/CD Pipeline Flow

### Normal Deployment (No TAG set)

```
1. isRollback()           → Check for TAG (none found)
2. isUpToDate()           → Check if changes needed
3. liquibase checks run   → Run quality checks
4. liquibase updateSQL    → Preview changes
5. liquibase update       → Apply changes
6. liquibase rollbackOneUpdate --force  → Test rollback
7. liquibase tag <id>     → Tag deployment
8. liquibase update       → Re-apply after rollback test
9. liquibase history      → Show deployment log
```

### Rollback Deployment (TAG set)

```
1. isRollback()           → Check for TAG (found!)
2. liquibase rollbackSQL  → Preview rollback
3. liquibase rollback <TAG> → Execute rollback
4. Exit                   → Stop (don't continue)
```

### Multi-Environment Flow

```
DEV Environment (build stage)
    ↓ (if successful)
QA Environment (test stage)
    ↓ (if successful)
PROD Environment (deploy stage)
    ↓ (after deployment)
Compare Environments (compare stage)
    ↓ (drift detection)
Snapshot PROD (post stage)
```

---

## Troubleshooting Quick Fixes

### Issue: "Changeset already executed"
```bash
# Clear checksums if changeset was modified
liquibase clearCheckSums
```

### Issue: "Database is locked"
```bash
# Release locks
liquibase releaseLocks
```

### Issue: "Validation failed"
```bash
# Validate changelog syntax
liquibase validate

# Check detailed status
liquibase status --verbose
```

### Issue: "Rollback failed"
```bash
# Preview what rollback would do
liquibase rollbackSQL <tag>

# Check if rollback SQL is correct in changelog
# Fix and retry
```

### Issue: "Checksum mismatch"
```bash
# Option 1: Clear checksums (if change was intentional)
liquibase clearCheckSums

# Option 2: Use runOnChange attribute
--changeset author:id runOnChange:true
```

---

## Best Practices Checklist

### ✅ Before Deployment
- [ ] Review changelog for syntax errors
- [ ] Verify all changesets have rollback statements
- [ ] Test in DEV environment first
- [ ] Run `liquibase updateSQL` to preview changes
- [ ] Run `liquibase checks run` for quality validation
- [ ] Tag deployment point for rollback capability

### ✅ After Deployment
- [ ] Verify changes applied correctly
- [ ] Run `liquibase history` to confirm
- [ ] Test application functionality
- [ ] Monitor for issues
- [ ] Create database snapshot for drift detection

### ✅ Rollback Preparation
- [ ] Identify the tag to rollback to
- [ ] Run `liquibase rollbackSQL <tag>` to preview
- [ ] Notify stakeholders of planned rollback
- [ ] Execute rollback during maintenance window
- [ ] Verify database state after rollback

---

## Important Files in This Project

```
liquibase/
├── changelog.sql                    # Main SQL changelog
├── changelog.xml                    # XML changelog (for file-based changes)
├── objects/storedprocedures/       # Stored procedure SQL files
│   ├── CustOrderHist_v1.sql       # Version 1 (original)
│   ├── CustOrderHist_v2.sql       # Version 2 (modified)
│   ├── CustOrdersOrders.sql       # Orders list procedure
│   └── CustOrdersDetail.sql       # Order details procedure
├── .gitlab-ci.yml                  # CI/CD pipeline configuration
├── liquibase.checks-settings.conf  # Quality checks configuration
├── DETAILED_EXPLANATION.md         # Complete project documentation
├── STORED_PROCEDURES_GUIDE.md      # Stored procedures deep dive
├── ROLLBACK_GUIDE.md              # Rollback mechanisms guide
└── QUICK_REFERENCE.md             # This file
```

---

## Key Concepts Summary

### Changesets
- **Atomic units** of database change
- **Executed once** (unless runOnChange or runAlways)
- **Tracked** in DATABASECHANGELOG table
- **Must include rollback** for safety

### Rollback
- **Undo mechanism** for database changes
- **Executes in reverse order** (last change first)
- **Tag-based** or count-based or date-based
- **Should be tested** before production deployment

### Stored Procedures
- **Precompiled SQL** stored in database
- **Accept parameters** for flexibility
- **Version controlled** through Liquibase changesets
- **Use runOnChange** for automatic updates

### Tags
- **Named checkpoints** in deployment history
- **Reference points** for rollback
- **Created after** successful deployment
- **Best practice:** Use version numbers or pipeline IDs

---

## Environment Variables (CI/CD)

```bash
# Database connection
LIQUIBASE_URL=jdbc:sqlserver://server:1433;database=mydb
LIQUIBASE_USERNAME=dbuser
LIQUIBASE_PASSWORD=dbpassword

# Rollback control
TAG=<pipeline_id>  # Set to trigger rollback in pipeline

# Pipeline variables
CI_JOB_NAME        # Current job name
CI_PIPELINE_ID     # Unique pipeline identifier
CI_COMMIT_BRANCH   # Current branch
CI_DEFAULT_BRANCH  # Main/default branch
```

---

## SQL Server Specific Commands

```sql
-- Rename table
EXEC sp_rename 'OldTableName', 'NewTableName'

-- Rename column
EXEC sp_rename 'TableName.OldColumnName', 'NewColumnName', 'COLUMN'

-- Drop procedure safely
DROP PROCEDURE IF EXISTS [dbo].[ProcedureName]

-- Batch separator (required between statements)
GO

-- Create/Alter procedure (SQL Server 2016+)
CREATE OR ALTER PROCEDURE [dbo].[ProcName]
AS
    SELECT * FROM MyTable
GO
```

---

## Useful SQL Queries

### Check Applied Changesets
```sql
SELECT * FROM DATABASECHANGELOG
ORDER BY DATEEXECUTED DESC
```

### Check Tagged Versions
```sql
SELECT * FROM DATABASECHANGELOG
WHERE TAG IS NOT NULL
ORDER BY DATEEXECUTED DESC
```

### Check Last Deployment
```sql
SELECT TOP 1 DEPLOYMENTID, COUNT(*) as ChangesetCount
FROM DATABASECHANGELOG
GROUP BY DEPLOYMENTID
ORDER BY MAX(DATEEXECUTED) DESC
```

### Find Specific Changeset
```sql
SELECT * FROM DATABASECHANGELOG
WHERE ID = 'your_changeset_id'
AND AUTHOR = 'your_author'
```

---

## Links to Detailed Documentation

- **[DETAILED_EXPLANATION.md](DETAILED_EXPLANATION.md)** - Complete project overview, architecture, and concepts
- **[STORED_PROCEDURES_GUIDE.md](STORED_PROCEDURES_GUIDE.md)** - Deep dive into stored procedures with examples
- **[ROLLBACK_GUIDE.md](ROLLBACK_GUIDE.md)** - Comprehensive rollback mechanisms and strategies
- **[README.md](README.md)** - Original project README with getting started info

---

## External Resources

- [Liquibase Documentation](https://docs.liquibase.com/)
- [Liquibase Commands Reference](https://docs.liquibase.com/commands/home.html)
- [GitLab Blog Post](https://about.gitlab.com/blog/2022/01/05/how-to-bring-devops-to-the-database-with-gitlab-and-liquibase/)
- [Liquibase Quality Checks](https://www.liquibase.com/quality-checks)
- [Liquibase Pro Features](https://www.liquibase.com/devsecops)

---

*This quick reference covers the essential commands and patterns used in this Liquibase project. For detailed explanations, see the comprehensive guides listed above.*
