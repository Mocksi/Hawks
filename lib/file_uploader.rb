require 'httpx'
require 'logger'

class FileUploader
  # FIXME: use a base URL for the upload and process URLs
  def initialize(logger, client_uuid)
    @logger = logger
    @client_uuid = client_uuid
  end

  def upload_files(tar_gz_files)
    log_upload_start(tar_gz_files)
    threads = create_upload_threads(tar_gz_files)
    wait_for_threads(threads)
  end

  def process_files
    HTTPX.wrap do |client|
      response = begin
        client.post(Hawksi.configuration.process_url, headers: { "x-client-id" => @client_uuid })
      rescue => e
        @logger.error "Failed to process files. Error: #{e.message}"
      end

      if response.is_a?(HTTPX::Response)
        @logger.info "Processing uploaded files. Status: #{response.status}"
      elsif response.is_a?(HTTPX::ErrorResponse)
        @logger.error "Failed to process files. Error: #{response.error}"
      end
    end
  end

  private

  def log_upload_start(tar_gz_files)
    @logger.info "Starting upload of #{tar_gz_files.size} files."
  end

  def create_upload_threads(tar_gz_files)
    tar_gz_files.each_slice(10).map do |batch|
      Thread.start { upload_batch(batch) }
    end
  end

  def wait_for_threads(threads)
    threads.each(&:join)
  end

  def upload_batch(batch)
    batch.each { |tar_gz_file| upload_file(tar_gz_file) }
  end

  def upload_file(tar_gz_file)
    HTTPX.wrap do |client|
      response = post_file(client, tar_gz_file)
      log_upload_result(tar_gz_file, response)
      response
    end
  end

  def post_file(client, tar_gz_file)
    filename = File.basename(tar_gz_file)
    client.post("#{Hawksi.configuration.upload_url}?filename=#{filename}",
                headers: { "x-client-id" => @client_uuid },
                body: File.read(tar_gz_file))
  rescue => e
    @logger.error "Failed to upload #{tar_gz_file}: #{e.message}"
    nil
  end

  def log_upload_result(tar_gz_file, response)
    if response && response.is_a?(HTTPX::Response) && response.status == 200
      @logger.info "Uploaded #{tar_gz_file}: #{response.status}"
    else
      @logger.error "Failed to upload #{tar_gz_file}. Status: #{response&.status}, Body: #{response&.body}"
    end
  end
end