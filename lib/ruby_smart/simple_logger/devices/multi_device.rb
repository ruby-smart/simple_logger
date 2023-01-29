# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Devices
      class MultiDevice

        attr_reader :devices
        attr_reader :status

        def initialize
          @devices = []
          @status  = true
        end

        # pass data to the devices
        # @param [Object] data
        def write(data)
          return false unless status

          devices.each do |device|
            if device[:formatter]
              device[:dev].write(device[:formatter].(*data))
            else
              device[:dev].write(data)
            end
          end
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

        # clears all devices
        def clear!
          @devices = []
        end

        # registers a new device.
        # CHAINABLE
        #
        # @param [Object] dev
        def register(dev, formatter = nil)
          @devices << {
            dev:       dev,
            formatter: formatter
          }

          self
        end

        # returns logs from the first loggable device
        # @return [Array] logs
        def logs
          logdev = devices.detect { |device| device[:dev].respond_to?(:logs) }
          logdev.nil? ? [] : logdev[:dev].logs
        end
      end
    end
  end
end