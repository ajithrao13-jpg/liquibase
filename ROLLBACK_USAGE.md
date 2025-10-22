# Rollback Usage Guide

This document explains how to use the GitLab CI/CD rollback jobs in this Liquibase project.

## Available Rollback Jobs

### 1. `rollback_database` (Simple Rollback)
Rolls back the database to the state tagged with the current pipeline ID (`$CI_PIPELINE_ID`).

**Usage:**
- Manually trigger this job in GitLab CI/CD UI
- No parameters needed
- Rolls back to the tag created during the deploy stage

**Example:**
Just click "Run" on the `rollback_database` job in GitLab pipeline view.

---

### 2. `rollback_by_tag_or_label` (Advanced Rollback)
Rolls back the database using custom tag and/or label parameters.

**Usage:**
Manually trigger this job in GitLab CI/CD UI and provide variables:

#### Parameters:
- **`ROLLBACK_TAG`**: (Required) The tag name to rollback to
  - Can be a pipeline ID (e.g., `12345`)
  - Can be a custom tag (e.g., `v1.0`, `production-release`)
  
- **`ROLLBACK_LABEL`**: (Optional) Label filter to apply during rollback
  - Can be a single label (e.g., `label1`)
  - Can be multiple labels (e.g., `label1,label2`)
  - When specified, only changesets with matching labels will be rolled back

#### Rollback Scenarios:

**Scenario 1: Rollback by Tag Only**
```yaml
ROLLBACK_TAG: "12345"
ROLLBACK_LABEL: ""
```
This will rollback all changesets to the state when tag `12345` was created.

**Scenario 2: Rollback by Tag with Label Filter**
```yaml
ROLLBACK_TAG: "production-v2.0"
ROLLBACK_LABEL: "label1,label2"
```
This will rollback to tag `production-v2.0` but only for changesets with labels `label1` or `label2`.

**Scenario 3: Using Pipeline IDs**
```yaml
ROLLBACK_TAG: "56789"
ROLLBACK_LABEL: ""
```
This will rollback to the state from pipeline `56789`.

---

## How to Trigger Rollback in GitLab

1. Navigate to your GitLab project
2. Go to **CI/CD** → **Pipelines**
3. Click on the pipeline you want to work with
4. Find the `rollback_by_tag_or_label` job
5. Click the **Play** button (▶️)
6. In the popup, add the variables:
   - Variable name: `ROLLBACK_TAG`, Value: your tag (e.g., `12345`)
   - Variable name: `ROLLBACK_LABEL`, Value: your labels (e.g., `label1,label2`) (optional)
7. Click **Run job**

---

## Examples from SQL Changesets

Based on the changesets in `code/tables.sql`:

```sql
--changeset ${author}:${changesetId}-1 labels:label1 context:context1
--changeset ${author}:${changesetId}-2 labels:label2 context:context2
--changeset ${author}:${changesetId}-3 labels:label3 context:context3
--changeset ${author}:${changesetId}-4 labels:label4 context:context4
```

**Example 1:** Rollback only changesets with `label1`
```yaml
ROLLBACK_TAG: "12345"
ROLLBACK_LABEL: "label1"
```

**Example 2:** Rollback changesets with `label1` OR `label2`
```yaml
ROLLBACK_TAG: "12345"
ROLLBACK_LABEL: "label1,label2"
```

**Example 3:** Rollback all changesets to a tag
```yaml
ROLLBACK_TAG: "12345"
ROLLBACK_LABEL: ""
```

---

## Tags in Liquibase

### Automatic Tagging
The `deploy_database` job automatically creates a tag with the pipeline ID before applying changes:
```bash
liquibase tag "$CI_PIPELINE_ID"
```

### Custom Tagging
You can also manually tag your database state using Liquibase:
```bash
liquibase --classpath="postgresql-42.7.8.jar" \
          --defaultsFile="liquibase.properties" \
          tag "my-custom-tag"
```

---

## Important Notes

1. **ROLLBACK_TAG is required** - You must always specify a tag to rollback to
2. **ROLLBACK_LABEL is optional** - Use it to selectively rollback certain changesets
3. **Label filtering** works with Liquibase's label expression syntax
4. **Rollback is a manual job** - It requires explicit confirmation to run
5. **Test first** - Consider testing rollback in a non-production environment first

---

## Troubleshooting

### Error: "Either ROLLBACK_TAG or ROLLBACK_LABEL must be set"
**Solution:** Make sure to provide at least the `ROLLBACK_TAG` variable when triggering the job.

### Error: "ROLLBACK_TAG is required for rollback operation"
**Solution:** The ROLLBACK_TAG parameter is mandatory. ROLLBACK_LABEL can only be used together with ROLLBACK_TAG.

### Tag not found
**Solution:** Verify that the tag exists in your database by running:
```bash
liquibase history
```
