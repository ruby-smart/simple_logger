# frozen_string_literal: false

module RubySmart
  module SimpleLogger
    module KlassLogger
      def self.extended(base)
        base.send(:include, RubySmart::SimpleLogger::Logger::Severity)
        base.class_eval do
          self.klass_logger_opts = {}
        end
      end

      def klass_logger_opts
        class_variable_get('@@klass_logger_opts')
      end

      def klass_logger_opts=(opts)
        clear!
        class_variable_set('@@klass_logger_opts', opts)
      end

      # delegate new method to logger
      def new(*args)
        args = [nil, self.klass_logger_opts.dup] if args.length == 0
        RubySmart::SimpleLogger::Logger.new(*args)
      end

      def klass_logger
        @klass_logger ||= self.new
      end

      def clear!
        @klass_logger = nil
      end

      def method_missing(name, *args, &block)
        return self.klass_logger.send(name, *args) if self.klass_logger.respond_to? name
        super
      end

      def respond_to?(method_name, _include_private = false)
        self.klass_logger.respond_to? method_name
      end
    end
  end
end
