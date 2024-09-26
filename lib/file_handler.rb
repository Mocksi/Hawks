# frozen_string_literal: true

require 'fileutils'
require 'securerandom'

# Handles file operations.
class FileHandler
  def initialize(base_dir, logger)
    @base_dir = base_dir
    @logger = logger
  end

  def find_files
    glob_pattern = File.join(@base_dir, '{requests,responses}', '*.json')
    Dir.glob(glob_pattern)
  end

  def generate_client_uuid
    uuid_file = File.join(@base_dir, 'client_uuid.txt')
    if File.exist?(uuid_file)
      client_uuid = File.read(uuid_file).strip
      @logger.info "Using existing client UUID: #{client_uuid}"
    else
      client_uuid = SecureRandom.uuid
      File.write(uuid_file, client_uuid)
      @logger.info "Generated and stored new client UUID: #{client_uuid}"
    end
    client_uuid
  end

  def create_tar_gz_files(files) # rubocop:disable Metrics/MethodLength
    tar_gz_files = []
    files.each do |file|
      tar_file = "#{file}.tar"
      tar_gz_file = "#{tar_file}.gz"

      unless File.exist?(tar_gz_file)
        # Create tarball containing only the file without directory structure
        system("tar -C #{File.dirname(file)} -cf #{tar_file} #{File.basename(file)}")

        # Compress tarball
        system("gzip #{tar_file}")
      end

      tar_gz_files << tar_gz_file
    end
    tar_gz_files
  end
end
