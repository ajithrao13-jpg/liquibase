# Stored Procedures Deep Dive Guide

## Understanding Stored Procedures in This Project

### What is a Stored Procedure?

A **stored procedure** is like a **function or method** in programming, but it lives in the database. Think of it as a reusable piece of SQL code that:
- Has a name (like `CustOrderHist`)
- Can accept inputs (parameters like `@CustomerID`)
- Executes SQL statements
- Returns results (data rows)
- Is stored compiled in the database for fast execution

### Why Use Stored Procedures?

#### 1. **Performance**
- Compiled once, executed many times
- Reduces network traffic (send procedure name, not full SQL)
- Database can optimize execution plan

#### 2. **Security**
- Users can execute procedures without direct table access
- Prevents SQL injection attacks
- Centralized security control

#### 3. **Code Reusability**
- Write once, use anywhere
- Consistent business logic
- Easier maintenance

#### 4. **Business Logic Encapsulation**
- Complex calculations in one place
- Multiple applications can use same logic
- Changes made in one place

---

## Stored Procedures in This Project - Detailed Walkthrough

### Procedure 1: CustOrderHist (Customer Order History)

#### Version 1 (Original - Correct Version)
**File:** `objects/storedprocedures/CustOrderHist_v1.sql`

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

#### Breaking It Down Line by Line:

**Line 1:** `DROP PROCEDURE IF EXISTS [dbo].[CustOrderHist]`
- **What it does:** Removes the procedure if it already exists
- **Why:** Prevents "procedure already exists" error
- **Schema:** `dbo` (database owner) is the schema name
- **Safe:** `IF EXISTS` means no error if procedure doesn't exist

**Line 2:** `GO`
- **What it does:** Batch separator (SQL Server specific)
- **Why:** Separates DROP from CREATE
- **Important:** Not a SQL statement, it's a batch delimiter

**Line 4:** `CREATE PROCEDURE [dbo].[CustOrderHist] @CustomerID nchar(5)`
- **CREATE PROCEDURE:** Defines new stored procedure
- **[dbo].[CustOrderHist]:** Full name with schema
- **@CustomerID:** Parameter name (@ indicates parameter)
- **nchar(5):** Data type - fixed length 5-character Unicode string

**Line 5:** `AS`
- **What it does:** Marks beginning of procedure body
- **All SQL after AS:** The actual procedure code

**Line 6:** `SELECT ProductName, Total=SUM(Quantity)`
- **SELECT:** Returns results to caller
- **ProductName:** Column from Products table
- **Total:** Alias (name) for the calculated column
- **SUM(Quantity):** Adds up all quantities for each product

**Line 7:** `FROM Products P, [Order Details] OD, Orders O, Customers C`
- **FROM:** Specifies tables to query
- **Products P:** Products table with alias 'P'
- **[Order Details] OD:** Order Details table (brackets needed for space in name)
- **Orders O:** Orders table with alias 'O'
- **Customers C:** Customers table with alias 'C'
- **Why aliases?** Shorter names for table references

**Lines 8-11:** WHERE clause (JOIN conditions)
```sql
WHERE C.CustomerID = @CustomerID              -- Filter by parameter
AND C.CustomerID = O.CustomerID               -- Join Customers to Orders
AND O.OrderID = OD.OrderID                    -- Join Orders to Order Details
AND OD.ProductID = P.ProductID                -- Join Order Details to Products
```
- **First line:** Filters to specific customer (the parameter)
- **Other lines:** Join tables together (implicit joins)
- **Result:** Gets all products ordered by this customer

**Line 12:** `GROUP BY ProductName`
- **Groups results:** One row per unique product name
- **Why needed?** Because we're using SUM() aggregate function
- **Effect:** Total shows sum of all orders for each product

**Line 13:** `GO`
- **Ends the batch:** Completes the procedure creation

#### What This Procedure Returns:

If you execute: `EXEC CustOrderHist 'ALFKI'`

