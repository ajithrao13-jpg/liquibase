# Liquibase Database Migration Project

This repository contains Liquibase database migration scripts and CI/CD pipeline configurations for managing PostgreSQL database changes.

## 📋 Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Project Structure](#project-structure)
- [Usage](#usage)
- [CI/CD Pipeline](#cicd-pipeline)
- [Best Practices](#best-practices)
- [Security Guidelines](#security-guidelines)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This project uses Liquibase to manage database schema changes in a version-controlled, automated, and auditable way. The CI/CD pipeline automates deployment and rollback operations.

## 📦 Prerequisites

- GitLab CI/CD or equivalent pipeline runner
- PostgreSQL database (version 12+)
- Access to database servers
- Environment variables configured (see Setup)

## 🚀 Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd liquibase
```

### 2. Configure Environment Variables

Set the following environment variables in your CI/CD settings or local environment:

**Required Variables:**
- `DB_HOST` - Database host address
- `DB_PORT` - Database port (default: 5432)
- `DB_NAME` - Database name
- `DB_USER` - Database username
- `DB_PASS` - Database password

### 3. Local Development Setup

For local development, create a `liquibase.properties` file:

```bash
# Copy the example file
cp liquibase.properties.example liquibase.properties

# Edit with your actual credentials
# IMPORTANT: Never commit this file to version control
nano liquibase.properties
```

### 4. Download JDBC Driver (Local Use)

```bash
# Download PostgreSQL JDBC driver
wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.8/postgresql-42.7.8.jar
```

## 📁 Project Structure

```
.
├── .gitlab-ci.yml              # CI/CD pipeline configuration
├── .gitignore                  # Git ignore rules (including credentials)
├── .env.example                # Environment variables template
├── liquibase.properties.example # Liquibase config template
├── db.changelog-master.xml     # Master changelog file
├── code/                       # Database changesets
│   ├── tables.sql             # Table definitions
│   ├── views.sql              # View definitions
│   └── procedures.sql         # Stored procedures
└── README.md                   # This file
```

## 🔧 Usage

### Local Liquibase Commands

```bash
# Validate changelog
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  validate

# Check status
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  status --verbose

# Update database
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  update

# Tag current state
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  tag "my-tag"

# Rollback to tag
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  rollback "my-tag"

# Generate rollback SQL (preview)
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  rollback-sql "my-tag"
```

## 🔄 CI/CD Pipeline

The GitLab CI/CD pipeline consists of three stages:

### 1. Validate Stage
- Validates changelog syntax
- Checks for pending changes
- Runs on merge requests and main/develop branches

### 2. Deploy Stage
- Tags current database state
- Shows pending changes
- Applies database migrations
- Requires manual approval
- Only runs on main/develop branches

### 3. Rollback Stage
- Previews rollback SQL
- Rolls back to tagged state
- Requires manual trigger
- Only available on main/develop branches

### Pipeline Execution

**To Deploy:**
1. Push changes to main or develop branch
2. Pipeline automatically runs validation
3. Navigate to GitLab CI/CD → Pipelines
4. Click "Deploy Database" job
5. Click "Play" button to start deployment

**To Rollback:**
1. Navigate to the pipeline that deployed changes
2. Click "Rollback Database" job
3. Click "Play" button to execute rollback

## ✅ Best Practices

### Changelog Best Practices

1. **One Change Per Changeset**: Each changeset should contain only one logical change
2. **Unique IDs**: Use dynamic IDs with author and commit SHA
3. **Include Rollback**: Always provide rollback statements
4. **Add Comments**: Document the purpose of each change
5. **Use Labels and Contexts**: Organize changesets with labels and contexts
6. **Idempotent Changes**: Use `IF NOT EXISTS` and `IF EXISTS` clauses
7. **Test Rollbacks**: Always test rollback procedures before production

### SQL Best Practices

```sql
-- Good: Idempotent, has rollback, well-documented
--changeset author:changeset-id labels:schema-change context:production
--comment: Add email column to user table
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);
--rollback ALTER TABLE users DROP COLUMN IF EXISTS email;

-- Bad: Not idempotent, no rollback
ALTER TABLE users ADD COLUMN email VARCHAR(255);
```

### Version Control Best Practices

1. **Never Commit Credentials**: Use `.gitignore` to exclude sensitive files
2. **Small Commits**: Make small, focused commits
3. **Meaningful Messages**: Use descriptive commit messages
4. **Branch Strategy**: Use feature branches, merge to develop, then main
5. **Code Review**: Always review database changes before merging

### Database Migration Best Practices

1. **Backup First**: Always backup before major changes
2. **Test in Non-Prod**: Test all changes in staging first
3. **Monitor Performance**: Watch for slow queries or locks
4. **Plan Downtime**: Communicate planned maintenance windows
5. **Keep History**: Never modify executed changesets

## 🔒 Security Guidelines

### Critical Security Rules

1. **Never commit database credentials** to version control
2. **Use environment variables** for sensitive data
3. **Rotate credentials regularly**
4. **Use least privilege** database accounts
5. **Enable SSL/TLS** for database connections
6. **Audit access logs** regularly
7. **Implement MFA** for production access

### Credential Management

✅ **DO:**
- Store credentials in CI/CD environment variables
- Use secret management tools (HashiCorp Vault, AWS Secrets Manager)
- Use `.env` files locally (excluded in `.gitignore`)
- Rotate credentials quarterly

❌ **DON'T:**
- Commit `liquibase.properties` with real credentials
- Share credentials via email or chat
- Use production credentials in non-production
- Store credentials in code comments

### Secure Pipeline Configuration

The pipeline is configured to:
- Validate environment variables before execution
- Download JDBC drivers securely from Maven Central
- Use parameterized changesets (no hardcoded values)
- Enable manual approval for production deployments
- Provide rollback preview before execution

## 🐛 Troubleshooting

### Common Issues

**Issue**: JDBC driver not found
```bash
# Solution: Download the driver
wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.8/postgresql-42.7.8.jar
```

**Issue**: Connection refused
```bash
# Solution: Check database connection
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
```

**Issue**: Changeset already exists
```bash
# Solution: Check executed changesets
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  history
```

**Issue**: Rollback fails
```bash
# Solution: Check rollback SQL first
liquibase --classpath=postgresql-42.7.8.jar \
  --defaultsFile=liquibase.properties \
  rollback-sql "tag-name"
```

### Debug Mode

Enable debug logging:
```bash
# Add to liquibase.properties
logLevel: DEBUG
logFile: liquibase.log
```

## 📚 Additional Resources

- [Liquibase Documentation](https://docs.liquibase.com)
- [Liquibase Best Practices](https://docs.liquibase.com/concepts/bestpractices.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)

## 📝 Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Test thoroughly in staging
4. Create a merge request
5. Get approval from team lead
6. Merge to develop, then main

## 📄 License

[Add your license information here]

## 👥 Support

For issues or questions:
- Create an issue in this repository
- Contact the DevOps team
- Check the troubleshooting section above

---

**⚠️ IMPORTANT**: Always backup your database before running migrations in production!
