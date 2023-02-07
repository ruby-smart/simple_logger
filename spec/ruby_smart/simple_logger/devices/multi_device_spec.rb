# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubySmart::SimpleLogger::Devices::MultiDevice do
  before do
    @receiver1 = RubySmart::SimpleLogger::Devices::MemoryDevice.new
    @receiver2 = RubySmart::SimpleLogger::Devices::MemoryDevice.new
    @receiver3 = RubySmart::SimpleLogger::Devices::MemoryDevice.new
    @dev = RubySmart::SimpleLogger::Devices::MultiDevice.
      register(@receiver1).
      register(@receiver2, RubySmart::SimpleLogger::Formatter.new(format: :datalog)).
      register(@receiver3, RubySmart::SimpleLogger::Formatter.new(format: :plain))
  end

  describe '#status' do
    it 'to be true' do
      expect(@dev.status).to be true
    end
  end

  describe '#write' do
    it 'writes data' do
      time = Time.parse('2021-11-25 23:00:47')
      expect {
        @dev.write ['ERROR', time, nil, 'some data']
      }.to change(@receiver1.logs, :count)
      expect(@receiver1.logs[-1]).to eq ['ERROR', time, nil, 'some data']
      expect(@receiver2.logs[-1]).to eq "[##{$$}] [2021-11-25 23:00:47] [ERROR] [some data]\n"
      expect(@receiver3.logs[-1]).to eq "some data\n"
    end

    it 'blocks on closed' do
      @dev.close

      expect {
        @dev.write ['ERROR', Time.now, nil, 'some data']
      }.to_not change(@receiver1.logs, :count)
      expect(@dev.status).to be false

      @dev.reopen
    end
  end

  describe '#close' do
    it 'closes' do
      expect(@dev.status).to eq true
      expect(@dev.close).to eq false
      @dev.reopen
    end
  end

  describe '#reopen' do
    it 'reopens' do
      @dev.close
      expect(@dev.status).to eq false
      expect(@dev.reopen).to eq true
    end
  end

  describe '#logs' do
    it 'find logs from loggable device' do
      @dev.write ['ERROR', Time.now, nil, 'some data']

      expect(@dev.logs).to be_a Array
      expect(@dev.logs).to eq @receiver1.logs
      expect(@dev.logs).to_not eq @receiver2.logs
    end
  end

  describe '#clear!' do
    it 'clears devices' do
      dev = RubySmart::SimpleLogger::Devices::MultiDevice.new.
        register(@receiver1).register(@receiver2)

      expect(dev.devices.count).to eq 2
      dev.clear!
      expect(dev.devices.count).to eq 0
    end
  end
end