You might get:
```
ProductName                 | Total
----------------------------|------
Chai                        | 125
Chang                       | 50
Aniseed Syrup              | 30
...
```

#### Version 2 (Modified - Test Version)
**File:** `objects/storedprocedures/CustOrderHist_v2.sql`

```sql
CREATE PROCEDURE [dbo].[CustOrderHist] @CustomerID nchar(5)
AS
SELECT ProductName, Total=SUM(Quantity + 1)  -- CHANGED: +1 added
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = @CustomerID
AND C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
GROUP BY ProductName
GO
```

**Key Difference:** `SUM(Quantity + 1)` instead of `SUM(Quantity)`

**What this means:**
- **For each order line:** Add 1 to quantity before summing
- **If customer ordered product 3 times:**
  - Version 1: Quantities 10, 5, 8 → Total = 23
  - Version 2: Quantities (10+1), (5+1), (8+1) → Total = 26 (3 extra)

**Why might this exist?**
- Could be a test change to demonstrate versioning
- Could be a bug that needs rolling back
- Demonstrates how procedures evolve

---

### Procedure 2: CustOrdersOrders (Customer's Orders List)

**File:** `objects/storedprocedures/CustOrdersOrders.sql`

```sql
CREATE PROCEDURE [dbo].[CustOrdersOrders] @CustomerID nchar(5)
AS
SELECT OrderID, OrderDate, RequiredDate, ShippedDate
FROM Orders
WHERE CustomerID = @CustomerID
ORDER BY OrderID
```

#### Purpose:
Get a list of all orders for a specific customer with their dates.

#### Breaking It Down:

**Parameters:**
- `@CustomerID nchar(5)` - The customer to look up

**What it selects:**
- `OrderID` - Unique order identifier
- `OrderDate` - When order was placed
- `RequiredDate` - When customer needs it
- `ShippedDate` - When it was actually shipped

**Filter:**
- `WHERE CustomerID = @CustomerID` - Only this customer's orders

**Sorting:**
- `ORDER BY OrderID` - Results sorted by order number (ascending)

#### Example Output:

Execute: `EXEC CustOrdersOrders 'ALFKI'`

```
OrderID | OrderDate  | RequiredDate | ShippedDate
--------|------------|--------------|-------------
10643   | 1997-08-25 | 1997-09-22   | 1997-09-02
10692   | 1997-10-03 | 1997-10-31   | 1997-10-13
10702   | 1997-10-13 | 1997-11-24   | 1997-10-21
```

#### Use Case:
When a customer calls customer service asking "What are my orders?", this procedure provides that list quickly.

---

### Procedure 3: CustOrdersDetail (Order Line Items)

**File:** `objects/storedprocedures/CustOrdersDetail.sql`

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

#### Purpose:
Get detailed line items for a specific order with calculated prices.

#### Breaking It Down:

**Parameters:**
- `@OrderID int` - The order to get details for

**Columns Returned:**

1. **ProductName** - Name of the product
   - Comes from Products table

2. **UnitPrice=ROUND(Od.UnitPrice, 2)** - Price per unit
   - `ROUND(..., 2)` - Rounds to 2 decimal places (e.g., 18.999 → 19.00)
   - `Od.UnitPrice` - Price from Order Details table

3. **Quantity** - Number of units ordered
   - Direct from Order Details table

4. **Discount=CONVERT(int, Discount * 100)** - Discount percentage
   - `Discount * 100` - Converts decimal to percentage (0.15 → 15)
   - `CONVERT(int, ...)` - Converts to integer (15.5 → 15)

5. **ExtendedPrice** - Total price for this line item
   - **Formula:** `Quantity × (1 - Discount) × UnitPrice`
   - **Example:** 10 units × $20 each with 15% discount
     - Calculation: 10 × (1 - 0.15) × 20 = 10 × 0.85 × 20 = $170.00
   - `CONVERT(money, ...)` - Converts to money data type
   - `ROUND(..., 2)` - Rounds to 2 decimal places

