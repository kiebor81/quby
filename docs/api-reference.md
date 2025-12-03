# API Reference

## Global Configuration

### `QueryKit.configure { |config| ... }`
Configure Quby with a block.

```ruby
QueryKit.configure do |config|
  config.adapter = :sqlite
  config.connection_options = { database: 'app.db' }
end
```

### `QueryKit.setup(adapter, options)`
Shorthand configuration.

```ruby
QueryKit.setup(:sqlite, database: 'app.db')
QueryKit.setup(:postgresql, host: 'localhost', dbname: 'mydb', user: 'postgres', password: 'pass')
QueryKit.setup(:mysql, host: 'localhost', database: 'mydb', username: 'root', password: 'pass')
```

### `QueryKit.connection`
Get the global connection. Raises `QueryKit::ConfigurationError` if not configured.

### `QueryKit.reset!`
Reset configuration and connection (useful for testing).

### `QueryKit.connect(adapter, options)`
Create a new connection without global configuration.

## Query Builder

### SELECT

- `query(table)` / `from(table)` / `table(table)` - Start query
- `select(*columns)` - Select columns
- `distinct` - Add DISTINCT
- `where(column, operator, value)` - WHERE condition
- `where(column, value)` - WHERE with = operator
- `where(hash)` - WHERE with hash
- `or_where(column, operator, value)` - OR WHERE
- `where_in(column, values)` - WHERE IN
- `where_not_in(column, values)` - WHERE NOT IN
- `where_null(column)` - WHERE column IS NULL
- `where_not_null(column)` - WHERE column IS NOT NULL
- `where_between(column, min, max)` - WHERE BETWEEN
- `where_exists(subquery)` - WHERE EXISTS (accepts Query or String)
- `where_not_exists(subquery)` - WHERE NOT EXISTS (accepts Query or String)
- `where_raw(sql, *bindings)` - Raw WHERE clause (**Security:** Use placeholders `?` for values, never string interpolation)
- `join(table, column1, operator, column2)` - INNER JOIN
- `left_join(...)` - LEFT JOIN
- `right_join(...)` - RIGHT JOIN
- `cross_join(table)` - CROSS JOIN
- `count(column = '*')` - Count aggregate (use with execute_scalar)
- `avg(column)` - Average aggregate
- `sum(column)` - Sum aggregate
- `min(column)` - Minimum aggregate
- `max(column)` - Maximum aggregate
- `union(query)` - Combine with UNION (removes duplicates)
- `union_all(query)` - Combine with UNION ALL (keeps duplicates)
- `order_by(column, direction = 'ASC')` - ORDER BY
- `order_by_desc(column)` - ORDER BY DESC
- `group_by(*columns)` - GROUP BY
- `having(column, operator, value)` - HAVING
- `limit(count)` / `take(count)` - LIMIT
- `offset(count)` / `skip(count)` - OFFSET
- `page(page_number, per_page)` - Pagination helper
- `to_sql` - Get SQL string
- `bindings` - Get bindings array

### INSERT

- `insert(table)` / `into(table)` - Start insert
- `values(hash)` - Single record
- `values(array_of_hashes)` - Multiple records
- `to_sql` - Get SQL string
- `bindings` - Get bindings array

### UPDATE

- `update(table)` - Start update
- `set(hash)` - Set values
- `where(...)` - Add WHERE conditions (same as SELECT)
- `to_sql` - Get SQL string
- `bindings` - Get bindings array

### DELETE

- `delete(table)` / `from(table)` - Start delete
- `where(...)` - Add WHERE conditions (same as SELECT)
- `to_sql` - Get SQL string
- `bindings` - Get bindings array

## Connection

- `get(query, model_class = nil)` - Execute SELECT, returns array
- `first(query, model_class = nil)` - Execute SELECT, returns first result or nil
- `execute_insert(query)` - Execute INSERT, returns last_insert_id
- `execute_update(query)` - Execute UPDATE, returns affected_rows
- `execute_delete(query)` - Execute DELETE, returns affected_rows
- `execute_scalar(query)` - Execute query, returns first column of first row (for aggregates)
- `raw(sql, *bindings, model_class: nil)` - Execute raw SQL (**Security:** Always use placeholders `?` for values)
- `transaction { ... }` - Execute block in transaction
- `query(table)` - Start SELECT query
- `insert(table)` - Start INSERT query
- `update(table)` - Start UPDATE query
- `delete(table)` - Start DELETE query

## Repository

### Class Methods

- `table(name)` - Set table name
- `model(klass)` - Set model class

### Instance Methods

- `find(id)` - Find by primary key (id column)
- `find_by(column, value)` - Find by any column
- `all` - Get all records
- `where(column, operator, value)` - WHERE query
- `where(column, value)` - WHERE with = operator
- `where_in(column, values)` - WHERE IN
- `where_not_in(column, values)` - WHERE NOT IN
- `first` - Get first record
- `count` - Count records
- `exists?(id = nil)` - Check if records exist (or specific ID)
- `create(attributes)` / `insert(attributes)` - Insert record, returns ID
- `update(id, attributes)` - Update record, returns affected_rows
- `delete(id)` / `destroy(id)` - Delete record, returns affected_rows
- `delete_where(conditions)` - Bulk delete, returns affected_rows
- `execute(query)` - Execute custom query with model mapping
- `execute_first(query)` - Execute custom query, return first result
- `transaction { ... }` - Execute block in transaction

## Adapters

Three built-in adapters:

### SQLiteAdapter
```ruby
QueryKit.connect(:sqlite, 'database.db')
QueryKit.connect(:sqlite, ':memory:')
```

### PostgreSQLAdapter
```ruby
QueryKit.connect(:postgresql, host: 'localhost', dbname: 'mydb', user: 'postgres', password: 'pass')
```

### MySQLAdapter
```ruby
QueryKit.connect(:mysql, host: 'localhost', database: 'mydb', username: 'root', password: 'pass')
```

## Return Values

- **SELECT**: Array of Hashes (or Models if model_class provided)
- **INSERT**: Integer (last_insert_id)
- **UPDATE**: Integer (affected_rows)
- **DELETE**: Integer (affected_rows)
- **first()**: Hash/Model or nil
- **raw()**: Array of Hashes (or Models if model_class provided)

## Exceptions

- `ArgumentError` - Invalid arguments (no table, no values, unknown adapter)
- `QueryKit::ConfigurationError` - Accessing `QueryKit.connection` without configuration
- Database-specific exceptions from drivers (sqlite3, pg, mysql2)
