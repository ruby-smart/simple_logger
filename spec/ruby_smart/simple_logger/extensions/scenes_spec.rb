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

    # skip, since this will affect the original method and reduces coverage
    xit 'overwrites a existing severity scene' do
      res = nil
      expect{
        res = RubySmart::SimpleLogger::Logger.scene :unknown do
          self.log 'My SPEC NEW'
        end
      }.to_not change(RubySmart::SimpleLogger::Logger.scenes, :count)
      expect(res).to eq true

      # restore orig
      RubySmart::SimpleLogger::Logger.scene :unknown, { level: :unknown, mask: { clr: :gray }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] } do |data, subject = 'Unknown', opts = {}|
        self.log data, _scene_opt(:unknown, { subject: subject }, opts)
      end
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

  describe '#_scene_opt' do
    before :all do
      @logger = RubySmart::SimpleLogger.new
    end

    it 'resolves scene options' do
      expect(@logger.send(:_scene_opt, :info)).to eq({ level: :info, mask: { clr: :cyan }, payload: [[:mask, ' [%{subject}] '], :__data__, :mask] })
    end

    it 'merges scene options' do
      expect(@logger.send(:_scene_opt, :info, payload: [:_data], sub: :ject)).to eq({ level: :info, mask: { clr: :cyan }, payload: [:_data], sub: :ject })
    end
  end
end