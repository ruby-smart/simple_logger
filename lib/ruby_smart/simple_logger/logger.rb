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
      PAYLOAD_DATA_KEY = :__data__

      # initializes a new Logger
      #
      # @param [Array] args (<builtin>,<opts>) OR (<builtin>) OR (<opts>)
      # @option args[Symbol,Array] <builtin> - provide a builtin, either a single symbol or array of symbols
      # @option args[Hash] <options> - provide custom options
      def initialize(*args)
        # transform args to opts
        opts = args.last.is_a?(Hash) ? args.pop : {}
        opts[:builtin] = args if args.length > 0

        # assign logdev to opts
        assign_logdev!(opts)

        # assign formatter to opts
        assign_formatter!(opts)

        # assign default opts
        assign_defaults!(opts)

        # initialize with a nil +logdev+ to prevent any nested +LogDevice+ creation.
        # we already arranged device & formatter to be able to respond to ther required methods
        super(nil)

        # level must be set through the *_level* method, to prevent invalid values
        self.level = opts[:level]

        # use the provided formatter
        self.formatter = opts[:formatter]

        # ignore payload and send data directly to the logdev
        @ignore_payload = true if opts[:payload] == false

        # ignore processed logging and send data without 'leveling' & PCD-char to the logdev
        @ignore_processed = true if opts[:processed] == false

        # ignore tagged logging and send data without 'tags' to the logdev
        @ignore_tagged = true if opts[:tagged] == false

        # set custom inspector (used for data inspection)
        # 'disable' inspector, if false was provided - which simply results in +#to_s+
        @inspector = (opts[:inspect] == false) ? :to_s : opts[:inspector]

        # set resolved logdev
        @logdev = opts[:logdev]
      end

      # overwrite level setter, to accept every available (also newly defined) Severity
      # @param [Numeric, String, Symbol] sev - severity to resolve
      def level=(sev)
        @level = _level(sev)
      end
    end
  end
end
