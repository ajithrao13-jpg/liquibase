# Example: Using the Rollback Job

## Scenario 1: Simple Rollback to a Specific Tag

**Objective:** Rollback database to pipeline 12345

**Steps in GitLab UI:**
1. Go to CI/CD → Pipelines
2. Click on any pipeline
3. Find `rollback_by_tag_or_label` job
4. Click Play button (▶️)
5. Add variable:
   ```
   Key: ROLLBACK_TAG
   Value: 12345
   ```
6. Click "Run job"

**What happens:**
```bash
# The job will execute:
liquibase \
  --classpath="postgresql-42.7.8.jar" \
  --defaultsFile="liquibase.properties" \
  rollback 12345
```

**Expected Output:**
```
Rolling back to tag: 12345
Liquibase command executing...
Rolling back changesets to tag 12345...
Rollback successful!
```

---

## Scenario 2: Rollback with Label Filter

**Objective:** Rollback to pipeline 12345 but only for changesets with label "label1"

**Steps in GitLab UI:**
1. Go to CI/CD → Pipelines
2. Click on any pipeline
3. Find `rollback_by_tag_or_label` job
4. Click Play button (▶️)
5. Add variables:
   ```
   Key: ROLLBACK_TAG
   Value: 12345
   
   Key: ROLLBACK_LABEL
   Value: label1
   ```
6. Click "Run job"

**What happens:**
```bash
# The job will execute:
liquibase \
  --classpath="postgresql-42.7.8.jar" \
  --defaultsFile="liquibase.properties" \
  --label-filter=label1 \
  rollback 12345
```

**Expected Output:**
```
Rolling back to tag: 12345
Applying label filter: label1
Liquibase command executing...
Rolling back changesets with label 'label1' to tag 12345...
Rollback successful!
```

**Effect:**
- Only changesets with `labels:label1` will be rolled back
- From `code/tables.sql`, this would rollback changeset `${changesetId}-1` only:
  ```sql
  --changeset ${author}:${changesetId}-1 labels:label1 context:context1
  --comment: Create person table if not exists
  ```

---

## Scenario 3: Rollback Multiple Labels

**Objective:** Rollback changesets with either label1 OR label2 to tag v1.0

**Steps in GitLab UI:**
1. Go to CI/CD → Pipelines
2. Click on any pipeline
3. Find `rollback_by_tag_or_label` job
4. Click Play button (▶️)
5. Add variables:
   ```
   Key: ROLLBACK_TAG
   Value: v1.0
   
   Key: ROLLBACK_LABEL
   Value: label1,label2
   ```
6. Click "Run job"

**What happens:**
```bash
# The job will execute:
liquibase \
  --classpath="postgresql-42.7.8.jar" \
  --defaultsFile="liquibase.properties" \
  --label-filter=label1,label2 \
  rollback v1.0
```

**Expected Output:**
```
Rolling back to tag: v1.0
Applying label filter: label1,label2
Liquibase command executing...
Rolling back changesets with labels 'label1' or 'label2' to tag v1.0...
Rollback successful!
```

**Effect:**
- Changesets with `labels:label1` OR `labels:label2` will be rolled back
- From `code/tables.sql`, this would rollback changesets `${changesetId}-1` and `${changesetId}-2`:
  ```sql
  --changeset ${author}:${changesetId}-1 labels:label1 context:context1
  --changeset ${author}:${changesetId}-2 labels:label2 context:context2
  ```

---

## Scenario 4: Error - No Parameters Provided

**What happens when user doesn't provide any parameters:**

**Steps in GitLab UI:**
1. Click Play on `rollback_by_tag_or_label` job
2. Don't add any variables
3. Click "Run job"

**Expected Output:**
```
ERROR: Either ROLLBACK_TAG or ROLLBACK_LABEL must be set
Set ROLLBACK_TAG to rollback to a specific tag (e.g., '12345' or 'v1.0')
Set ROLLBACK_LABEL to filter changesets by label (e.g., 'label1,label2')
Both can be set to use tag rollback with label filtering
```
**Job Status:** ❌ Failed (exit code 1)

---

## Scenario 5: Custom Production Tag

**Objective:** Create a custom tag for production release and use it for rollback

**Step 1: Create a custom tag**
After a successful deployment, manually run:
```bash
liquibase \
  --classpath="postgresql-42.7.8.jar" \
  --defaultsFile="liquibase.properties" \
  tag "production-v2.0-2024-10-22"
```

**Step 2: Later, rollback to that tag**
In GitLab UI:
```
Key: ROLLBACK_TAG
Value: production-v2.0-2024-10-22
```

**What happens:**
```bash
liquibase \
  --classpath="postgresql-42.7.8.jar" \
  --defaultsFile="liquibase.properties" \
  rollback production-v2.0-2024-10-22
```

---

## Comparison: Old vs New Rollback Jobs

### Old Job: `rollback_database`
- **Tag:** Automatically uses `$CI_PIPELINE_ID`
- **Labels:** Not supported
- **Flexibility:** Limited - can only rollback to the current pipeline's tag
- **Use case:** Quick rollback of current pipeline

### New Job: `rollback_by_tag_or_label`
- **Tag:** User-specified (any tag name)
- **Labels:** Supported with filtering
- **Flexibility:** High - can rollback to any tag, filter by labels
- **Use case:** 
  - Rollback to older pipelines
  - Rollback specific features by label
  - Production rollback with custom tags

---

## Best Practices

1. **Always tag before production deployments:**
   ```bash
   liquibase tag "production-$(date +%Y%m%d-%H%M%S)"
   ```

2. **Use meaningful labels in changesets:**
   ```sql
   --changeset author:id labels:feature-user-auth
   --changeset author:id labels:feature-reporting
   ```

3. **Test rollback in non-production first:**
   - Run rollback job in staging environment
   - Verify data integrity
   - Then apply to production if needed

4. **Document your tags:**
   Keep a log of important tags and what they represent

5. **Use label filters for partial rollbacks:**
   When only specific features need to be rolled back

---

## Viewing Available Tags

To see all tags in your database:
```bash
liquibase history
```

This will show all applied changesets and tags, helping you choose the right tag for rollback.
