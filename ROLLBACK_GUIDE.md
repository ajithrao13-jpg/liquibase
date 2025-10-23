# Liquibase Rollback: Complete Guide

## What is Rollback?

**Rollback** is the ability to **undo database changes** and return to a previous state. Think of it like:
- **Ctrl+Z** for your database
- **Time machine** for your schema
- **Undo button** for deployments
- **Safety net** for production

---

## Why Rollback Matters

### Real-World Scenarios

#### Scenario 1: Bug in Production
```
Friday 5 PM: Deploy new stored procedure
Friday 5:30 PM: Users report incorrect calculations
Friday 5:35 PM: ROLLBACK to previous version
Friday 5:36 PM: System working again ✅
```

#### Scenario 2: Performance Issue
```
Deploy: Add new index
Result: Database slows down (wrong index strategy)
Action: ROLLBACK the index
Result: Performance restored ✅
```

#### Scenario 3: Data Issue
```
Deploy: ALTER table adding column
Result: Application errors (old code doesn't expect column)
Action: ROLLBACK to remove column
Result: Application working ✅
```

#### Scenario 4: Failed Dependency
```
Deploy: Update stored procedure A
Deploy: Update stored procedure B (depends on A)
Result: Procedure B fails
Action: ROLLBACK both procedures
Result: Both back to working state ✅
```

---

## How Liquibase Tracks Changes

### The DATABASECHANGELOG Table

When you run Liquibase update, it creates a special table:

```sql
DATABASECHANGELOG
├── ID                  (changeset identifier)
├── AUTHOR              (who made the change)
├── FILENAME            (which changelog file)
├── DATEEXECUTED        (when it was run)
├── ORDEREXECUTED       (sequence number)
├── EXECTYPE            (EXECUTED, RERAN, etc.)
├── MD5SUM              (checksum of SQL)
├── DESCRIPTION         (what changed)
├── COMMENTS            (notes)
├── TAG                 (version tag)
├── LIQUIBASE           (version used)
└── CONTEXTS            (deployment context)
```

### Example DATABASECHANGELOG Contents:

```
| ID                              | AUTHOR | FILENAME      | DATEEXECUTED        | ORDEREXECUTED | TAG   |
|---------------------------------|--------|---------------|---------------------|---------------|-------|
| createTable_salesTableZ         | SteveZ | changelog.sql | 2024-01-15 10:00:00 | 1             |       |
| insertInto_salesTableZ          | SteveZ | changelog.sql | 2024-01-15 10:00:01 | 2             |       |
| createTable_CustomerInfo        | SteveZ | changelog.sql | 2024-01-15 10:00:02 | 3             |       |
| addPrimaryKey_pk_CustomerTypeID | Martha | changelog.sql | 2024-01-15 10:00:03 | 4             | v1.0  |
| CustomerInfo_ADD_address        | Amy    | changelog.sql | 2024-01-15 10:00:04 | 5             |       |
| CREATE_PROCEDURE_CustOrderHist1 | Mike   | changelog.sql | 2024-01-15 10:00:05 | 6             |       |
| CREATE_PROCEDURE_CustOrderHist_v2| Tsvi  | changelog.xml | 2024-01-15 10:00:06 | 7             | v1.1  |
```

This table is how Liquibase knows:
- ✅ What changes have been applied
- ✅ In what order they were applied
- ✅ When to stop rolling back
- ✅ What to roll back

---

## Rollback Commands

### 1. rollback <tag>

**Syntax:**
```bash
liquibase rollback <tag>
```

**What it does:**
- Rolls back all changesets executed **after** the specified tag
- Stops at the tagged changeset
- Executes rollback statements in **reverse order**

**Example:**

**Current State:**
```
[TAG: v1.0]
   ↓ Applied
[Changeset A]
   ↓ Applied
[Changeset B]
   ↓ Applied
[Changeset C]
   ↓ Applied
[TAG: v1.1]
   ↓ Applied
[Changeset D] ← Current state
```

