# frozen_string_literal: true

require 'logger'

module RubySmart
  module SimpleLogger
    module Extensions
      module Processed
        def self.included(base)
          base.extend ClassMethods
          base.include InstanceMethods
          base.class_eval do
            # set default box chars
            self.box_chars = {
              __default__:   %w(╟ ├),
              __processed__: %w(║ │),
              start:         %w(╔ ┌),
              end:           %w(╚ └)
            }.freeze
          end
        end

        module ClassMethods
          def box_chars
            class_variable_get('@@box_chars')
          end

          def box_chars=(chars)
            class_variable_set('@@box_chars', chars)
          end
        end

        module InstanceMethods
          # returns the current processed level.
          # by providing a handle it will either increase or decrease the current level.
          # @param [nil, Symbol] handle - optional handle to increase or decrease the current lvl (+:up+ / +:down+)
          # @return [Integer]
          def processed_lvl(handle = nil)
            @processed_lvl ||= -1

            case handle
            when :up
              @processed_lvl += 1
            when :down
              @processed_lvl -= 1 if @processed_lvl >= 0
            else
              # nothing here ...
            end

            @processed_lvl
          end

          # returns true if the processed state is active.
          # @return [Boolean]
          def processed?
            processed_lvl >= 0
          end

          private

          # transforms the provided data into a 'processed' string and forces the data to be transformed to string.
          # simple returns the provided data, if currently not processed.
          # @param [Object] data
          # @param [Hash] opts
          # @return [Object,String]
          def _pcd(data, opts)
            # check for active pcd (processed)
            return data if opts[:pcd] == false || !processed?

            # resolve lvl, once
            lvl = opts[:lvl] || processed_lvl

            # create final string
            lvl.times.map { |i| "#{_pcd_box_char(:__processed__, i)} " }.join + _pcd_box_char(opts[:pcd], lvl) + " #{data}"
          end

          # returns the processed box character for provided key and position.
          # returns the +:__default__+, if provided key was not found.
          # returns the max-pos char, if current pos was not found.
          # @param [Symbol] key
          # @param [Integer] pos
          # @return [String]
          def _pcd_box_char(key, pos = 0)
            chars = self.class.box_chars[key] || self.class.box_chars[:__default__]
            chars[pos] || chars[-1]
          end
        end
      end
    end
  end
end
