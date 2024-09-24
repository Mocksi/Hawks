# frozen_string_literal: true

require 'thor'
require_relative 'file_storage'

# CLI for listing captured requests and responses
class CapturesCLI < Thor
  desc 'list', 'Lists recent captured requests and responses'
  option :base_dir, type: :string,
                    desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def list(*_args) # rubocop:disable Metrics/MethodLength
    base_dir = FileStorage.base_dir
    FileStorage.base_dir = options[:base_dir] if options[:base_dir]

    # Glob pattern to match JSON files in both requests and responses directories
    glob_pattern = File.join(base_dir, '{requests,responses}', '*.json')

    files = Dir.glob(glob_pattern)

    if files.empty?
      puts 'No captured requests or responses found.'
      return
    end

    files.each do |file|
      puts "Reading file: #{file}"
      puts File.read(file)
    end
  end
end
