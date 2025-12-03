# Security Best Practices

## SQL Injection Protection

Quby uses **parameterized queries** by default, which protects against SQL injection when used correctly. However, like any query builder, it's possible to introduce vulnerabilities through misuse.

## Safe Practices (Parameterized)

All standard query builder methods use parameterized queries automatically:

```ruby
# SAFE - Values are parameterized
db.query('users').where('email', params[:email])
db.query('users').where('age', '>', params[:age])
db.query('users').where_in('id', params[:ids])

# SAFE - INSERT/UPDATE values are parameterized
db.insert('users').values(name: params[:name], email: params[:email])
db.update('users').set(name: params[:name]).where('id', params[:id])

# SAFE - Even with hash syntax
db.query('users').where(email: params[:email], status: params[:status])
```

**Generated SQL:** All values become `?` placeholders with separate bindings array.

```ruby
query = db.query('users').where('email', user_input)
query.to_sql      # => "SELECT * FROM users WHERE email = ?"
query.bindings    # => [user_input]  # Safely escaped by database driver
```

## Unsafe Practices (String Interpolation)

### where_raw() with Interpolation

```ruby
# DANGEROUS - Direct string interpolation
db.query('users').where_raw("email = '#{params[:email]}'")

# SAFE - Use placeholders with bindings
db.query('users').where_raw('email = ?', params[:email])
```

### raw() with Interpolation

```ruby
# DANGEROUS - SQL injection vulnerability
db.raw("SELECT * FROM users WHERE id = #{params[:id]}")

# SAFE - Use placeholders
db.raw('SELECT * FROM users WHERE id = ?', params[:id])
```

### Column/Table Names from User Input

```ruby
# DANGEROUS - Column names aren't parameterized
column = params[:sort_by]  # User could pass "id; DROP TABLE users--"
db.query('users').order_by(column)

# SAFE - Whitelist allowed columns
allowed_columns = ['name', 'email', 'created_at']
column = allowed_columns.include?(params[:sort_by]) ? params[:sort_by] : 'id'
db.query('users').order_by(column)
```

### Dynamic Table Names

```ruby
# DANGEROUS
table = params[:table]
db.query(table).get

# SAFE - Use a whitelist
allowed_tables = ['users', 'posts', 'comments']
table = allowed_tables.include?(params[:table]) ? params[:table] : 'users'
db.query(table).get
```

## Security Checklist

### DO

1. **Always use parameterized queries** for user input values
2. **Whitelist column/table names** when accepting user input
3. **Validate input types** before passing to queries
4. **Use bindings array** with `raw()` and `where_raw()`
5. **Apply business logic validation** before database queries

```ruby
# Example: Safe dynamic filtering
def search_users(filters)
  query = db.query('users')
  
  # Whitelist allowed filters
  if filters[:email]
    query.where('email', filters[:email])
  end
  
  if filters[:status] && ['active', 'inactive'].include?(filters[:status])
    query.where('status', filters[:status])
  end
  
  # Whitelist sort columns
  sort_by = ['name', 'created_at'].include?(filters[:sort]) ? filters[:sort] : 'id'
  query.order_by(sort_by)
  
  db.get(query)
end
```

### DON'T

1. **Never interpolate user input** into SQL strings
2. **Don't trust user input** for column/table names
3. **Don't skip validation** because "it's internal"
4. **Don't use `eval()` or similar** with query strings
5. **Don't expose raw database errors** to users (information disclosure)

```ruby
# BAD - Multiple vulnerabilities
def bad_search(params)
  # String interpolation vulnerability
  condition = "email = '#{params[:email]}'"
  
  # Unvalidated column name
  sort = params[:sort_by]
  
  # Vulnerable query
  db.raw("SELECT * FROM users WHERE #{condition} ORDER BY #{sort}")
end

# GOOD - Safe implementation
def good_search(params)
  query = db.query('users')
  
  if params[:email]
    query.where('email', params[:email])  # Parameterized
  end
  
  sort = ['name', 'email', 'id'].include?(params[:sort_by]) ? params[:sort_by] : 'id'
  query.order_by(sort)  # Whitelisted
  
  db.get(query)
end
```

