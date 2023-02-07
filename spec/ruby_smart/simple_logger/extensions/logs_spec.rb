# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Logs extension" do
  before do
    @logger = RubySmart::SimpleLogger.new :memory
  end

  describe '#logs' do
    it 'returns logs' do
      @logger.info "start"
      @logger.error "not allowed"
      @logger.info "done"

      expect(@logger.logs).to be_a Array
      expect(@logger.logs.map{|log| log[2]}).to eq ["start", "not allowed", "done"]
    end

    it 'returns a empty array' do
      logger2 = RubySmart::SimpleLogger.new
      expect(logger2.logs).to eq []
    end
  end

  describe '#logs_to_h' do
    it 'returns grouped logs' do
      @logger.info "start"
      @logger.error "not allowed"
      @logger.info "done"

      expect(@logger.logs_to_h).to eq({info: ['start', 'done'], error: ['not allowed']})
    end

    it 'returns a empty hash' do
      logger2 = RubySmart::SimpleLogger.new
      expect(logger2.logs_to_h).to eq({})
    end
  end

  describe '#log_stats' do
    it 'returns stats hash' do
      @logger.info "start"
      @logger.error "not allowed"
      @logger.info "done"

      expect(@logger.log_stats).to eq({info: 2, error: 1})
    end
  end
end