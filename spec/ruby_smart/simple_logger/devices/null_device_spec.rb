# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubySmart::SimpleLogger::Devices::NullDevice do
  before do
    @dev = RubySmart::SimpleLogger::Devices::NullDevice.new
  end

  describe '#logs' do
    it 'returns an empty array' do
      expect(@dev.logs).to eq []
    end
  end

  describe '#status' do
    it 'to be true' do
      expect(@dev.status).to be true
    end
  end

  describe '#write' do
    it 'writes null data' do
      expect {
        @dev.write 'some data'
      }.to_not change(@dev.logs, :count)
      expect(@dev.logs.count).to eq 0
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
      expect(@dev.logs.count).to eq 0
      @dev.clear!
      expect(@dev.logs.count).to eq 0
    end
  end
end