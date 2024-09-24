
require 'spec_helper'
require 'hawksi/configuration'

RSpec.describe Hawksi::Configuration do
  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(Hawksi.configuration).to be_an_instance_of(Hawksi::Configuration)
    end

    it 'memoizes the configuration instance' do
      config1 = Hawksi.configuration
      config2 = Hawksi.configuration
      expect(config1).to eq(config2)
    end
  end

  describe '.configure' do
    it 'yields the configuration instance' do
      expect { |b| Hawksi.configure(&b) }.to yield_with_args(Hawksi.configuration)
    end
  end

  describe '#initialize' do
    let(:config) { Hawksi::Configuration.new }

    it 'sets default values for URLs' do
      expect(config.instance_variable_get(:@mocksi_server)).to eq('https://app.mocksi.ai')
      expect(config.instance_variable_get(:@reactor_url)).to eq('https://api.mocksi.ai/api/v1/reactor')
      expect(config.instance_variable_get(:@upload_url)).to eq('https://api.mocksi.ai/api/v1/upload')
      expect(config.instance_variable_get(:@process_url)).to eq('https://api.mocksi.ai/api/v1/process')
    end

    context 'when environment variables are set' do
      before do
        ENV['MOCKSI_SERVER'] = 'https://custom.mocksi.ai'
        ENV['MOCKSI_REACTOR_URL'] = 'https://custom.mocksi.ai/reactor'
        ENV['MOCKSI_UPLOAD_URL'] = 'https://custom.mocksi.ai/upload'
        ENV['MOCKSI_PROCESS_URL'] = 'https://custom.mocksi.ai/process'
      end

      after do
        ENV.delete('MOCKSI_SERVER')
        ENV.delete('MOCKSI_REACTOR_URL')
        ENV.delete('MOCKSI_UPLOAD_URL')
        ENV.delete('MOCKSI_PROCESS_URL')
      end

      it 'uses environment variables for URLs' do
        config = Hawksi::Configuration.new
        expect(config.instance_variable_get(:@mocksi_server)).to eq('https://custom.mocksi.ai')
        expect(config.instance_variable_get(:@reactor_url)).to eq('https://custom.mocksi.ai/reactor')
        expect(config.instance_variable_get(:@upload_url)).to eq('https://custom.mocksi.ai/upload')
        expect(config.instance_variable_get(:@process_url)).to eq('https://custom.mocksi.ai/process')
      end
    end
    context 'when a value is set to an empty string' do
      before do
        ENV['MOCKSI_SERVER'] = ''
        ENV['MOCKSI_REACTOR_URL'] = ''
        ENV['MOCKSI_UPLOAD_URL'] = ''
        ENV['MOCKSI_PROCESS_URL'] = ''
      end

      after do
        ENV.delete('MOCKSI_SERVER')
        ENV.delete('MOCKSI_REACTOR_URL')
        ENV.delete('MOCKSI_UPLOAD_URL')
        ENV.delete('MOCKSI_PROCESS_URL')
      end

      it 'uses default values for empty string environment variables' do
        config = Hawksi::Configuration.new
        expect(config.instance_variable_get(:@mocksi_server)).to eq('https://app.mocksi.ai')
        expect(config.instance_variable_get(:@reactor_url)).to eq('https://api.mocksi.ai/api/v1/reactor')
        expect(config.instance_variable_get(:@upload_url)).to eq('https://api.mocksi.ai/api/v1/upload')
        expect(config.instance_variable_get(:@process_url)).to eq('https://api.mocksi.ai/api/v1/process')
      end
    end
  end
end
