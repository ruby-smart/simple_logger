# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubySmart::SimpleLogger::KlassLogger do
  before :all do
    # need to extend manually after we loaded the SimpleLogger libs
    Dummy::Logger.extend!
  end

  describe 'severity' do
    it 'has' do
      expect(Dummy::Logger::DEBUG).to eq 0
    end
  end

  describe '.new' do
    it 'creates a new instance' do
      expect(Dummy::Logger.new).to be_a RubySmart::SimpleLogger::Logger
    end
  end

  describe '.klass_logger' do
    it 'stores a logger' do
      expect(Dummy::Logger.klass_logger).to be_a RubySmart::SimpleLogger::Logger
      logger = Dummy::Logger.klass_logger
      expect(Dummy::Logger.klass_logger).to be logger
    end
  end

  describe '.clear!' do
    it 'clears a logger' do
      expect(Dummy::Logger.klass_logger).to be
      expect(Dummy::Logger.instance_variable_get(:@klass_logger)).to be
      Dummy::Logger.clear!
      expect(Dummy::Logger.instance_variable_get(:@klass_logger)).to be_nil
    end
  end

  describe 'scenes' do
    it 'delegates scene methods' do
      expect(Dummy::Logger.respond_to?(:info)).to be true

      Dummy::Logger.overwrite!
      expect(Dummy::Logger.debug(:debug)).to be true
    end


    describe 'delegates error' do
      it 'calls error' do
        expect(Dummy::Logger.error("some test")).to eq true
      end

      it 'calls error with subject & opts' do
        expect(Dummy::Logger.error("some test", "subject", payload: false)).to eq true
      end


      it 'calls error with opts only' do
        expect(Dummy::Logger.error("some test", payload: false)).to eq true
      end

      it 'calls error with exception' do
        expect{
          Dummy::Logger.error("some test", "subject", "other param", payload: false)
        }.to raise_error(ArgumentError)
      end
    end

    it 'delegates other methods' do
      expect{
        Dummy::Logger.unknown_method
      }.to raise_error(NoMethodError)
    end
  end
end