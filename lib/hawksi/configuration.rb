# frozen_string_literal: true

# Top level module
module Hawksi
  # Global mocksi configurations
  class Configuration
    attr_accessor :mocksi_server, :reactor_url, :upload_url, :process_url

    def initialize
      @mocksi_server = get_env('MOCKSI_SERVER') || 'https://app.mocksi.ai'
      @reactor_url = get_env('MOCKSI_REACTOR_URL') || 'https://api.mocksi.ai/api/v1/reactor'
      @upload_url = get_env('MOCKSI_UPLOAD_URL') || 'https://api.mocksi.ai/api/v1/upload'
      @process_url = get_env('MOCKSI_PROCESS_URL') || 'https://api.mocksi.ai/api/v1/process'
    end

    private

    def get_env(key)
      env_value = ENV.fetch(key, '').strip
      env_value.empty? ? nil : env_value
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
