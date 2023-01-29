# frozen_string_literal: true

require 'logger'

module RubySmart
  module SimpleLogger
    module Extensions
      module Severity
        # include log level constants from original logger severity
        include ::Logger::Severity

        # add severity success (sub-kind of info = 1)
        SUCCESS = 1.1

        # creates an severity hash
        # {
        #   0   => 'DEBUG',
        #   1   => 'INFO',
        #   1.1 => 'SUCCESS',
        #   2   => 'WARN',
        #   ...
        # }
        SEVERITIES = %w(DEBUG INFO SUCCESS WARN ERROR FATAL UNKNOWN).map { |sev| [const_get(sev), sev] }.to_h.freeze

        # creates an level hash from SEVERITIES
        LEVEL = SEVERITIES.reduce({}) { |m, (lvl, sev)| m[sev.downcase.to_sym] = lvl; m }.freeze

        private

        # overwrite original method to provide additional severities
        #
        # @example
        #   format_severity(1.1)
        #   > 'SUCCESS'
        #
        # @param [Numeric] severity
        # @return [String (frozen)] severity name
        def format_severity(severity)
          self.class::SEVERITIES[severity] || 'UNKNOWN'
        end

        # resolves the severity level by provided Number, Symbol or String
        #
        # @param [Numeric, String, Symbol] sev - severity to resolve
        # @return [Numeric,nil] severity level
        def _level(sev)
          # no sev provided
          return UNKNOWN if sev.nil?
          # numeric and valid
          return sev if sev.is_a?(Numeric) && SEVERITIES.key?(sev)

          key = sev.to_s.downcase.to_sym
          # symbol (:success) and valid
          return LEVEL[key] if LEVEL.key?(key)

          # fallback to unknown
          UNKNOWN
        end
      end
    end
  end
end