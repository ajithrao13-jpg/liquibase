# Visual Flow Diagrams and Examples

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Liquibase Project                          │
└─────────────────────────────────────────────────────────────────┘
                              |
                              v
        ┌────────────────────────────────────────┐
        │      Changelog Files (Source)          │
        │  - changelog.sql (SQL format)          │
        │  - changelog.xml (XML format)          │
        │  - objects/storedprocedures/*.sql      │
        └────────────────────────────────────────┘
                              |
                              v
                    ┌─────────────────┐
                    │   Liquibase     │
                    │   Processing    │
                    └─────────────────┘
                              |
            ┌─────────────────┴─────────────────┐
            v                                   v
    ┌───────────────┐                  ┌───────────────┐
    │  Forward      │                  │   Rollback    │
    │  (Deploy)     │                  │   (Undo)      │
    └───────────────┘                  └───────────────┘
            |                                   |
            v                                   v
    ┌───────────────────────────────────────────────────┐
    │            SQL Server Database                    │
    │  - Application Tables                            │
    │  - Stored Procedures                             │
    │  - DATABASECHANGELOG (tracking)                  │
    │  - DATABASECHANGELOGLOCK (concurrency)          │
    └───────────────────────────────────────────────────┘
```

## Changeset Execution Flow

```
┌──────────────────────────────────────────────────────────────┐
│  Step 1: Liquibase reads changelog files                    │
└──────────────────────────────────────────────────────────────┘
                         |
                         v
┌──────────────────────────────────────────────────────────────┐
│  Step 2: Compare with DATABASECHANGELOG table                │
│  - Which changesets already executed?                        │
│  - Which changesets are new?                                 │
└──────────────────────────────────────────────────────────────┘
                         |
                         v
┌──────────────────────────────────────────────────────────────┐
│  Step 3: Execute new changesets in order                     │
│  - Execute forward SQL                                       │
│  - Record in DATABASECHANGELOG                              │
│  - Store checksum                                           │
└──────────────────────────────────────────────────────────────┘
                         |
                         v
┌──────────────────────────────────────────────────────────────┐
│  Step 4: Database updated successfully                       │
└──────────────────────────────────────────────────────────────┘
```

## Rollback Execution Flow

```
┌──────────────────────────────────────────────────────────────┐
│  Step 1: Identify rollback target (tag, count, or date)     │
└──────────────────────────────────────────────────────────────┘
                         |
                         v
┌──────────────────────────────────────────────────────────────┐
│  Step 2: Query DATABASECHANGELOG for changesets to rollback │
│  - Get changesets after target                               │
│  - Order by ORDEREXECUTED DESC (reverse order)              │
└──────────────────────────────────────────────────────────────┘
                         |
                         v
┌──────────────────────────────────────────────────────────────┐
│  Step 3: Execute rollback SQL for each changeset            │
│  - Get rollback SQL from changelog                          │
│  - Execute in reverse order                                 │
│  - Remove from DATABASECHANGELOG                            │
└──────────────────────────────────────────────────────────────┘
                         |
                         v
┌──────────────────────────────────────────────────────────────┐
│  Step 4: Database rolled back to target state               │
└──────────────────────────────────────────────────────────────┘
```

## Stored Procedure Lifecycle

### Create → Deploy → Modify → Rollback

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: Initial Creation (v1)                             │
└─────────────────────────────────────────────────────────────┘

Developer writes:
    CustOrderHist_v1.sql
    ├── DROP PROCEDURE IF EXISTS
    ├── CREATE PROCEDURE
    └── Logic: Total = SUM(Quantity)

                         |
                         v

Liquibase deploys:
    Database State: [CustOrderHist exists with v1 logic]
    DATABASECHANGELOG: Record created

                         |
                         v

┌─────────────────────────────────────────────────────────────┐
│  Phase 2: Modification (v2)                                 │
└─────────────────────────────────────────────────────────────┘

Developer writes:
    CustOrderHist_v2.sql
    ├── DROP PROCEDURE IF EXISTS
    ├── CREATE PROCEDURE
    └── Logic: Total = SUM(Quantity + 1)  ← Changed

Changeset references:
    <sqlFile path="CustOrderHist_v2.sql"/>
    <rollback>
        <sqlFile path="CustOrderHist_v1.sql"/>  ← Rollback to v1
    </rollback>

                         |
                         v

Liquibase deploys:
    Database State: [CustOrderHist exists with v2 logic]
    DATABASECHANGELOG: New record added

                         |
                         v

┌─────────────────────────────────────────────────────────────┐
│  Phase 3: Issue Discovered - Need Rollback                  │
└─────────────────────────────────────────────────────────────┘

Liquibase rollback:
    Execute: CustOrderHist_v1.sql (from rollback section)
    ├── DROP PROCEDURE IF EXISTS
    ├── CREATE PROCEDURE
    └── Logic: Total = SUM(Quantity)  ← Back to original

                         |
                         v

Database State: [CustOrderHist exists with v1 logic] ✅
DATABASECHANGELOG: v2 record removed
```

## CI/CD Pipeline Flow with Decision Points

```
┌────────────────────────────────────────────────────────────┐
│  Pipeline Triggered                                        │
│  (Git push to main branch)                                 │
└────────────────────────────────────────────────────────────┘
                         |
                         v
                 ┌──────────────┐
                 │  Check TAG   │
                 │  variable    │
                 └──────────────┘
                         |
        ┌────────────────┴────────────────┐
        v                                  v
   [TAG set?]                         [No TAG?]
        |                                  |
        v                                  v
┌───────────────┐                  ┌──────────────┐
│  ROLLBACK     │                  │  DEPLOYMENT  │
│  MODE         │                  │  MODE        │
└───────────────┘                  └──────────────┘
        |                                  |
        v                                  v
┌──────────────────────────────┐   ┌──────────────────────────────┐
│ 1. Preview rollback SQL      │   │ 1. Check database status     │
│ 2. Execute rollback to TAG   │   │ 2. Run quality checks        │
│ 3. Log results               │   │ 3. Preview SQL (updateSQL)   │
│ 4. Exit pipeline             │   │ 4. Apply changes (update)    │
└──────────────────────────────┘   │ 5. TEST ROLLBACK ←important! │
                                   │ 6. Tag deployment            │
                                   │ 7. Re-apply changes          │
                                   │ 8. Show history              │
                                   └──────────────────────────────┘
                                              |
                        ┌─────────────────────┴─────────────────────┐
                        v                                           v
                   [Success?]                                  [Failed?]
                        |                                           |
                        v                                           v
              ┌──────────────────┐                    ┌──────────────────────┐
              │ Proceed to next  │                    │ Pipeline fails       │
              │ environment      │                    │ Changes not applied  │
              └──────────────────┘                    │ Investigation needed │
                                                     └──────────────────────┘
```

## Multi-Environment Deployment Flow

```
┌───────────────────────────────────────────────────────────────┐
│                      DEV Environment                          │
│  Stage: build                                                 │
│  Purpose: First testing ground                                │
└───────────────────────────────────────────────────────────────┘
    │
    │ Liquibase:
    │ ├── checks run
    │ ├── update
    │ ├── rollbackOneUpdate --force (test)
    │ └── tag <pipeline_id>
    │
    ├─ [Success] ──┐
    │              │
    v              v
┌───────────────────────────────────────────────────────────────┐
│                      QA Environment                           │
│  Stage: test                                                  │
│  Purpose: Integration testing                                │
└───────────────────────────────────────────────────────────────┘
    │
    │ Liquibase:
    │ ├── checks run
    │ ├── update
    │ ├── rollbackOneUpdate --force (test)
    │ └── tag <pipeline_id>
    │
    ├─ [Success] ──┐
    │              │
    v              v
┌───────────────────────────────────────────────────────────────┐
│                    PROD Environment                           │
│  Stage: deploy                                                │
│  Purpose: Production deployment                              │
└───────────────────────────────────────────────────────────────┘
    │
    │ Liquibase:
    │ ├── checks run
    │ ├── update
    │ ├── rollbackOneUpdate --force (test)
    │ └── tag <pipeline_id>
    │
    v
┌───────────────────────────────────────────────────────────────┐
│              Drift Detection (Compare Stage)                  │
│  - DEV vs QA comparison                                       │
│  - QA vs PROD comparison                                      │
│  - Generate JSON reports                                      │
└───────────────────────────────────────────────────────────────┘
    │
    v
┌───────────────────────────────────────────────────────────────┐
│              Snapshot (Post Stage)                            │
│  - Capture PROD database state                                │
│  - Store as JSON                                              │
│  - Use for future drift detection                            │
└───────────────────────────────────────────────────────────────┘
```

## Example: Table Creation with Rollback

```
TIME: T0 (Before Deployment)
════════════════════════════════════════════════════════
Database Tables:
    ├── Customers
    ├── Orders
    └── Products

DATABASECHANGELOG:
    (3 previous changesets)

════════════════════════════════════════════════════════

TIME: T1 (Changeset Executed)
════════════════════════════════════════════════════════
Changeset:
    --changeset SteveZ:createTable_salesTableZ
    CREATE TABLE salesTableZ (
        ID int NOT NULL,
        NAME varchar(20),
        REGION varchar(20),
        MARKET varchar(20)
    )
    --rollback DROP TABLE salesTableZ

Execution:
    CREATE TABLE salesTableZ ✅

Database Tables:
    ├── Customers
    ├── Orders
    ├── Products
    └── salesTableZ  ← NEW

DATABASECHANGELOG:
    ├── (3 previous changesets)
    └── SteveZ:createTable_salesTableZ (ORDEREXECUTED=4) ← NEW

════════════════════════════════════════════════════════

TIME: T2 (Rollback Executed)
════════════════════════════════════════════════════════
Command: liquibase rollbackCount 1

Rollback SQL from changeset:
    DROP TABLE salesTableZ

Execution:
    DROP TABLE salesTableZ ✅

Database Tables:
    ├── Customers
    ├── Orders
    └── Products
    (salesTableZ removed ✅)

DATABASECHANGELOG:
    (3 previous changesets)
    (SteveZ:createTable_salesTableZ removed ✅)

════════════════════════════════════════════════════════
Result: Database back to T0 state ✅
```

## Example: Stored Procedure Modification with Rollback

```
TIME: T0 (Original State)
════════════════════════════════════════════════════════
Stored Procedure: CustOrderHist
    Logic: Total = SUM(Quantity)

Test Execution:
    EXEC CustOrderHist 'ALFKI'
    
    ProductName     | Total
    ─────────────── | ─────
    Chai            | 100
    Chang           | 50

════════════════════════════════════════════════════════

TIME: T1 (After v2 Deployment)
════════════════════════════════════════════════════════
Changeset:
    <sqlFile path="CustOrderHist_v2.sql"/>
    <rollback>
        <sqlFile path="CustOrderHist_v1.sql"/>
    </rollback>

Stored Procedure: CustOrderHist
    Logic: Total = SUM(Quantity + 1)  ← CHANGED

Test Execution:
    EXEC CustOrderHist 'ALFKI'
    
    ProductName     | Total
    ─────────────── | ─────
    Chai            | 101  ← +1 (INCORRECT!)
    Chang           | 51   ← +1 (INCORRECT!)

Issue Detected: Calculations wrong! ❌

════════════════════════════════════════════════════════

TIME: T2 (After Rollback)
════════════════════════════════════════════════════════
Command: liquibase rollback <tag>

Rollback Executes: CustOrderHist_v1.sql
    DROP PROCEDURE IF EXISTS CustOrderHist
    CREATE PROCEDURE with original logic

Stored Procedure: CustOrderHist
    Logic: Total = SUM(Quantity)  ← RESTORED ✅

Test Execution:
    EXEC CustOrderHist 'ALFKI'
    
    ProductName     | Total
    ─────────────── | ─────
    Chai            | 100  ← Correct ✅
    Chang           | 50   ← Correct ✅

Issue Resolved: Calculations correct! ✅

════════════════════════════════════════════════════════
Result: Database back to working state ✅
```

## Tag-Based Rollback Example

```
Deployment Timeline:
════════════════════════════════════════════════════════

Monday 9 AM: Deploy to PROD
    Changesets: A, B, C applied
    Tag created: "v1.0-prod"
    DATABASECHANGELOG:
        ├── A (order=1)
        ├── B (order=2)
        └── C (order=3, tag=v1.0-prod)

Tuesday 10 AM: Deploy to PROD
    Changesets: D, E applied
    Tag created: "v1.1-prod"
    DATABASECHANGELOG:
        ├── A (order=1)
        ├── B (order=2)
        ├── C (order=3, tag=v1.0-prod)
        ├── D (order=4)
        └── E (order=5, tag=v1.1-prod)

Wednesday 2 PM: Deploy to PROD
    Changesets: F, G, H applied
    Tag created: "v1.2-prod"
    DATABASECHANGELOG:
        ├── A (order=1)
        ├── B (order=2)
        ├── C (order=3, tag=v1.0-prod)
        ├── D (order=4)
        ├── E (order=5, tag=v1.1-prod)
        ├── F (order=6)
        ├── G (order=7)
        └── H (order=8, tag=v1.2-prod)

Wednesday 3 PM: Issue discovered!
    Command: liquibase rollback v1.1-prod
    
    Rollback executes (reverse order):
        1. Rollback H ✅
        2. Rollback G ✅
        3. Rollback F ✅
        4. Stop at tag v1.1-prod
    
    DATABASECHANGELOG:
        ├── A (order=1)
        ├── B (order=2)
        ├── C (order=3, tag=v1.0-prod)
        ├── D (order=4)
        └── E (order=5, tag=v1.1-prod) ← Back to here ✅

════════════════════════════════════════════════════════
Result: Rolled back to Tuesday's deployment ✅
        F, G, H changes removed
        A, B, C, D, E remain
```

## runOnChange Behavior Example

```
Scenario: Stored procedure needs frequent updates
════════════════════════════════════════════════════════

Changeset Definition:
    --changeset dev:myproc runOnChange:true
    CREATE OR ALTER PROCEDURE MyProc
    AS
        SELECT * FROM MyTable
    --rollback DROP PROCEDURE MyProc

Day 1 (Initial):
    SQL: SELECT * FROM MyTable
    Checksum calculated: ABC123
    Action: CREATE PROCEDURE ✅
    DATABASECHANGELOG:
        └── myproc (checksum=ABC123, executed)

Day 2 (No changes):
    SQL: SELECT * FROM MyTable (unchanged)
    Checksum calculated: ABC123
    Compare: ABC123 = ABC123 (same)
    Action: SKIP (already executed with same checksum)

Day 3 (Modified):
    SQL: SELECT ID, Name FROM MyTable (changed)
    Checksum calculated: DEF456
    Compare: DEF456 ≠ ABC123 (different!)
    Action: RE-EXECUTE because runOnChange=true ✅
    DATABASECHANGELOG:
        └── myproc (checksum=DEF456, re-executed)

Without runOnChange:
    Day 3: Would SKIP even though SQL changed ❌
    Result: Database has old procedure version
    Problem: Logic not updated!

With runOnChange:
    Day 3: RE-EXECUTES because SQL changed ✅
    Result: Database has new procedure version
    Success: Logic updated! ✅

════════════════════════════════════════════════════════
Best Practice: Always use runOnChange:true for stored
procedures, views, and functions!
```

## DATABASECHANGELOG Table Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    DATABASECHANGELOG                        │
├─────────────────┬───────────────────────────────────────────┤
│ Column          │ Purpose                                   │
├─────────────────┼───────────────────────────────────────────┤
│ ID              │ Changeset identifier (unique with author) │
│ AUTHOR          │ Who created the changeset                 │
│ FILENAME        │ Which changelog file                      │
│ DATEEXECUTED    │ When it was applied                       │
│ ORDEREXECUTED   │ Sequence number (order applied)           │
│ EXECTYPE        │ EXECUTED, RERAN, FAILED, etc.            │
│ MD5SUM          │ Checksum of SQL (detects changes)        │
│ DESCRIPTION     │ What type of change (createTable, etc.)   │
│ COMMENTS        │ Optional developer notes                  │
│ TAG             │ Version tag (for rollback reference)     │
│ LIQUIBASE       │ Liquibase version used                    │
│ CONTEXTS        │ Context (dev, prod, etc.)                │
│ LABELS          │ Labels for filtering                      │
│ DEPLOYMENT_ID   │ Groups changesets from same deployment    │
└─────────────────┴───────────────────────────────────────────┘

Example Records:
┌────────────┬────────┬─────────────┬─────────────────────┬──────────────┬──────┐
│ ID         │ AUTHOR │ FILENAME    │ DATEEXECUTED        │ ORDER │ TAG  │
├────────────┼────────┼─────────────┼─────────────────────┼───────┼──────┤
│ create_tbl │ SteveZ │ changelog..│ 2024-01-15 10:00:00 │   1   │      │
│ insert_data│ SteveZ │ changelog..│ 2024-01-15 10:00:01 │   2   │      │
│ add_pk     │ Martha │ changelog..│ 2024-01-15 10:00:02 │   3   │ v1.0 │
│ add_col    │ Amy    │ changelog..│ 2024-01-15 10:00:03 │   4   │      │
│ create_proc│ Mike   │ changelog..│ 2024-01-15 10:00:04 │   5   │      │
│ proc_v2    │ Tsvi   │ changelog..│ 2024-01-15 10:00:05 │   6   │ v1.1 │
└────────────┴────────┴─────────────┴─────────────────────┴───────┴──────┘

This table is how Liquibase tracks:
✅ What's been applied
✅ In what order
✅ When it was applied
✅ What tags exist for rollback
```

## Summary: The Complete Picture

```
                    ┌───────────────────┐
                    │   Developer       │
                    │   Writes SQL      │
                    └─────────┬─────────┘
                              │
                              v
                    ┌───────────────────┐
                    │  Changelog Files  │
                    │  (with rollback)  │
                    └─────────┬─────────┘
                              │
                              v
                    ┌───────────────────┐
                    │   Git Commit &    │
                    │   Push to Repo    │
                    └─────────┬─────────┘
                              │
                              v
                    ┌───────────────────┐
                    │  GitLab Pipeline  │
                    │   Triggered       │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    v                   v
            [Normal Deploy]      [Rollback Mode]
                    │                   │
                    v                   v
        ┌─────────────────┐   ┌─────────────────┐
        │ DEV Environment │   │ Rollback to TAG │
        └────────┬────────┘   └────────┬────────┘
                 │                     │
                 v                     v
        ┌─────────────────┐   ┌─────────────────┐
        │ QA Environment  │   │  Verify State   │
        └────────┬────────┘   └────────┬────────┘
                 │                     │
                 v                     v
        ┌─────────────────┐   ┌─────────────────┐
        │PROD Environment │   │   Success! ✅    │
        └────────┬────────┘   └─────────────────┘
                 │
                 v
        ┌─────────────────┐
        │ Drift Detection │
        │   & Snapshot    │
        └─────────────────┘

Every step is:
✅ Tracked
✅ Logged
✅ Reversible
✅ Auditable
```

---

*These visual diagrams complement the detailed documentation. For complete explanations, see:*
- *DETAILED_EXPLANATION.md*
- *STORED_PROCEDURES_GUIDE.md*
- *ROLLBACK_GUIDE.md*
- *QUICK_REFERENCE.md*
