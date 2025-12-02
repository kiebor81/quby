source 'https://rubygems.org'

# Specify your gem's dependencies in quby.gemspec
gemspec

# Development and testing dependencies
group :development, :test do
  gem 'rake', '~> 13.0'
  gem 'bundler', '~> 2.0'
  gem 'minitest', '~> 5.16'
  gem 'minitest-reporters', '~> 1.5'
  gem 'simplecov', '~> 0.22', require: false
end

# Optional database adapters (install only what you need)
group :development do
  gem 'sqlite3', '~> 1.6'
  # gem 'pg', '~> 1.5'        # Uncomment for PostgreSQL
  # gem 'mysql2', '~> 0.5'    # Uncomment for MySQL
end
