# Liquibase Database Change Management

This repository contains database change management scripts using Liquibase for automated, version-controlled database deployments.

## 📚 Documentation

- **[Developer Workflow Guide](DEVELOPER_WORKFLOW.md)** - Complete guide for developers working with Liquibase
- **[Architecture Documentation](architecture.md)** - System architecture and pipeline design

## 🚀 Quick Start

### For New Developers

1. **Read the Developer Workflow Guide** - Start with [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md) for detailed instructions
2. **Clone the repository** and checkout the `develop` branch
3. **Create your feature branch** from `develop`
4. **Follow the workflow** outlined in the guide

### Creating Database Changes

All database changes go in the `objects/` folder structure:

```
objects/
├── tables/       # Table SQL files
├── sp/           # Stored procedure SQL files
└── views/        # View SQL files
```

**See [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md) for detailed examples and instructions.**

## 📂 Project Structure

```
liquibase/
├── objects/                      # Database objects (NEW structure)
│   ├── tables/                   # Table SQL files
│   ├── sp/                       # Stored procedure SQL files
│   └── views/                    # View SQL files
├── objects/                      # Child XML changelogs
│   ├── tables.xml               # References all table SQL files
│   ├── sp.xml                   # References all stored procedure SQL files
│   └── views.xml                # References all view SQL files
├── changelogs/                   # Legacy SQL files
│   ├── tables.sql
│   ├── views.sql
│   └── procedures.sql
├── master_objects.xml           # Master changelog for new structure
├── db.changelog-master.xml      # Root changelog file
├── .gitlab-ci.yml               # CI/CD pipeline configuration
├── DEVELOPER_WORKFLOW.md        # Developer guide
└── architecture.md              # Architecture documentation
```

## 🔄 Git Workflow

1. Work on individual feature branch
2. Push changes to your branch
3. Create Pull Request to `develop` branch
4. Lint stage runs automatically (validation & checks)
5. After merge to `develop`, deployment runs with manual approval
6. Rollback available if needed

## 🛠️ CI/CD Pipeline Stages

### 1. Lint Stage (Automatic)
- Runs on push, MR, and PR
- Validates changelog syntax
- Checks database connectivity
- Runs quality checks
- Generates reports

### 2. Deploy Stage (Manual Approval)
- Runs on `develop` branch
- Requires manual approval
- Tags database state
- Applies changes
- Available for dev, cert, and prod environments

### 3. Rollback Stage (Manual)
- Available after deployment
- Standard rollback to previous tag
- Custom rollback options available

## 📖 Key Resources

- [Liquibase Documentation](https://docs.liquibase.com/)
- [Developer Workflow Guide](DEVELOPER_WORKFLOW.md) - **Start here!**
- [Architecture Guide](architecture.md)

## 🤝 Contributing

Please follow the developer workflow outlined in [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md).

## 📞 Support

For questions or issues:
1. Check [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md) troubleshooting section
2. Review pipeline logs for specific errors
3. Consult with team lead or senior developer

