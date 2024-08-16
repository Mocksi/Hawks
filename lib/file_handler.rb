require 'fileutils'
require 'securerandom'

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

  def create_tar_gz_files(files)
    tar_gz_files = []
    files.each do |file|
      tar_file = "#{file}.tar"
      tar_gz_file = "#{tar_file}.gz"

      unless File.exist?(tar_gz_file)
        # Create tarball
        system("tar -cf #{tar_file} #{file}")

        # Compress tarball
        system("gzip #{tar_file}")
      end


      tar_gz_files << tar_gz_file
    end
    tar_gz_files
  end
end
