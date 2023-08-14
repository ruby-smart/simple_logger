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
        def _opts_init!(opts)
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

          # -- instance related ----------------------------------------------------------------------------------------

          # ignore payload and send data directly to the logdev
          @ignore_payload   = true if @ignore_payload.nil? && opts[:payload] == false

          # ignore processed logging and send data without 'leveling' & PCD-char to the logdev
          @ignore_processed = true if @ignore_processed.nil? && opts[:processed] == false

          # ignore tagged logging and send data without 'tags' to the logdev
          @ignore_tagged    = true if @ignore_tagged.nil? && opts[:tagged] == false

          # set custom inspector (used for data inspection)
          # 'disable' inspector, if false was provided - which simply results in +#to_s+
          @inspector = (opts[:inspect] == false) ? :to_s : opts[:inspector]

          # prevent to return any data
          nil
        end

        # enhance provided opts with +:device+.
        # opts may be manipulated by resolved device
        # does not return any data.
        # @param [Hash] opts
        def _opts_device!(opts)
          # check for already existing +device+
          return if opts[:device]

          # remove builtin key from opts and force an array
          builtins = Array(opts.delete(:builtin))

          # expand builtins with stdout
          builtins << :stdout if opts.delete(:stdout)

          # expand builtins with memory
          builtins << :memory if opts.delete(:memory)

          builtins.uniq!

          # don't create multi-device for a single (or +nil+) builtin
          if builtins.length < 2
            opts[:device] = _resolve_device(builtins[0], opts)
          else
            opts[:device] = ::RubySmart::SimpleLogger::Devices::MultiDevice.new
            builtins.each do |builtin|
              # IMPORTANT: dup, original hash to prevent reference manipulation (on the TOP-level, only)
              builtin_opts = opts.dup
              opts[:device].register(_resolve_device(builtin, builtin_opts), _resolve_formatter(builtin_opts))
            end

            # force 'passthrough', as format, since this is required for multi-devices
            opts[:format] = :passthrough
          end

          # prevent to return any data
          nil
        end

        # enhance provided opts with +:formatter+.
        # opts may be manipulated by resolved formatter
        # does not return any data.
        # @param [Hash] opts
        def _opts_formatter!(opts)
          # check for already existing +formatter+
          return if opts[:formatter]

          opts[:formatter] = _resolve_formatter(opts)

          # prevent to return any data
          nil
        end

        # resolves & returns formatter from provided opts
        # @param [Hash] opts
        # @return [RubySmart::SimpleLogger::Formatter]
        def _resolve_formatter(opts)
          # set default format
          opts[:format] ||= :plain

          # fix nl - which depends on other opts
          opts[:nl]  = _nl(opts)

          # fix clr
          opts[:clr] = true if opts[:clr].nil?

          ::RubySmart::SimpleLogger::Formatter.new(opts)
        end

        # resolves & returns device from builtin & provided opts
        # @param [Object] builtin
        # @param [Hash] opts
        def _resolve_device(builtin, opts)
          case builtin
          when nil # builtin is nil - resolve optimal device for current environment
            if ::ThreadInfo.stdout?
              _resolve_device(:stdout, opts)
            elsif ::ThreadInfo.rails? && ::Rails.logger
              _resolve_device(:rails, opts)
            else
              _resolve_device(:memory, opts)
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
                .register(::Rails.logger.instance_variable_get(:@logdev).dev)
            else
              ::Rails.logger.instance_variable_get(:@logdev).dev
            end
          when :proc
            # force overwrite opts
            @ignore_payload = true
            opts[:nl]       = false
            opts[:format]   = :passthrough

            ::RubySmart::SimpleLogger::Devices::ProcDevice.new(opts.delete(:proc))
          when :memory
            # force overwrite opts
            @ignore_payload = true
            opts[:format]   = :memory
            # no color logging for memory devices
            opts[:clr] = false

            ::RubySmart::SimpleLogger::Devices::MemoryDevice.new
          when Module, String
            # force overwrite opts
            opts[:clr] = false
            _logdev(opts, builtin)
          else
            _logdev(opts, builtin)
          end
        end

        # resolve the final log-device from provided param
        # @param [Hash] opts
        # @param [Object] device
        # @return [:Logger::LogDevice]
        def _logdev(opts, device = nil)
          device ||= opts.delete(:device)

          # if existing device is already writeable, simply return it
          return device if device.respond_to?(:write)

          file_location = nil

          # resolve the file_location from provided device
          case device
          when Module
            devstring = device.to_s
            logfile   = (devstring.respond_to?(:underscore) ? devstring.underscore : _underscore(device.to_s)) + '.log'
            # check for rails
            if ::ThreadInfo.rails?
              file_location = File.join(Rails.root, 'log', logfile)
            else
              file_location = File.join('log', logfile)
            end

            # resolve path to create a folder
            file_path = File.dirname(file_location)
            FileUtils.mkdir_p(file_path) unless File.directory?(file_path)

            # the logdev
            file_location
          when String
            file_location = (device[0] == '/' ? device : "log/#{device}")

            # resolve path to create a folder
            file_path = File.dirname(file_location)
            FileUtils.mkdir_p(file_path) unless File.directory?(file_path)

            file_location
          else
            raise "Unable to build SimpleLogger! The provided device '#{device}' must respond to 'write'!"
          end

          if GemInfo.match?(RUBY_VERSION, '< 2.7')
            ::Logger::LogDevice.new(file_location,
                                    shift_age:           opts[:shift_age] || 0,
                                    shift_size:          opts[:shift_size] || 1048576,
                                    shift_period_suffix: opts[:shift_period_suffix])
          else
            ::Logger::LogDevice.new(file_location,
                                    shift_age:           opts[:shift_age] || 0,
                                    shift_size:          opts[:shift_size] || 1048576,
                                    shift_period_suffix: opts[:shift_period_suffix],
                                    binmode:             opts[:binmode])
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
        #   > :not_really_a_color
        #
        # @param [Boolean, String, Integer, Symbol] res_or_clr
        # @return [Symbol] color
        def _res_clr(res_or_clr)
          case res_or_clr
          when true, 1, '1'
            :green
          when false, 0, '0'
            :red
          else
            res_or_clr.to_sym
          end
        end

        # resolves subject & opts from provided args.
        # returns provided default subject, if not in args.
        # @param [Object] args
        # @param [String] subject
        # @return [Array]
        def _scene_subject_with_opts(args, subject = '')
          if args[0].is_a?(Hash)
            [subject, args[0]]
          else
            [args[0] || subject, args[1] || {}]
          end
        end
      end
    end
  end
end