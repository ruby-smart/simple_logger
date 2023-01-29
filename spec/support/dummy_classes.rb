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
end