# frozen_string_literal: false

# use from ruby_smart-support
require 'thread_info'
require 'fileutils'

module RubySmart
  module SimpleLogger
    module Extensions
      module Helper

        private

        # set / overwrite default opts
        # @param [Hash] opts
        def assign_defaults!(opts)
          # -- level ---------------------------------------------------------------------------------------------------

          # initialize a default rails-dependent output
          if ::ThreadInfo.rails?
            opts[:level] ||= (::Rails.env.production? ? :info : :debug)
          end

          # clean & rewrite level (possible symbols) to real level
          opts[:level] = _level(opts[:level] || :debug)

          # -- mask ----------------------------------------------------------------------------------------------------

          # set mask from options
          self.mask(opts[:mask]) if opts[:mask]

          # disable mask color if explicit disabled
          self.mask(clr: false) if opts[:clr] == false

          # reduce mask-size to window size
          if ::ThreadInfo.windowed? && ::ThreadInfo.winsize[1] < self.mask[:length]
            self.mask(length: ::ThreadInfo.winsize[1])
          end

          # prevent returning any data
          nil
        end

        # enhance provided opts with +:logdev+.
        # opts may be manipulated by resolved device
        # does not return any data.
        # @param [Hash] opts
        def assign_logdev!(opts)
          # check for already existing +logdev+
          return if opts[:logdev]

          # remove builtin key from opts and force an array
          builtins = Array(opts.delete(:builtin))

          # expand builtins with stdout
          builtins << :stdout if opts.delete(:stdout)

          # expand builtins with memory
          builtins << :memory if opts.delete(:memory)

          builtins.uniq!

          # don't create multi-device for a single (or +nil+) builtin
          if builtins.length < 2
            opts[:logdev] = _resolve_device(builtins[0], opts)
          else
            opts[:logdev] = ::RubySmart::SimpleLogger::Devices::MultiDevice.new
            builtins.each do |builtin|
              # IMPORTANT: dup, original hash to prevent reference manipulation (on the TOP-level, only)
              builtin_opts = opts.dup
              opts[:logdev].register(_resolve_device(builtin, builtin_opts), _resolve_formatter(builtin_opts))

              # disable payload, if any is disabled
              opts[:payload] = false if builtin_opts[:payload] == false
            end

            # force 'passthrough', as format, since this is required for multi-devices
            opts[:format] = :passthrough
          end

          # prevent returning any data
          nil
        end

        # enhance provided opts with +:formatter+.
        # opts may be manipulated by resolved formatter
        # does not return any data.
        # @param [Hash] opts
        def assign_formatter!(opts)
          # check for already existing +formatter+
          return if opts[:formatter]

          opts[:formatter] = _resolve_formatter(opts)

          # prevent returning any data
          nil
        end

        # resolves & returns formatter from provided opts
        # @param [Hash] opts
        # @return [RubySmart::SimpleLogger::Formatter]
        def _resolve_formatter(opts)
          # set default format
          opts[:format] ||= :plain

          # fix nl - which depends on other opts
          opts[:nl] = _nl(opts)

          # fix clr
          opts[:clr] = true if opts[:clr].nil?

          ::RubySmart::SimpleLogger::Formatter.new(opts)
        end

        # resolves & returns device from builtin & provided opts
        # @param [Object,nil] builtin
        # @param [Hash] opts
        def _resolve_device(builtin, opts)
          # in case the provided *builtin* already responds to +write+, return it
          return builtin if builtin.respond_to?(:write)

          case builtin
          when nil # builtin is nil - resolve optimal device for current environment
            if opts.key?(:device)
              _resolve_device(opts.delete(:device), opts)
            elsif ::ThreadInfo.stdout?
              _resolve_device(:stdout, opts)
            elsif ::ThreadInfo.debugger?
              _resolve_device(:debugger, opts)
            elsif ::ThreadInfo.rails? && ::Rails.logger
              _resolve_device(:rails, opts)
            else
              _resolve_device(:memory, opts)
            end
          when :null
            ::RubySmart::SimpleLogger::Devices::NullDevice.new
          when :debugger
            raise "Unable to build SimpleLogger with 'debugger' builtin for not initialized Debugger!" unless ThreadInfo.debugger?

            # since some IDEs did a Debase rewriting for Ruby 3.x, the logger is a Proc instead of a Logger instance
            if ::Debugger.logger.is_a?(Proc)
              opts[:format] = :plain # only the data string is forwarded to the proc
              ::RubySmart::SimpleLogger::Devices::ProcDevice.new(::Debugger.logger)
            else
              _resolve_device(::Debugger.logger, opts)
            end
          when :stdout
            STDOUT
          when :stderr
            STDERR
          when :rails
            raise "Unable to build SimpleLogger with 'rails' builtin for not initialized rails application!" unless ThreadInfo.rails?

            # special check for rails-with-console (IRB -> STDOUT) combination - mostly in combination with +Debase+.
            if ThreadInfo.console? && ::Rails.logger.instance_variable_get(:@logdev).dev != STDOUT
              ::RubySmart::SimpleLogger::Devices::MultiDevice
                .register(_resolve_device(:stdout, opts))
                .register(_resolve_device(::Rails.logger, opts))
            else
              _resolve_device(::Rails.logger, opts)
            end
          when :proc
            # slurp the proc and call the '_resolve_device' again
            _resolve_device(opts.delete(:proc), opts)
          when :memory
            # force overwrite opts
            opts[:payload] = false
            opts[:format] = :memory
            # no color logging for memory devices
            opts[:clr] = false

            ::RubySmart::SimpleLogger::Devices::MemoryDevice.new
          when Proc
            # force overwrite opts
            opts[:payload] = false
            opts[:nl] = false
            opts[:format] = :passthrough

            ::RubySmart::SimpleLogger::Devices::ProcDevice.new(builtin)
          when Module
            # no color logging for logfiles
            opts[:clr] = false

            logfile = _underscore(builtin.to_s) + '.log'

            file_location = if ::ThreadInfo.rails? # check for rails
                              File.join(::Rails.root, 'log', logfile)
                            else
                              File.join('log', logfile)
                            end

            # resolve path to create a folder
            file_path = File.dirname(file_location)
            FileUtils.mkdir_p(file_path) unless File.directory?(file_path)

            # resolve new logdev with the provided options
            _logdev(file_location, opts)
          when String
            # no color logging for logfiles
            opts[:clr] = false

            logfile = if builtin[-4..-1] == '.log'
                        builtin
                      else
                        builtin + '.log'
                      end

            file_location = if builtin[0] == '/'
                              builtin
                            elsif ::ThreadInfo.rails?
                              File.join(Rails.root, 'log', logfile)
                            else
                              File.join('log', logfile)
                            end

            # resolve path to create a folder
            file_path = File.dirname(file_location)
            FileUtils.mkdir_p(file_path) unless File.directory?(file_path)

            # resolve new logdev with the provided options
            _logdev(file_location, opts)
          when ::Logger
            # resolve the logdev from the provided logger
            builtin.instance_variable_get(:@logdev).dev
          else
            raise "Unable to build SimpleLogger! The provided device '#{builtin}' must respond to 'write'!"
          end
        end

        # Creates and configures a new instance of Logger::LogDevice based on the provided file location
        # and optional settings.
        #
        # The configuration differs slightly based on the Ruby version being used. For Ruby versions
        # prior to 2.7, the options `:binmode` is omitted as it is not supported. For Ruby 2.7 and newer,
        # the `:binmode` option is included.
        #
        # @param [String] file_location - the file path where the log will be written.
        # @param [Hash] opts
        #   A hash of options to configure the log device:
        #   - `:shift_age` (default: 0) - Specifies the number of old log files to retain.
        #   - `:shift_size` (default: 1048576, 1MB) - Specifies the maximum size of the log file,
        #     after which the file will be rotated.
        #   - `:shift_period_suffix` - A string specifying the date format for rotated files (optional).
        #   - `:binmode` (Ruby >= 2.7 only) - Enables binary mode explicitly if set to `true`.
        #
        # @return [Logger::LogDevice]
        #   Returns a newly configured instance of Logger::LogDevice.
        def _logdev(file_location, opts)
          if GemInfo.match?(RUBY_VERSION, '< 2.7')
            ::Logger::LogDevice.new(file_location,
                                    shift_age: opts[:shift_age] || 0,
                                    shift_size: opts[:shift_size] || 1048576,
                                    shift_period_suffix: opts[:shift_period_suffix])
          else
            ::Logger::LogDevice.new(file_location,
                                    shift_age: opts[:shift_age] || 0,
                                    shift_size: opts[:shift_size] || 1048576,
                                    shift_period_suffix: opts[:shift_period_suffix],
                                    binmode: opts[:binmode])
          end
        end

        # this is a 1:1 copy of +String#underscore+ @ activesupport gem
        # and only used if activesupport is not available ...
        def _underscore(camel_cased_word)
          return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
          word = camel_cased_word.to_s.gsub("::", "/")
          word.gsub!(/(?:(?<=([A-Za-z\d]))|\b)((?=a)b)(?=\b|[^a-z])/) { "#{$1 && '_' }#{$2.downcase}" }
          word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
          word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
          word.tr!("-", "_")
          word.downcase!
          word
        end

        # returns the +nl+ (new line) flag, depending on the provided options.
        # recognizes +:nl+ and +:payload+ options.
        # @param [Hash] opts
        # @return [Boolean]
        def _nl(opts)
          return opts[:nl] unless opts[:nl].nil?

          opts[:payload].is_a?(FalseClass)
        end

        # merge all provided hashes into one single hash
        #
        # @example
        #   _opt({level: :debug, formatter: :my, payload: []}, {payload: [:_], ins: true})
        #   > {level: :debug, formatter: :my, payload: [:_], ins: true}
        #
        # @param [Hash] opts
        # @return [Hash] opts
        def _opt(*opts)
          # IMPORTANT: Do not remove first empty hash!
          opts.unshift {}

          # merge each single provided option
          opts.reduce({}) do |m, opt|
            opt.each do |k, v|
              if v.is_a?(Hash) && m[k].is_a?(Hash)
                m[k] = m[k].merge(v)
              else
                m[k] = v
              end
            end
            m
          end
        end

        # 'tags' a provided string
        # returns the string if no tag was provided or general tags are disabled
        # @param [String] str
        # @param [nil|Symbol|String] tag
        # @return [String]
        def _tagged(str, tag = nil)
          # check for active tag
          return str if tag.nil? || ignore_tagged?

          "#{"[#{tag.to_s.upcase.bg_cyan}]"} #{str}"
        end

        # colorizes a provided string
        # returns the string if no color was provided or invalid
        #
        # @example
        #   _clr('Test',nil)
        #   > "Test"
        #
        #   _clr('Test2', :red)
        #   > "\e[1;31mTest2\e[0m"
        #
        #   _clr('Test3', :not_a_valid_color)
        #   > "Test3"
        #
        # @param [String] str
        # @param [String, Symbol, nil] color
        # @return [String] colored string
        def _clr(str, color = nil)
          return str unless color
          str.send(color) rescue str
        end

        # force string to exact length
        #
        # @example
        #   _lgth('test', 10)
        #   > "test      "
        #
        #   _lgth('very long teststring', 10)
        #    > "very long "
        #
        #   _lgth('very', 10,'-')
        #   > "very------"
        #
        # @param [String] str
        # @param [Integer] length
        # @param [String] padstr - optional (default: ' ')
        # @return [String] str
        def _lgth(str, length, padstr = ' ')
          str.to_s.ljust(length, padstr)[0..(length - 1)]
        end

        # returns a Symbol by provided result or color
        #
        # @example
        #   _res_clr(true)
        #   > :green
        #
        #   _res_clr('0')
        #   > :red
        #
        #   _res_clr(:yellow)
        #   > :yellow
        #
        #   _res_clr('not_really_a_color')
        #   > :green
        #
        # @param [Boolean, String, Integer, Symbol] args
        # @return [Symbol] color
        def _res_clr(*args)
          case (res = args.compact.first)
          when true, 'true', 1, '1'
            :green
          when false, 'false', 0, '0', ''
            :red
          when '-', nil
            :yellow
          when String
            :green
          when Symbol
            res
          else
            :grey
          end
        end
      end
    end
  end
end