## Common Attack Vectors

### 1. WHERE Clause Injection

```ruby
# Attacker input: "' OR '1'='1"
# VULNERABLE
db.raw("SELECT * FROM users WHERE email = '#{params[:email]}'")
# Becomes: SELECT * FROM users WHERE email = '' OR '1'='1'

# SAFE
db.query('users').where('email', params[:email])
# Becomes: SELECT * FROM users WHERE email = ? with binding ["' OR '1'='1"]
```

### 2. UNION-based Injection

```ruby
# Attacker input: "' UNION SELECT password FROM admin_users--"
# VULNERABLE
db.raw("SELECT * FROM users WHERE name = '#{params[:name]}'")

# SAFE
db.query('users').where('name', params[:name])
```

### 3. Second-Order Injection

```ruby
# Data stored in database contains SQL
malicious_data = "'; DROP TABLE users--"

# VULNERABLE - Even though not direct user input
db.raw("SELECT * FROM logs WHERE message = '#{malicious_data}'")

# SAFE - Always parameterize, even for stored data
db.query('logs').where('message', malicious_data)
```

## Repository Pattern Security

Repositories should validate input at the boundary:

```ruby
class UserRepository < QueryKit::Repository
  table 'users'
  model User
  
  # SAFE - Validates and whitelists
  def search(filters)
    query = where('status', 'active')
    
    if filters[:email]&.match?(/\A[^@\s]+@[^@\s]+\z/)  # Basic email validation
      query = query.where('email', filters[:email])
    end
    
    if filters[:min_age]&.is_a?(Integer) && filters[:min_age] > 0
      query = query.where('age', '>=', filters[:min_age])
    end
    
    query
  end
  
  # SAFE - Whitelists sort columns
  def list_sorted(sort_by: 'id', direction: 'ASC')
    allowed_sorts = ['id', 'name', 'email', 'created_at']
    allowed_directions = ['ASC', 'DESC']
    
    sort = allowed_sorts.include?(sort_by) ? sort_by : 'id'
    dir = allowed_directions.include?(direction.upcase) ? direction.upcase : 'ASC'
    
    all.order_by(sort, dir)
  end
end
```

## Framework Integration

### Rails

```ruby
# Controller
class UsersController < ApplicationController
  def index
    # Validate params with strong parameters
    filters = params.permit(:email, :status, :sort_by)
    
    @users = UserRepository.new.search(filters)
  end
end
```

### Sinatra

```ruby
# Route
get '/users' do
  # Validate and sanitize
  email = params[:email]&.strip
  status = ['active', 'inactive'].include?(params[:status]) ? params[:status] : nil
  
  query = db.query('users')
  query = query.where('email', email) if email
  query = query.where('status', status) if status
  
  json db.get(query)
end
```

## Tools and Testing

### Testing for SQL Injection

```ruby
# In your tests
def test_sql_injection_protection
  malicious_input = "'; DROP TABLE users--"
  
  # Should not execute malicious SQL
  results = db.query('users').where('email', malicious_input)
  
  # Query should have placeholder
  assert_includes results.to_sql, '?'
  assert_equal [malicious_input], results.bindings
end
```

### Static Analysis

Consider using:
- **Brakeman** - Rails security scanner
- **bundler-audit** - Check for vulnerable gems
- **RuboCop** - Lint for security issues

## Summary

**Quby is secure by default** when you use the query builder methods. The main risks are:

1. Using `raw()` or `where_raw()` with string interpolation
2. Accepting user input for column/table names without whitelisting
3. Not validating input types before queries

**Golden Rule:** If user input touches your query, use the query builder methods (which parameterize) or explicit placeholders with bindings. Never use string interpolation.

## Further Reading

- [OWASP SQL Injection Guide](https://owasp.org/www-community/attacks/SQL_Injection)
- [Ruby on Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [Prepared Statements](https://en.wikipedia.org/wiki/Prepared_statement)