**Command:**
```bash
liquibase rollback v1.1
```

**Result:**
```
[TAG: v1.0]
   ↓ Applied
[Changeset A]
   ↓ Applied
[Changeset B]
   ↓ Applied
[Changeset C]
   ↓ Applied
[TAG: v1.1] ← Rolled back to here ✅
   ✗ Rolled back
[Changeset D] ✗ Rolled back
```

**Rollback Order:**
1. Rollback Changeset D
2. Stop (at tag v1.1)

---

### 2. rollbackOneUpdate --force

**Syntax:**
```bash
liquibase rollbackOneUpdate --force
```

**What it does:**
- Rolls back the **most recent deployment** (all changesets in last update)
- `--force` skips confirmation prompt
- Useful for quick "undo last change"

**Example:**

**Deployment 1 (Tuesday):**
```
Applied: Changeset A, B, C
```

**Deployment 2 (Wednesday):**
```
Applied: Changeset D, E, F
```

**Current State:**
```
[Changeset A] ← Deployment 1
[Changeset B] ← Deployment 1
[Changeset C] ← Deployment 1
[Changeset D] ← Deployment 2
[Changeset E] ← Deployment 2
[Changeset F] ← Deployment 2 (latest)
```

**Command:**
```bash
liquibase rollbackOneUpdate --force
```

**Result:**
```
[Changeset A] ← Deployment 1
[Changeset B] ← Deployment 1
[Changeset C] ← Deployment 1 ✅ Current state after rollback
   ✗ Rolled back Changeset D
   ✗ Rolled back Changeset E
   ✗ Rolled back Changeset F
```

**All changesets from Deployment 2 are rolled back.**

---

### 3. rollbackCount <number>

**Syntax:**
```bash
liquibase rollbackCount 3
```

**What it does:**
- Rolls back the specified **number of changesets**
- Counts from most recent backwards

**Example:**

**Current State:**
```
[Changeset A]
[Changeset B]
[Changeset C]
[Changeset D]
[Changeset E] ← Current state
```

**Command:**
```bash
liquibase rollbackCount 3
```

**Result:**
```
[Changeset A]
[Changeset B] ← Rolled back to here ✅
   ✗ Rolled back Changeset C
   ✗ Rolled back Changeset D
   ✗ Rolled back Changeset E
```

**3 changesets rolled back (E, D, C).**

---

### 4. rollbackToDate <date>

**Syntax:**
```bash
liquibase rollbackToDate "2024-01-15"
liquibase rollbackToDate "2024-01-15 10:30:00"
```

**What it does:**
- Rolls back all changesets executed **after** specified date/time
- Useful for "go back to yesterday"

**Example:**

**Changesets:**
```
Changeset A - Executed: 2024-01-15 09:00:00
Changeset B - Executed: 2024-01-15 10:00:00
Changeset C - Executed: 2024-01-15 11:00:00
Changeset D - Executed: 2024-01-15 12:00:00
Changeset E - Executed: 2024-01-15 13:00:00 ← Current
```

**Command:**
```bash
liquibase rollbackToDate "2024-01-15 10:30:00"
```

**Result:**
```
Changeset A - 09:00:00 ✅
Changeset B - 10:00:00 ✅ Rolled back to here
   ✗ Changeset C - 11:00:00 (after 10:30)
   ✗ Changeset D - 12:00:00 (after 10:30)
   ✗ Changeset E - 13:00:00 (after 10:30)
```

---

### 5. rollbackSQL <tag> (Preview)

**Syntax:**
```bash
liquibase rollbackSQL v1.0
```

**What it does:**
- Shows the SQL that **would** be executed
- Does **NOT** actually execute rollback
- Useful for review before rolling back

