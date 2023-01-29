# frozen_string_literal: true

module RubySmart
  module SimpleLogger
    module Extensions
      module Timer
        def timer(action, key = :default, opts = {})
          @timers      ||= {}
          @timers[key] ||= {
            start:   nil,
            stop:    nil,
            measure: 0
          }

          case action
          when :restart
            @timers[key][:start]   = Time.now
            @timers[key][:stop]    = nil
            @timers[key][:measure] = 0

            true
          when :start, :continue
            @timers[key][:start] = Time.now
            @timers[key][:stop]  = nil

            true
          when :stop
            return false if !@timers[key][:start] || @timers[key][:stop]
            @timers[key][:stop]    = Time.now
            @timers[key][:measure] += @timers[key][:stop] - @timers[key][:start]

            true
          when :pause
            return false if !@timers[key][:start] || @timers[key][:stop]

            @timers[key][:measure] += Time.now - @timers[key][:start]
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
            current = @timers[key][:measure]
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