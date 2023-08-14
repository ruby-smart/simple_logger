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
              # control characters by provided +:pcd+
              default:       %w(╟ ├),
              start:         %w(╔ ┌),
              end:           %w(╚ └),

              # additional characters, added ad specific position
              __processed__: %w(║ │),
              __feed__:      %w(═ ─),
              __tagged__:    %w(┄ ┄),
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
          # @param [Symbol|Integer] handle - optional handle to increase or decrease the current lvl (+:up+ / +:down+)
          # @return [Integer]
          def processed_lvl(handle = nil)
            @processed_lvl ||= -1

            case handle
            when :reset
              @processed_lvl = -1
            when :up
              @processed_lvl += 1
            when :down
              @processed_lvl -= 1 if @processed_lvl >= 0
            else
              @processed_lvl = handle if handle.is_a?(Integer)
            end

            @processed_lvl
          end

          # returns true if the processed state is active.
          # @return [Boolean]
          def processed?
            processed_lvl >= 0 && !@ignore_processed
          end

          private

          # transforms the provided data into a 'processed' string and forces the data to be transformed to string.
          # simple returns the provided data, if currently not processed.
          # @param [String] data
          # @param [Hash] opts
          # @return [String]
          def _pcd(data, opts)
            # check for active pcd (processed)
            return data if opts[:pcd] == false || !processed?

            # resolve the current level - either directly through the options or the +processed_lvl+.
            lvl = opts[:lvl] || processed_lvl

            # prepares the out-string array
            strs = []

            # add level-charters with indent
            lvl.times.each { |i|
              # ║ │
              strs << _pcd_box_char(:__processed__, i) + ' '
            }

            # add pcd-related control character
            strs << _pcd_box_char(opts[:pcd], lvl)

            # add pcd-operation string
            if opts[:pcd].is_a?(Symbol)
              # ╔ START ❯
              # └   END ❯
              strs << " #{opts[:pcd].to_s.upcase.rjust(5)} \u276F"
            end

            # check for tagged
            # ┄
            if opts[:tag]
              strs << _pcd_box_char(:__tagged__, lvl)
            else
              strs << ' '
            end

            # add data
            strs << data.to_s

            strs.join
          end

          # returns the processed box character for provided key and position.
          # returns the +:__default__+, if provided key was not found.
          # returns the max-pos char, if current pos was not found.
          # @param [Symbol] key
          # @param [Integer] pos
          # @return [String]
          def _pcd_box_char(key, pos = 0)
            chars = self.class.box_chars[key] || self.class.box_chars[:default]
            chars[pos] || chars[-1]
          end
        end
      end
    end
  end
end
