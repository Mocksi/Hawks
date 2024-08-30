require 'thor'
require 'securerandom'
require 'httpx'
require 'fileutils'
require 'open3'
require_relative 'file_storage'
require_relative 'file_uploader'
require_relative 'file_handler'
require_relative 'command_executor'
require 'logger'

class UploadsCLI < Thor
  def initialize(*args)
    super
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @base_dir = options[:base_dir] || FileStorage.base_dir
    @file_handler = FileHandler.new(@base_dir, @logger)
    @client_uuid = get_client_uuid
    @file_uploader = FileUploader.new(@logger, @client_uuid)
    @command_executor = CommandExecutor.new(@logger, @client_uuid)
  end

  desc "update", "Update uploaded requests and responses"
  option :base_dir, type: :string, desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def update(*args)
    set_base_dir
    files = find_files

    if files.empty?
      @logger.info "No captured requests or responses found."
      return
    end

    tar_gz_files = create_tar_gz_files(files)
    return unless valid_tar_gz_files?(tar_gz_files)

    upload_files(tar_gz_files)
  end

  desc "process", "Process uploaded requests and responses"
  option :base_dir, type: :string, desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def process(*args)
    set_base_dir
    process_files
  end

  desc "execute COMMAND PARAMS", "Execute a command with the given parameters"
  option :base_dir, type: :string, desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def execute(command, *params)
    set_base_dir
    @command_executor.execute_command(command, params)
  end

  private

  def set_base_dir
    FileStorage.base_dir = @base_dir
  end

  def get_client_uuid
    @file_handler.generate_client_uuid
  end

  def find_files
    @file_handler.find_files
  end

  def create_tar_gz_files(files)
    @file_handler.create_tar_gz_files(files)
  end

  def valid_tar_gz_files?(tar_gz_files)
    return true if tar_gz_files.is_a?(Array)

    @logger.error "Expected tar_gz_files to be an array, but got #{tar_gz_files.class}"
    false
  end

  def upload_files(tar_gz_files)
    @file_uploader.upload_files(tar_gz_files)
  end

  def process_files
    @file_uploader.process_files
  end
end