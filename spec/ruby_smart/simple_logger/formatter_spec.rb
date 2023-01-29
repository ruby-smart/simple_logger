# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubySmart::SimpleLogger::Formatter do
  before do
    @formatter = RubySmart::SimpleLogger::Formatter.new
    @dt = DateTime.parse('2021-11-21 12:10:39')
  end

  describe 'defaults' do
    it 'has' do
      expect(@formatter.opts).to eq({nl: true, format: :default})
    end
  end

  describe '#formats' do
    it 'returns class formats' do
      expect(@formatter.formats).to be_a Hash
      expect(@formatter.formats.values[0].keys).to eq [:str, :cb]
    end
  end

  describe '#opts' do
    it 'returns opts' do
      expect(@formatter.opts).to be_a Hash
    end

    it 'merges opts' do
      expect(@formatter.opts).to eq({nl: true, format: :default})

      @formatter.opts(nl: false)
      expect(@formatter.opts).to eq({nl: false, format: :default})
    end

    it 'resets current_format' do
      format = @formatter.send(:current_format)
      expect(@formatter.send(:current_format)).to be format

      @formatter.opts(format: :plain)
      expect(@formatter.send(:current_format)).to_not be format
    end
  end

  describe '#clear!' do
    it 'resets current_format' do
      @formatter.send(:current_format)
      expect(@formatter.instance_variable_get(:@current_format)).to be

      @formatter.clear!
      expect(@formatter.instance_variable_get(:@current_format)).to_not be
    end
  end

  describe '#current_format_cb' do
    it 'returns current_format cb' do
      expect(@formatter.send(:current_format_cb)).to be_a Proc
    end

    it 'sets current_format' do
      expect(@formatter.instance_variable_get(:@current_format)).to be_nil
      @formatter.send(:current_format_cb)
      expect(@formatter.instance_variable_get(:@current_format)).to be
    end
  end

  describe '#current_format_str' do
    it 'returns current_format str' do
      expect(@formatter.send(:current_format_str)).to be_a String
    end

    it 'sets current_format' do
      expect(@formatter.instance_variable_get(:@current_format)).to be_nil
      @formatter.send(:current_format_str)
      expect(@formatter.instance_variable_get(:@current_format)).to be
    end
  end

  describe '#format_datetime' do
    it 'returns long time string' do
      expect(@formatter.send(:format_datetime, @dt)).to eq '2021-11-21T12:10:39.000000'
    end

    it 'returns short time string' do
      expect(@formatter.send(:format_datetime, @dt, true)).to eq '2021-11-21 12:10:39'
    end
  end

  describe '#msg2str' do
    it 'converts string' do
      expect(@formatter.send(:msg2str, 'str')).to eq 'str'
    end

    it 'converts array' do
      expect(@formatter.send(:msg2str, ['str','with','what'])).to eq '["str", "with", "what"]'
    end

    it 'joins array' do
      expect(@formatter.send(:msg2str, ['str','with','what'], true)).to eq 'str] [with] [what'
    end

    it 'converts exception array' do
      expect(@formatter.send(:msg2str, Exception.new('no methods available'))).to eq "no methods available (Exception)\n"
    end

    it 'inspects others' do
      expect(@formatter.send(:msg2str, ::RubySmart::SimpleLogger)).to eq "RubySmart::SimpleLogger"
    end
  end

  describe '#call' do
    it 'formats default message with nl' do
      expect(@formatter.('ERROR', @dt, nil, 'sed diam nonumy eirmod tem')).to eq "E, [2021-11-21T12:10:39.000000 ##{$$}]   ERROR -- : sed diam nonumy eirmod tem\n"
    end

    it 'formats default message' do
      @formatter.opts(nl: false)
      expect(@formatter.('SUCCESS', @dt, nil, 'At vero eos et accusam et justo duo dolores')).to eq "S, [2021-11-21T12:10:39.000000 ##{$$}] SUCCESS -- : At vero eos et accusam et justo duo dolores"
    end

    it 'formats plain' do
      @formatter.opts(nl: false, format: :plain)
      expect(@formatter.('SUCCESS', @dt, nil, 'At vero')).to eq "At vero"
      expect(@formatter.('WARN', @dt, nil, {a: 1, b: '2', c: :_3})).to eq({a: 1, b: '2', c: :_3})
      expect(@formatter.('WARN', @dt, nil, RubySmart::SimpleLogger::Formatter.new)).to be_a RubySmart::SimpleLogger::Formatter
    end

    it 'formats passthrough' do
      @formatter.opts(format: :passthrough)
      expect(@formatter.('SUCCESS', @dt, nil, 'At vero')).to eq ['SUCCESS', @dt, nil, 'At vero']
      expect(@formatter.('WARN', @dt, nil, {a: 1, b: '2', c: :_3})).to eq(['WARN', @dt, nil, {a: 1, b: '2', c: :_3}])
    end

    it 'formats tmp' do
      @formatter.opts(format: :memory)
      expect(@formatter.('SUCCESS', @dt, nil, 'At vero')).to eq [:success, @dt, 'At vero']
      expect(@formatter.('WARN', @dt, nil, {a: 1, b: '2', c: :_3})).to eq([:warn, @dt,{a: 1, b: '2', c: :_3}])
    end

    it 'formats datalog' do
      @formatter.opts(format: :datalog)
      expect(@formatter.('SUCCESS', @dt, nil, 'At vero')).to eq "[SUCCESS] [2021-11-21 12:10:39] [##{$$}] [At vero]\n"
      @formatter.opts(nl: false)
      expect(@formatter.('WARN', @dt, nil, ['str','with','what'])).to eq "[   WARN] [2021-11-21 12:10:39] [##{$$}] [str] [with] [what]"
    end
  end
end