# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Timer extension" do
  before do
    @logger = RubySmart::SimpleLogger.new :memory
  end

  describe '#timer' do
    it 'does not react to unknown action' do
      expect(@logger.timer(nil)).to be_nil
      expect(@logger.timer(:unknown)).to be_nil
    end
  end

  describe 'restarts' do
    it 'new timer' do
      expect(@logger.timer(:restart, :t0_1)).to be true
    end

    it 'running timer' do
      expect(@logger.timer(:restart, :t0_2)).to be true
      sleep 0.05
      tmp = @logger.timer(:current, :t0_2)
      expect(tmp).to be > 0
      expect(@logger.timer(:restart, :t0_2)).to be true
      expect(@logger.timer(:current, :t0_2)).to be < tmp
    end

    it 'stopped timer' do
      expect(@logger.timer(:restart, :t0_3)).to be true
      sleep 0.05
      expect(@logger.timer(:stop, :t0_3)).to be true

      tmp = 0
      expect{
        tmp = @logger.timer(:current, :t0_3)
      }.to_not change{
        @logger.timer(:current, :t0_3)
      }
      expect(@logger.timer(:restart, :t0_3)).to be true
      expect(@logger.timer(:current, :t0_3)).to be < tmp
    end
  end

  describe 'starts' do
    it 'new timer' do
      expect(@logger.timer(:start, :t1)).to be true
    end

    it 'running timer' do
      expect(@logger.timer(:start, :t2)).to be true
      tmp = 0
      expect{
        sleep 0.05
        tmp = @logger.timer(:current, :t2)
      }.to change{
        @logger.timer(:current, :t2)
      }

      expect(@logger.timer(:start, :t2)).to be true
      expect(@logger.timer(:current, :t2)).to be < tmp
    end
  end

  describe 'stops' do
    it 'running timer' do
      expect(@logger.timer(:start, :t3)).to be true
      expect(@logger.timer(:stop, :t3)).to be true
      expect(@logger.timer(:current, :t3)).to be > 0
    end

    it 'cannot for missing timer' do
      expect(@logger.timer(:stop, :t4)).to be false
    end

    it 'cannot for already stopped timer' do
      expect(@logger.timer(:start, :t5)).to be true
      expect(@logger.timer(:stop, :t5)).to be true
      expect(@logger.timer(:stop, :t5)).to be false
    end
  end

  describe 'pauses' do
    it 'running timer' do
      expect(@logger.timer(:start, :t6)).to be true
      expect(@logger.timer(:pause, :t6)).to be true

      expect{
        @logger.timer(:current, :t6)
      }.to_not change{
        @logger.timer(:current, :t6)
      }
    end

    it 'cannot for missing timer' do
      expect(@logger.timer(:pause, :t7)).to be false
    end

    it 'cannot for already stopped timer' do
      expect(@logger.timer(:start, :t8)).to be true
      expect(@logger.timer(:stop, :t8)).to be true
      expect(@logger.timer(:pause, :t8)).to be false
    end
  end

  describe 'continues' do
    it 'paused timer' do
      expect(@logger.timer(:start, :t9)).to be true
      expect(@logger.timer(:pause, :t9)).to be true

      tmp = 0
      expect{
        tmp = @logger.timer(:current, :t9)
      }.to_not change{
        @logger.timer(:current, :t9)
      }

      expect(@logger.timer(:continue, :t9)).to be true

      expect{
        @logger.timer(:current, :t9)
      }.to change{
        @logger.timer(:current, :t9)
      }

      expect(@logger.timer(:current, :t9)).to be > tmp
    end
  end

  describe 'clears' do
    it 'unknown timer' do
      expect(@logger.timer(:clear, :t10)).to eq 0
    end

    it 'stopped timer' do
      expect(@logger.timer(:start, :t11)).to be true
      expect(@logger.timer(:stop, :t11)).to be true
      expect(@logger.timer(:clear, :t11)).to be > 0
    end

    it 'paused timer' do
      expect(@logger.timer(:start, :t12)).to be true
      expect(@logger.timer(:pause, :t12)).to be true
      expect(@logger.timer(:clear, :t12)).to be > 0
    end

    it 'running timer' do
      expect(@logger.timer(:start, :t13)).to be true
      expect(@logger.timer(:clear, :t13)).to be > 0
    end
  end
end