require_relative "lib/quby/version"

Gem::Specification.new do |spec|
  spec.name          = "quby"
  spec.version       = Quby::VERSION
  spec.authors       = ["kiebor81"]

  spec.summary       = "A lightweight, fluent query builder for Ruby"
  spec.description   = "Quby is a micro-ORM inspired by SqlKata and Dapper, providing a clean, " \
                       "fluent API for building SQL queries without the overhead of " \
                       "Active Record. Perfect for small projects and scripts."
  spec.homepage      = "https://github.com/kiebor81/quby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kiebor81/quby"
  spec.metadata["changelog_uri"] = "https://github.com/kiebor81/quby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "LICENSE",
    "CHANGELOG.md"
  ]

  spec.require_paths = ["lib"]


  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.16"
  spec.add_development_dependency "minitest-reporters", "~> 1.5"
  
end
