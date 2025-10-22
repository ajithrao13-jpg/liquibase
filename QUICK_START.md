# Quick Start Guide

## 🚨 START HERE - Critical Actions First!

### Step 1: IMMEDIATE - Rotate Database Credentials (P0)

**The password `Ntersan@1016` was exposed in git. You MUST change it NOW.**

```sql
# Connect to your database
psql -h 34.28.74.92 -U postgres -d postgres

# Change the password
ALTER USER postgres WITH PASSWORD 'YOUR_NEW_SECURE_PASSWORD';
```

**See [SECURITY_ALERT.md](./SECURITY_ALERT.md) for complete instructions.**

---

## 🎯 What This Review Accomplished

Your Liquibase repository has been reviewed and improved with:

✅ **Security**: Removed exposed credentials, added .gitignore, pre-commit hooks  
✅ **Pipeline**: Added validation stage, approval gates, rollback preview  
✅ **Documentation**: 7 comprehensive guides (2,500+ lines)  
✅ **Best Practices**: Documented changeset patterns, security policies, CI/CD operations  

---

## 📚 Documentation Quick Reference

| Document | When to Use |
|----------|-------------|
| **[SECURITY_ALERT.md](./SECURITY_ALERT.md)** | ⚠️ **READ FIRST** - Critical security actions |
| **[README.md](./README.md)** | Setup, usage, troubleshooting |
| **[PIPELINE_GUIDE.md](./PIPELINE_GUIDE.md)** | How to deploy and rollback |
| **[CHANGELOG_BEST_PRACTICES.md](./CHANGELOG_BEST_PRACTICES.md)** | Writing database changes |
| **[SECURITY.md](./SECURITY.md)** | Security policies and procedures |
| **[IMPROVEMENTS.md](./IMPROVEMENTS.md)** | What changed and why |
| **[REVIEW_SUMMARY.md](./REVIEW_SUMMARY.md)** | Executive summary |

---

## ⚡ Quick Actions

### 1. Secure Your Credentials (CRITICAL)

```bash
# 1. Rotate database password (see above)

# 2. Update GitLab CI/CD variables
# Navigate to: Settings → CI/CD → Variables
# Update: DB_PASS with new password
# Mark as: Protected ✓ | Masked ✓
```

### 2. Set Up Locally

```bash
# 1. Clone repository
git clone <your-repo-url>
cd liquibase

# 2. Create local config (don't commit this!)
cp liquibase.properties.example liquibase.properties

# 3. Edit liquibase.properties with your credentials
nano liquibase.properties

# 4. Download JDBC driver
wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.8/postgresql-42.7.8.jar

# 5. Install pre-commit hooks (optional but recommended)
pip install pre-commit
pre-commit install
```

### 3. Test Your Setup

```bash
# Validate changelog
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  validate

# Check status
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  status
```

### 4. Use the Pipeline

1. **Push Changes** → Validation runs automatically
2. **Navigate to Pipeline** → Click "deploy_database"
3. **Review Output** → Check what will be applied
4. **Click Play** → Approve deployment
5. **Monitor** → Watch logs for success

**Full guide**: [PIPELINE_GUIDE.md](./PIPELINE_GUIDE.md)

---

## 🔒 Security Checklist

Complete these actions to secure your repository:

- [ ] **CRITICAL**: Database password rotated
- [ ] GitLab CI/CD variables updated
- [ ] Database audit logs reviewed
- [ ] Security team notified
- [ ] Git history cleaned (optional but recommended)
- [ ] Pre-commit hooks installed
- [ ] Team trained on new processes
- [ ] .gitignore verified working

---

## 📖 Common Tasks

### Create a New Changeset

```sql
-- In changelogs/tables.sql or appropriate file
--changeset ${author}:${changesetId}-X labels:my-label context:production
--comment: Description of what this change does
ALTER TABLE my_table ADD COLUMN new_column VARCHAR(50);
--rollback ALTER TABLE my_table DROP COLUMN new_column;
```

**Best practices**: [CHANGELOG_BEST_PRACTICES.md](./CHANGELOG_BEST_PRACTICES.md)

### Deploy Changes

1. Commit and push to main/develop
2. Go to GitLab → CI/CD → Pipelines
3. Wait for validation to pass
4. Click "deploy_database" → Play
5. Monitor deployment logs

**Full guide**: [PIPELINE_GUIDE.md](./PIPELINE_GUIDE.md)

### Rollback Changes

1. Go to original deployment pipeline
2. Click "rollback_database" → Play
3. Review rollback SQL
4. Confirm and monitor

**Full guide**: [PIPELINE_GUIDE.md](./PIPELINE_GUIDE.md)

---

## ❓ FAQ

### Q: Why can't I commit liquibase.properties?

**A**: It contains sensitive credentials. Use `liquibase.properties.example` as a template and create your own local copy (which is ignored by git).

### Q: Where do I put database credentials?

**A**: 
- **Locally**: In `liquibase.properties` (not tracked by git)
- **CI/CD**: In GitLab CI/CD variables (Settings → CI/CD → Variables)

### Q: How do I download the JDBC driver?

**A**: 
```bash
wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.8/postgresql-42.7.8.jar
```

Or the pipeline downloads it automatically.

### Q: Why was my deployment rejected?

**A**: Check:
1. Validation stage passed?
2. Environment variables configured?
3. JDBC driver available?
4. Database accessible from runner?

### Q: How do I write a good changeset?

**A**: See [CHANGELOG_BEST_PRACTICES.md](./CHANGELOG_BEST_PRACTICES.md) for comprehensive guide with examples.

---

## 🆘 Getting Help

### For Security Issues
- **Critical**: Follow [SECURITY_ALERT.md](./SECURITY_ALERT.md)
- **General**: Review [SECURITY.md](./SECURITY.md)

### For Pipeline Issues
- **Guide**: [PIPELINE_GUIDE.md](./PIPELINE_GUIDE.md)
- **Troubleshooting**: [README.md](./README.md#troubleshooting)

### For Code Questions
- **Best Practices**: [CHANGELOG_BEST_PRACTICES.md](./CHANGELOG_BEST_PRACTICES.md)
- **Examples**: Review existing changesets in `changelogs/`

---

## 🎓 Next Steps

1. ✅ Complete security actions from [SECURITY_ALERT.md](./SECURITY_ALERT.md)
2. 📖 Read [README.md](./README.md) for complete setup
3. 🔧 Test pipeline in staging environment
4. 👥 Train team on new processes
5. 📋 Establish code review workflow
6. 🔄 Set up regular security audits

---

## ⭐ Key Points to Remember

1. 🔴 **NEVER commit credentials** - Always use environment variables
2. 🟡 **Always validate before deploying** - Let validation stage catch errors
3. 🟢 **Test rollbacks** - Make sure you can undo changes
4. 🟢 **One change per changeset** - Makes rollback easier
5. 🟢 **Document your changes** - Future you will thank you
6. 🟢 **Review before merging** - Catch issues early
7. 🟢 **Monitor after deployment** - Verify everything works

---

**🚀 You're Ready!** Follow the security steps above, then dive into the documentation to learn more.

**Remember**: Your database credentials were exposed and MUST be rotated. See [SECURITY_ALERT.md](./SECURITY_ALERT.md).

---

Good luck! 🎉