**Example Output:**
```sql
-- Rollback Changeset: Kevin:ALTER_PROCEDURE_[dbo].[CustOrderHist2]
ALTER PROCEDURE [dbo].[CustOrderHist2] @CustomerID nchar(5) AS 
SELECT ProductName, Total=SUM(Quantity) 
FROM Products P, [Order Details] OD, Orders O, Customers C 
WHERE C.CustomerID = @CustomerID 
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID GROUP BY ProductName;

-- Rollback Changeset: Amy:CustomerInfo_ADD_address
ALTER TABLE CustomerInfo DROP COLUMN address;

-- Rollback Changeset: Martha:addPrimaryKey_pk_CustomerTypeID
ALTER TABLE CustomerInfo DROP CONSTRAINT pk_CustomerTypeID;
```

**Use Cases:**
- ✅ Review changes before applying
- ✅ Generate rollback scripts for manual execution
- ✅ Document rollback procedures
- ✅ Verify rollback logic is correct

---

## Rollback Examples from This Project

### Example 1: Simple Table Creation

**Forward (Create):**
```sql
--changeset SteveZ:createTable_salesTableZ
CREATE TABLE salesTableZ (
   ID int NOT NULL,
   NAME varchar(20) NULL,
   REGION varchar(20) NULL,
   MARKET varchar(20) NULL
)
--rollback DROP TABLE salesTableZ
```

**How Rollback Works:**

**Before Deployment:**
```
Database: []
```

**After Deployment:**
```
Database: [salesTableZ table exists]
```

**After Rollback:**
```
Database: []
Executed: DROP TABLE salesTableZ ✅
```

**Timeline:**
```
Time     | Action              | Database State
---------|---------------------|----------------
10:00 AM | (Initial)           | No salesTableZ
10:05 AM | Deploy changeset    | salesTableZ exists
10:10 AM | Issue discovered    | salesTableZ exists
10:11 AM | Rollback            | No salesTableZ ✅
```

---

### Example 2: Data Insert with Row-by-Row Rollback

**Forward (Insert):**
```sql
--changeset SteveZ:insertInto_salesTableZ
INSERT INTO salesTableZ (ID, NAME, REGION, MARKET)
VALUES
(0, 'AXV', 'NA', 'HHN'),
(1, 'MKL', 'SA', 'LMP'),
(2, 'POK', 'LA', 'LLA')
--rollback DELETE FROM salesTableZ WHERE ID=0
--rollback DELETE FROM salesTableZ WHERE ID=1
--rollback DELETE FROM salesTableZ WHERE ID=2
```

**How Rollback Works:**

**Before Deployment:**
```
salesTableZ:
(empty)
```

**After Deployment:**
```
salesTableZ:
ID | NAME | REGION | MARKET
---|------|--------|--------
0  | AXV  | NA     | HHN
1  | MKL  | SA     | LMP
2  | POK  | LA     | LLA
```

**After Rollback:**
```
salesTableZ:
(empty) ✅

Executed:
1. DELETE FROM salesTableZ WHERE ID=2
2. DELETE FROM salesTableZ WHERE ID=1
3. DELETE FROM salesTableZ WHERE ID=0
```

**Note:** Rollback executes in **reverse order** (2, 1, 0).

**Why Row-by-Row?**
- ✅ Precise - Only removes what was added
- ✅ Safe - Doesn't affect other data
- ❌ Verbose - One statement per row

**Alternative (Bulk):**
```sql
--rollback DELETE FROM salesTableZ WHERE ID IN (0, 1, 2)
```

---

### Example 3: Primary Key Constraint

**Forward (Add Constraint):**
```sql
--changeset Martha:addPrimaryKey_pk_CustomerTypeID
ALTER TABLE CustomerInfo 
ADD CONSTRAINT pk_CustomerTypeID PRIMARY KEY (CustomerTypeID)
--rollback ALTER TABLE CustomerInfo DROP CONSTRAINT pk_CustomerTypeID
```

**How Rollback Works:**

**Before Deployment:**
```
CustomerInfo table:
- No primary key
- CustomerTypeID column exists but not constrained
```

