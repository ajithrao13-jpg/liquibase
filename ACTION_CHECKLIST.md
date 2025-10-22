# Action Checklist - Post-Review Tasks

## 🚨 PRIORITY 0 - IMMEDIATE (Complete within 1 hour)

**These actions are CRITICAL and must be completed immediately.**

### Database Security

- [ ] **Rotate database password** for user `postgres` on host `34.28.74.92`
  ```sql
  psql -h 34.28.74.92 -U postgres -d postgres
  ALTER USER postgres WITH PASSWORD 'NEW_SECURE_PASSWORD';
  ```
  **Note**: Choose a strong password (16+ characters, mixed case, numbers, symbols)

- [ ] **Update GitLab CI/CD variables** with new password
  - Navigate to: Settings → CI/CD → Variables
  - Update variable: `DB_PASS`
  - Ensure marked as: Protected ✓ | Masked ✓
  - Click "Save variables"

- [ ] **Review database audit logs** for unauthorized access
  - Check PostgreSQL logs for unusual connections
  - Look for failed login attempts
  - Review queries executed by `postgres` user
  - Document any suspicious activity

- [ ] **Notify security team** about credential exposure
  - Send email to security team
  - Include timeline of exposure
  - Document remediation actions taken
  - Request security incident number

---

## 🟡 PRIORITY 1 - SHORT TERM (Complete within 24 hours)

### Git Repository Cleanup

- [ ] **Clean git history** (Recommended but optional)
  
  **Option A: Using BFG Repo-Cleaner (Easier)**
  ```bash
  # Download BFG
  wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar
  
  # Clone mirror
  git clone --mirror https://github.com/ajithrao13-jpg/liquibase.git
  cd liquibase.git
  
  # Remove file from history
  java -jar ../bfg-1.14.0.jar --delete-files liquibase.properties
  
  # Clean up
  git reflog expire --expire=now --all
  git gc --prune=now --aggressive
  
  # Force push (WARNING: Rewrites history)
  git push --force
  ```
  
  **Option B: Using git filter-branch**
  ```bash
  git filter-branch --force --index-filter \
    "git rm --cached --ignore-unmatch liquibase.properties" \
    --prune-empty --tag-name-filter cat -- --all
  
  git push --force --all
  ```
  
  ⚠️ **IMPORTANT**: Coordinate with team before force pushing!

- [ ] **Review repository access**
  - List all users with access: Settings → Members
  - Remove unnecessary access
  - Verify access levels are appropriate
  - Document who has access and why

- [ ] **Enable IP whitelisting** on database
  ```
  # In PostgreSQL pg_hba.conf
  host all postgres 10.0.0.0/8 md5  # Your office network
  host all postgres <CI_RUNNER_IP> md5  # GitLab runner
  ```

- [ ] **Enable SSL/TLS** for database connections
  - Verify PostgreSQL SSL is enabled
  - Update connection strings to require SSL:
    ```
    jdbc:postgresql://host:5432/db?ssl=true&sslmode=require
    ```

### Pipeline Configuration

- [ ] **Configure all required CI/CD variables**
  - Settings → CI/CD → Variables
  - Required variables:
    - `DB_HOST` - Database hostname (mark as Protected, Masked)
    - `DB_PORT` - Database port (mark as Protected)
    - `DB_NAME` - Database name (mark as Protected)
    - `DB_USER` - Database username (mark as Protected, Masked)
    - `DB_PASS` - Database password (mark as Protected, Masked)
  - Verify all are set correctly

- [ ] **Test pipeline in staging** (if you have staging environment)
  - Push a test change to staging branch
  - Verify validation stage runs
  - Test deployment manually
  - Test rollback functionality
  - Document any issues

### Local Development Setup

- [ ] **Set up local development environment**
  ```bash
  # Clone repository
  git clone <your-repo-url>
  cd liquibase
  
  # Create local config
  cp liquibase.properties.example liquibase.properties
  
  # Edit with your credentials (DO NOT COMMIT)
  nano liquibase.properties
  
  # Download JDBC driver
  wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.8/postgresql-42.7.8.jar
  ```

- [ ] **Install and configure pre-commit hooks**
  ```bash
  pip install pre-commit
  cd /path/to/liquibase/repo
  pre-commit install
  pre-commit run --all-files  # Test it works
  ```

- [ ] **Verify .gitignore is working**
  ```bash
  # Should NOT show liquibase.properties even if it exists
  git status
  
  # Should return nothing
  git ls-files | grep liquibase.properties
  ```

---

## 🟢 PRIORITY 2 - MEDIUM TERM (Complete within 1 week)

### Documentation and Training

- [ ] **Review all documentation with team**
  - [ ] README.md - Setup and usage
  - [ ] SECURITY.md - Security policies
  - [ ] PIPELINE_GUIDE.md - CI/CD operations
  - [ ] CHANGELOG_BEST_PRACTICES.md - Writing changesets
  - Schedule team meeting to review

- [ ] **Conduct security training session**
  - Why credentials should never be committed
  - How to use environment variables
  - How to use pre-commit hooks
  - Security incident response procedures

- [ ] **Establish code review process**
  - Define approval requirements
  - Create review checklist
  - Assign reviewers
  - Document process

### Additional Security Measures

- [ ] **Implement database activity monitoring**
  - Enable PostgreSQL logging
  - Set up log aggregation
  - Configure alerts for suspicious activity
  - Test alert system

