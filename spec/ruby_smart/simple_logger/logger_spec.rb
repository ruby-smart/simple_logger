# frozen_string_literal: false

require 'spec_helper'

RSpec.describe RubySmart::SimpleLogger::Logger do
  before do
    @logger = RubySmart::SimpleLogger.new
  end

  describe '#initialize' do
    it 'initializes with opts' do
      l = RubySmart::SimpleLogger.new :stdout, level: :debug, format: :passthrough, clr: false, nl: true
      expect(l.level).to eq RubySmart::SimpleLogger::Logger::DEBUG
      expect(l.formatter.instance_variable_get(:@opts)).to eq({clr: false, format: :passthrough, nl: true})
    end

    it 'initializes with multiple' do
      l = RubySmart::SimpleLogger.new :memory, :stdout
      expect(l.logdev).to be_a RubySmart::SimpleLogger::Devices::MultiDevice
    end

    it 'initializes with multiple & opts' do
      l = RubySmart::SimpleLogger.new :memory, :stdout, level: :debug, format: :passthrough, clr: false, nl: true
      expect(l.logdev).to be_a RubySmart::SimpleLogger::Devices::MultiDevice
      expect(l.formatter.instance_variable_get(:@opts)).to eq({clr: false, format: :passthrough, nl: true})
    end
  end

  describe '#level' do
    it 'should be debug as default' do
      expect(@logger.level).to eq RubySmart::SimpleLogger::Logger::DEBUG
    end

    it 'should fallback to unknown' do
      @logger.level = :totally_wrong
      expect(@logger.level).to eq RubySmart::SimpleLogger::Logger::UNKNOWN
    end

    it 'should accept symbols' do
      @logger.level = :success
      expect(@logger.level).to eq 1.1
    end

    it 'should accept strings' do
      @logger.level = "ERROR"
      expect(@logger.level).to eq 3
    end

    it 'should accept numeric' do
      @logger.level = 2
      expect(@logger.level).to eq 2
    end
  end

  describe '#formatter' do
    it 'has a simple_logger formatter' do
      expect(@logger.formatter).to be_a RubySmart::SimpleLogger::Formatter
    end

    it 'uses plain as default' do
      expect(RubySmart::SimpleLogger.new('custom.log').formatter.opts[:format]).to eq :plain
    end
  end

  describe '#logdev' do
    it 'is accessible' do
      expect(@logger.logdev).to be
    end
  end

  describe '#mask' do
    it 'has a default mask' do
      expect(@logger.mask).to eq({char:"=", length: 100, clr: :blue})
    end
  end
end