**After Deployment:**
```
CustomerInfo table:
- Primary key on CustomerTypeID ✅
- Cannot insert duplicate CustomerTypeID
- Cannot insert NULL CustomerTypeID
```

**After Rollback:**
```
CustomerInfo table:
- No primary key ✅
- CustomerTypeID column still exists (not dropped)
- Can insert duplicates again
- Can insert NULLs again

Executed: ALTER TABLE CustomerInfo DROP CONSTRAINT pk_CustomerTypeID
```

**Important:** Rollback removes **constraint only**, not the column.

---

### Example 4: Add Column

**Forward (Add Column):**
```sql
--changeset Amy:CustomerInfo_ADD_address
ALTER TABLE CustomerInfo ADD address varchar(255)
--rollback ALTER TABLE CustomerInfo DROP COLUMN address
```

**How Rollback Works:**

**Before Deployment:**
```
CustomerInfo:
CustomerTypeID | CustomerDesc
---------------|---------------
RETAIL         | Retail Customer
WHOLESALE      | Wholesale Customer
```

**After Deployment:**
```
CustomerInfo:
CustomerTypeID | CustomerDesc        | address
---------------|---------------------|--------
RETAIL         | Retail Customer     | NULL
WHOLESALE      | Wholesale Customer  | NULL
```

**After Rollback:**
```
CustomerInfo:
CustomerTypeID | CustomerDesc
---------------|---------------
RETAIL         | Retail Customer
WHOLESALE      | Wholesale Customer

Executed: ALTER TABLE CustomerInfo DROP COLUMN address ✅
```

**⚠️ WARNING:** If data was added to the `address` column, it's **lost** on rollback!

**Example with Data Loss:**
```
Before Rollback:
CustomerTypeID | CustomerDesc        | address
---------------|---------------------|------------------
RETAIL         | Retail Customer     | 123 Main St
WHOLESALE      | Wholesale Customer  | 456 Oak Ave

After Rollback:
CustomerTypeID | CustomerDesc
---------------|---------------
RETAIL         | Retail Customer     ← Address lost!
WHOLESALE      | Wholesale Customer  ← Address lost!
```

---

### Example 5: Stored Procedure (Create)

**Forward (Create):**
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

**How Rollback Works:**

**Before Deployment:**
```
Database procedures:
- CustOrderHist1: Does not exist
```

**After Deployment:**
```
Database procedures:
- CustOrderHist1: Exists ✅
  Can execute: EXEC CustOrderHist1 'ALFKI'
```

**After Rollback:**
```
Database procedures:
- CustOrderHist1: Does not exist ✅
  Execute fails: "Could not find stored procedure"

Executed: DROP PROCEDURE [dbo].[CustOrderHist1]
```

---

### Example 6: Stored Procedure (Alter)

**Forward (Modify):**
```sql
--changeset Kevin:ALTER_PROCEDURE_[dbo].[CustOrderHist2]
ALTER PROCEDURE dbo.CustOrderHist2 @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity) + 1  -- Changed!
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName;
--rollback ALTER PROCEDURE [dbo].[CustOrderHist2] @CustomerID nchar(5) AS 
--rollback SELECT ProductName, Total=SUM(Quantity)  -- Original
--rollback FROM Products P, [Order Details] OD, Orders O, Customers C 
--rollback WHERE C.CustomerID = @CustomerID 
--rollback AND C.CustomerID = O.CustomerID 
--rollback AND O.OrderID = OD.OrderID 
--rollback AND OD.ProductID = P.ProductID GROUP BY ProductName;
```

**How Rollback Works:**

**Before Deployment (Original):**
```sql
CustOrderHist2 logic:
Total = SUM(Quantity)

Example output for customer 'ALFKI':
ProductName | Total
------------|------
Chai        | 100
Chang       | 50
```

**After Deployment (Modified):**
```sql
CustOrderHist2 logic:
Total = SUM(Quantity) + 1

Example output for customer 'ALFKI':
ProductName | Total
------------|------
Chai        | 101  ← +1 added
Chang       | 51   ← +1 added
```

