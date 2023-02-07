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
      expect(@formatter.formats.values[0]).to be_a Proc
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
      format = @formatter.send(:current_formatter)
      expect(@formatter.send(:current_formatter)).to be format

      @formatter.opts(format: :plain)
      expect(@formatter.send(:current_formatter)).to_not be format
    end
  end

  describe '#clear!' do
    it 'resets current_format' do
      @formatter.send(:current_formatter)
      expect(@formatter.instance_variable_get(:@current_formatter)).to be

      @formatter.clear!
      expect(@formatter.instance_variable_get(:@current_formatter)).to_not be
    end
  end

  describe '#data2array' do
    it 'always returns an array' do
      expect(@formatter.send(:data2array, nil)).to be_a Array
      expect(@formatter.send(:data2array, [])).to be_a Array
      expect(@formatter.send(:data2array, '')).to be_a Array
    end

    it 'transforms array' do
      expect(@formatter.send(:data2array,[{a: ['nested', 'data']}])).to eq ["{:a=>[\"nested\", \"data\"]}"]
      expect(@formatter.send(:data2array,["some text with \nline breaks", "other text with\nline breaks"])).to eq ["some text with ", "line breaks", "other text with", "line breaks"]
    end

    it 'converts exception array' do
      expect(@formatter.send(:data2array, Exception.new('no methods available'))).to eq ["exception: Exception","no methods available"]
    end
  end

  describe '#format' do
    it 'formats args' do
      expect(@formatter.send(:format, '%s - special format %s', 'a','b')).to eq 'a - special format b'
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

  describe '#data2datalog' do
    it 'converts string' do
      expect(@formatter.send(:data2datalog, 'str')).to eq 'str'
    end

    it 'joins array' do
      expect(@formatter.send(:data2datalog, ['str','with','what'])).to eq "str] [with] [what"
    end

    it 'converts exception array' do
      expect(@formatter.send(:data2datalog, Exception.new('no methods available'))).to eq "exception: Exception] [no methods available"
    end

    it 'inspects others' do
      expect(@formatter.send(:data2datalog, ::RubySmart::SimpleLogger)).to eq "RubySmart::SimpleLogger"
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
      expect(@formatter.('WARN', @dt, nil, {a: 1, b: '2', c: :_3})).to eq("{:a=>1, :b=>\"2\", :c=>:_3}")
      expect(@formatter.('WARN', @dt, nil, RubySmart::SimpleLogger::Formatter.new)).to include 'RubySmart::SimpleLogger::Formatter'
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
      expect(@formatter.('SUCCESS', @dt, nil, 'At vero')).to eq "[##{$$}] [2021-11-21 12:10:39] [SUCCESS] [At vero]\n"
      @formatter.opts(nl: false)
      expect(@formatter.('WARN', @dt, nil, ['str','with','what'])).to eq "[##{$$}] [2021-11-21 12:10:39] [WARN] [str] [with] [what]"
    end
  end

  describe '#_nl' do
    it 'returns with newline' do
      f = RubySmart::SimpleLogger::Formatter.new nl: true, format: :plain
      expect(f.('SUCCESS', @dt, nil, 'A text with auto-newline')).to eq "A text with auto-newline\n"
    end

    it 'returns without newline' do
      f = RubySmart::SimpleLogger::Formatter.new nl: false, format: :plain
      expect(f.('SUCCESS', @dt, nil, 'A text with auto-newline')).to eq "A text with auto-newline"
    end
  end

  describe '#_clr' do
    it 'returns colorized text' do
      f = RubySmart::SimpleLogger::Formatter.new clr: true, format: :plain
      expect(f.send(:_clr, 'Some text'.purple, 'SUCCESS')).to eq "\e[1;32m\e[1;35mSome text\e[0m\e[0m"
      expect(f.send(:_clr, 'Some text', 'ERROR')).to eq "\e[1;31mSome text\e[0m"
    end

    it 'returns decolorized text' do
      f = RubySmart::SimpleLogger::Formatter.new clr: false, format: :plain
      expect(f.send(:_clr, 'Some text'.purple, 'SUCCESS')).to eq "Some text"
      expect(f.send(:_clr, 'Some text', 'ERROR')).to eq "Some text"
    end
  end

  describe '#_declr' do
    it 'returns colorized text' do
      f = RubySmart::SimpleLogger::Formatter.new clr: true, format: :plain
      expect(f.send(:_declr, 'Some text'.purple)).to eq "\e[1;35mSome text\e[0m"
      expect(f.send(:_declr, 'Some text')).to eq "Some text"
    end

    it 'returns decolorized text' do
      f = RubySmart::SimpleLogger::Formatter.new clr: false, format: :plain
      expect(f.send(:_declr, 'Some text'.purple)).to eq "Some text"
      expect(f.send(:_declr, 'Some text')).to eq "Some text"
    end
  end
end