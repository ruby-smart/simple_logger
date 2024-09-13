# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    class Payload

      attr_reader :data
      attr_reader :type
      attr_reader :nl

      def self.build(data, **opts)
        new(data, **opts)
      end

      def initialize(data, type: :raw, nl: true)
        @data = data
        @type = type
        @nl   = nl
      end

      def to_s
        data.to_s
      end

      def is_data?
        self.type == :data
      end

      def nl?
        self.nl != false
      end
    end
  end
end