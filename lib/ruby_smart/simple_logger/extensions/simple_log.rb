# frozen_string_literal: false

module RubySmart
  module SimpleLogger
    module Extensions
      module SimpleLog
        def self.included(base)
          base.extend ClassMethods
          base.include InstanceMethods
          base.class_eval do
            # defines the default inspector to be used
            #
            # :auto
            self.inspector = :auto

            # this will overwrite the default log method from the Ruby Logger
            # but makes it still accessible through: #_log
            alias_method :_log, :log
            alias_method :log, :simple_log
          end
        end

        module ClassMethods
          def inspector
            class_variable_get('@@inspector')
          end

          def inspector=(inspector)
            class_variable_set('@@inspector', inspector)
          end
        end

        module InstanceMethods
          # Acts as the MAIN logging method and sends the data to the device
          # - checks provided level before logging
          # - creates & formats payload
          #
          # @param [Object] data
          # @param [Hash] opts
          # @option opts [Symbol, Numeric, String] :level - which level is logging
          # @option opts [Array] :payload - payload for logging multilines (scene)
          # @option opts [Symbol] :inspect - inspection method for data
          # @option opts [Symbol] :formatter - formatter type
          # @option opts [Hash] :mask - mask data
          # @return [Boolean] logging result
          def simple_log(data, opts = {})
            # resolve & check level
            level = _level(opts[:level])
            return false if level < self.level

            # prevents data from being transformed into payload
            if ignore_payload? || opts[:payload].is_a?(FalseClass)
              # prevent logging nil data
              return false if data.nil?

              add level, _parse_data(data, opts)
              return true
            end

            # create a default payload, if nothing was provided
            # :_ -> alias for log data
            opts[:payload] ||= [self.class::PAYLOAD_DATA_KEY]

            # create a default mask, if nothing was provided
            opts[:mask] ||= self.mask

            # create payloads and log each payload
            # returns the payload boolean result
            _payloads(opts.delete(:payload), opts, data) do |p|
              add level, p
            end

            # returns true as logging result
            true
          end

          # returns true if no payload should be created - instead the data will be send directly to the logdev
          # forces the *simple_log* method to prevent building payloads from schemes - it just forwards the level & data to the logdev
          #
          # @return [Boolean]
          def ignore_payload?
            !!@ignore_payload
          end

          # returns true if no tags should be created - instead the data will be send directly to the logdev
          # forces the *simple_log* method to prevent building tags from opts
          #
          # @return [Boolean]
          def ignore_tagged?
            !!@ignore_tagged
          end

          # resolve an inspector method for data inspection
          # @return [Symbol, nil]
          def inspector
            # return or resolve inspector
            @inspector ||= if self.class.inspector == :auto
                             # provide awesome_print support
                             Object.respond_to?(:ai) ? :ai : :inspect
                           else
                             self.class.inspector || :inspect
                           end
          end

          private

          # parses each payload and creates a callback
          #
          # @param [Array] payloads
          # @param [Hash] opts
          # @param [Object] data
          def _payloads(payloads, opts, data)
            payloads.each do |payload|
              # IMPORTANT: Do NOT remove this - prevents frozen string literal problem on other file sources
              str = ''
              if payload == self.class::PAYLOAD_DATA_KEY
                # checks, if we should inspect the data
                str << _parse_inspect_data(data, opts)
              else
                str << _parse_payload(payload, opts)
              end

              # always append newline - except it is forced excluded
              str << "\n" if opts[:nl] != false

              yield str
            end

            true
          end

          # parses the provided data to string.
          # - calls an inspection method, if provided
          # - tags the string, if provided
          # - adds processed prefix-chars, if provided
          #
          # @param [Object] data
          # @param [Hash] opts
          # @return [String] stringified data
          def _parse_data(data, opts)
            _pcd(
              _tagged(
                data.to_s,
                opts[:tag]
              ),
              opts
            )
          end

          # parses the provided data to string, but calls a possible inspect method.
          # @param [Object] data
          # @param [Hash] opts
          # @return [String] stringified data
          def _parse_inspect_data(data, opts)
            _parse_data(
              data.send(opts[:inspect] ? (opts[:inspector] || self.inspector) : :to_s),
              opts
            )
          end

          # parses a single payload with provided options
          #
          # @example
          #   _parse_payload(:mask, opts)
          #
          #   _parse_payload({mask: ' [%{subject}] '}, opts)
          #
          #   _parse_payload([:mask, ' [%{subject}] '], opts)
          #
          # @param [Array, Hash, Symbol, String] payload
          # @param [Hash] opts
          # @return [String] str
          def _parse_payload(payload, opts)
            # resolve type & additional sub-payloads (fraction)
            payload        = payload.to_a[0] if payload.is_a?(Hash)
            type, fraction = (payload.is_a?(Array) ? payload : [payload, nil])

            # prevent type case - type is the fraction
            return type if type.is_a?(String)

            case type
            when :mask, :_mask
              # resolve mask data
              mask = self.mask.merge(opts[:mask])

              # resolve text from fraction
              # this could also be a payload
              txt = _parse_payload({ _txt: fraction }, opts)

              # clean possible colored text - sucks but necessary :(
              txt.gsub!(/\e\[[\d;]+m?/, '')

              # check for provided txt length - this will decide if it's a full-line mask
              if txt.length == 0
                _clr((mask[:char] * mask[:length]), mask[:clr])
              else
                # text size is to large for mask
                txt    = txt[0, (mask[:length] - 1)] if txt.length > mask[:length]
                txt_lh = (txt.length / 2).floor

                left_mask  = mask[:char] * ((mask[:length] / 2) - txt_lh)
                right_mask = mask[:char] * (mask[:length] - left_mask.length - txt.length)

                _clr("#{left_mask}#{txt}#{right_mask}", mask[:clr])
                # _clr(left_mask, mask[:clr]) + _clr(txt, mask[:clr]) + _clr(right_mask, mask[:clr])
              end
            when :txt, :_txt
              txt = _parse_payload(fraction, opts)
              txt = _parse_opts(txt, opts)
              return '' if txt.length == 0

              # force string to exact length
              txt = txt.ljust(opts[:length], ' ')[0..(opts[:length] - 1)] if opts[:length]

              _clr(txt, opts[:clr])
            when :concat
              fraction = [fraction] unless fraction.is_a?(Array)
              fraction.map { |f| _parse_payload(f, opts) }.join
            when :blank, :_blank
              ''
            else
              # unknown type will be resolved by returning as string
              fraction.nil? ? type.to_s : fraction.to_s
            end
          end

          # parses wildcards ( %{xyz} ) from provided text by using the option keys
          #
          # @param [String] str
          # @param [Hash] opts
          # @return [String] parsed txt
          def _parse_opts(str, opts = {})
            mask           = opts[:mask] || { length: 0 }
            str            = str.to_s
            txt            = str.dup

            # SPECIAL: prevent subject being parsed longer as the mask#length
            opts[:subject] = opts[:subject].to_s[0, (mask[:length] - 4 - mask[:char].length * 2)] if opts[:subject] && mask[:length] && opts[:subject].to_s.length > mask[:length]

            str.scan(/%\{(\w+)\}/) do |mm|
              next unless mm.length > 0 && mm[0]
              m = mm[0].to_sym
              txt.gsub!("%{#{m}}", (opts[m] ? opts[m].to_s : ''))
            end

            txt
          end
        end
      end
    end
  end
end