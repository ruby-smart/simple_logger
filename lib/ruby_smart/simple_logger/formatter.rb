# frozen_string_literal: false

module RubySmart
  module SimpleLogger
    class Formatter
      class << self
        # returns all registered formats
        # @return [Hash] formats
        def formats
          class_variable_get('@@formats')
        end

        # sets formats
        # @param [Hash] formats
        def formats=(formats)
          class_variable_set('@@formats', formats)
        end
      end

      # set default formats
      self.formats = {
        # the ruby default's logging format (except to format the severity to 7-chars)
        default: {
          str: "%s, [%s #%d] %7s -- %s: %s",
          cb:  lambda { |severity, time, progname, data| [severity[0], format_datetime(time), $$, severity, progname, msg2str(data)] }
        },
        # all provided args as array
        passthrough: {
          str: false, # no formatting
          cb: lambda { |*args| args }
        },
        # the plain data (msg) only, no severity, etc.
        plain: {
          str: false, # no formatting
          cb: lambda { |_severity, _time, _progname, data| data }
        },
        # special array data for memory-logging
        memory: {
          str: false, # no formatting
          cb: lambda { |severity, time, _progname, data| [severity.downcase.to_sym, time, data] }
        },
        # special datalog data with all provided data in additional brackets -> [data] [data] [data]
        datalog: {
          str: "[%7s] [%s] [#%d] [%s]",
          cb:  lambda { |severity, time, _progname, data| [severity, format_datetime(time, true), $$, msg2str(data, true)] }
        }
      }

      # defines the severity colors
      SEVERITY_COLORS = {
        'DEBUG'   => :blue,
        'INFO'    => :cyan,
        'WARN'    => :yellow,
        'ERROR'   => :red,
        'FATAL'   => :bg_red,
        'SUCCESS' => :green
      }

      # initialize with options
      # @param [Hash] opts
      # @option opts [Symbol] :format - define other format
      # @option opts [Boolean] :nl - create newline after each call (default: true)
      # @option opts [Boolean] :clr - colorizes the whole output (default: false)
      def initialize(opts = {})
        # set default opts
        opts[:nl]     = true if opts[:nl].nil?
        opts[:format] = :default if opts[:format].nil?

        @opts = opts
      end

      # standard call method - used to format provided terms
      def call(severity, time, progname, data)
        if current_format_str
          str = current_format_str % instance_exec(severity, time, progname, data, &current_format_cb)
          str << "\n" if opts[:nl]

          # check for colorized output
          (opts[:clr] && SEVERITY_COLORS[severity]) ? str.send(SEVERITY_COLORS[severity]) : str
        else
          instance_exec(severity, time, progname, data, &current_format_cb)
        end
      end

      # returns all formats
      # @return [Hash] formats
      def formats
        self.class.formats
      end

      # combined getter & setter for options
      # new options are merged with existing
      #
      # @example
      #   opts
      #   > {formatter: :default, nl: true}
      #
      #   opts(nl: false, test: 45)
      #   opts
      #   > {formatter: :default, nl: false, test: 45}
      #
      # @param [nil, Hash] opts
      # @return [Hash] opts
      def opts(opts = nil)
        return @opts if opts.nil?

        clear!

        @opts.merge!(opts)
      end

      # clears auto-generated / cached data
      def clear!
        @current_format = nil
      end

      private

      def current_format
        @current_format ||= self.formats.key?(opts[:format]) ? self.formats[opts[:format]] : self.formats.values.first
      end

      def current_format_str
        current_format[:str]
      end

      def current_format_cb
        current_format[:cb]
      end

      def format_datetime(time, short = false)
        if short
          time.strftime("%Y-%m-%d %H:%M:%S")
        else
          time.strftime("%Y-%m-%dT%H:%M:%S.%6N")
        end
      end

      def msg2str(msg, join = false)
        case msg
        when ::String
          msg
        when ::Array
          join ? msg.join('] [') : msg.inspect
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" + (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end
    end
  end
end
