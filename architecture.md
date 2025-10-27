# Architecture Diagram - Liquibase CI/CD Pipeline

## High-Level Architecture Overview

This document provides a high-level architecture diagram of the Liquibase CI/CD pipeline with rollback capabilities.

```mermaid
flowchart TB
    Dev[Developer] -->|Push Changes| DevBranch[Developer Branch]
    DevBranch -->|Create| PR[Pull Request]
    
    PR -->|Trigger| Pipeline[GitLab CI Pipeline]
    
    Pipeline --> LintStage[Lint Stage]
    
    subgraph LintStage[Lint Stage]
        direction TB
        Validate[liquibase-validate<br/>- Check connection<br/>- Validate changelog<br/>- Show status]
        Checks[liquibase-checks<br/>- Run quality checks<br/>- Verify best practices]
        Validate --> Checks
    end
    
    LintStage -->|Success| DeployStage[Deploy Stage]
    
    subgraph DeployStage[Deploy Stage]
        direction TB
        DeployDev[liquibase-deploy-to-dev<br/>- Set context filter<br/>- Tag pipeline<br/>- Run update-sql<br/>- Execute update]
    end
    
    DeployStage -->|Deployment Complete| RollbackStage[Rollback Stage]
    
    subgraph RollbackStage[Rollback Stage - Manual]
        direction TB
        
        StandardRollback[Standard Rollback<br/>liquibase-rollback-from-dev<br/>- Rollback to previous tag<br/>- Uses pipeline tag]
        
        CustomRollback[Custom Rollback<br/>liquibase_custom_rollback<br/>- Tag-based rollback<br/>- Custom command rollback<br/>- Flexible rollback options]
        
        subgraph CustomOptions[Custom Rollback Variables]
            direction LR
            RB_TAG[RB_TAG<br/>Target tag for rollback]
            RB_LABEL[RB_LABEL<br/>Label filter for rollback]
            RB_CMD[RB_CMD<br/>Custom Liquibase command<br/>e.g., rollbackCount,<br/>rollbackToDate,<br/>rollbackSQL]
        end
        
        CustomOptions -.->|Configure| CustomRollback
    end
    
    DeployStage -.->|If needed| StandardRollback
    DeployStage -.->|If needed| CustomRollback
    
    subgraph Database[Database Environment]
        direction TB
        DevDB[(Development Database)]
        CertDB[(Certification Database)]
        ProdDB[(Production Database)]
    end
    
    DeployStage -->|Apply Changes| DevDB
    StandardRollback -->|Revert Changes| DevDB
    CustomRollback -->|Revert Changes| DevDB
    
    LintStage -.->|Connect & Validate| DevDB
    
    style LintStage fill:#e1f5ff,stroke:#0366d6,stroke-width:2px
    style DeployStage fill:#dcffe4,stroke:#28a745,stroke-width:2px
    style RollbackStage fill:#fff3cd,stroke:#ffc107,stroke-width:2px
    style StandardRollback fill:#f8d7da,stroke:#dc3545,stroke-width:2px
    style CustomRollback fill:#f8d7da,stroke:#dc3545,stroke-width:2px
    style CustomOptions fill:#fff,stroke:#6c757d,stroke-width:1px,stroke-dasharray: 5 5
```

## Pipeline Stages Breakdown

### 1. **Lint Stage** (Automated)
   - **liquibase-validate**: Validates the changelog syntax and database connection
   - **liquibase-checks**: Runs quality checks on the changelog and database
   - Runs automatically on all pipeline triggers (PR, push, merge, etc.)

### 2. **Deploy Stage** (Automated/Manual)
   - **liquibase-deploy-to-dev**: Deploys database changes to development environment
   - Creates a tag using `$CI_PIPELINE_ID`
   - Runs `update-sql` for preview and `update` for execution
   - Can be extended to cert and production environments (currently commented out)

### 3. **Rollback Stage** (Manual Only)
   - **Standard Rollback** (`liquibase-rollback-from-dev`):
     - Rolls back to the last pipeline tag
     - Runs `rollback-sql` for preview and `rollback` for execution
   
   - **Custom Rollback** (`liquibase_custom_rollback`):
     - Provides flexible rollback options via variables:
       - `RB_TAG` + `RB_LABEL`: Rollback to specific tag with label filter
       - `RB_CMD`: Execute any custom Liquibase rollback command
     - Examples of custom commands:
       - `rollbackCount <value>`: Rollback a specific number of changesets
       - `rollbackToDate <date>`: Rollback to a specific date
       - `rollbackSQL <tag>`: Generate rollback SQL without executing

## Workflow

1. **Developer** pushes code changes to a **developer branch**
2. **Pull Request** is created, triggering the GitLab CI pipeline
3. **Lint jobs** run automatically:
   - Validate changelog structure and syntax
   - Check database connectivity
   - Run quality checks
4. **Deploy job** runs (automatically or manually depending on configuration):
   - Tags the deployment with pipeline ID
   - Applies database changes via Liquibase update
5. **Rollback options** are available (manual trigger only):
   - **Standard rollback**: Quick rollback to previous tag
   - **Custom rollback**: Flexible rollback with custom parameters

## Key Features

- **Automated Validation**: Every PR triggers validation and checks
- **Tagging Strategy**: Each deployment creates a tag for easy rollback
- **Multiple Rollback Options**: Standard and custom rollback strategies
- **Environment Progression**: Designed for dev → cert → prod workflow
- **Manual Safety**: Rollback operations require manual approval
- **Flexible Custom Rollback**: Support for tag-based, count-based, date-based, and SQL-only rollbacks

## Environment Variables

### Standard Variables (per environment)
- `database_server`: Database server hostname
- `database_name`: Database name
- `database_username`: Database username
- `database_password`: Database password
- `database_type`: Type of database (azure_sql, mssql, postgresql)
- `env_context`: Environment context (dev, cert, prod)

### Custom Rollback Variables
- `RB_TAG`: Target tag for rollback (optional)
- `RB_LABEL`: Label filter for selective rollback (optional)
- `RB_CMD`: Custom Liquibase command for advanced rollback scenarios (optional)

## Usage Examples

### Standard Rollback
Simply trigger the `liquibase-rollback-from-dev` job manually from GitLab CI.

### Custom Rollback - By Tag and Label
1. Set variables in GitLab:
   - `RB_TAG`: "12345" (pipeline ID or custom tag)
   - `RB_LABEL`: "feature-x"
2. Trigger `liquibase_custom_rollback` job manually

### Custom Rollback - By Count
1. Set variables in GitLab:
   - `RB_CMD`: "rollbackCount 3"
2. Trigger `liquibase_custom_rollback` job manually

### Custom Rollback - By Date
1. Set variables in GitLab:
   - `RB_CMD`: "rollbackToDate 2025-01-15"
2. Trigger `liquibase_custom_rollback` job manually

### Generate Rollback SQL Only
1. Set variables in GitLab:
   - `RB_CMD`: "rollbackSQL <tag>"
2. Trigger `liquibase_custom_rollback` job manually
