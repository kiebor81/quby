---
layout: default
title: Quby Documentation
---

# Quby Documentation

A lightweight, fluent query builder and micro-ORM for Ruby, inspired by .NET's SqlKata and Dapper.

## Features

- **Zero dependencies** (except database drivers)
- **Fluent, chainable API** inspired by SqlKata
- **Multiple database adapters** (SQLite3, PostgreSQL, MySQL)
- **Comprehensive WHERE clauses** (operators, IN, NULL, BETWEEN, EXISTS, raw SQL)
- **JOIN support** (INNER, LEFT, RIGHT, CROSS)
- **Aggregate shortcuts** (count, avg, sum, min, max)
- **UNION/UNION ALL** for combining queries
- **Optional model mapping** (Dapper-style)
- **Optional repository pattern** (C#-style)
- **Transaction support**
- **Raw SQL when you need it**
- **SQL injection protection** via parameterized queries

## Quick Start

```ruby
require 'querykit'

# Configure once
db = QueryKit.connect(:sqlite, database: 'app.db')

# Query builder
users = db.get(
  db.query('users')
    .where('age', '>', 18)
    .order_by('name')
    .limit(10)
)

# Repository pattern
class UserRepository < QueryKit::Repository
  table 'users'
  model User
end

repo = UserRepository.new(db)
user = repo.find(1)
users = repo.where('age', '>', 18)
```

## Installation

```bash
gem install quby

# Then install your database driver:
gem install sqlite3    # For SQLite
gem install pg         # For PostgreSQL
gem install mysql2     # For MySQL
```

## Documentation

### Core Guides

- [Getting Started](getting-started.html) - Setup and basic usage
- [Query Builder](query-builder.html) - SELECT, INSERT, UPDATE, DELETE
- [Advanced Features](advanced-features.html) - Model mapping, repositories, transactions
- [API Reference](api-reference.html) - Complete API documentation
- [Security Best Practices](security.html) - SQL injection protection and safe usage
- [Concurrency & Thread Safety](concurrency.html) - Multi-threaded usage and connection management

### Extensions

- [CASE WHEN Extension](extensions/case-when.html) - Optional fluent CASE expressions

## Why Quby?

**vs Active Record:** Much lighter, no DSL, no magic. Just build queries and execute them.

**vs Sequel:** Simpler API, fewer features by design. If you need a full ORM, use Sequel.

**vs Raw SQL:** Type-safe, composable queries with protection against SQL injection.

## Philosophy

- **Minimal dependencies** - Only database drivers required
- **Opt-in features** - Core stays lean, extensions are optional
- **Secure by default** - Parameterized queries, clear documentation
- **Explicit over implicit** - You control the SQL that gets generated
- **Composable** - Build queries gradually, conditionally

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.html) for guidelines on how to contribute.

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](../CODE_OF_CONDUCT.html). By participating, you are expected to uphold this code.

## License

Quby is released under the [MIT License](https://github.com/kiebor81/quby/blob/main/LICENSE).

## Links

- [GitHub Repository](https://github.com/kiebor81/quby)
- [Issue Tracker](https://github.com/kiebor81/quby/issues)
- [Changelog](https://github.com/kiebor81/quby/blob/main/CHANGELOG.md)
