# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "SimpleLog extension" do
  before do
    @logger = RubySmart::SimpleLogger.new device: RubySmart::SimpleLogger::Devices::MemoryDevice.new
  end

  describe '#simple_log' do
    it 'logs' do
      expect(@logger.log('ok')).to eq true
      expect(@logger.success('ok')).to eq true
    end

    it 'prevents log on level' do
      @logger.level = :error
      expect(@logger.warn('ok')).to eq false
      expect(@logger.success('ok')).to eq false
      expect(@logger.error('ok')).to eq true
    end

    it 'prevents log on nil data' do
      logger2 = RubySmart::SimpleLogger.new :memory
      expect(logger2.success('ok')).to eq true
      expect(logger2.theme('theme')).to eq false
    end
  end

  describe '#_parse_payload' do
    it 'transforms hash' do
      expect(@logger.send(:_parse_payload,{'pay' => 'load'}, {})).to eq 'pay'
    end

    it 'prevent type case' do
      expect(@logger.send(:_parse_payload,['This is my payload'], {})).to eq 'This is my payload'
    end

    it 'parses mask' do
      expect(@logger.send(:_parse_payload,[:mask, ' [%{subject}] '], {subject: 'Intros', mask: {length: 20, char: '-', clr: nil}})).to eq '----- [Intros] -----'

      # oversize
      expect(@logger.send(:_parse_payload,[:mask, ' [%{subject}] '], {subject: 'Oversized subject length', mask: {length: 20, char: '-', clr: nil}})).to eq '- [Oversized subj] -'

      # colored text
      expect(@logger.send(:_parse_payload,[:mask, ' [%{subject}] '], {subject: "This \e[1;36mtext\e[0m is colored", mask: {length: 40, char: '-', clr: nil}})).to eq '-------- [This text is colored] --------'

      # nested
      expect(@logger.send(:_parse_payload,[:mask, {concat: ['a & ',[:txt, 'Lorem ipsum dolor sit amet']]}], {mask: {length: 40, char: '-', clr: nil}, length: 20})).to eq '----------a & Lorem ipsum dolo----------'
    end

    it 'parses txt' do
      expect(@logger.send(:_parse_payload,[:txt, 'Lorem ipsum dolor sit amet'], {clr: :red, length: 15})).to eq "\e[1;31mLorem ipsum dol\e[0m"
      # with wildcards
      expect(@logger.send(:_parse_payload,[:txt, 'Lorem ipsum dolor sit amet - %{additional}'], {additional: 'at vero eos et accusam'})).to eq 'Lorem ipsum dolor sit amet - at vero eos et accusam'
    end

    it 'parses concat' do
      expect(@logger.send(:_parse_payload,[:concat, ['some text A ', '- with text B', [:mask]]],{mask: {length: 10, char: '#'}})).to eq "some text A - with text B\e[1;34m##########\e[0m"
    end

    it 'parses blank' do
      expect(@logger.send(:_parse_payload,[:blank],{})).to eq ""
      expect(@logger.send(:_parse_payload,[:blank,"string"],{})).to eq ""
    end

    it 'parses unknown' do
      expect(@logger.send(:_parse_payload,[:unknown_key,"string"],{})).to eq "string"
      expect(@logger.send(:_parse_payload,[:unknown_key,::RubySmart::SimpleLogger],{})).to eq "RubySmart::SimpleLogger"
    end
  end

  describe '#inspector' do
    it 'stores inspector method' do
      expect(@logger.instance_variable_get('@inspector')).to be_nil
      @logger.inspector

      expect(@logger.instance_variable_get('@inspector')).to_not be_nil
    end

    it 'resolves from class' do
      expect(@logger.class.inspector).to eq :auto

      @logger.class.inspector = :to_s
      expect(@logger.class.inspector).to eq :to_s
      expect(@logger.inspector).to eq :to_s

      @logger.class.inspector = :inspect
      # still stored in object ...
      expect(@logger.inspector).to eq :to_s

      @logger.class.inspector = nil
      @logger.instance_variable_set("@inspector", nil)
      expect(@logger.inspector).to eq :inspect
    end

    it 'resolves from awesome_print' do
      Object.class_eval do
        def ai
          "ok"
        end
      end

      @logger.class.inspector = :auto
      @logger.instance_variable_set("@inspector", nil)
      expect(@logger.inspector).to eq :ai
    end
  end
end