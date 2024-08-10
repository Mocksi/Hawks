# lib/request_interceptor.rb
require 'json'
require 'logger'
require_relative '../lib/file_storage'

module Hawksi
  class RequestInterceptor
    def initialize(app, logger: Logger.new('hawksi.log'), storage: FileStorage)
      @app = app
      @logger = logger
      @storage = storage
    end

    def call(env)
      request = Rack::Request.new(env)
      log_request(request)

      status, headers, response = @app.call(env)

      log_response(status, headers, response)
      [status, headers, response]
    end

    private

    def log_request(request)

      begin
        data = {
          method: request.request_method,
          path: request.path,
          query_string: request.query_string,
          url: request.url,
          scheme: request.scheme,
          host: request.host,
          port: request.port,
          env: request.env,
          cookies: request.cookies,
          params: request.params,
          body: request.body&.read,
          ip: request.ip,
          xhr: request.xhr?,
          content_type: request.content_type,
          content_length: request.content_length
        }
        @logger.info("Request: #{data.to_json}")
        @storage.store('requests', data)
      rescue => e
        @logger.error("Error logging request: #{e.message}")
      end
    end
    
    def log_response(status, headers, response)
      begin
        body = if response.respond_to?(:body)
                 response.body.join.to_s
               else
                 response.join.to_s
               end
        data = {
          status: status,
          headers: headers,
          body: body,
          content_type: headers['Content-Type'],
          content_length: headers['Content-Length']
        }
        @logger.info("Response: #{data.to_json}")
        @storage.store('responses', data)
      rescue => e
        @logger.error("Error logging response: #{e.message}")
      end
    end
  end
end
