# Changelog

## [0.1.0]

### Added
- Initial release of Quby
- Fluent query builder for SELECT, INSERT, UPDATE, DELETE
- WHERE conditions with operators: =, >, <, >=, <=, !=, LIKE
- WHERE variants: where_in, where_not_in, where_null, where_not_null, where_between, where_raw
- JOIN support: INNER, LEFT, RIGHT
- ORDER BY, GROUP BY, HAVING clauses
- LIMIT, OFFSET, and pagination helpers
- Database adapters for SQLite3, PostgreSQL, MySQL
- Transaction support
- Raw SQL execution