# frozen_string_literal: true

# include all spec support files
Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each do |file|
  require file
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.order = :random

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# need to call the bundler setup to resolve Gemfile-configuration
# otherwise it will run for all currently installed / loaded gems
require "bundler/setup"

# require the gem
require "ruby_smart/simple_logger"