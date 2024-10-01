# frozen_string_literal: true

require 'httpx'
require 'json'
require 'logger'

# Generates and sends commands to the Reactor endpoint.
class CommandExecutor
  attr_reader :logger, :client_uuid, :endpoint_url

  def initialize(logger, client_uuid)
    @logger = logger
    @client_uuid = client_uuid
    @endpoint_url = Hawksi.configuration.reactor_url
  end

  def execute_command(command, params) # rubocop:disable Metrics/MethodLength
    request_body = build_request_body(command, params)
    response = send_request(request_body)

    if response.nil?
      logger.error 'Failed to execute command due to a request error.'
    elsif response.is_a?(HTTPX::ErrorResponse)
      logger.error "HTTPX Error: #{response.error.message}"
    elsif response.status == 200
      process_response(response)
    else
      logger.error "Command execution failed. Status: #{response.status}, Body: #{response.body}"
    end
  end

  private

  def build_request_body(command, params)
    {
      client_id: client_uuid,
      command: command,
      instructions: params.join(' ')
    }.to_json
  end

  def send_request(request_body)
    logger.info "sending request to #{endpoint_url}"
    logger.info "request body: #{request_body}"
    HTTPX.post(endpoint_url, headers: { 'Content-Type' => 'application/json', 'x-client-id' => client_uuid },
                             body: request_body)
  rescue StandardError => e
    logger.error "Failed to send request: #{e.message}"
    nil
  end

  def process_response(response)
    result = JSON.parse(response.body)
    log_command_result(result)
  rescue JSON::ParserError => e
    logger.error "Failed to parse response JSON: #{e.message}"
  end

  def log_command_result(result)
    if result['result'] == 'error'
      logger.error "Error during command execution: #{result['message']}"
    else
      logger.info "Command executed successfully. #{result}"
      puts(result.fetch('response', ''))
    end
  end
end
