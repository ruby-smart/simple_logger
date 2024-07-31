# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Devices
      class NullDevice
        attr_reader :status

        def initialize
          @status = true
        end

        def write(*)
          nil
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
          nil
        end

        # returns logs
        # @return [Array] logs
        def logs
          []
        end
      end
    end
  end
end