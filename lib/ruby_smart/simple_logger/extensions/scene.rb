# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Extensions
      module Scene
        def self.included(base)
          base.extend ClassMethods
          base.include InstanceMethods
          base.class_eval do
            # holds the default scene options
            # [Hash] scenes
            self.scenes = {}
          end
        end

        module ClassMethods
          # returns all registered scene default options
          # @return [Hash] scenes
          def scenes
            class_variable_get('@@scenes')
          end

          # sets scene options
          # @param [Hash] scenes
          def scenes=(scenes)
            class_variable_set('@@scenes', scenes)
          end

          # registers a new scene by provided key & options
          # also defines this method by provided block
          #
          # @example
          #   scene :line, { level: :debug } do |data, opts = {}|
          #     self.log data, _scene_opt(:line, opts)
          #   end
          #
          # @param [Symbol] key - name of the scene method
          # @param [Hash] opts - scene default options
          # @param [Proc] block - scene block to define a appropriate method
          # @return [Boolean] created result
          def scene(key, opts = {}, &block)
            # protect overwrite existing methods
            # but allow all severities (levels)
            return false if instance_methods.include?(key) && !self::LEVEL.key?(key)

            # register scene default options
            self.scenes[key] = opts

            # define (or overwrite) this method, if a block was provided
            define_method(key, &block) if block_given?

            # returns success result
            true
          end
        end

        module InstanceMethods
          # returns all registered scene default options
          # @return [Hash] scenes
          def scenes
            self.class.scenes
          end

          private

          # resolves scene options by provided key & merges them with additional options
          # @param [Symbol] key
          # @param [Array<Hash>] opts
          def _scene_opt(key, *opts)
            _opt((scenes[key] || {}), *opts)
          end
        end
      end
    end
  end
end
