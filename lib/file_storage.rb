# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'securerandom'

# Handles file storage..
class FileStorage
  def self.base_dir
    @base_dir ||= ENV['HAWKSI_BASE_DIR'] || './tmp/intercepted_data'
    puts("Using base directory: #{@base_dir}")

    @base_dir
  end

  def self.base_dir=(dir)
    @base_dir = dir
    puts("Base directory set to: #{@base_dir}")
  end

  def self.store(type, data)
    dir = File.join(base_dir, type)
    FileUtils.mkdir_p(dir)

    Thread.new do
      filename = "#{SecureRandom.uuid}.json"
      file_path = File.join(dir, filename)

      puts("Storing data in: #{file_path}")
      File.write(file_path, data.to_json)
      puts("Data stored in: #{file_path}")
    end
  end
end
