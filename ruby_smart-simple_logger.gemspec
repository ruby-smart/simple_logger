# frozen_string_literal: true

require_relative "lib/ruby_smart/simple_logger/version"

Gem::Specification.new do |spec|
  spec.name    = "ruby_smart-simple_logger"
  spec.version = RubySmart::SimpleLogger.version
  spec.authors     = ['Tobias Gonsior']
  spec.email       = ['info@ruby-smart.org']

  spec.summary               = "A simple, multifunctional logging library for Ruby."
  spec.description = <<~DESC
    RubySmart::SimpleLogger is a fast, customizable logging library with multi-device support, 
    special (PRE-defined) scenes for better logging visibility.
  DESC

  spec.homepage              = 'https://github.com/ruby-smart/simple_logger'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/ruby-smart/simple_logger'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/ruby_smart-simple_logger'
  spec.metadata['changelog_uri']     = "#{spec.metadata["source_code_uri"]}/blob/main/docs/CHANGELOG.md"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'ruby_smart-support', '~> 1.2'

  spec.add_development_dependency 'awesome_print', '~> 1.9'
  spec.add_development_dependency 'coveralls_reborn', '~> 0.25'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'yard', '~> 0.9'
end
