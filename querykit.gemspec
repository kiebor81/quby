require_relative "lib/querykit/version"

Gem::Specification.new do |spec|
  spec.name          = "querykit"
  spec.version       = QueryKit::VERSION
  spec.authors       = ["kiebor81"]

  spec.summary       = "Ruby SQL query builder and micro-ORM"
  spec.description   = "QueryKit is a lightweight query builder and micro-ORM inspired by SqlKata and Dapper, " \
                       "providing a clean, fluent API for building SQL queries without the overhead of " \
                       "Active Record. Perfect for small projects and scripts."
  spec.homepage      = "https://github.com/kiebor81/querykit"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"] = "https://github.com/kiebor81/querykit"
  spec.metadata["changelog_uri"] = "https://github.com/kiebor81/querykit/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*.rb",
    "sig/**/*.rbs",
    "README.md",
    "LICENSE",
    "CHANGELOG.md"
  ]

  spec.require_paths = ["lib"]

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.3"
  spec.add_development_dependency "minitest", "~> 5.26"
  spec.add_development_dependency "minitest-reporters", "~> 1.7"
  
end