**Tables Used:**
- `Products P` - Product information (name)
- `[Order Details] Od` - Order line items (quantity, price, discount)

**Join:**
- `Od.ProductID = P.ProductID` - Connects order details to products

**Filter:**
- `Od.OrderID = @OrderID` - Only items from this specific order

#### Example Output:

Execute: `EXEC CustOrdersDetail 10643`

```
ProductName      | UnitPrice | Quantity | Discount | ExtendedPrice
-----------------|-----------|----------|----------|---------------
Chai             | 18.00     | 15       | 25       | 202.50
Guaraná Fantástica| 4.50    | 21       | 25       | 70.88
Manjimup Apples  | 53.00     | 2        | 25       | 79.50
```

#### Calculation Example:
For "Chai" row:
- Quantity: 15 units
- UnitPrice: $18.00
- Discount: 25% (shown as 25)
- Calculation: 15 × (1 - 0.25) × 18.00 = 15 × 0.75 × 18.00 = $202.50

#### Use Case:
When looking at an invoice or receipt, this shows what was ordered and the calculated totals.

---

## Stored Procedures in changelog.sql

The `changelog.sql` file also defines stored procedures directly. Let's examine them:

### Procedure: CustOrderHist1

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

**Key Points:**
- **Defined inline** in changelog (not in separate file)
- **Author:** Mike
- **ID:** CREATE_PROCEDURE_[dbo].[CustOrderHist1]
- **Same logic** as CustOrderHist_v1
- **Simple rollback:** Just drops the procedure

**When to use inline vs. file:**
- **Inline:** Simple procedures, one-time changes
- **File:** Complex procedures, need version control

---

### Procedure: CustOrderHist2 (with runOnChange)

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

**Special Attribute: runOnChange:true**

This is **CRITICAL** for stored procedures because:

1. **Normal changesets run once** - Liquibase marks them as executed
2. **With runOnChange:true** - Liquibase re-runs if SQL changes
3. **How it detects changes** - Calculates checksum (hash) of SQL
4. **When it re-runs** - If checksum differs from last execution

**Example Scenario:**

**Day 1:** Create procedure
```sql
-- Liquibase calculates checksum: ABC123
-- Executes CREATE PROCEDURE
-- Records in DATABASECHANGELOG: executed=true, checksum=ABC123
```

**Day 2:** Modify procedure in changelog
```sql
-- Changed: Total=SUM(Quantity) to Total=SUM(Quantity * 2)
-- Liquibase calculates new checksum: DEF456
-- Compares: DEF456 ≠ ABC123
-- Because runOnChange=true, re-executes the changeset
-- Updates DATABASECHANGELOG: checksum=DEF456
```

**Without runOnChange:**
- Liquibase sees changeset already executed
- Skips it
- Procedure doesn't get updated
- **Problem:** Database has old version

