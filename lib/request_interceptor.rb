# frozen_string_literal: true

require 'socket'
require 'json'
require 'logger'
require 'digest'
require_relative 'file_storage'
require_relative 'mocksi_handler'

module Hawksi
  # Initializes a new instance of RequestInterceptor.
  #
  # @param app [Rack::Builder] The Rack application to wrap.
  # @param logger [Logger] The logger instance to use for logging.
  # @param storage [FileStorage] The file storage instance to use for storing requests and responses.
  class RequestInterceptor
    def initialize(app, logger: Logger.new('hawksi.log'), storage: FileStorage)
      @app = app
      @logger = logger
      @storage = storage
      @templates = {}
      @templates_mutex = Mutex.new

      @socket_path = '/tmp/hawksi.sock'
      start_unix_socket_server
    end

    def call(env)
      request = Rack::Request.new(env)
      request_key = generate_request_key(request) # Generate a key for the request

      # Check if there's a template for this request
      template = nil
      @templates_mutex.synchronize do
        template = @templates[request_key]
      end
      if template
        status, headers, _temp = @app.call(env)

        # Serve the template
        headers['Etag'] = Digest::MD5.hexdigest(template)
        return [status, headers, [template]]
      end

      # Original code
      return MocksiHandler.handle(request) if request.path.end_with?('/favicon.ico')

      if request.path.start_with?('/mocksi') || request.path.start_with?('/_') || request.path.start_with?('/api')
        return MocksiHandler.handle(request)
      end

      log_request(request, request_key)

      status, headers, response = @app.call(env)

      log_response(status, headers, response, request_key)
      [status, headers, response]
    end

    private

    def start_unix_socket_server
      # Remove the socket file if it already exists
      File.unlink(@socket_path) if File.exist?(@socket_path)

      at_exit do
        File.unlink(@socket_path) if File.exist?(@socket_path)
      end

      @server_thread = Thread.new do
        @server = UNIXServer.new(@socket_path)
        @logger.info("Unix socket server started at #{@socket_path}")
        puts "Unix socket server started at #{@socket_path}"
        loop do
          client = @server.accept
          Thread.new(client) do |conn|
            handle_client(conn)
          end
        end
      rescue StandardError => e
        @logger.error("Unix socket server error: #{e.message}")
      ensure
        @server.close if @server
      end
    end

    def handle_client(conn)
      while message = conn.gets
        # Process the message
        process_message(message.chomp)
      end
    rescue StandardError => e
      @logger.error("Error handling client: #{e.message}")
    ensure
      conn.close
    end

    def process_message(message)
      data = JSON.parse(message)
      case data['action']
      when 'set_template'
        key = data['key']
        template = data['template']
        @templates_mutex.synchronize do
          @templates[key] = template
        end
        @logger.info("Template set for key: #{key}")
      when 'remove_template'
        key = data['key']
        @templates_mutex.synchronize do
          @templates.delete(key)
        end
        @logger.info("Template removed for key: #{key}")
      else
        @logger.warn("Unknown action: #{data['action']}")
      end
    rescue JSON::ParserError => e
      puts("JSON parsing error: #{e.message}")
      @logger.error("JSON parsing error: #{e.message}")
    end

    def generate_request_key(request)
      "#{request.request_method}_#{request.path}"
    end

    def log_request(request, request_key) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      data = {
        request_key: request_key, # Include the request key in the logged data
        method: request.request_method,
        path: request.path,
        query_string: request.query_string,
        url: request.url,
        scheme: request.scheme,
        host: request.host,
        port: request.port,
        env: {
          'REQUEST_METHOD' => request.env['REQUEST_METHOD'],
          'SCRIPT_NAME' => request.env['SCRIPT_NAME'],
          'PATH_INFO' => request.env['PATH_INFO'],
          'QUERY_STRING' => request.env['QUERY_STRING'],
          'SERVER_NAME' => request.env['SERVER_NAME'],
          'SERVER_PORT' => request.env['SERVER_PORT'],
          'REMOTE_ADDR' => request.env['REMOTE_ADDR'],
          'HTTP_HOST' => request.env['HTTP_HOST'],
          'HTTP_USER_AGENT' => request.env['HTTP_USER_AGENT'],
          'HTTP_COOKIE' => request.env['HTTP_COOKIE'],
          'HTTP_ACCEPT' => request.env['HTTP_ACCEPT'],
          'CONTENT_TYPE' => request.env['CONTENT_TYPE'],
          'CONTENT_LENGTH' => request.env['CONTENT_LENGTH'],
          'rack.session' => request.env['rack.session']
        },
        cookies: request.cookies,
        params: request.params,
        body: request.body&.read,
        ip: request.ip,
        xhr: request.xhr?,
        content_type: request.content_type,
        content_length: request.content_length,
        capture_type: 'request'
      }
      @logger.info("Request: #{data.to_json}")
      @storage.store('requests', data)
    rescue StandardError => e
      @logger.error("Error logging request: #{e.message}")
    ensure
      request.body&.rewind
    end

    def log_response(status, headers, response, request_key) # rubocop:disable Metrics/MethodLength
      body = if response.respond_to?(:body)
               response.body.join.to_s
             else
               response.join.to_s
             end
      data = {
        request_key: request_key, # Include the request key in the response log
        status: status,
        headers: headers,
        body: body,
        content_type: headers['Content-Type'],
        content_length: headers['Content-Length'],
        capture_type: 'response'
      }
      @logger.info("Response: #{data.to_json}")
      @storage.store('responses', data)
    rescue StandardError => e
      @logger.error("Error logging response: #{e.message}")
    end
  end
end