**After Rollback (Restored):**
```sql
CustOrderHist2 logic:
Total = SUM(Quantity)  ← Back to original ✅

Example output for customer 'ALFKI':
ProductName | Total
------------|------
Chai        | 100  ← Correct again
Chang       | 50   ← Correct again

Executed: ALTER PROCEDURE with original logic
```

---

### Example 7: File-Based Rollback (XML Changeset)

**Changeset:**
```xml
<changeSet author="Tsvi" id="CREATE_PROCEDURE_CustOrderHist_v2">
    <sqlFile path="objects/storedprocedure/CustOrderHist_v2.sql" endDelimiter="GO"/>
    <rollback>
        <sqlFile path="objects/storedprocedure/CustOrderHist_v1.sql" endDelimiter="GO"/>
    </rollback>
</changeSet>
```

**File: CustOrderHist_v2.sql (Forward):**
```sql
DROP PROCEDURE IF EXISTS [dbo].[CustOrderHist]
GO
CREATE PROCEDURE [dbo].[CustOrderHist] @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity + 1)  -- v2 logic
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName
GO
```

**File: CustOrderHist_v1.sql (Rollback):**
```sql
DROP PROCEDURE IF EXISTS [dbo].[CustOrderHist]
GO
CREATE PROCEDURE [dbo].[CustOrderHist] @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity)  -- v1 logic
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName
GO
```

**How Rollback Works:**

**Before Deployment:**
```
Procedure: CustOrderHist with v1 logic (or doesn't exist)
```

**After Deployment:**
```
Executed: CustOrderHist_v2.sql
Procedure: CustOrderHist with v2 logic (Quantity + 1) ✅
```

**After Rollback:**
```
Executed: CustOrderHist_v1.sql
Procedure: CustOrderHist with v1 logic (Quantity) ✅
```

**Advantages of File-Based Rollback:**
- ✅ Clean version control (v1, v2, v3 files)
- ✅ Easy to see differences (compare files)
- ✅ Reusable (v1 file used for multiple rollbacks)
- ✅ Testable (can run files independently)
- ✅ Maintainable (no long rollback comments in changelog)

---

## Rollback in CI/CD Pipeline

### The Pipeline's Rollback Flow

From `.gitlab-ci.yml` line 10-25:

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

**How It Works:**

### Scenario A: Normal Deployment (No TAG)

**Environment Variables:**
```bash
TAG=""  # Empty
```

**Pipeline Execution:**
```
1. isRollback() called
2. Check: Is TAG empty? YES
3. Output: "No TAG provided, running any pending changes"
4. Continue with normal deployment flow:
   - liquibase checks run
   - liquibase updateSQL
   - liquibase update
   - liquibase rollbackOneUpdate --force (test)
   - liquibase tag $CI_PIPELINE_ID
   - liquibase update (re-apply after test)
   - liquibase history
```

### Scenario B: Rollback Deployment (TAG Set)

**Environment Variables:**
```bash
TAG="12345"  # Previous pipeline ID
```

**Pipeline Execution:**
```
1. isRollback() called
2. Check: Is TAG empty? NO
3. Generate rollback SQL: liquibase rollbackSQL 12345
4. Check: Does rollback SQL exist? YES
5. Execute: liquibase rollback 12345
6. Log to: ${CI_JOB_NAME}_${CI_PIPELINE_ID}.log
7. Exit: 0 (success)
8. Pipeline stops (doesn't continue to update)
```

**Result:**
- Database rolled back to state at TAG 12345
- No new changes applied
- Logs show rollback actions

---

### The Rollback Test (Line 38)

```bash
liquibase rollbackOneUpdate --force
```

**Purpose:** Test that rollback **works** before tagging deployment

**Full Flow:**

