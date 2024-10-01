# frozen_string_literal: true

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

# Initializes a new instance of UploadsCLI with the given options.
#
# Sets up a logger for writing to stdout, sets the base directory for file
# operations, creates a new FileHandler instance, a new FileUploader instance,
# and a new CommandExecutor instance.
class UploadsCLI < Thor
  def initialize(*args)
    super
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO
    @base_dir = options[:base_dir] || FileStorage.base_dir
    @file_handler = FileHandler.new(@base_dir, @logger)
    @client_uuid = current_client_uuid
    @file_uploader = FileUploader.new(@logger, @client_uuid)
    @command_executor = CommandExecutor.new(@logger, @client_uuid)
    @socket_path = '/tmp/hawksi.sock'
  end

  desc 'update', 'Update uploaded requests and responses'
  option :base_dir, type: :string,
                    desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def update(*_args)
    set_base_dir
    files = find_files

    if files.empty?
      @logger.info 'No captured requests or responses found.'
      return
    end

    tar_gz_files = create_tar_gz_files(files)
    return unless valid_tar_gz_files?(tar_gz_files)

    upload_files(tar_gz_files)
  end

  desc 'process', 'Process uploaded requests and responses'
  option :base_dir, type: :string,
                    desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def process(*_args)
    set_base_dir
    process_files
  end

  desc 'execute COMMAND PARAMS', 'Execute a command with the given parameters'
  option :base_dir, type: :string,
                    desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def execute(command, *params)
    set_base_dir
    @command_executor.execute_command(command, params)
  end

  desc 'set_template KEY FILENAME', 'Set a template for the given key using the content of the specified file'
  option :base_dir, type: :string,
                    desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def set_template(key, filename)
    set_base_dir
    unless File.exist?(filename)
      @logger.error "File not found: #{filename}"
      return
    end

    # Read the template content from the file
    template_content = File.read(filename)

    message = {
      action: 'set_template',
      key: key,
      template: template_content
    }
    # Send the message to the /tmp/hawksi.sock socket
    socket = UNIXSocket.new(@socket_path)
    socket.write(message.to_json)
    socket.close
  end

  desc 'remove_template KEY', 'Remove the template for the given key'
  option :base_dir, type: :string,
                    desc: 'Base directory for storing intercepted data. Defaults to ./tmp/intercepted_data'
  def remove_template(key)
    set_base_dir
    message = {
      action: 'remove_template',
      key: key
    }
    socket = UNIXSocket.new(@socket_path)
    socket.write(message.to_json)
    socket.close
  end

  private

  def set_base_dir
    FileStorage.base_dir = @base_dir
  end

  def current_client_uuid
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