**Use Cases for runOnChange:**
- ✅ Stored procedures (logic changes frequently)
- ✅ Views (definition might change)
- ✅ Functions (algorithm updates)
- ❌ Table creation (shouldn't change after creation)
- ❌ Data inserts (don't want to re-insert)

---

### Procedure: CustOrderHist2 (ALTER version)

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

**Key Differences from CREATE:**

1. **Uses ALTER instead of CREATE**
   - `ALTER PROCEDURE` - Modifies existing procedure
   - `CREATE PROCEDURE` - Creates new procedure
   - ALTER preserves permissions, ownership

2. **Multi-line Rollback**
   - Each line starts with `--rollback`
   - Contains the **previous version** of the procedure
   - Restores original logic (without +1)

**Why ALTER instead of DROP/CREATE?**

**ALTER Procedure:**
```
Advantages:
✅ Preserves permissions (EXECUTE grants)
✅ Keeps object ID (references stay valid)
✅ No "procedure doesn't exist" errors
✅ Safer for production

Disadvantages:
❌ Procedure must already exist
❌ Can't change parameter types dramatically
```

**DROP/CREATE:**
```
Advantages:
✅ Clean slate (no leftover artifacts)
✅ Can change anything
✅ Works even if procedure doesn't exist

Disadvantages:
❌ Loses permissions (must regrant)
❌ Changes object ID (breaks references)
❌ Briefly makes procedure unavailable
❌ Riskier in production
```

**Rollback Strategy:**

**Forward (Modify):**
```sql
ALTER PROCEDURE CustOrderHist2 ...
SELECT ProductName, Total=SUM(Quantity) + 1  -- New logic
```

**Rollback (Restore):**
```sql
ALTER PROCEDURE CustOrderHist2 ...
SELECT ProductName, Total=SUM(Quantity)  -- Original logic
```

**Both use ALTER** because procedure exists in both states.

---

## Rollback Strategies for Stored Procedures

### Strategy 1: Drop on Rollback (New Procedure)

**Use when:** Creating a brand new procedure

```sql
--changeset author:create_new_proc
CREATE PROCEDURE MyNewProc
AS
SELECT * FROM MyTable
--rollback DROP PROCEDURE MyNewProc
```

**Timeline:**
```
Before: [Procedure doesn't exist]
   ↓
Deploy: CREATE PROCEDURE MyNewProc
   ↓
After: [Procedure exists]
   ↓
Rollback: DROP PROCEDURE MyNewProc
   ↓
After Rollback: [Procedure doesn't exist] ✅ Back to original state
```

### Strategy 2: Restore Previous Version (Modified Procedure)

**Use when:** Modifying existing procedure

```sql
--changeset author:modify_proc
ALTER PROCEDURE MyProc
AS
SELECT *, NewColumn FROM MyTable  -- Added new column
--rollback ALTER PROCEDURE MyProc AS
--rollback SELECT * FROM MyTable  -- Original version
```

**Timeline:**
```
Before: [Procedure returns all columns]
   ↓
Deploy: ALTER adds NewColumn
   ↓
After: [Procedure returns all + NewColumn]
   ↓
Rollback: ALTER removes NewColumn
   ↓
After Rollback: [Procedure returns all columns] ✅ Back to original state
```

### Strategy 3: File-Based Rollback (Version Control)

**Use when:** Complex procedures, maintaining versions

**changelog.xml:**
```xml
<changeSet author="dev" id="update_proc_v3">
    <sqlFile path="procedures/MyProc_v3.sql" endDelimiter="GO"/>
    <rollback>
        <sqlFile path="procedures/MyProc_v2.sql" endDelimiter="GO"/>
    </rollback>
</changeSet>
```

**Files:**
- `MyProc_v3.sql` - New version (deploy)
- `MyProc_v2.sql` - Previous version (rollback)

**Timeline:**
```
Before: [Procedure v2 deployed]
   ↓
Deploy: Execute MyProc_v3.sql
   ↓
After: [Procedure v3 deployed]
   ↓
Rollback: Execute MyProc_v2.sql
   ↓
After Rollback: [Procedure v2 deployed] ✅ Back to previous version
```

**Advantages:**
- ✅ Clean version history
- ✅ Easy to see differences between versions
- ✅ Can maintain many versions
- ✅ Simpler changelog
- ✅ Better for complex procedures

---

## Common Patterns in This Project

### Pattern 1: Customer Lookup Procedures

All three main procedures follow a similar pattern:

```
Input: Customer ID or Order ID
   ↓
Join related tables
   ↓
Calculate or aggregate data
   ↓
Return formatted results
```

**CustOrderHist:** Customer → Orders → Products (with totals)
**CustOrdersOrders:** Customer → Orders (with dates)
**CustOrdersDetail:** Order → Products (with calculations)

### Pattern 2: Implicit Joins

All procedures use **implicit JOIN syntax**:

```sql
FROM Products P, [Order Details] OD, Orders O, Customers C
WHERE C.CustomerID = O.CustomerID 
AND O.OrderID = OD.OrderID 
AND OD.ProductID = P.ProductID
```

**Modern alternative (explicit JOIN):**
```sql
FROM Customers C
INNER JOIN Orders O ON C.CustomerID = O.CustomerID
INNER JOIN [Order Details] OD ON O.OrderID = OD.OrderID
INNER JOIN Products P ON OD.ProductID = P.ProductID
```

**Both are equivalent**, but explicit JOIN is more readable.

### Pattern 3: Aggregation with GROUP BY

Several procedures use SUM with GROUP BY:

```sql
SELECT ProductName, Total=SUM(Quantity)
FROM ...
GROUP BY ProductName
```

**How it works:**
```
Raw data:
ProductName | Quantity
------------|----------
Chai        | 10
Chang       | 5
Chai        | 15
Chai        | 8
Chang       | 3

After GROUP BY ProductName and SUM(Quantity):
ProductName | Total
------------|-------
Chai        | 33    (10 + 15 + 8)
Chang       | 8     (5 + 3)
```

---

## Best Practices Demonstrated

1. **Always include rollback** - Every procedure change has rollback
2. **Use DROP IF EXISTS** - Prevents errors on re-deployment
3. **Version your procedures** - v1, v2 files for history
4. **Use runOnChange for procedures** - Ensures updates deploy
5. **Document parameters** - Clear naming (@CustomerID not @C)
6. **Schema qualify names** - [dbo].[ProcName] is explicit
7. **Use GO separators** - Proper batch separation
8. **Test rollback** - Pipeline validates rollback works

---

## Troubleshooting Guide

### Problem: Procedure not updating

**Symptom:** Changed SQL but procedure still has old logic

**Cause:** Changeset already executed, runOnChange not set

**Solution:**
```sql
--changeset author:proc_update runOnChange:true  -- Add this
CREATE PROCEDURE ...
```

### Problem: Rollback fails with "Procedure doesn't exist"

**Symptom:** Rollback tries to DROP non-existent procedure

**Cause:** Procedure was manually deleted or never created

**Solution:**
```sql
--rollback DROP PROCEDURE IF EXISTS [dbo].[MyProc]  -- Add IF EXISTS
```

### Problem: Permission denied on procedure after ALTER

**Symptom:** Users can't execute procedure after update

**Cause:** ALTER preserved permissions, but user lost access

**Solution:**
```sql
-- Add GRANT after ALTER
ALTER PROCEDURE ...
GO
GRANT EXECUTE ON [dbo].[MyProc] TO [user_role]
GO
```

### Problem: Rollback restores wrong version

**Symptom:** Rollback doesn't match previous state

**Cause:** Rollback SQL doesn't match previous version

**Solution:**
- Review DATABASECHANGELOG history
- Check version control for correct previous version
- Update rollback SQL to match actual previous state

---

## Summary

### Stored Procedures in This Project:

1. **CustOrderHist** (v1, v2)
   - Purpose: Customer order history with product totals
   - Versions: v1 (correct), v2 (test with +1)
   - Rollback: Restore previous version

2. **CustOrdersOrders**
   - Purpose: List customer's orders with dates
   - Single version
   - Rollback: Would drop if created

3. **CustOrdersDetail**
   - Purpose: Order line items with price calculations
   - Complex calculations (discount, extended price)
   - Rollback: Would drop if created

### Key Concepts:

- **Stored procedures** = Reusable SQL code in database
- **Parameters** = Inputs (like function arguments)
- **Versioning** = Multiple versions for evolution
- **Rollback** = Undo changes safely
- **runOnChange** = Re-run when SQL changes
- **ALTER vs CREATE** = Modify vs create new

### The Big Picture:

```
Development → Version Control → Liquibase → Database
     ↓              ↓               ↓           ↓
  Write SQL    Track changes    Deploy      Execute
     ↓              ↓               ↓           ↓
  Test logic   Tag versions    Test rollback Store compiled
     ↓              ↓               ↓           ↓
  Commit      Review diffs     Tag deployment Call from apps
```

This systematic approach ensures **reliable, traceable, reversible** database changes!
