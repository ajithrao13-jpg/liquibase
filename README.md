# Liquibase - GitLab CI/CD Pipelines Project Example

This GitLab project is a demonstration of Liquibase running in a GitLab CI/CD pipline against a SQL Server Database.

## Documentation

📚 **Comprehensive Guides Available:**

- **[DETAILED_EXPLANATION.md](DETAILED_EXPLANATION.md)** - Complete explanation of the project, including architecture, stored procedures, and rollback mechanisms
- **[STORED_PROCEDURES_GUIDE.md](STORED_PROCEDURES_GUIDE.md)** - Deep dive into stored procedures with detailed breakdowns and examples
- **[ROLLBACK_GUIDE.md](ROLLBACK_GUIDE.md)** - Comprehensive guide to rollback mechanisms, strategies, and best practices
- **[VISUAL_GUIDE.md](VISUAL_GUIDE.md)** - Visual flow diagrams and ASCII art showing how everything works
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick reference for commands, syntax, and common patterns

These guides explain:
- ✅ How the current branch code works in detail
- ✅ Stored procedures and their functionality
- ✅ Rollback mechanisms and how they work
- ✅ CI/CD pipeline flow
- ✅ Best practices and troubleshooting

## Getting started

Please follow this [GitLab Blog Post](https://about.gitlab.com/blog/2022/01/05/how-to-bring-devops-to-the-database-with-gitlab-and-liquibase/) to get started.

## Liquibase commands in the pipeline

### [liquibase checks run](https://docs.liquibase.com/commands/community/quality-checks/checks-run.html)

[Liquibase quality checks for database changes](https://www.liquibase.com/quality-checks) provide a layer of security and quality to your database development process. Liquibase provides several checks for data integrity, privileges & roles, along with best practices to keep your production database safe. A quality checks configuration file is already provided with the repository. View the current configuration with the `liquibase checks show` command. [Learn about how to create and configure your own customized quality checks](https://docs.liquibase.com/commands/community/quality-checks/home.html).

### [liquibase updateSQL](https://docs.liquibase.com/commands/community/updatesql.html)

This command lets you review and inspect the raw SQL before applying changes to your database.

### [liquibase update](https://docs.liquibase.com/commands/community/update.html)

This command applies changes to the database.

### [liquibase rollbackOneUpdate --force](https://docs.liquibase.com/commands/pro/rollbackoneupdate.html)

Liquibase offers a number of [rollback commands](https://docs.liquibase.com/commands/home.html) that are useful when you need to revert changes quickly and roll the database back to a good, stable state.

### [liquibase tag](https://docs.liquibase.com/commands/community/tag.html)

This command can help indicate the current database state, version, release, or any other information you choose. After setting the tag, you can use the `rollback <tag>` command to roll back all changes up to the tag.

### [liquibase history](https://docs.liquibase.com/commands/community/history.html)

The history command is a helper command that lists out all your deploymentIds and all changesets associated with each deploymentId.

### [liquibase diff](https://docs.liquibase.com/commands/community/diff.html)

The Liquibase diff command allows you to compare the states of two databases so you can quickly detect differences (drift). With Liquibase Pro, you can also detect differences between stored logic objects, which can sometimes be the source of malware. You can then generate a JSON report and set up alerts to investigate the source of any drift.

### [liquibase snapshot](https://docs.liquibase.com/commands/community/snapshot.html)

Snapshots capture the state of your database. In this instance, we get a snapshot of the state of the Prod database. With Liquibase Pro you can also capture stored logic objects in the database in addition to the schema. [Snapshots can be used in conjunction with the diff command to protect against malware](https://www.liquibase.com/devsecops).

## Contributing


## Related projects

