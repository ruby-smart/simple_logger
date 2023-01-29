# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Severity extension" do

  before :all do
    @logger = RubySmart::SimpleLogger.new
  end

  describe '#format_severity' do
    it 'formats numeric to string' do
      expect(@logger.send(:format_severity, 1.1)).to eq 'SUCCESS'
    end

    it 'returns unknown' do
      expect(@logger.send(:format_severity, 99)).to eq 'UNKNOWN'
    end
  end

  describe '#_level' do
    it 'returns nil' do
      expect(@logger.send(:_level, nil)).to eq 5
    end

    it 'returns unknown' do
      expect(@logger.send(:_level, "nothing here")).to eq 5
    end

    it 'returns for numeric' do
      expect(@logger.send(:_level, 3)).to eq 3
    end

    it 'returns for string' do
      expect(@logger.send(:_level, 'error')).to eq 3
    end

    it 'returns for symbol' do
      expect(@logger.send(:_level, :warn)).to eq 2
    end
  end
end