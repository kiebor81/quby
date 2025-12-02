# CASE WHEN Extension

An optional extension that adds fluent CASE WHEN support to Quby queries.

## Installation

The extension is **opt-in**. Enable it using the plugin system:

```ruby
require 'quby'
require 'quby/extensions/case_when'

# Enable the extension
Quby.use_extensions(Quby::CaseWhenExtension)
```

Or directly with prepend:

```ruby
Quby::Query.prepend(Quby::CaseWhenExtension)
```

## Usage

### Simple CASE (with column)

Used when comparing a single column against multiple values:

```ruby
case_expr = db.query('users')
  .select_case('status')
  .when('active').then('Active User')
  .when('inactive').then('Inactive User')
  .else('Pending')
  .as('status_label')

query = db.query('users')
  .select('name', case_expr)

# SQL: SELECT name, CASE status WHEN ? THEN ? WHEN ? THEN ? ELSE ? END AS status_label FROM users
```

### Searched CASE (without column)

Used for complex conditions with different columns:

```ruby
case_expr = db.query('users')
  .select_case
  .when('age', '<', 18).then('Minor')
  .when('age', '<', 65).then('Adult')
  .else('Senior')
  .as('age_group')

query = db.query('users')
  .select('name', case_expr)

# SQL: SELECT name, CASE WHEN age < ? THEN ? WHEN age < ? THEN ? ELSE ? END AS age_group FROM users
```

### Multiple CASE Expressions

You can use multiple CASE expressions in a single query:

```ruby
age_case = db.query('users')
  .select_case
  .when('age', '<', 18).then('Young')
  .else('Old')
  .as('age_category')

status_case = db.query('users')
  .select_case('status')
  .when('active').then('Y')
  .else('N')
  .as('is_active')

query = db.query('users')
  .select('name', age_case, status_case)

results = db.get(query)
```

## API Reference

### `select_case(column = nil)`

Creates a CaseBuilder for constructing CASE expressions.

- **column** (optional): Column name for simple CASE. Omit for searched CASE.
- **Returns**: CaseBuilder instance

### CaseBuilder Methods

#### `when(condition, operator = nil, value = nil)`

Adds a WHEN clause.

**Simple CASE** (with column):
```ruby
.when('value')  # WHEN ? (compares against the column)
```

**Searched CASE** (without column):
```ruby
.when('column', 'value')      # WHEN column = ?
.when('column', '>', value)   # WHEN column > ?
.when('raw condition')        # WHEN raw condition
```

#### `then(value)`

Sets the result for the last WHEN clause.

```ruby
.when('age', '<', 18).then('Minor')
```

#### `else(value)`

Sets the default value (optional).

```ruby
.else('Unknown')
```

#### `as(alias)`

Sets the column alias for the CASE expression.

```ruby
.as('age_group')
```

## Examples

### Grade Calculation

```ruby
grade_case = db.query('students')
  .select_case
  .when('score', '>=', 90).then('A')
  .when('score', '>=', 80).then('B')
  .when('score', '>=', 70).then('C')
  .when('score', '>=', 60).then('D')
  .else('F')
  .as('grade')

query = db.query('students')
  .select('name', 'score', grade_case)
  .order_by('score', 'DESC')

students = db.get(query)
```

### Status Indicators

```ruby
status_case = db.query('orders')
  .select_case('status')
  .when('completed').then('Done')
  .when('pending').then('Waiting')
  .when('cancelled').then('Cancelled')
  .else('Unknown')
  .as('status_display')

query = db.query('orders')
  .select('id', 'customer_name', status_case)

orders = db.get(query)
```

### Conditional Aggregation

```ruby
# Count active users by age group
active_count = db.query('users')
  .select_case
  .when('status', 'active').then(1)
  .else(0)
  .as('is_active')

query = db.query('users')
  .select(
    'CASE WHEN age < 18 THEN "Minor" ELSE "Adult" END as age_group',
    'SUM(' + active_count.to_sql + ') as active_count'
  )
  .group_by('age_group')
```

## Why Opt-In?

The CASE WHEN extension is optional because:

1. **Not everyone needs it** - Most queries don't require CASE expressions
2. **Raw SQL works fine** - You can always use `raw()` for CASE statements
3. **Keep core simple** - Quby's philosophy is minimal by default
4. **Method override** - The extension uses `prepend` to override `select()`

## Without the Extension

If you prefer not to use the extension, you can still write CASE expressions with raw SQL:

```ruby
query = db.query('users')
  .select(
    'name',
    'CASE 
       WHEN age < 18 THEN "Minor"
       WHEN age < 65 THEN "Adult"
       ELSE "Senior"
     END as age_group'
  )

users = db.get(query)
```

The extension simply provides a more fluent, type-safe way to build these expressions.