- [ ] **Set up monitoring and alerting**
  - Pipeline failure alerts
  - Database connection alerts
  - Security event alerts
  - Failed login attempt alerts

- [ ] **Create dedicated database user for Liquibase**
  ```sql
  -- Create new user with limited privileges
  CREATE USER liquibase_user WITH PASSWORD 'SECURE_PASSWORD';
  GRANT CONNECT ON DATABASE postgres TO liquibase_user;
  GRANT USAGE ON SCHEMA public TO liquibase_user;
  GRANT CREATE ON SCHEMA public TO liquibase_user;
  GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO liquibase_user;
  
  -- Update CI/CD variables to use new user
  ```

- [ ] **Implement regular credential rotation schedule**
  - Set calendar reminder for quarterly rotation
  - Document rotation procedure
  - Create rotation checklist
  - Assign rotation responsibility

### Process Improvements

- [ ] **Create change management process**
  - Define change request template
  - Establish approval workflow
  - Document rollback procedures
  - Create communication plan

- [ ] **Set up regular security audits**
  - Schedule quarterly security reviews
  - Create audit checklist
  - Assign audit responsibility
  - Document findings and actions

- [ ] **Implement automated testing** (optional)
  - Create test database
  - Write integration tests
  - Set up automated testing in pipeline
  - Document test procedures

---

## 🔵 PRIORITY 3 - LONG TERM (Complete within 1-3 months)

### Advanced Security

- [ ] **Implement secret management system**
  - Evaluate options (HashiCorp Vault, AWS Secrets Manager, etc.)
  - Set up secret management system
  - Migrate credentials to secret manager
  - Update pipeline to use secret manager

- [ ] **Implement automated security scanning**
  - Set up dependency scanning
  - Configure SAST/DAST tools
  - Enable container scanning
  - Review and address findings

- [ ] **Enable database encryption at rest**
  - Review PostgreSQL encryption options
  - Implement Transparent Data Encryption (TDE)
  - Verify encryption is working
  - Document encryption keys management

### Infrastructure Improvements

- [ ] **Set up automated database backups**
  - Configure automated backup schedule
  - Test backup restoration
  - Document backup procedures
  - Set up backup monitoring

- [ ] **Implement disaster recovery plan**
  - Document recovery procedures
  - Test recovery process
  - Define RTO/RPO targets
  - Create runbook

- [ ] **Implement multi-environment strategy**
  - Set up dev/staging/prod environments
  - Configure environment-specific variables
  - Implement promotion workflow
  - Document environment differences

### Process Maturity

- [ ] **Implement compliance controls**
  - Define compliance requirements
  - Implement audit trail
  - Create compliance reporting
  - Schedule regular compliance reviews

- [ ] **Performance optimization**
  - Implement query performance monitoring
  - Optimize slow queries
  - Create index optimization plan
  - Regular performance reviews

- [ ] **Establish metrics and KPIs**
  - Define success metrics
  - Set up metric collection
  - Create dashboards
  - Regular metric reviews

---

## ✅ Verification Steps

### After Priority 0 (Immediate Actions)

```bash
# Verify new password works
psql -h 34.28.74.92 -U postgres -d postgres

# Verify CI/CD variables set
# Check in GitLab: Settings → CI/CD → Variables

# Verify audit log access
# Check PostgreSQL logs for unusual activity
```

### After Priority 1 (Short Term Actions)

```bash
# Verify git history cleaned
git log -p | grep -i "Ntersan"  # Should return nothing

# Verify pre-commit hooks working
echo "password = test123" > test.txt
git add test.txt
git commit -m "test"  # Should be blocked by detect-secrets

# Verify pipeline works
# Push to test branch and check validation runs
```

### After Priority 2 (Medium Term Actions)

```bash
# Verify monitoring is working
# Check that alerts are configured

# Verify team is trained
# Quiz team members on security practices

# Verify new user works
psql -h 34.28.74.92 -U liquibase_user -d postgres
```

---

## 📊 Progress Tracking

### Priority 0 (Critical)
**Target**: Complete within 1 hour  
**Progress**: [ ] 0/4 completed

### Priority 1 (High)
**Target**: Complete within 24 hours  
**Progress**: [ ] 0/11 completed

### Priority 2 (Medium)
**Target**: Complete within 1 week  
**Progress**: [ ] 0/13 completed

### Priority 3 (Low)
**Target**: Complete within 1-3 months  
**Progress**: [ ] 0/9 completed

**Overall Progress**: [ ] 0/37 completed (0%)

---

## 📝 Notes Section

Use this space to track:
- Issues encountered
- Decisions made
- Deviations from plan
- Additional actions needed

```
Date: ___________
Action: _____________________________
Status: _____________________________
Notes: _____________________________
____________________________________
____________________________________
```

---

## 📞 Contact Information

**For Questions or Issues:**

- **Security Team**: _____________________________
- **DevOps Team**: _____________________________
- **Database Team**: _____________________________
- **Team Lead**: _____________________________
- **On-Call Engineer**: _____________________________

---

## 📋 Sign-off

When all Priority 0 actions are complete:

```
Completed by: _____________________________
Date: _____________________________
Verified by: _____________________________
Date: _____________________________

Credential Rotation Confirmed: [ ]
Audit Logs Reviewed: [ ]
Security Team Notified: [ ]
CI/CD Variables Updated: [ ]
```

---

**REMEMBER**: Priority 0 actions are CRITICAL and must be completed immediately!

Print this checklist and track your progress!