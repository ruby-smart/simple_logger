# frozen_string_literal: true

require "gem_info"
require 'ruby_smart/simple_logger'

# to prevent compatibility issues with the ruby-debug-ide gem (uses same Namespace 'Debugger')
GemInfo.safe_require 'ruby-debug-ide'

# try to load 'awesome_print', if available
GemInfo.safe_require 'awesome_print'

module Debugger
  extend ::RubySmart::SimpleLogger::KlassLogger

  # force debugger to 'DEBUG' severity
  self.klass_logger_opts = { level: ::RubySmart::SimpleLogger::Logger::DEBUG }

  # overwrite existing "debug" method (if Debase was loaded, this needs to be rewritten)
  def self.debug(*args, **kwargs)
    return false if args.none?
    klass_logger.debug(*args, **kwargs)
  end
end