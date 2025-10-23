# Liquibase Project - Detailed Explanation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Database Change Management with Liquibase](#database-change-management-with-liquibase)
3. [Stored Procedures in Detail](#stored-procedures-in-detail)
4. [Rollback Mechanisms](#rollback-mechanisms)
5. [CI/CD Pipeline Flow](#cicd-pipeline-flow)
6. [Practical Examples](#practical-examples)

---

## Project Overview

This is a **GitLab CI/CD project** that demonstrates database change management using **Liquibase** with a **SQL Server Database**. Liquibase is a database schema change management tool that allows you to track, version, and deploy database changes in a structured and automated way.

### Project Structure
```
liquibase/
├── changelog.sql           # SQL-formatted changelog with database changes
├── changelog.xml           # XML-formatted changelog (alternative format)
├── objects/
│   └── storedprocedures/  # Directory containing stored procedure files
│       ├── CustOrderHist_v1.sql
│       ├── CustOrderHist_v2.sql
│       ├── CustOrdersDetail.sql
│       ├── CustOrdersOrders.sql
│       └── ... (other stored procedures)
├── .gitlab-ci.yml         # CI/CD pipeline configuration
└── README.md              # Basic project documentation
```

---

## Database Change Management with Liquibase

### What is a ChangeSet?

A **changeset** is the basic unit of change in Liquibase. Each changeset:
- Has a unique identifier (combination of author + id)
- Contains SQL statements to modify the database
- Can include rollback instructions
- Is executed only once (tracked in DATABASECHANGELOG table)

### ChangeLog Files

This project uses **two types of changelog formats**:

#### 1. SQL Format (`changelog.sql`)
The SQL format allows you to write native SQL with special Liquibase comments:

```sql
-- liquibase formatted sql changeLogId:e2baab75-eb98-40c0-848b-e4c758fd39bf

-- changeset SteveZ:createTable_salesTableZ
CREATE TABLE salesTableZ (
   ID int NOT NULL,
   NAME varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
   REGION varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
   MARKET varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
--rollback DROP TABLE salesTableZ
```

**Explanation:**
- `-- changeset Author:UniqueID` - Defines a new changeset
- SQL statements follow the changeset declaration
- `--rollback` - Specifies how to undo this change

#### 2. XML Format (`changelog.xml`)
The XML format provides more structure and options:

```xml
<changeSet author="Tsvi" id="CREATE_PROCEDURE_CustOrderHist_v2">
    <sqlFile path="objects/storedprocedure/CustOrderHist_v2.sql" endDelimiter="GO"/>
    <rollback>
        <sqlFile path="objects/storedprocedure/CustOrderHist_v1.sql" endDelimiter="GO"/>
    </rollback>
</changeSet>
```

**Explanation:**
- `<changeSet>` - XML element defining a changeset
- `<sqlFile>` - References an external SQL file
- `<rollback>` - Defines rollback behavior using another SQL file

---

## Stored Procedures in Detail

### What are Stored Procedures?

Stored procedures are **precompiled SQL code** stored in the database that can be executed multiple times. They:
- Accept parameters
- Execute complex business logic
- Return results
- Improve performance (compiled once, executed many times)
- Enhance security (can control data access)

### Stored Procedures in This Project

#### 1. **CustOrderHist_v1.sql** (Version 1)
```sql
DROP PROCEDURE IF EXISTS [dbo].[CustOrderHist]
GO

CREATE PROCEDURE [dbo].[CustOrderHist] @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity)
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName
GO
```

**What it does:**
1. **Drops existing procedure** if it exists (to avoid conflicts)
2. **Creates a new procedure** named `CustOrderHist`
3. **Accepts parameter** `@CustomerID` (5-character customer ID)
4. **Returns** product names and total quantities ordered by that customer
5. **Joins four tables**: Products, Order Details, Orders, and Customers
6. **Groups results** by product name

**Business Purpose:** Get the order history (products and quantities) for a specific customer.

#### 2. **CustOrderHist_v2.sql** (Version 2 - Modified)
```sql
DROP PROCEDURE IF EXISTS [dbo].[CustOrderHist]
GO

CREATE PROCEDURE [dbo].[CustOrderHist] @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity + 1)  -- Note: +1 added here
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName
GO
```

**What changed:**
- The calculation now uses `SUM(Quantity + 1)` instead of `SUM(Quantity)`
- This adds 1 to each quantity before summing (probably a bug or test change)

**Version Management:** 
- Version 1 is the original/correct version
- Version 2 is the "updated" version
- If you rollback, it will restore version 1

#### 3. **CustOrdersOrders.sql**
```sql
CREATE PROCEDURE [dbo].[CustOrdersOrders] @CustomerID nchar(5)
AS
SELECT OrderID, OrderDate, RequiredDate, ShippedDate
FROM Orders
WHERE CustomerID = @CustomerID
ORDER BY OrderID
```

**What it does:**
- Lists all orders for a specific customer
- Shows order dates, required dates, and shipped dates
- Orders results by OrderID

#### 4. **CustOrdersDetail.sql**
```sql
CREATE PROCEDURE [dbo].[CustOrdersDetail] @OrderID int
AS
SELECT ProductName,
    UnitPrice=ROUND(Od.UnitPrice, 2),
    Quantity,
    Discount=CONVERT(int, Discount * 100), 
    ExtendedPrice=ROUND(CONVERT(money, Quantity * (1 - Discount) * Od.UnitPrice), 2)
FROM Products P, [Order Details] Od
WHERE Od.ProductID = P.ProductID and Od.OrderID = @OrderID
```

**What it does:**
- Shows detailed line items for a specific order
- Calculates extended price: `Quantity × UnitPrice × (1 - Discount)`
- Formats discount as percentage (multiplies by 100)
- Rounds prices to 2 decimal places

### Stored Procedures in changelog.sql

The `changelog.sql` file also contains stored procedure definitions:

#### Example 1: Simple Stored Procedure Creation
```sql
--changeset Mike:CREATE_PROCEDURE_[dbo].[CustOrderHist1]
CREATE PROCEDURE dbo.CustOrderHist1 @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity)
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName;
--rollback DROP PROCEDURE [dbo].[CustOrderHist1];
```

**Rollback:** Simply drops the procedure if you need to undo the change.

#### Example 2: Stored Procedure with runOnChange
```sql
--changeset Mike:CREATE_PROCEDURE_[dbo].[CustOrderHist2] runOnChange:true
CREATE PROCEDURE [dbo].[CustOrderHist2] @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity)
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName;
--rollback DROP PROCEDURE [dbo].[CustOrderHist2];
```

**Special attribute `runOnChange:true`:**
- The changeset will re-run if the SQL code changes
- Useful for stored procedures that need to be updated
- Liquibase checks the checksum of the SQL

#### Example 3: Altering a Stored Procedure
```sql
--changeset Kevin:ALTER_PROCEDURE_[dbo].[CustOrderHist2]
ALTER PROCEDURE dbo.CustOrderHist2 @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity) + 1  -- Modified calculation
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName;
--rollback ALTER PROCEDURE [dbo].[CustOrderHist2] @CustomerID nchar(5) AS 
--rollback SELECT ProductName, Total=SUM(Quantity) 
--rollback FROM Products P, [Order Details] OD, Orders O, Customers C 
--rollback WHERE C.CustomerID = @CustomerID 
--rollback AND C.CustomerID = O.CustomerID 
--rollback AND O.OrderID = OD.OrderID 
--rollback AND OD.ProductID = P.ProductID GROUP BY ProductName;
```

**Key Points:**
- Uses `ALTER PROCEDURE` to modify existing procedure
- Rollback contains the **previous version** of the procedure
- Multi-line rollback uses multiple `--rollback` comments

---

## Rollback Mechanisms

### Why Rollback is Important

Rollback allows you to **undo database changes** when:
- A deployment causes issues
- You need to revert to a previous stable state
- Testing requires reverting changes
- A bug is discovered in production

### How Liquibase Tracks Changes

Liquibase maintains two special tables in your database:

1. **DATABASECHANGELOG** - Records all executed changesets
   - id, author, filename, dateExecuted, orderExecuted, execType, md5sum, etc.

2. **DATABASECHANGELOGLOCK** - Prevents concurrent modifications
   - Ensures only one process modifies the database at a time

### Types of Rollback in This Project

#### 1. **Simple Rollback (Drop Table)**
```sql
--changeset SteveZ:createTable_salesTableZ
CREATE TABLE salesTableZ (...)
--rollback DROP TABLE salesTableZ
```

**How it works:**
- **Forward:** Creates the table
- **Rollback:** Drops the table
- **Simple and clean**

#### 2. **Multi-Statement Rollback (Delete Rows)**
```sql
--changeset SteveZ:insertInto_salesTableZ
INSERT INTO salesTableZ (ID, NAME, REGION, MARKET)
VALUES
(0, 'AXV', 'NA', 'HHN'),
(1, 'MKL', 'SA', 'LMP'),
(2, 'POK', 'LA', 'LLA'),
(3, 'DER', 'CA', 'PRA'),
(4, 'BFV', 'PA', 'LMP'),
(5, 'SAW', 'AA', 'LMP'),
(6, 'JUF', 'NY', 'LMP')
--rollback DELETE FROM salesTableZ WHERE ID=0
--rollback DELETE FROM salesTableZ WHERE ID=1
--rollback DELETE FROM salesTableZ WHERE ID=2
--rollback DELETE FROM salesTableZ WHERE ID=3
--rollback DELETE FROM salesTableZ WHERE ID=4
--rollback DELETE FROM salesTableZ WHERE ID=5
--rollback DELETE FROM salesTableZ WHERE ID=6
```

**How it works:**
- **Forward:** Inserts 7 rows
- **Rollback:** Deletes each row individually by ID
- **Preserves data integrity** (only removes what was added)

#### 3. **Constraint Rollback**
```sql
--changeset Martha:addPrimaryKey_pk_CustomerTypeID
ALTER TABLE CustomerInfo ADD CONSTRAINT pk_CustomerTypeID PRIMARY KEY (CustomerTypeID)
--rollback ALTER TABLE CustomerInfo DROP CONSTRAINT pk_CustomerTypeID
```

**How it works:**
- **Forward:** Adds primary key constraint
- **Rollback:** Removes the constraint
- **Maintains referential integrity**

#### 4. **Column Addition Rollback**
```sql
--changeset Amy:CustomerInfo_ADD_address
ALTER TABLE CustomerInfo ADD address varchar(255)
--rollback ALTER TABLE CustomerInfo DROP COLUMN address
```

**How it works:**
- **Forward:** Adds new column
- **Rollback:** Removes the column (and any data in it)
- **Warning:** Data loss occurs on rollback

#### 5. **Stored Procedure Rollback (Drop)**
```sql
--changeset Mike:CREATE_PROCEDURE_[dbo].[CustOrderHist1]
CREATE PROCEDURE dbo.CustOrderHist1 @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity)
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName;
--rollback DROP PROCEDURE [dbo].[CustOrderHist1];
```

**How it works:**
- **Forward:** Creates the stored procedure
- **Rollback:** Drops the stored procedure
- **Complete removal** of the procedure

#### 6. **Stored Procedure Rollback (Restore Previous Version)**
```sql
--changeset Kevin:ALTER_PROCEDURE_[dbo].[CustOrderHist2]
ALTER PROCEDURE dbo.CustOrderHist2 @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity) + 1
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName;
--rollback ALTER PROCEDURE [dbo].[CustOrderHist2] @CustomerID nchar(5) AS 
--rollback SELECT ProductName, Total=SUM(Quantity) 
--rollback FROM Products P, [Order Details] OD, Orders O, Customers C 
--rollback WHERE C.CustomerID = @CustomerID 
--rollback AND C.CustomerID = O.CustomerID 
--rollback AND O.OrderID = OD.OrderID 
--rollback AND OD.ProductID = P.ProductID GROUP BY ProductName;
```

**How it works:**
- **Forward:** Modifies procedure (adds +1 to calculation)
- **Rollback:** Restores previous version (removes +1)
- **Preserves the procedure** with original logic

#### 7. **File-Based Rollback (XML Format)**
```xml
<changeSet author="Tsvi" id="CREATE_PROCEDURE_CustOrderHist_v2">
    <sqlFile path="objects/storedprocedure/CustOrderHist_v2.sql" endDelimiter="GO"/>
    <rollback>
        <sqlFile path="objects/storedprocedure/CustOrderHist_v1.sql" endDelimiter="GO"/>
    </rollback>
</changeSet>
```

**How it works:**
- **Forward:** Executes `CustOrderHist_v2.sql` (creates procedure with `Quantity + 1`)
- **Rollback:** Executes `CustOrderHist_v1.sql` (creates procedure with `Quantity` only)
- **Version management:** Maintains multiple versions of the same procedure in separate files

**File contents:**
- `CustOrderHist_v2.sql`: `Total=SUM(Quantity + 1)` (buggy version)
- `CustOrderHist_v1.sql`: `Total=SUM(Quantity)` (correct version)

### Liquibase Rollback Commands

#### 1. **rollback <tag>**
```bash
liquibase rollback myTag
```
- Rolls back all changes made after the specified tag
- Tags are created using `liquibase tag <tagName>`

#### 2. **rollbackOneUpdate --force**
```bash
liquibase rollbackOneUpdate --force
```
- Rolls back the most recent deployment
- `--force` bypasses confirmation
- Used in the CI/CD pipeline (line 38 of `.gitlab-ci.yml`)

#### 3. **rollbackCount <number>**
```bash
liquibase rollbackCount 3
```
- Rolls back the specified number of changesets

#### 4. **rollbackToDate <date>**
```bash
liquibase rollbackToDate 2024-01-01
```
- Rolls back all changes made after the specified date

#### 5. **rollbackSQL <tag>** (Preview)
```bash
liquibase rollbackSQL myTag
```
- Shows the SQL that would be executed for rollback
- Doesn't actually execute the rollback
- Useful for reviewing changes before applying

---

## CI/CD Pipeline Flow

### Pipeline Stages

The `.gitlab-ci.yml` defines a multi-stage pipeline:

```
build → test → deploy → compare → snapshot
```

### Helper Functions

#### 1. **isUpToDate()**
```bash
function isUpToDate(){
  status=$(liquibase status --verbose)
  if [[ $status == *'is up to date'* ]]; then
    echo "database is already up to date" & exit 0
  fi;
}
```
**Purpose:** Checks if database has pending changes. Exits if already up-to-date.

#### 2. **isRollback()**
```bash
function isRollback(){
  if [ -z "$TAG" ]; then
    echo "No TAG provided, running any pending changes"
  elif [[ "$(liquibase rollbackSQL $TAG)" ]]; then
    liquibase --logLevel=info --logFile=${CI_JOB_NAME}_${CI_PIPELINE_ID}.log rollback $TAG && exit 0
  else exit 0
  fi;
}
```
**Purpose:** 
- If TAG environment variable is set, performs rollback to that tag
- Otherwise, proceeds with normal deployment
- This allows selective rollback in the pipeline

### Standard Job Flow (.liquibase_job)

Each environment (DEV, QA, PROD) follows this sequence:

```bash
1. isRollback              # Check if rollback is needed
2. isUpToDate              # Check if updates are needed
3. liquibase checks run    # Run quality checks
4. liquibase updateSQL     # Preview SQL changes
5. liquibase update        # Apply changes
6. liquibase rollbackOneUpdate --force  # Test rollback capability
7. liquibase tag $CI_PIPELINE_ID        # Tag this deployment
8. liquibase update        # Re-apply (after testing rollback)
9. liquibase history       # Show deployment history
```

### Why Test Rollback in Pipeline?

**Line 38:** `liquibase rollbackOneUpdate --force`

This step is **crucial** because it:
1. **Validates rollback SQL** - Ensures your rollback statements work
2. **Tests recovery** - Confirms you can undo changes if needed
3. **Catches errors early** - Finds rollback issues before production
4. **Documents the process** - Creates a log of the rollback test

**The flow:**
```
Update → Apply Changes → Rollback One Update (Test) → Tag → Re-apply → Done
```

After rollback test succeeds, changes are re-applied (line 40) so the database ends up in the desired state.

### Environment Progression

#### Build Stage (DEV)
- Runs quality checks
- Tests changes in development environment
- Creates logs: `build-job_<pipeline_id>.log`

#### Test Stage (QA)
- Deploys to QA environment
- Runs same checks as DEV
- Creates logs: `test-job_<pipeline_id>.log`

#### Deploy Stage (PROD)
- Deploys to production
- Applies same verified changes
- Creates logs: `deploy-prod_<pipeline_id>.log`

#### Compare Stage
- **DEV→TEST:** Compares DEV and TEST databases for drift
- **TEST→PROD:** Compares TEST and PROD databases for drift
- Generates JSON reports: `diff_between_DEV_TEST.json`, `diff_between_TEST_PROD.json`

#### Snapshot Stage
- Creates snapshot of PROD database
- JSON format: `snapshot_PROD_<pipeline_id>.json`
- Useful for drift detection and security analysis

---

## Practical Examples

### Example 1: Creating a Table with Rollback

**Scenario:** Add a new customer table

```sql
--changeset john:create_customer_table
CREATE TABLE Customers (
    CustomerID int PRIMARY KEY,
    CustomerName varchar(100) NOT NULL,
    Email varchar(100),
    CreatedDate datetime DEFAULT GETDATE()
)
--rollback DROP TABLE Customers
```

**What happens:**
1. **Deploy:** Table is created
2. **Tracked:** Changeset recorded in DATABASECHANGELOG
3. **If rollback:** Table is dropped
4. **Result:** Database returns to previous state

### Example 2: Modifying a Stored Procedure

**Scenario:** Update procedure logic

**Initial version:**
```sql
--changeset jane:create_get_orders_v1
CREATE PROCEDURE GetCustomerOrders @CustomerID int
AS
SELECT * FROM Orders WHERE CustomerID = @CustomerID
--rollback DROP PROCEDURE GetCustomerOrders
```

**Updated version:**
```sql
--changeset jane:update_get_orders_v2
ALTER PROCEDURE GetCustomerOrders @CustomerID int
AS
SELECT OrderID, OrderDate, TotalAmount 
FROM Orders 
WHERE CustomerID = @CustomerID
ORDER BY OrderDate DESC
--rollback ALTER PROCEDURE GetCustomerOrders @CustomerID int AS
--rollback SELECT * FROM Orders WHERE CustomerID = @CustomerID
```

**What happens:**
1. **Deploy v1:** Procedure created (returns all columns)
2. **Deploy v2:** Procedure modified (returns specific columns, sorted)
3. **Rollback v2:** Procedure reverted to v1 (returns all columns)
4. **Result:** Can switch between versions

### Example 3: CI/CD with Rollback

**Normal Deployment (No TAG):**
```bash
# Deployment pipeline runs
1. Check status
2. Run quality checks
3. Preview SQL (updateSQL)
4. Apply changes (update)
5. Test rollback (rollbackOneUpdate --force)
6. Tag deployment (tag CI_PIPELINE_ID)
7. Re-apply changes (update)
8. Show history
```

**Rollback Deployment (TAG set to previous pipeline ID):**
```bash
# Set environment variable: TAG=12345
1. isRollback() detects TAG
2. Previews rollback SQL
3. Executes rollback to tag 12345
4. Exits successfully
```

### Example 4: Handling Failed Deployment

**Scenario:** Deployment fails in PROD

```bash
# Step 1: Identify the pipeline ID from history
liquibase history

# Step 2: Set TAG to previous good deployment
export TAG=previous_pipeline_id

# Step 3: Re-run the pipeline
# The isRollback() function will handle the rollback
```

**Alternative using command:**
```bash
# Direct rollback command
liquibase rollback previous_pipeline_id

# Or rollback last deployment
liquibase rollbackOneUpdate --force
```

---

## Key Concepts Summary

### Changesets
- **Atomic units** of database change
- **Executed once** (unless runOnChange=true)
- **Tracked** in DATABASECHANGELOG
- **Include rollback** instructions

### Stored Procedures
- **Precompiled** SQL code in database
- **Accept parameters** for flexibility
- **Improve performance** (compiled once)
- **Version controlled** through Liquibase
- **Can be rolled back** to previous versions

### Rollback
- **Safety mechanism** to undo changes
- **Required for each changeset** (best practice)
- **Multiple strategies:**
  - Drop objects (tables, procedures)
  - Delete data (inserted rows)
  - Restore previous versions (ALTER statements)
  - Execute rollback files (file-based)
- **Tested automatically** in CI/CD pipeline

### CI/CD Pipeline
- **Multi-stage** deployment (DEV → QA → PROD)
- **Automatic checks** (quality, drift detection)
- **Rollback testing** built-in
- **Audit trail** (history, snapshots, logs)
- **Tag-based** version control

---

## Best Practices from This Project

1. **Always provide rollback statements** - Every changeset has a rollback
2. **Test rollback in pipeline** - Line 38 validates rollback works
3. **Use tags for versions** - Pipeline ID tags each deployment
4. **Version stored procedures** - Separate files for v1, v2, etc.
5. **Preview before applying** - `updateSQL` shows changes first
6. **Maintain audit trail** - History and snapshots track changes
7. **Detect drift** - Compare environments regularly
8. **Log everything** - All operations logged for troubleshooting

---

## Troubleshooting

### Issue: Rollback fails
**Solution:** Check the rollback SQL syntax in your changeset

### Issue: Changes not applied
**Solution:** Run `liquibase status` to see pending changes

### Issue: Checksum mismatch
**Solution:** Changeset was modified after deployment. Use `clearCheckSums` or add `runOnChange:true`

### Issue: Stored procedure not updated
**Solution:** Use `runOnChange:true` attribute for procedures that need updates

---

## Conclusion

This Liquibase project demonstrates **enterprise-grade database change management** with:
- Comprehensive rollback strategies
- Stored procedure version control
- Automated CI/CD pipeline
- Quality checks and drift detection
- Complete audit trail

The key to success is understanding that **every change must be reversible**, and this project exemplifies that principle through well-crafted rollback statements and automated testing.
