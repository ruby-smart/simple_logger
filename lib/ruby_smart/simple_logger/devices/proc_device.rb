# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Devices
      class ProcDevice

        attr_reader :status

        def initialize(proc)
          @proc = proc
          @status = true
        end

        # pass data to the callback
        # @param [Object] data
        def write(data)
          return false unless status

          @proc.call(data)
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
      end
    end
  end
end