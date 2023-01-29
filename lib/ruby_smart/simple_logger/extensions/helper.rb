# frozen_string_literal: false

# use from ruby_smart-support
require 'thread_info'
require 'fileutils'

module RubySmart
  module SimpleLogger
    module Extensions
      module Helper

        private

        # prepare builtin defaults
        # @param [Hash] opts
        def _opts_builtin(opts)
          builtin = opts.delete(:builtin)

          case builtin
          when nil
            # device is nil - resolve optimal device
            opts[:device] ||= if ::ThreadInfo.stdout?
                                # colorize output
                                opts[:clr] = true if opts[:clr].nil?

                                STDOUT
                              elsif ::ThreadInfo.rails? && ::Rails.logger
                                ::RubySmart::SimpleLogger::Devices::MultiDevice.new.register(::Rails.logger.instance_variable_get(:@logdev).dev)
                              else
                                ::RubySmart::SimpleLogger::Devices::MemoryDevice.new
                              end
          when :stdout
            opts[:device] ||= STDOUT
            # colorize output
            opts[:clr]    = true if opts[:clr].nil?
          when :stderr
            opts[:device] ||= STDERR
            # colorize output
            opts[:clr]    = true if opts[:clr].nil?
          when :rails
            opts[:device] ||= ::RubySmart::SimpleLogger::Devices::MultiDevice.new.register(::Rails.logger.instance_variable_get(:@logdev).dev)
          when :proc
            # auto sets related opts for proc device
            opts[:payload] = false
            opts[:format]  ||= :passthrough

            # force set device
            opts[:device] ||= ::RubySmart::SimpleLogger::Devices::ProcDevice.new(opts[:proc])
          when :memory
            # auto sets related opts for memory device
            opts[:payload] = false

            # set device
            opts[:device] ||= if opts[:stdout]
                                # IMPORTANT: There will be a 'default' formatter created, which will passthrough all data to the device
                                opts[:format] ||= :passthrough

                                # special case handling to additionally stdout logs
                                ::RubySmart::SimpleLogger::Devices::MultiDevice.new.
                                  register(::RubySmart::SimpleLogger::Devices::MemoryDevice.new, ::RubySmart::SimpleLogger::Formatter.new(format: :memory, nl: false)).
                                  register(STDOUT, ::RubySmart::SimpleLogger::Formatter.new(format: :default, nl: true, clr: (opts[:clr] != nil)))
                              else
                                opts[:format] ||= :memory
                                ::RubySmart::SimpleLogger::Devices::MemoryDevice.new
                              end
          else
            # forward provided device ONLY if unset in opts
            opts[:device] ||= builtin
          end
        end

        # resolve the final log-device from provided param
        # @param [Object] device
        # @return [Object]
        def _logdev(device)
          if device.is_a?(Module)
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

            file_location
          elsif device.is_a?(String)
            device = "log/#{device}" unless device[0] == '/'

            # resolve path to create a folder
            file_path = File.dirname(device)
            FileUtils.mkdir_p(file_path) unless File.directory?(file_path)

            device
          elsif device.respond_to?(:write)
            device
          else
            raise "SimpleLogger :: device '#{device}' must respond to 'write'!"
          end
        end

        # this is a 1:1 copy of +String#underscore+ @ activesupport gem
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

        # build log-device & options on initialize
        # @param [Hash] opts
        # @return [Array<logdev,opts>] logdev, opts
        def _init_opts(opts)
          # clean & rewrite opts (especially device) to a real logdev
          _opts_builtin(opts)

          # set mask from options
          self.mask(opts[:mask]) if opts[:mask]

          # disable mask color if explicit disabled
          self.mask(clr: false) if opts[:clr] == false

          # reduce mask-size to window size
          if ::ThreadInfo.windowed? && ::ThreadInfo.winsize[1] < self.mask[:length]
            self.mask(length: ::ThreadInfo.winsize[1])
          end

          # initialize a default rails-dependent output
          if ::ThreadInfo.rails?
            opts[:level] ||= (::Rails.env.production? ? :info : :debug)
          end

          # clean & rewrite level (possible symbols) to real level
          opts[:level] = _level(opts[:level] || :debug)

          # provide custom formatter and forward special opts (format, nl, clr)
          opts[:formatter] ||= ::RubySmart::SimpleLogger::Formatter.new({ format: :plain, nl: false, clr: false }.merge(opts.slice(:format, :nl, :clr)))

          # ignore payload and send data directly to the logdev
          @ignore_payload  = true if opts[:payload].is_a?(FalseClass)

          # set the inspector to be used for data inspection
          @inspector = opts[:inspector]

          # disable inspector
          @inspector = :to_s if opts[:inspect] == false

          # # build logdev
          # opts[:logdev] = _logdev(opts[:device])

          # simple return opts
          opts
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
        def _clr(str, color)
          return str unless color && str.respond_to?(color)
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
      end
    end
  end
end