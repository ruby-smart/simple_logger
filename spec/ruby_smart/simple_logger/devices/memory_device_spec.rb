# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubySmart::SimpleLogger::Devices::MemoryDevice do
  before do
    @dev = RubySmart::SimpleLogger::Devices::MemoryDevice.new
  end

  describe '#logs' do
    it 'returns an array' do
      expect(@dev.logs).to be_a Array
    end
  end

  describe '#status' do
    it 'to be true' do
      expect(@dev.status).to be true
    end
  end

  describe '#write' do
    it 'writes data' do
      expect {
        @dev.write 'some data'
      }.to change(@dev.logs, :count)
      expect(@dev.logs.last).to eq 'some data'
    end

    it 'blocks on closed' do
      @dev.close

      expect {
        @dev.write 'some data'
      }.to_not change(@dev.logs, :count)
      expect(@dev.status).to be false
    end
  end

  describe '#close' do
    it 'closes' do
      expect(@dev.status).to eq true
      expect(@dev.close).to eq false
    end
  end

  describe '#reopen' do
    it 'reopens' do
      @dev.close
      expect(@dev.status).to eq false
      expect(@dev.reopen).to eq true
    end
  end

  describe '#clear!' do
    it 'clears logs' do
      @dev.write 'some data'
      expect(@dev.logs.count).to eq 1
      @dev.clear!
      expect(@dev.logs.count).to eq 0
    end
  end
end