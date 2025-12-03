# QueryKit 

A fluent, intuitive query builder and micro-ORM for Ruby inspired by .NET''s SqlKata. Perfect for projects where Active Record feels like overkill.

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

## Installation

```bash

gem install querykit

```

Then your preferred database driver.

```bash
# SQLite
gem install sqlite3

# PostgreSQL
gem install pg

# MySQL
gem install mysql2
```
## Quick Start

See [`demo.rb`](examples/demo.rb) for more extensive examples.

```ruby
require_relative 'querykit'

# Configure once
QueryKit.setup(:sqlite, database: 'app.db')

# Query builder
users = QueryKit.connection.get(
  QueryKit.connection.query('users')
    .where('age', '>', 18)
    .order_by('name')
    .limit(10)
)

# Repository pattern (query scoping)
class UserRepository < QueryKit::Repository
  table ''users''
  model User
end

repo = UserRepository.new
user = repo.find(1)
users = repo.where('age', '>', 18)
```

## Documentation

- [Getting Started](docs/getting-started.md) - Setup and basic usage
- [Query Builder](docs/query-builder.md) - SELECT, INSERT, UPDATE, DELETE
- [Advanced Features](docs/advanced-features.md) - Model mapping, repositories, transactions
- [API Reference](docs/api-reference.md) - Complete API documentation
- [Security Best Practices](docs/security.md) - SQL injection protection and safe usage
- [Concurrency & Thread Safety](docs/concurrency.md) - Multi-threaded usage and connection management
- [CASE WHEN Extension](docs/extensions/case-when.md) - Optional fluent CASE expressions

**Full documentation site:** https://kiebor81.github.io/querykit

**API documentation (YARD):** Generate locally with `rake doc`

## Why QueryKit?

**vs Active Record:** Much lighter, no DSL, no magic. Just build queries and execute them.

**vs Sequel:** Simpler API, fewer features by design. If you need a full ORM, use Sequel.

**vs Raw SQL:** Type-safe, composable queries with protection against SQL injection.

## Security

QueryKit uses **parameterized queries by default**, protecting against SQL injection when used correctly:

```ruby
# SAFE - Values are automatically parameterized
db.query('users').where('email', user_input)

# UNSAFE - Never interpolate user input
db.raw("SELECT * FROM users WHERE email = '#{user_input}'")

# SAFE - Use placeholders with raw SQL
db.raw('SELECT * FROM users WHERE email = ?', user_input)
```

**See [Security Best Practices](docs/security.md) for detailed guidance.**

## Philosophy

- **Minimal dependencies** - Only database drivers required
- **Simple and explicit** - No hidden magic or metaprogramming
- **Composable** - Build queries piece by piece
- **Flexible** - Use what you need, ignore what you don't
- **Extensible** - Opt-in extensions for advanced features

## Extensions

QueryKit supports optional extensions that add advanced features without bloating the core:

```ruby
require 'querykit/extensions/case_when'

# Load extensions at startup
QueryKit.use_extensions(QueryKit::CaseWhenExtension)

# Or load multiple extensions
QueryKit.use_extensions([Extension1, Extension2])
```

Available extensions:
- **CASE WHEN** - Fluent CASE expression builder ([docs](docs/extensions/case-when.md))

Extensions use Ruby's `prepend` to cleanly override methods without monkey-patching.

## What QueryKit Doesn't Do

These features are intentionally excluded to maintain simplicity:

- **Migrations** - Use a dedicated migration tool
- **Associations** - Write explicit JOINs instead
- **Validations** - Handle in your business logic layer
- **Callbacks** - Keep side effects explicit
- **Soft Deletes** - Implement as a WHERE filter in repositories
- **Eager Loading** - Use JOINs or accept N+1 queries

For advanced SQL features, use raw SQL:

```ruby
# Common Table Expressions (CTEs)
db.raw(<<~SQL, user_id)
  WITH ranked_orders AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rn
    FROM orders
  )
  SELECT * FROM ranked_orders WHERE rn = 1 AND user_id = ?
SQL

# Window Functions
db.raw('SELECT *, AVG(salary) OVER (PARTITION BY department) as dept_avg FROM employees')

# Upsert (SQLite)
db.raw('INSERT INTO users (id, name) VALUES (?, ?) ON CONFLICT(id) DO UPDATE SET name=excluded.name', id, name)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Acknowledgments

Inspired by [SqlKata](https://sqlkata.com/) (.NET) and [Arel](https://github.com/rails/arel) (Ruby).

## License

This is a personal project, but suggestions and bug reports are welcome via issues.

MIT License - see [LICENSE](LICENSE) for details.
