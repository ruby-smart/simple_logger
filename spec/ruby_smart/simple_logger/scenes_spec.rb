# frozen_string_literal: false

require 'spec_helper'

RSpec.describe RubySmart::SimpleLogger::Scenes do
  before :all do
    # forces inspector to ruby's default 'inspect' method
    @logger     = RubySmart::SimpleLogger.new RubySmart::SimpleLogger::Devices::MemoryDevice.new, format: :plain, nl: false, clr: true, inspector: :inspect
    @log_result = []
  end

  describe 'severity methods' do
    it '#debug' do
      expect {
        spec_log_result(:debug) do |res|
          res << "\e[1;34m============================================== [Debug] =============================================\e[0m\n"
          res << "\"example\"\n" # debug with #inspect
          res << "\e[1;34m====================================================================================================\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#info' do
      expect {
        spec_log_result(:info) do |res|
          res << "\e[1;36m============================================== [Info] ==============================================\e[0m\n"
          res << "example\n"
          res << "\e[1;36m====================================================================================================\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#warn' do
      expect {
        spec_log_result(:warn) do |res|
          res << "\e[1;33m============================================== [Warn] ==============================================\e[0m\n"
          res << "example\n"
          res << "\e[1;33m====================================================================================================\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#error' do
      expect {
        spec_log_result(:error) do |res|
          res << "\e[1;31m============================================== [Error] =============================================\e[0m\n"
          res << "example\n"
          res << "\e[1;31m====================================================================================================\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#fatal' do
      expect {
        spec_log_result(:fatal) do |res|
          res << "\e[41m============================================== [Fatal] =============================================\e[0m\n"
          res << "example\n"
          res << "\e[41m====================================================================================================\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#success' do
      expect {
        spec_log_result(:success) do |res|
          res << "\e[1;32m============================================= [Success] ============================================\e[0m\n"
          res << "example\n"
          res << "\e[1;32m====================================================================================================\e[0m\n"
        end
      }.to change { @log_result }
    end
  end

  describe 'header-footer methods' do
    it '#header' do
      expect {
        spec_log_result(:header, "header") do |res|
          res << "\e[1;34m====================================================================================================\e[0m\n"
          res << "\e[1;34m============================================= <header> =============================================\e[0m\n"
          res << "\e[1;34m====================================================================================================\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#footer' do
      expect {
        spec_log_result(:footer, "footer") do |res|
          res << "\e[1;34m====================================================================================================\e[0m\n"
          res << "\e[1;34m============================================= >footer< =============================================\e[0m\n"
          res << "\e[1;34m====================================================================================================\e[0m\n"
        end
      }.to change { @log_result }
    end

    it 'with timer' do
      expect(@logger.timer(:current)).to be 0
      @logger.header "header", timer: true
      expect(@logger.timer(:current)).to be > 0
      @logger.footer "footer", timer: true

      expect(@logger.logs[-1]).to include 'duration: '
    end
  end

  it '#topic' do
    expect {
      spec_log_result(:topic, "topic") do |res|
        res << "\e[0;34m-----------------------------------------------------------------------------------------------\e[0m\n"
        res << "\e[0;34m#------------------------------------------- topic -------------------------------------------#\e[0m\n"
        res << "\e[0;34m-----------------------------------------------------------------------------------------------\e[0m\n"
      end
    }.to change { @log_result }
  end

  describe 'theme methods' do
    it '#theme' do
      expect {
        spec_log_result(:theme, "theme") do |res|
          res << "\e[1;35m# theme\e[0m\n"
          res << "\e[1;35m-------------------------------------------------------------------------------------\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#theme_result' do
      expect {
        spec_log_result(:theme_result, "ok", true) do |res|
          res << "\e[1;35m-------------------------------------------------------------------------------------\e[0m\n"
          res << "\e[1;32m-> ok\e[0m\n\n"
        end
      }.to change { @log_result }
    end

    it '#theme_line' do
      expect {
        spec_log_result(:theme_line, :_) do |res|
          res << "\e[1;35m-------------------------------------------------------------------------------------\e[0m\n"
        end
      }.to change { @log_result }
    end
  end

  it '#desc' do
    expect {
      spec_log_result(:desc) do |res|
        res << "\e[1;35mexample\e[0m\n"
      end
    }.to change { @log_result }
  end

  describe 'job methods' do
    it '#job' do
      expect {
        spec_log_result(:job, "job") do |res|
          res << "- \e[1;36mjob                                                             \e[0m => "
        end
      }.to change { @log_result }
    end

    it '#sub_job' do
      expect {
        spec_log_result(:sub_job, "sub job") do |res|
          res << "  * \e[1;36msub job                                                       \e[0m => "
        end
      }.to change { @log_result }
    end

    it '#result' do
      expect {
        spec_log_result(:result, "fail", false) do |res|
          res << "\e[1;31mfail\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#job_result' do
      expect {
        spec_log_result(:job_result, "job", 'unknown', :yellow) do |res|
          res << "- \e[1;36mjob                                                             \e[0m => \e[1;33munknown\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#sub_job_result' do
      expect {
        spec_log_result(:sub_job_result, "sub job", true) do |res|
          res << "  * \e[1;36msub job                                                       \e[0m => \e[1;32mtrue\e[0m\n"
        end
      }.to change { @log_result }
    end
  end

  describe 'raw methods' do
    it '#line' do
      expect {
        spec_log_result(:line, "data") do |res|
          res << "data\n"
        end
      }.to change { @log_result }
    end

    it '#print' do
      expect {
        spec_log_result(:print, "data") do |res|
          res << "data"
        end
      }.to change { @log_result }
    end

    it '#nl' do
      expect {
        spec_log_result(:nl, :_) do |res|
          res << "\n"
        end
      }.to change { @log_result }
    end
  end

  describe 'spec methods' do
    it '#spec true' do
      expect {
        spec_log_result(:spec, true) do |res|
          res << "\e[1;32m.\e[0m"
        end
      }.to change { @log_result }
    end

    it '#spec false' do
      expect {
        spec_log_result(:spec, false) do |res|
          res << "\e[1;31mF\e[0m"
        end
      }.to change { @log_result }
    end

    it '#spec unknown' do
      expect {
        spec_log_result(:spec, 'unknown') do |res|
          res << "\e[1;33m?\e[0m"
        end
      }.to change { @log_result }
    end
  end

  describe 'progress methods' do
    it '#progress 0' do
      expect {
        spec_log_result(:progress, 'step 1', 0) do |res|
          res << "- \e[1;36mstep 1                                          \e[0m [  0%] \e[1;32m>\e[0m\e[1;31m-------------------------------------------------\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#progress 40' do
      expect {
        spec_log_result(:progress, 'step 2', 40) do |res|
          res << "- \e[1;36mstep 2                                          \e[0m [ 40%] \e[1;32m===================>\e[0m\e[1;31m------------------------------\e[0m\n"
        end
      }.to change { @log_result }
    end

    it '#progress 100' do
      expect {
        spec_log_result(:progress, 'step 3', 100) do |res|
          res << "- \e[1;36mstep 3                                          \e[0m [100%] \e[1;32m=================================================>\e[0m\e[1;31m\e[0m\n"
        end
      }.to change { @log_result }
    end
  end

  describe 'processed methods' do
    before do
      @logger.instance_variable_set(:@ignore_payload, true)
      @log_result = []
      @logger.logdev.dev.clear!
    end

    after do
      @logger.instance_variable_set(:@ignore_payload, false)
    end

    it '#processed lvl 0' do
      @logger.processed("custom process") do
        expect {
          spec_log_result(:success, 'note') do |res|
            res << "╟ note"
          end
        }.to change { @log_result }
      end
    end

    it '#processed multiple lvl' do
      @logger.processed("custom process") do
        @logger.success("ok")

        @logger.processed("sub-process") do
          @logger.error("nope")
          @logger.info("japp")
          nil
        end

        @logger.processed("sub-process 2",) do
          @logger.error("nope")
          false
        end
      end

      logs = @logger.logs.join("\n")

      expect(logs).to eq "╔ START - custom process\n╟ ok\n║ ┌ START - sub-process\n║ ├ nope\n║ ├ japp\n║ └ END   - sub-process \n║ ┌ START - sub-process 2\n║ ├ nope\n║ └ END   - FAILED \n╚ END   - SUCCESS "
      expect(logs).to_not include("(duration:")
    end

    it '#processed with timer' do
      @logger.processed("other process", timer: true) do
        @logger.success("ok")
        nil
      end

      expect(@logger.logs.join).to include("(duration:")
    end
  end
end