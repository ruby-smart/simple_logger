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
        # the ruby default's logging format -except the reformatted severity to 7-chars (instead of 5)
        default: -> (severity, time, progname, data) {
          _nl data2array(data, false).map { |str|
            str == '' ? str : _clr(format('%s, [%s #%d] %7s -- %s: ', severity[0], format_datetime(time), $$, severity, progname), severity) + _declr(str)
          }
        },

        # simply 'passthrough' all args, without any formatting
        passthrough: -> (*args) { args },

        # just forward the formatted data, without any other args (no severity, time, progname)
        plain: -> (_severity, _time, _progname, data) { _nl _declr(data.to_s) },

        # specialized array for memory-logging
        memory: -> (severity, time, _progname, data) { [severity.downcase.to_sym, time, _declr(data)] },

        # specialized string as datalog with every provided data in additional brackets -> [data] [data] [data]
        datalog: -> (severity, time, _progname, data) {
          _nl _declr(format('[#%d] [%s] [%s] [%s]', $$, format_datetime(time, true), severity, data2datalog(data)))
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

        # only store required options
        @opts = opts.slice(:nl, :format, :clr)
      end

      # standard call method - used to format provided params
      def call(severity, time, progname, data)
        instance_exec(severity, time, progname, data, &current_formatter)
      end

      # returns all class formats
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

      # clears current formatter
      def clear!
        @current_formatter = nil
      end

      private

      # returns the current formatter callback
      # @return [Proc]
      def current_formatter
        @current_formatter ||= self.formats[opts[:format]] || self.formats.values.first
      end

      # splits-up the provided data into a flat array.
      # each will be split by new-line char +\n+.
      # @param [Object] data
      # @param [Boolean] allow_array
      # @return [Array<String>]
      def data2array(data, allow_array = true)
        case data
        when ::String
          data.split("\n", -1)
        when ::Array
          # prevent to split-up arrays into multiple lines for this format:
          # a array should +not+ be multi-lined
          return data2array(data.inspect) unless allow_array

          data.map { |item| data2array(item) }.flatten
        when ::Exception
          [
            "exception: #{data.class}",
            data2array(data.message),
            data.backtrace || []
          ].flatten
        else
          data2array(data.inspect)
        end
      end

      # splits-up the provided data into a single string with each data item in brackets -> [data] [data] [data]
      # @param [Object] data
      # @return [String]
      def data2datalog(data)
        data2array(data).join('] [')
      end

      # formats the provided format string with args.
      # @param [String] format
      # @param [Array] args
      # @return [String]
      def format(format, *args)
        format % args
      end

      # def current_format_str
      #   current_format[:str]
      # end
      #
      # def current_format_cb
      #   current_format[:cb]
      # end
      #
      # def current_format_data(data)
      #   (current_format[:data] ? current_format[:data].(data) : data).to_s.split("\n")
      # end

      def format_datetime(time, short = false)
        if short
          time.strftime("%Y-%m-%d %H:%M:%S")
        else
          time.strftime("%Y-%m-%dT%H:%M:%S.%6N")
        end
      end

      # returns the formatted string with or without a new-line.
      # Also drops a trailing new-line, if it exists.
      # depends, on the +:nl+ option.
      # @param [String, Array] data
      # @return [String]
      def _nl(data)
        # convert possible array to string
        data = data.join("\n") if data.is_a?(Array)

        # check, if a nl-flag should be added or dropped
        if opts[:nl] && data[-1] != "\n"
          data + "\n"
        elsif !opts[:nl] && data[-1] == "\n"
          data[0..-2]
        else
          data
        end
      end

      # returns the formatted string with a color-code
      # depends, on the +:clr+ option.
      # @param [String] str
      # @param [String<uppercase>] severity
      # @return [String]
      def _clr(str, severity)
        if opts[:clr] && (clr = SEVERITY_COLORS[severity])
          str.send(clr)
        else
          _declr(str)
        end
      end

      # de-colorizes provided string
      # @param [String] str
      # @return [String]
      def _declr(str)
        if opts[:clr] || !str.is_a?(String)
          str
        else
          str.gsub(/\e\[[\d;]+m/, '')
        end
      end
    end
  end
end
