# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubySmart::SimpleLogger::Devices::ProcDevice do
  before do
    @devlogs = []
    @dev = RubySmart::SimpleLogger::Devices::ProcDevice.new(lambda{|data| @devlogs << "->#{data}<-"})
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
      }.to change(@devlogs, :count)
      expect(@devlogs.last).to eq '->some data<-'
    end

    it 'blocks on closed' do
      @dev.close

      expect {
        @dev.write 'some data'
      }.to_not change(@devlogs, :count)
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
end