# frozen_string_literal: true

RSpec.describe RubySmart::SimpleLogger do
  describe '.version' do
    it "returns a gem version" do
      expect(RubySmart::SimpleLogger.version).to be_a Gem::Version
    end

    it "has a version number" do
      expect(RubySmart::SimpleLogger.version.to_s).to eq RubySmart::SimpleLogger::VERSION::STRING
    end
  end
end
