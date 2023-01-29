# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Extensions
      module Mask
        def self.included(base)
          base.extend ClassMethods
          base.include InstanceMethods
          base.class_eval do
            # defines the default mask to be used
            #
            # @option [String] :char - the character to be used as mask
            # @option [Integer] :length - the mask length (amount of mask chars be line)
            # @option [Symbol] :clr - the color to be used by printing the mask
            self.mask = { char: '=', length: 100, clr: :blue }
          end
        end

        module ClassMethods
          def mask
            class_variable_get('@@mask')
          end

          def mask=(mask)
            class_variable_set('@@mask', mask)
          end
        end

        module InstanceMethods
          # combined getter & setter for instances mask
          # new mask is merged with existing
          #
          # @example
          #   mask
          #   > {char: '=', length: 100}
          #
          #   mask(clr: :blue, length: 10)
          #   mask
          #   > {char: '=', length: 10, clr: :blue}
          #
          # @param [nil, Hash] mask
          # @return [Hash] mask
          def mask(mask = nil)
            return (@mask || self.class.mask) if mask.nil?

            @mask = (@mask || self.class.mask).merge(mask)
          end
        end
      end
    end
  end
end
