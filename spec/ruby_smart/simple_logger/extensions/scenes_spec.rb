# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Scenes extension" do
  describe '.scenes' do
    it 'returns a hash' do
      expect(RubySmart::SimpleLogger::Logger.scenes).to be_a Hash
    end
  end

  describe '.scene' do
    it 'creates a new scene' do
      expect{
        RubySmart::SimpleLogger::Logger.scene :spec_check do
          self.log 'SPEC-CHECK'
        end
      }.to change(RubySmart::SimpleLogger::Logger.scenes, :count)
      expect(RubySmart::SimpleLogger::Logger.scenes.keys).to include :spec_check
    end

    it 'blocks non severity methods' do
      res = nil
      expect{
        res = RubySmart::SimpleLogger::Logger.scene :theme do
          self.log 'SPEC-THEME'
        end
      }.to_not change(RubySmart::SimpleLogger::Logger.scenes, :count)
      expect(res).to eq false
    end
  end

  describe '#scenes' do
    it 'returns class scenes' do
      logger = RubySmart::SimpleLogger.new
      expect(logger.scenes).to eq RubySmart::SimpleLogger::Logger.scenes
    end
  end

  describe '#_scene_opts' do
    before :all do
      @logger = RubySmart::SimpleLogger.new
    end

    it 'resolves scene options' do
      expect(@logger.send(:_scene_opts, :info)).to eq({ level: :info, mask: { clr: :cyan }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] })
    end

    it 'merges scene options' do
      expect(@logger.send(:_scene_opts, :info, payload: [:_data], sub: :ject)).to eq({ level: :info, mask: { clr: :cyan }, payload: [:_data], sub: :ject })
    end
  end

  describe '.scene?' do
    it 'returns true' do
      expect(RubySmart::SimpleLogger::Logger.scene?(:info)).to eq true
    end

    it 'returns false' do
      expect(RubySmart::SimpleLogger::Logger.scene?(:unknown_scene)).to eq false
    end
  end
end