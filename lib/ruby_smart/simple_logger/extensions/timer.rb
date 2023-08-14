# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Extensions
      module Timer
        def timer(action, key = :default, opts = {})
          return if key.nil?

          @timers      ||= {}
          @timers[key] ||= {
            start:   nil,
            stop:    nil,
            total: 0
          }

          case action
          when :start, :restart
            @timers[key][:start]   = Time.now
            @timers[key][:stop]    = nil
            @timers[key][:total] = 0

            true
          when :continue
            @timers[key][:start] = Time.now
            @timers[key][:stop]  = nil

            true
          when :stop
            return false if !@timers[key][:start] || @timers[key][:stop]
            @timers[key][:stop]    = Time.now
            @timers[key][:total] += @timers[key][:stop] - @timers[key][:start]

            true
          when :pause
            return false if !@timers[key][:start] || @timers[key][:stop]

            @timers[key][:total] += Time.now - @timers[key][:start]
            @timers[key][:start]   = nil
            @timers[key][:stop]    = nil

            true
          when :clear
            self.timer(:stop, key)
            current = self.timer(:current, key)
            @timers.delete(key)

            # time_ago_in_words in only available if activesupport & actionview gems are loaded
            if opts[:humanized] && respond_to?(:time_ago_in_words)
              time_ago_in_words(current.to_i.seconds.from_now, include_seconds: true)
            else
              current
            end
          when :current
            current = @timers[key][:total]
            current += Time.now - @timers[key][:start] if @timers[key][:start] && @timers[key][:stop].nil?
            current
          else
            nil
          end
        end
      end
    end
  end
end