# frozen_string_literal: true

require "gem_info"

require_relative "simple_logger/core_ext/ruby/string"
require_relative "simple_logger/version"
require_relative "simple_logger/logger"
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
if GemInfo.loaded?('activesupport') && GemInfo.installed?('actionview')
  ActiveSupport.on_load(:active_record) do
    require('action_view/helpers/date_helper')
    RubySmart::SimpleLogger::Logger.include(ActionView::Helpers::DateHelper)
  end
end