```
Step 1: liquibase update
   ↓
Database has changesets A, B, C applied

Step 2: liquibase rollbackOneUpdate --force
   ↓
Database has changesets A, B (C rolled back)
   ↓
Validates: Rollback SQL is correct ✅

Step 3: liquibase tag $CI_PIPELINE_ID
   ↓
Tag deployment (can rollback to this later)

Step 4: liquibase update
   ↓
Database has changesets A, B, C again (C re-applied)
   ↓
Final State: All changes applied, rollback tested ✅
```

**Why Test Rollback?**

**Without Rollback Test:**
```
Deploy to PROD → Discover rollback doesn't work → PANIC! 😱
```

**With Rollback Test:**
```
Deploy to DEV → Test rollback → Fix issues → Deploy to PROD → Safe! ✅
```

**Example Rollback Failure Caught:**

```sql
--changeset author:add_column
ALTER TABLE MyTable ADD MyColumn int
--rollback ALTER TABLE MyTable DROP COLUMN WrongColumnName  -- Bug!
```

**Pipeline catches this:**
```
1. Update applies: ALTER TABLE MyTable ADD MyColumn int ✅
2. Rollback test runs: ALTER TABLE MyTable DROP COLUMN WrongColumnName ❌
3. Error: "Column WrongColumnName does not exist"
4. Pipeline fails ❌
5. Fix rollback SQL ✅
6. Re-run pipeline ✅
```

---

## Best Practices for Rollback

### 1. Always Provide Rollback

**❌ Bad:**
```sql
--changeset author:create_table
CREATE TABLE MyTable (ID int)
-- No rollback specified!
```

**✅ Good:**
```sql
--changeset author:create_table
CREATE TABLE MyTable (ID int)
--rollback DROP TABLE MyTable
```

### 2. Test Rollback Locally

```bash
# Deploy
liquibase update

# Test rollback
liquibase rollbackCount 1

# Re-apply
liquibase update

# Verify both work ✅
```

### 3. Use Tags for Milestones

```bash
# After successful deployment
liquibase tag "v1.0.0_production"

# Later, if issues
liquibase rollback "v1.0.0_production"
```

### 4. Preview Before Rolling Back

```bash
# See what would happen (doesn't execute)
liquibase rollbackSQL v1.0.0

# Review output, then execute
liquibase rollback v1.0.0
```

### 5. Keep Versions for Stored Procedures

**Directory Structure:**
```
objects/storedprocedures/
├── MyProc_v1.sql
├── MyProc_v2.sql
├── MyProc_v3.sql
└── MyProc_v4.sql
```

**Changelog:**
```xml
<changeSet id="myproc_v4" author="dev">
    <sqlFile path="objects/storedprocedures/MyProc_v4.sql"/>
    <rollback>
        <sqlFile path="objects/storedprocedures/MyProc_v3.sql"/>
    </rollback>
</changeSet>
```

### 6. Document Data Loss Rollbacks

```sql
--changeset author:add_column
ALTER TABLE MyTable ADD NewColumn varchar(100)
--rollback ALTER TABLE MyTable DROP COLUMN NewColumn
--rollback WARNING: Rolling back will DELETE all data in NewColumn!
```

### 7. Use Transactions Where Possible

```sql
--changeset author:multiple_changes runInTransaction:true
INSERT INTO Table1 VALUES (1, 'A');
INSERT INTO Table2 VALUES (1, 'B');
UPDATE Table3 SET Status = 'Active' WHERE ID = 1;
--rollback DELETE FROM Table1 WHERE ID = 1;
--rollback DELETE FROM Table2 WHERE ID = 1;
--rollback UPDATE Table3 SET Status = 'Inactive' WHERE ID = 1;
```

**Benefit:** All changes or none (atomic)

---

## Common Rollback Mistakes

### Mistake 1: Incomplete Rollback

**Problem:**
```sql
--changeset author:add_columns
ALTER TABLE MyTable ADD Column1 int;
ALTER TABLE MyTable ADD Column2 varchar(50);
ALTER TABLE MyTable ADD Column3 datetime;
--rollback ALTER TABLE MyTable DROP COLUMN Column1;
-- Oops! Forgot Column2 and Column3
```

