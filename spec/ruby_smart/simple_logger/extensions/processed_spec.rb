# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Processed extension" do
  describe '#processed_lvl' do
    it 'returns default' do
      expect(RubySmart::SimpleLogger.new.processed_lvl).to eq -1
    end

    it 'returns current value' do
      logger = RubySmart::SimpleLogger.new :memory
      expect(logger.processed_lvl).to eq -1

      logger.instance_variable_set(:@processed_lvl, 10)
      expect(logger.processed_lvl).to eq 10
    end

    it 'increases' do
      logger = RubySmart::SimpleLogger.new :memory
      expect(logger.processed_lvl).to eq -1
      expect(logger.processed_lvl(:up)).to eq 0
      expect(logger.processed_lvl(:up)).to eq 1
      expect(logger.processed_lvl).to eq 1
    end

    it 'decreases' do
      logger = RubySmart::SimpleLogger.new :memory
      expect(logger.processed_lvl).to eq -1
      expect(logger.processed_lvl(:down)).to eq -1

      logger.instance_variable_set(:@processed_lvl, 6)

      expect(logger.processed_lvl(:down)).to eq 5
      expect(logger.processed_lvl(:down)).to eq 4
      expect(logger.processed_lvl).to eq 4
    end

    it 'resets' do
      logger = RubySmart::SimpleLogger.new :memory
      logger.instance_variable_set(:@processed_lvl, 6)

      expect(logger.processed_lvl(:reset)).to eq -1
    end
  end

  describe '#processed?' do
    it 'returns current processed state' do
      logger = RubySmart::SimpleLogger.new :memory
      expect(logger.processed?).to eq false

      logger.processed_lvl(:up)
      expect(logger.processed?).to eq true

      logger.processed_lvl(:down)
      expect(logger.processed?).to eq false
    end
  end

  describe '#_pcd' do
    it 'returns unprocessed data' do
      logger = RubySmart::SimpleLogger.new :memory
      data = {a: {simple: 'data', with: 83}}

      expect(logger.send(:_pcd, data, {})).to eq data

      logger.processed_lvl(:up)
      expect(logger.send(:_pcd, data, {pcd: false})).to eq data
    end

    it 'returns processed data' do
      logger = RubySmart::SimpleLogger.new :memory
      data = {a: {simple: 'data', with: 83}}

      logger.processed_lvl(:up)
      expect(logger.send(:_pcd, data, {})).to eq '╟ {:a=>{:simple=>"data", :with=>83}}'

      logger.processed_lvl(:up)
      expect(logger.send(:_pcd, data, {})).to eq '║ ├ {:a=>{:simple=>"data", :with=>83}}'

      logger.processed_lvl(:up)
      expect(logger.send(:_pcd, data, {})).to eq '║ │ ├ {:a=>{:simple=>"data", :with=>83}}'
    end

    it 'returns processed data with char' do
      logger = RubySmart::SimpleLogger.new :memory
      data = "test"

      logger.processed_lvl(:up)
      expect(logger.send(:_pcd, data, {pcd: :start})).to eq "╔ START ❯ test"

      logger.processed_lvl(:up)
      expect(logger.send(:_pcd, data, {pcd: :start})).to eq "║ ┌ START ❯ test"
      expect(logger.send(:_pcd, data, {pcd: :start, lvl: 0})).to eq "╔ START ❯ test"

      expect(logger.send(:_pcd, data, {pcd: :end})).to eq "║ └   END ❯ test"
    end
  end

  describe '#_pcd_box_char' do
    it 'returns default chars' do
      logger = RubySmart::SimpleLogger.new :memory
      expect(logger.send(:_pcd_box_char, nil, 0)).to eq '╟'
      expect(logger.send(:_pcd_box_char, nil, 1)).to eq '├'
      expect(logger.send(:_pcd_box_char, nil, 2)).to eq '├'
      expect(logger.send(:_pcd_box_char, :unknown, 10)).to eq '├'
    end

    it 'returns start char' do
      logger = RubySmart::SimpleLogger.new :memory
      expect(logger.send(:_pcd_box_char, :start, 0)).to eq '╔'
      expect(logger.send(:_pcd_box_char, :start, 1)).to eq '┌'
      expect(logger.send(:_pcd_box_char, :start, 2)).to eq '┌'
    end

    it 'returns end char' do
      logger = RubySmart::SimpleLogger.new :memory
      expect(logger.send(:_pcd_box_char, :end, 0)).to eq '╚'
      expect(logger.send(:_pcd_box_char, :end, 1)).to eq '└'
      expect(logger.send(:_pcd_box_char, :end, 2)).to eq '└'
    end
  end
end