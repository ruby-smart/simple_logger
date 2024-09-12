# frozen_string_literal: true

module Dummy
  module With
    module UsersHelper
      module OfAny
        class Levels

        end
      end
    end
  end

  module Logger
    def self.extend!
      extend ::RubySmart::SimpleLogger::KlassLogger
    end

    def self.overwrite!
      @klass_logger = self.new :memory
    end
  end

  class Model

    attr_reader :state

    def initialize(state)
      @state = state
    end

    def id
      state == :create ? nil : 4711
    end

    def to_s
      "A dummy model"
    end

    def persisted?
      state != :error
    end

    def errors
      if state == :create || state == :update
        []
      elsif state == :skipped
        Struct.new(:data, keyword_init: true) do
          def full_messages
            []
          end

          def empty?
            true
          end
        end.new
      else
        Struct.new(:data, keyword_init: true) do
          def full_messages
            %w[a full message string]
          end

          def empty?
            false
          end
        end.new
      end
    end

    def previous_changes
      state == :skipped ? nil : 'some changes'
    end

    def previously_new_record?
      state == :create
    end
  end
end