**Result:** Partial rollback, database in inconsistent state

**Fix:**
```sql
--rollback ALTER TABLE MyTable DROP COLUMN Column3;
--rollback ALTER TABLE MyTable DROP COLUMN Column2;
--rollback ALTER TABLE MyTable DROP COLUMN Column1;
```

### Mistake 2: Wrong Rollback Order

**Problem:**
```sql
--changeset author:fk_constraint
ALTER TABLE Orders ADD CONSTRAINT fk_customer FOREIGN KEY (CustomerID) REFERENCES Customers(ID);
ALTER TABLE OrderDetails ADD CONSTRAINT fk_order FOREIGN KEY (OrderID) REFERENCES Orders(ID);
--rollback ALTER TABLE Orders DROP CONSTRAINT fk_customer;  -- Wrong order!
--rollback ALTER TABLE OrderDetails DROP CONSTRAINT fk_order;
```

**Result:** Cannot drop Orders FK while OrderDetails FK depends on it

**Fix:** Reverse the order
```sql
--rollback ALTER TABLE OrderDetails DROP CONSTRAINT fk_order;  -- Drop dependent first
--rollback ALTER TABLE Orders DROP CONSTRAINT fk_customer;     -- Then drop parent
```

### Mistake 3: Hardcoded Values in Rollback

**Problem:**
```sql
--changeset author:update_status
UPDATE Orders SET Status = 'Shipped' WHERE OrderID = 12345;
--rollback UPDATE Orders SET Status = 'Pending';  -- Assumes previous value
```

**Issue:** What if previous status was 'Processing', not 'Pending'?

**Better Approach:**
```sql
-- Store previous state in another table first, or
-- Use more specific rollback
--rollback UPDATE Orders SET Status = 'Processing' WHERE OrderID = 12345;
```

### Mistake 4: No Rollback for Destructive Changes

**Problem:**
```sql
--changeset author:delete_old_data
DELETE FROM Orders WHERE OrderDate < '2020-01-01';
--rollback -- No way to restore deleted data!
```

**Better Approach:**
```sql
-- Archive instead of delete
CREATE TABLE Orders_Archive (like Orders);
INSERT INTO Orders_Archive SELECT * FROM Orders WHERE OrderDate < '2020-01-01';
DELETE FROM Orders WHERE OrderDate < '2020-01-01';
--rollback INSERT INTO Orders SELECT * FROM Orders_Archive;
--rollback DROP TABLE Orders_Archive;
```

---

## Summary

### Key Takeaways:

1. **Rollback is essential** - Always provide rollback SQL
2. **Test rollback** - Don't wait for production to find issues
3. **Use tags** - Mark stable deployment points
4. **Preview first** - Use rollbackSQL to review changes
5. **Maintain versions** - Keep old versions of procedures in files
6. **Order matters** - Rollback executes in reverse order
7. **Be careful with data** - Some rollbacks cause data loss
8. **Pipeline automation** - CI/CD tests rollback automatically

### Rollback Command Quick Reference:

```bash
# Rollback to a tag
liquibase rollback <tag>

# Rollback last deployment
liquibase rollbackOneUpdate --force

# Rollback N changesets
liquibase rollbackCount <N>

# Rollback to date
liquibase rollbackToDate <date>

# Preview rollback (doesn't execute)
liquibase rollbackSQL <tag>

# Create a tag
liquibase tag <tagname>

# View deployment history
liquibase history
```

### The Rollback Mindset:

When writing changesets, always ask:
1. ✅ Can this be rolled back?
2. ✅ Will rollback restore the previous state?
3. ✅ Will any data be lost on rollback?
4. ✅ Are dependencies handled in correct order?
5. ✅ Have I tested the rollback?

**Remember:** A deployment without a tested rollback is like a parachute without a backup - risky! 🪂
