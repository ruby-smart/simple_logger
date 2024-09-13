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

              add level, _payload(:data, data, opts)
              return true
            end

            # create a default payload, if nothing was provided
            opts[:payload] ||= [self.class::PAYLOAD_DATA_KEY]

            # create a default mask, if nothing was provided
            opts[:mask] ||= self.mask

            # split payload into single  lines
            each_payload(opts, data) do |payload|
              add level, payload
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

          # parses and yields each payload
          # @param [Hash] opts
          # @param [Object] data
          def each_payload(opts, data)
            opts[:payload].each do |payload|
              if payload == self.class::PAYLOAD_DATA_KEY
                yield _payload(:data, _parse_data(data, opts), opts)
              else
                yield _payload(:mask, _parse_payload(payload, opts), opts)
              end
            end
          end

          # builds and returns a +Payload+
          # @param [Symbol] type
          # @param [Object] data
          # @param [Hash] opts
          # @return [RubySmart::SimpleLogger::Payload]
          def _payload(type, data, opts)
            Payload.build(data, type:, nl: opts[:nl])
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
                _clr(
                  _inspect(data, opts),
                  opts[:clr]
                ),
                opts[:tag]
              ),
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
              txt.gsub!(self.class::COLOR_REPLACE_REGEXP, '')

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
            # EDGE-CASE for *subject* (which is commonly used in SL headers)
            # prevent subject being parsed longer as the mask#length
            opts[:subject] = opts[:subject].to_s[0, (opts[:mask][:length] - 4 - opts[:mask][:char].length * 2)] if opts[:subject] && opts[:mask] && opts[:mask][:length] && opts[:subject].to_s.length > opts[:mask][:length]

            # replace wildcards and return new string
            str.to_s % opts
          end
        end
      end
    end
  end
end