# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Extensions
      module Logs
        # returns the logdev logs
        # @return [Array]
        def logs
          return [] unless logdev.respond_to?(:logs)
          logdev.logs
        end

        # transforms the logs-array into a hash of logs, grouped by level (:error, :success, ...)
        # @return [Hash] logs
        def logs_to_h
          logs.reduce({}) do |m, log|
            m[log[0]] ||= []
            m[log[0]] << log[2]
            m
          end
        end

        # returns a hash with total amounts per logged type (key)
        # @return [Hash]
        def log_stats
          logs_to_h.reduce({}) { |m, (sev, logs)| m[sev] = logs.count; m }
        end
      end
    end
  end
end
