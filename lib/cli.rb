require 'thor'
require 'puma'
require 'puma/cli'
require_relative 'request_interceptor'
require_relative 'file_storage'

class CLI < Thor
  desc "start", "Starts the Hawksi Interceptor server"
  option :base_dir, type: :string, desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def start(*args)
    FileStorage.base_dir = options[:base_dir] if options[:base_dir]
    puts "Starting HawksiInterceptor server..."
    Puma::CLI.new(args).run
  end

  desc "stop", "Stops the HawksiInterceptor server"
  def stop
    puts "Stopping Hawksi Interceptor server..."
    system("pkill -f puma")
  end

  desc "requests list", "Lists recent intercepted requests"
  def requests_list
    Dir.glob('./intercepted_data/requests/*.json').each do |file|
      puts File.read(file)
    end
  end

  desc "clear", "Clears stored request/response data"
  def clear
    FileUtils.rm_rf('./intercepted_data/requests')
    FileUtils.rm_rf('./intercepted_data/responses')
    puts "Cleared stored data."
  end
end
