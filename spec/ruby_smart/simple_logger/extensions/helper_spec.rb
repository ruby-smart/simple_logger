# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Helper extension" do
  before :all do
    @logger = RubySmart::SimpleLogger.new
  end

  describe 'builtin' do
    describe 'nil' do
      it 'uses optimal device' do
        expect(@logger.logdev).to be
        expect(@logger.logdev).to_not be_nil
      end
    end

    describe 'proc' do
      it 'uses proc' do
        logger = RubySmart::SimpleLogger.new :proc, proc: lambda { |_data| }

        expect(logger.formatter.opts[:format]).to eq :passthrough
        expect(logger.formatter.opts[:nl]).to eq false
        expect(logger.ignore_payload?).to eq true
        expect(logger.logdev).to be_a RubySmart::SimpleLogger::Devices::ProcDevice
      end

      it 'can use provided device' do
        logger = RubySmart::SimpleLogger.new Proc.new { |_data| }
        expect(logger.logdev).to be_a RubySmart::SimpleLogger::Devices::ProcDevice
      end
    end

    describe 'string' do
      it 'can use provided file' do
        logger = RubySmart::SimpleLogger.new 'builtins_spec.log'
        expect(logger.logdev.dev).to be_a ::File
        expect(logger.logdev.dev.path).to eq 'log/builtins_spec.log'
      end

      it 'adds missing extension' do
        logger = RubySmart::SimpleLogger.new 'custom'
        expect(logger.logdev.dev).to be_a ::File
        expect(logger.logdev.dev.path).to eq 'log/custom.log'
      end
    end

    describe 'tmp' do
      it 'uses tmp specs' do
        logger = RubySmart::SimpleLogger.new :memory

        expect(logger.formatter.opts[:format]).to eq :memory
        expect(logger.ignore_payload?).to eq true
      end

      it 'uses MultiDevice with stdout' do
        logger = RubySmart::SimpleLogger.new :memory, stdout: true

        expect(logger.formatter.opts[:format]).to eq :passthrough
        expect(logger.logdev).to be_a RubySmart::SimpleLogger::Devices::MultiDevice
        expect(logger.ignore_payload?).to eq true
      end

      it 'uses MultiDevice with memory' do
        logger = RubySmart::SimpleLogger.new RubySmart, memory: true

        expect(logger.formatter.opts[:format]).to eq :passthrough
        expect(logger.logdev).to be_a RubySmart::SimpleLogger::Devices::MultiDevice
        expect(logger.ignore_payload?).to eq true
      end
    end

    describe 'others' do
      it 'forwards provided device' do
        logger = RubySmart::SimpleLogger.new STDOUT
        expect(logger.logdev).to eq STDOUT
      end

      it 'uses STDERR' do
        logger = RubySmart::SimpleLogger.new :stderr
        expect(logger.logdev).to eq STDERR
      end

      it 'uses module' do
        logger = RubySmart::SimpleLogger.new RubySmart::SimpleLogger, stdout: true
        expect(logger.formatter.opts[:format]).to eq :passthrough
        expect(logger.logdev).to be_a RubySmart::SimpleLogger::Devices::MultiDevice

        logger = RubySmart::SimpleLogger.new RubySmart::SimpleLogger
        expect(logger.formatter.opts[:format]).to eq :plain
        expect(logger.logdev.dev).to be_a ::File
        expect(logger.logdev.dev.path).to eq 'log/ruby_smart/simple_logger.log'
      end

      it 'uses logger' do
        l = ::Logger.new(STDERR)
        logger = RubySmart::SimpleLogger.new l
        expect(logger.logdev).to eq l.instance_variable_get(:@logdev).dev
      end

      it 'uses null' do
        logger = RubySmart::SimpleLogger.new :null
        expect(logger.logdev).to be_a RubySmart::SimpleLogger::Devices::NullDevice
      end

      it 'uses debugger with logger' do
        expect {
          RubySmart::SimpleLogger.new :debugger
        }.to raise_error("Unable to build SimpleLogger with 'debugger' builtin for not initialized Debugger!")

        stub_const '::Debugger', Class.new
        Debugger.class_eval do
          def self.logger
            @logger ||= ::Logger.new(STDERR)
          end

          def self.handler
            nil
          end
        end

        logger = RubySmart::SimpleLogger.new :debugger
        expect(logger.logdev).to eq Debugger.logger.instance_variable_get(:@logdev).dev
      end

      it 'uses debugger with proc' do
        stub_const '::Debugger', Class.new
        Debugger.class_eval do
          def self.logger
            @logger ||= Proc.new { |_data| }
          end

          def self.handler
            nil
          end
        end

        logger = RubySmart::SimpleLogger.new :debugger
        expect(logger.logdev).to be_a RubySmart::SimpleLogger::Devices::ProcDevice
      end

      it 'NOT uses rails' do
        expect {
          RubySmart::SimpleLogger.new :rails
        }.to raise_error("Unable to build SimpleLogger with 'rails' builtin for not initialized rails application!")
      end
    end
  end

  describe '#_init_opts' do
    it ':device' do
      logger = RubySmart::SimpleLogger.new device: 'builtins_spec.log'
      expect(logger.logdev.dev).to be_a ::File
    end

    it ':nl' do
      logger = RubySmart::SimpleLogger.new nl: true
      expect(logger.formatter.opts[:nl]).to eq true

      logger2 = RubySmart::SimpleLogger.new nl: false
      expect(logger2.formatter.opts[:nl]).to eq false
    end

    it ':clr' do
      logger2 = RubySmart::SimpleLogger.new :stdout, clr: true
      expect(logger2.formatter.opts[:clr]).to eq true

      logger3 = RubySmart::SimpleLogger.new clr: false
      expect(logger3.formatter.opts[:clr]).to eq false
    end

    it ':payload' do
      logger = RubySmart::SimpleLogger.new payload: false
      expect(logger.ignore_payload?).to eq true
    end

    it ':format' do
      logger = RubySmart::SimpleLogger.new :stdout, format: :plain
      expect(logger.formatter.opts[:format]).to eq :plain
    end

    it ':mask' do
      logger = RubySmart::SimpleLogger.new :stdout, mask: { length: 10 }
      expect(logger.mask).to eq({ char: "=", length: 10, clr: :blue })
    end

    it ':level' do
      logger = RubySmart::SimpleLogger.new level: :fatal
      expect(logger.level).to eq 4
    end
  end

  describe '#_opt' do
    it 'returns a empty hash' do
      expect(@logger.send(:_opt)).to eq({})
    end

    it 'merges provided hashes' do
      opts1 = { level: :debug, formatter: :my, payload: [], subtree: { items: { status: true } } }
      opts2 = { payload: [:_], ins: true }
      opts3 = { subtree: { items: { pos: 1 }, count: 12 } }

      expect(@logger.send(:_opt, opts1, opts2, opts3)).to eq({ formatter: :my, ins: true, level: :debug, payload: [:_], subtree: { count: 12, items: { pos: 1 } } })
    end
  end

  describe '#_clr' do
    it 'colorizes a provided string' do
      expect(@logger.send(:_clr, 'Test', :red)).to eq "\e[1;31mTest\e[0m"
      expect(@logger.send(:_clr, 'Test', :bg_blue)).to eq "\e[44mTest\e[0m"
    end

    it 'returns the string' do
      expect(@logger.send(:_clr, 'Test', nil)).to eq 'Test'
    end

    it 'returns the string for invalid color' do
      expect(@logger.send(:_clr, 'Test', :mapple)).to eq 'Test'
    end
  end

  describe '#_tagged' do
    it 'tags provided string' do
      expect(@logger.send(:_tagged, 'Test', :hint)).to eq "[\e[46mHINT\e[0m] Test"
    end
  end

  describe '#_lgth' do
    it 'forces string to exact length' do
      expect(@logger.send(:_lgth, 'test', 10)).to eq "test      "
    end

    it 'cuts too long string' do
      expect(@logger.send(:_lgth, 'very longteststring', 10)).to eq "very longt"
    end

    it 'appends padstr' do
      expect(@logger.send(:_lgth, 'very', 10, '-')).to eq "very------"
    end
  end

  describe '#_res_clr' do
    it 'returns success color' do
      expect(@logger.send(:_res_clr, true)).to eq :green
      expect(@logger.send(:_res_clr, 1)).to eq :green
      expect(@logger.send(:_res_clr, '1')).to eq :green
    end

    it 'returns fail color' do
      expect(@logger.send(:_res_clr, false)).to eq :red
      expect(@logger.send(:_res_clr, 0)).to eq :red
      expect(@logger.send(:_res_clr, '0')).to eq :red
    end

    it 'returns color' do
      expect(@logger.send(:_res_clr, :orange)).to eq :orange
      expect(@logger.send(:_res_clr, :yellow)).to eq :yellow
    end

    it 'returns fallback' do
      expect(@logger.send(:_res_clr, 45)).to eq :grey
      expect(@logger.send(:_res_clr, ::Logger::LogDevice)).to eq :grey
    end
  end

  describe '#_resolve_device' do
    it 'returns a logdev instance' do
      expect(@logger.send(:_resolve_device, "x.log", {})).to be_a ::Logger::LogDevice
    end

    it 'returns Module location' do
      expect(@logger.send(:_resolve_device, Dummy::With::UsersHelper::OfAny::Levels, {}).dev.path).to eq 'log/dummy/with/users_helper/of_any/levels.log'
      expect(@logger.send(:_resolve_device, Dummy::With::UsersHelper::OfAny, {}).dev.path).to eq 'log/dummy/with/users_helper/of_any.log'
      expect(@logger.send(:_resolve_device, Dummy::With::UsersHelper, {}).dev.path).to eq 'log/dummy/with/users_helper.log'
      expect(@logger.send(:_resolve_device, Dummy, {}).dev.path).to eq 'log/dummy.log'
    end

    it 'returns Module location for rails' do
      # here the method +::ThreadInfo.rails?+ must temporary return true
      allow(::ThreadInfo).to receive(:rails?).and_return(true)
      stub_const '::Rails', Class.new
      ::Rails.class_eval do
        def self.root
          "log/rails_root";
        end
      end

      expect(@logger.send(:_resolve_device, RubySmart::SimpleLogger, {}).dev.path).to eq 'log/rails_root/log/ruby_smart/simple_logger.log'
    end

    it 'returns file location' do
      expect(@logger.send(:_resolve_device, "my-cool-logfile.log", {}).dev.path).to eq 'log/my-cool-logfile.log'

      path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'log', 'helper_spec.log'))
      expect(@logger.send(:_resolve_device, path, {}).dev.path).to eq path
    end

    it 'returns file location for rails' do
      allow(::ThreadInfo).to receive(:rails?).and_return(true)
      stub_const '::Rails', Class.new
      ::Rails.class_eval do
        def self.root
          "log/rails_root";
        end
      end

      expect(@logger.send(:_resolve_device, "my-cool-logfile.log", {}).dev.path).to eq 'log/rails_root/log/my-cool-logfile.log'
    end

    it 'returns provided device' do
      expect(@logger.send(:_resolve_device, STDOUT, {})).to eq STDOUT
      expect(@logger.send(:_resolve_device, nil, { device: STDOUT })).to eq STDOUT
    end

    it 'fails' do
      expect {
        @logger.send(:_resolve_device, :wrong, {})
      }.to raise_exception RuntimeError, "Unable to build SimpleLogger! The provided device 'wrong' must respond to 'write'!"
    end
  end
end