# frozen_string_literal: true

require_relative 'extensions/helper'
require_relative 'extensions/logs'
require_relative 'extensions/mask'
require_relative 'extensions/scene'
require_relative 'extensions/severity'
require_relative 'extensions/simple_log'
require_relative 'extensions/timer'

require_relative 'devices/memory_device'
require_relative 'devices/multi_device'
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
      include Extensions::Scene
      include Extensions::Severity
      include Extensions::SimpleLog
      include Extensions::Timer

      include Scenes

      # enable access to the logdev
      attr_reader :logdev

      # defines a uniq key to parse the data
      PAYLOAD_DATA_KEY = :_data

      # initialize new Logger
      # @param [Object, Symbol, nil] builtin
      # @param [Hash] opts
      # @option opts [Symbol] :format - defines a custom format
      def initialize(builtin = nil, opts = nil)
        # check if only a hash was provided
        if opts.nil? && builtin.is_a?(Hash)
          opts = builtin
        else
          opts ||= {}

          # extend builtin option if not set
          opts[:builtin] = builtin unless opts[:builtin]
        end

        # initialize provided opts
        o = _init_opts(opts)

        super(
          _logdev(o[:device]),
          o[:shift_age] || 0,
          o[:shift_size] || 1048576,
          **o.slice(:level, :progname, :formatter, :datetime_format, :binmode, :shift_period_suffix)
        )
      end

      # overwrite level setter, to accept every available (also newly defined) Severity
      # @param [Numeric, String, Symbol] sev - severity to resolve
      def level=(sev)
        @level = _level(sev)
      end
    end
  end
end
