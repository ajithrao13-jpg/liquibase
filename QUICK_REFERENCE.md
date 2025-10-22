# Quick Reference: GitLab Rollback Jobs

## Job Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GitLab CI/CD Pipeline                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Stage: DEPLOY                                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │ deploy_database                                     │    │
│  │  1. Tag DB with pipeline ID                        │    │
│  │  2. Apply changesets                               │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Stage: ROLLBACK (Manual)                                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │ rollback_database                                   │    │
│  │  • Rolls back to current pipeline tag              │    │
│  │  • No parameters needed                            │    │
│  │  • Quick & simple                                  │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │ rollback_by_tag_or_label  ⭐ NEW                   │    │
│  │  • Rolls back to ANY tag                           │    │
│  │  • Supports label filtering                        │    │
│  │  • Flexible & powerful                             │    │
│  │                                                     │    │
│  │  Parameters:                                        │    │
│  │    ROLLBACK_TAG: Required (tag name)               │    │
│  │    ROLLBACK_LABEL: Optional (label filter)         │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Job Comparison

| Feature | rollback_database | rollback_by_tag_or_label |
|---------|-------------------|--------------------------|
| **Tag Source** | Current pipeline ID | User-specified |
| **Label Support** | ❌ No | ✅ Yes |
| **Custom Tags** | ❌ No | ✅ Yes |
| **Parameters** | None | ROLLBACK_TAG, ROLLBACK_LABEL |
| **Flexibility** | Low | High |
| **Use Case** | Quick rollback of current deployment | Targeted rollback, production releases |

---

## Parameter Reference

### ROLLBACK_TAG (Required)
- **Type:** String
- **Examples:**
  - `"12345"` - Pipeline ID
  - `"v1.0"` - Version tag
  - `"production-2024-10-22"` - Custom tag
- **Purpose:** Specifies which database state to rollback to

### ROLLBACK_LABEL (Optional)
- **Type:** String (comma-separated)
- **Examples:**
  - `"label1"` - Single label
  - `"label1,label2"` - Multiple labels
  - `""` - No filtering (default)
- **Purpose:** Filters which changesets to rollback based on their labels

---

## Usage Patterns

### Pattern 1: Simple Rollback
```yaml
ROLLBACK_TAG: "12345"
```
→ Rollback ALL changesets to tag 12345

### Pattern 2: Filtered Rollback
```yaml
ROLLBACK_TAG: "12345"
ROLLBACK_LABEL: "feature-auth"
```
→ Rollback only changesets labeled "feature-auth" to tag 12345

### Pattern 3: Multi-Label Rollback
```yaml
ROLLBACK_TAG: "v1.0"
ROLLBACK_LABEL: "critical,security"
```
→ Rollback changesets labeled "critical" OR "security" to tag v1.0

---

## Error Handling

### ❌ No parameters provided
```
ERROR: Either ROLLBACK_TAG or ROLLBACK_LABEL must be set
```
**Fix:** Provide at least ROLLBACK_TAG

### ❌ Only ROLLBACK_LABEL provided
```
ERROR: ROLLBACK_TAG is required for rollback operation
```
**Fix:** ROLLBACK_TAG is mandatory; ROLLBACK_LABEL is supplementary

### ❌ Tag doesn't exist
```
Liquibase error: Tag 'xyz' not found
```
**Fix:** Check available tags with `liquibase history`

---

## Liquibase Label Syntax

Labels in changesets:
```sql
--changeset author:id labels:label1
--changeset author:id labels:label1,label2
--changeset author:id labels:feature-auth
```

Label filter expressions:
- `label1` - Single label
- `label1,label2` - OR condition (label1 OR label2)
- `label1 AND label2` - AND condition (both required)
- `!label1` - NOT condition (exclude label1)

---

## How to Trigger in GitLab

1. **Navigate:** CI/CD → Pipelines → Select Pipeline
2. **Find Job:** `rollback_by_tag_or_label`
3. **Click:** Play button (▶️)
4. **Add Variables:**
   - Click "Add variable"
   - Enter key-value pairs
5. **Execute:** Click "Run job"

---

## Common Scenarios

### Scenario A: Emergency Production Rollback
1. Identify the last good production tag (e.g., "prod-v2.5")
2. Trigger `rollback_by_tag_or_label`
3. Set `ROLLBACK_TAG: "prod-v2.5"`
4. Leave `ROLLBACK_LABEL` empty
5. Execute

### Scenario B: Rollback Single Feature
1. Identify feature label (e.g., "feature-reporting")
2. Identify target tag (e.g., "12345")
3. Set `ROLLBACK_TAG: "12345"`
4. Set `ROLLBACK_LABEL: "feature-reporting"`
5. Execute

### Scenario C: Rollback to Previous Pipeline
1. Find previous pipeline ID (e.g., "56789")
2. Set `ROLLBACK_TAG: "56789"`
3. Leave `ROLLBACK_LABEL` empty
4. Execute

---

## Best Practices

✅ **DO:**
- Tag important states (production releases, milestones)
- Use meaningful label names in changesets
- Test rollback in staging first
- Document your tagging strategy

❌ **DON'T:**
- Rollback without verifying tag exists
- Use rollback as primary deployment strategy
- Skip testing in non-production environments
- Forget to communicate with team before production rollback

---

## Quick Command Reference

### Tag current state
```bash
liquibase tag "my-tag-name"
```

### View history and tags
```bash
liquibase history
```

### Manual rollback
```bash
# Simple rollback
liquibase rollback "tag-name"

# With label filter
liquibase --label-filter="label1,label2" rollback "tag-name"
```

---

## Need Help?

- 📖 [Rollback Usage Guide](ROLLBACK_USAGE.md) - Detailed documentation
- 💡 [Examples](EXAMPLES.md) - Step-by-step scenarios
- 🌐 [Liquibase Docs](https://docs.liquibase.com) - Official documentation
