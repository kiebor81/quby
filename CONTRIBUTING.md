# Contributing to Quby

Thanks for your interest in contributing to Quby. This guide will help you get started.

## Philosophy

Quby is intentionally **minimal and focused**. Before contributing, please understand our design principles:

- **Minimal dependencies** - Only database drivers required
- **Opt-in features** - Core stays lean, extensions are optional
- **Secure by default** - Parameterized queries, clear documentation

## Getting Started

### Setup

```bash
# Clone the repository
git clone https://github.com/kiebor81/quby.git
cd quby

# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Check coverage
open coverage/index.html
```

### Project Structure

```
lib/
  quby/
    adapters/          # Database adapters (SQLite, PostgreSQL, MySQL)
    extensions/        # Optional extensions (e.g., case_when.rb)
    query.rb           # SELECT query builder
    insert_query.rb    # INSERT query builder
    update_query.rb    # UPDATE query builder
    delete_query.rb    # DELETE query builder
    connection.rb      # Database connection and execution
    repository.rb      # Repository pattern base class
    configuration.rb   # Global configuration
  quby.rb              # Main entry point

test/                  # Minitest suite
docs/                  # Documentation
examples/              # Demo files
```

## How to Contribute

### Reporting Bugs

Open an issue with:
- Ruby version
- Database adapter (SQLite, PostgreSQL, MySQL)
- Minimal code to reproduce
- Expected vs actual behavior
- Error messages/stack traces

### Suggesting Features

Before proposing a feature, consider:

1. **Does it fit Quby's philosophy?** We prioritize simplicity over features.
2. **Can it be an extension?** New features should be opt-in when possible.
3. **Is there a real use case?** Avoid hypothetical "nice to have" features.
4. **What's the maintenance cost?** More code = more to maintain.

Open an issue to discuss before implementing large features.

### Pull Requests

1. **Fork and create a branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Write tests first**
   - All new features need tests
   - Aim for >90% code coverage
   - Test both success and error cases

3. **Implement the feature**
   - Follow existing code style
   - Add inline documentation for complex logic
   - Keep methods small and focused

4. **Update documentation**
   - Update relevant docs in `docs/`
   - Add examples if appropriate
   - Update CHANGELOG.md

5. **Run the test suite**
   ```bash
   bundle exec rake test
   ```

6. **Submit PR**
   - Clear title and description
   - Reference related issues
   - Explain why the change is needed

## Code Style

### General Guidelines

- **Single quotes** - Unless interpolation needed
- **Descriptive names** - `execute_insert` not `exec_ins`
- **Guard clauses** - Return early rather than deep nesting

### Example

```ruby
# frozen_string_literal: true

module Quby
  class Example
    def process(data)
      return nil if data.nil?
      return [] if data.empty?
      
      data.map { |item| transform(item) }
    end
    
    private
    
    def transform(item)
      # Implementation
    end
  end
end
```

## Testing

### Writing Tests

```ruby
# frozen_string_literal: true

require_relative 'test_helper'

class MyFeatureTest < Minitest::Test
  include TestHelper
  
  def setup
    setup_db  # Helper creates in-memory SQLite DB
  end
  
  def test_feature_works
    query = @db.query('users').where('age', '>', 18)
    
    assert_equal "SELECT * FROM users WHERE age > ?", query.to_sql
    assert_equal [18], query.bindings
  end
  
  def test_feature_handles_errors
    error = assert_raises(ArgumentError) do
      @db.query('users').invalid_method
    end
    
    assert_equal 'Expected error message', error.message
  end
end
```

### Test Categories

- **Unit tests** - Test individual classes/methods in isolation
- **Integration tests** - Test full workflows with real database
- **Security tests** - Test SQL injection protection

### Running Tests

```bash
# All tests
bundle exec rake test

# Single file
bundle exec ruby test/query_test.rb

# Single test
bundle exec ruby test/query_test.rb -n test_basic_select

# With coverage
bundle exec rake test
open coverage/index.html
```

## Creating Extensions

Extensions should:

1. **Live in `lib/quby/extensions/`**
2. **Be opt-in via `Quby.use_extensions()`**
3. **Use `prepend` to override Query methods**
4. **Have comprehensive tests**
5. **Have dedicated documentation**

### Extension Template

```ruby
# frozen_string_literal: true

module Quby
  module MyExtension
    # Override or add methods to Query
    def my_new_method(*args)
      # Implementation
      self  # Return self for chaining
    end
    
    # Override existing methods
    def select(*columns)
      # Custom logic
      super  # Call original implementation
    end
  end
end
```

### Usage

```ruby
require 'quby/extensions/my_extension'

Quby.use_extensions(Quby::MyExtension)

# Now available on all queries
db.query('users').my_new_method
```

## Documentation

### Where to Document

- **README.md** - High-level overview, quick start
- **docs/getting-started.md** - Installation and basic usage
- **docs/query-builder.md** - Query building reference
- **docs/advanced-features.md** - Model mapping, repositories, transactions
- **docs/api-reference.md** - Complete API listing
- **docs/extensions/** - Individual extension guides

## Questions?

- Open an issue for questions
- Check existing issues and PRs first
- Be patient waiting for responses

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).
