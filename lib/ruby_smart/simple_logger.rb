# frozen_string_literal: true

require "gem_info"

require_relative "simple_logger/core_ext/ruby/string"
require_relative "simple_logger/version"
require_relative "simple_logger/logger"
require_relative "simple_logger/payload"
require_relative "simple_logger/klass_logger"

module RubySmart
  module SimpleLogger
    # delegate new method to logger
    def self.new(*args)
      RubySmart::SimpleLogger::Logger.new(*args)
    end
  end
end

# load date extensions for logger
# since 'actionview' is loaded in different ways, we only can check for +installed?+ here...
if GemInfo.installed?('actionview')
  # IMPORTANT: any require will break the loading process
  RubySmart::SimpleLogger::Logger.include(ActionView::Helpers::DateHelper) unless RubySmart::SimpleLogger::Logger.included_modules.include?(ActionView::Helpers::DateHelper)
end
