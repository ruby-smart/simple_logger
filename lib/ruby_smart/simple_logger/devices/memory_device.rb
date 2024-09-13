# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Devices
      class MemoryDevice
        attr_reader :logs
        attr_reader :status

        def initialize
          @logs   = []
          @status = true
        end

        # adds data to the logs
        # @param [Object] data
        def write(data)
          return false unless status
          return false unless data

          @logs << data
        end

        alias_method :<<, :write

        # disables writing
        def close
          @status = false
        end

        # enables writing
        def reopen
          @status = true
        end

        # clears all logs
        def clear!
          @logs = []
        end
      end
    end
  end
end