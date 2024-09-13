# frozen_string_literal: true

require_relative 'extensions/helper'
require_relative 'extensions/logs'
require_relative 'extensions/mask'
require_relative 'extensions/processed'
require_relative 'extensions/scene'
require_relative 'extensions/severity'
require_relative 'extensions/simple_log'
require_relative 'extensions/timer'

require_relative 'devices/memory_device'
require_relative 'devices/multi_device'
require_relative 'devices/null_device'
require_relative 'devices/proc_device'

require_relative 'formatter'
require_relative 'scenes'

# requires ruby's logger
require 'logger'
require 'gem_info'

module RubySmart
  module SimpleLogger
    class Logger < ::Logger
      include Extensions::Helper
      include Extensions::Logs
      include Extensions::Mask
      include Extensions::Processed
      include Extensions::Scene
      include Extensions::Severity
      include Extensions::SimpleLog
      include Extensions::Timer

      include Scenes

      # enable access to the logdev
      attr_reader :logdev

      # defines a uniq key to parse the data
      # @return [Symbol]
      PAYLOAD_DATA_KEY = :__data__

      # defines a regexp to replace colors in string
      # @return [Regexp]
      COLOR_REPLACE_REGEXP = /\e\[[\d;]+m?/

      # initializes a new Logger
      #
      # @param [Array] args (<builtin>,<opts>) OR (<builtin>) OR (<opts>)
      # @option args[Symbol,Array] <builtin> - provide a builtin, either a single symbol or array of symbols
      # @option args[Hash] <options> - provide custom options
      def initialize(*args)
        opts = args.last.is_a?(Hash) ? args.pop : {}
        opts[:builtin] = args if args.length > 0

        # enhance options with device & formatter
        _opts_device!(opts)
        _opts_formatter!(opts)

        # initialize & set defaults by provided opts
        _opts_init!(opts)

        # initialize with a nil +logdev+ to prevent any nested +LogDevice+ creation.
        # we already arranged device & formatter to be able to respond to ther required methods
        super(nil)

        # set explicit after called super
        self.level = opts[:level]
        self.formatter = opts[:formatter]
        @logdev = _logdev(opts)
      end

      # overwrite level setter, to accept every available (also newly defined) Severity
      # @param [Numeric, String, Symbol] sev - severity to resolve
      def level=(sev)
        @level = _level(sev)
      end
    end
  end
end
