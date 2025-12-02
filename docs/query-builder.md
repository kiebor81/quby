# Query Builder Reference

## SELECT Queries

### Basic Queries

```ruby
db = Quby.connection

# All columns
db.query('users')

# Specific columns
db.query('users').select('id', 'name', 'email')

# Distinct
db.query('users').select('country').distinct
```

### WHERE Clauses

```ruby
# Basic operators
.where('age', '>', 18)
.where('country', 'USA')              # Defaults to =
.where(status: 'active', verified: true)  # Hash syntax

# OR conditions
.or_where('role', 'admin')

# IN / NOT IN
.where_in('id', [1, 2, 3])
.where_not_in('status', ['banned', 'deleted'])

# NULL checks
.where_null('deleted_at')
.where_not_null('email_verified_at')

# BETWEEN
.where_between('price', 10, 100)

# Raw SQL
.where_raw('YEAR(created_at) = ?', 2024)
```

### Subquery Conditions

```ruby
# WHERE EXISTS
subquery = db.query('orders')
  .select('1')
  .where_raw('orders.user_id = users.id')
  
db.query('users').where_exists(subquery)

# WHERE NOT EXISTS
db.query('users').where_not_exists(subquery)

# Can also use raw SQL strings
db.query('users').where_exists('SELECT 1 FROM orders WHERE orders.user_id = users.id')
```

### JOINs

```ruby
.join('orders', 'users.id', '=', 'orders.user_id')
.left_join('profiles', 'users.id', '=', 'profiles.user_id')
.right_join('addresses', 'users.id', '=', 'addresses.user_id')
.cross_join('categories')  # Cartesian product
```

### Sorting and Grouping

```ruby
# Order by
.order_by('created_at', 'DESC')
.order_by_desc('name')

# Group by
.group_by('user_id')
.group_by('country', 'city')
.having('count', '>', 5)
```

### Limiting Results

```ruby
.limit(10)
.offset(20)
.take(10)           # Alias for limit
.skip(20)           # Alias for offset
.page(3, 15)        # Page 3, 15 per page
```

### Execution

```ruby
users = db.get(query)       # Returns array
user = db.first(query)      # Returns first result or nil

# Debug
puts query.to_sql           # See SQL
puts query.bindings.inspect # See bindings
```

## INSERT Queries

```ruby
# Single record
query = db.insert('users').values(
  name: 'John',
  email: 'john@example.com',
  age: 30
)
id = db.execute_insert(query)

# Multiple records (bulk)
query = db.insert('users').values([
  { name: 'Alice', email: 'alice@example.com' },
  { name: 'Bob', email: 'bob@example.com' }
])
id = db.execute_insert(query)  # Returns last inserted ID
```

## UPDATE Queries

```ruby
query = db.update('users')
  .set(status: 'active', updated_at: Time.now)
  .where('id', 1)

affected = db.execute_update(query)  # Returns affected row count
```

## DELETE Queries

```ruby
query = db.delete('users')
  .where('status', 'banned')

affected = db.execute_delete(query)  # Returns affected row count
```

## Common Patterns

### Pagination

```ruby
page = 1
per_page = 20

query = db.query('posts')
  .where('published', true)
  .order_by('created_at', 'DESC')
  .page(page, per_page)

posts = db.get(query)
```

### Aggregate Shortcuts

```ruby
# Quick aggregates (return scalar values)
count = db.execute_scalar(db.query('users').count)
avg_age = db.execute_scalar(db.query('users').avg('age'))
total = db.execute_scalar(db.query('orders').sum('amount'))
highest = db.execute_scalar(db.query('products').max('price'))
lowest = db.execute_scalar(db.query('products').min('price'))

# With conditions
active_count = db.execute_scalar(
  db.query('users').where('status', 'active').count
)
```

### Manual Aggregates with SELECT

```ruby
# For multiple aggregates or grouping
db.query('orders')
  .select(
    'user_id',
    'COUNT(*) as order_count',
    'SUM(total) as total_spent',
    'AVG(total) as avg_order'
  )
  .group_by('user_id')
```

### Combining Queries

```ruby
# UNION (removes duplicates)
q1 = db.query('customers').select('email')
q2 = db.query('subscribers').select('email')
combined = q1.union(q2)

# UNION ALL (keeps duplicates)
all_emails = q1.union_all(q2)

# Multiple unions
result = db.query('table1').select('name')
  .union(db.query('table2').select('name'))
  .union_all(db.query('table3').select('name'))
```

### Subqueries

```ruby
db.query('users')
  .where_raw('id IN (SELECT user_id FROM orders WHERE total > ?)', 100)
```

## Supported Operators

- `=` (default)
- `>`, `<`, `>=`, `<=`
- `!=`, `<>`
- `LIKE`, `NOT LIKE`
- `IN`, `NOT IN`
- `BETWEEN`
- `IS NULL`, `IS NOT NULL`
