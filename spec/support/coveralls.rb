# frozen_string_literal: true

require 'coveralls'
Coveralls.wear! do
  # exclude specs
  add_filter %r{^/spec/}
  add_filter %w{simple_logger.rb}

  # GROUPS
  add_group "Ruby", 'ruby/'
  add_group "Extensions", 'extensions/'
  add_group "Devices", 'devices/'

  add_group "Modules" do |file|
    file.filename.match(/simple_logger\/(?![_\w]*version)[_\w]+\.rb/)
  end

  self.formatter = SimpleCov::Formatter::HTMLFormatter unless ENV.fetch('CI', nil)
end