# Architecture Diagram - Liquibase CI/CD Pipeline

## High-Level Architecture Overview

This document provides a high-level architecture diagram of the Liquibase CI/CD pipeline with rollback capabilities.

```mermaid
graph TB
    subgraph IDE[" Development Environment "]
        A[Developer<br/>IntelliJ IDEA]
    end
    
    subgraph VCS[" Version Control "]
        B[Remote Branch]
        C[Pull Request to<br/>Develop Branch]
    end
    
    A -->|Push Changes| B
    B -->|Create PR| C
    
    subgraph CI[" GitLab CI/CD Pipeline "]
        D[Pipeline Triggered]
        E[Lint Stage - Automated]
        F[liquibase-validate<br/>Check Connection<br/>Validate Changelog]
        G[liquibase-checks<br/>Quality Checks<br/>Best Practices]
        H[Deploy Stage - Automated]
        I[liquibase-deploy-to-dev<br/>Generate SQL Preview<br/>Tag Pipeline<br/>Execute Update]
        K[Rollback Stage - Manual]
        L[Standard Rollback<br/>Previous Tag]
        M[Custom Rollback<br/>Tag + Label<br/>Count Based<br/>Date Based<br/>SQL Preview]
        
        D --> E
        E --> F
        F --> G
        G -->|Success| H
        H --> I
        I -.->|If Issues| K
        K --> L
        K --> M
    end
    
    C -->|Triggers| D
    
    subgraph DB[" Database Environment "]
        J[(Development<br/>Database)]
    end
    
    I -->|Apply Changes| J
    L -.->|Revert| J
    M -.->|Revert| J
    
    style IDE fill:#e1f5ff,stroke:#0366d6,stroke-width:3px
    style VCS fill:#f0e6ff,stroke:#6f42c1,stroke-width:3px
    style CI fill:#fff5e6,stroke:#fd7e14,stroke-width:3px
    style DB fill:#f8d7da,stroke:#721c24,stroke-width:3px
    
    style A fill:#b8daff,stroke:#004085,stroke-width:2px
    style B fill:#d6d8ff,stroke:#383d41,stroke-width:2px
    style C fill:#c3e6ff,stroke:#004085,stroke-width:2px
    style D fill:#ffc107,stroke:#856404,stroke-width:2px
    style E fill:#d1ecf1,stroke:#0c5460,stroke-width:2px
    style F fill:#d1ecf1,stroke:#0c5460,stroke-width:2px
    style G fill:#d1ecf1,stroke:#0c5460,stroke-width:2px
    style H fill:#d4edda,stroke:#155724,stroke-width:2px
    style I fill:#d4edda,stroke:#155724,stroke-width:2px
    style K fill:#fff3cd,stroke:#856404,stroke-width:2px
    style L fill:#ffe5e5,stroke:#c00,stroke-width:2px
    style M fill:#ffe5e5,stroke:#c00,stroke-width:2px
    style J fill:#f5c6cb,stroke:#721c24,stroke-width:2px
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

**Diagram Flow Explanation:**

1. **Developer (IntelliJ IDEA)** → Creates and tests database changes locally
2. **Push Changes** → Pushes to remote feature/developer branch
3. **Create Pull Request** → Opens PR to develop branch in GitLab
4. **Triggers Pipeline** → GitLab CI/CD automatically starts
5. **Lint Stage** → Automated validation:
   - `liquibase-validate`: Checks connection and validates changelog
   - `liquibase-checks`: Runs quality checks and best practices
6. **Deploy Stage** → Automated deployment (on lint success):
   - `liquibase-deploy-to-dev`: Tags deployment and applies changes
7. **Database** → Changes applied to development database
8. **Rollback Stage** → Manual trigger if needed:
   - Standard Rollback: Quick revert to previous tag
   - Custom Rollback: Flexible options (tag, label, count, date, SQL preview)

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