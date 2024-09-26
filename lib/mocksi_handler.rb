# frozen_string_literal: true

require 'httpx'

HAWK_SVG = <<~SVG
  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <text x="9" y="8" font-size="8" text-anchor="middle" font-family="sans-serif">Hwk</text>
  </svg>
SVG

# Handles calls to /mocksi
module MocksiHandler
  class << self
    def fetch_mocksi_server_url
      mocksi_server_url = Hawksi.configuration.mocksi_server
      raise 'Mocksi server URL not configured' if mocksi_server_url.nil? || mocksi_server_url.empty?

      mocksi_server_url
    end

    def prep_headers(request)
      headers = {}
      request.env.each do |key, value|
        if key.start_with?('HTTP_')
          header_key = key.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
          headers[header_key] = value
        end
        ## Yay for Rack's weirdness. See https://github.com/rack/rack/issues/1311
        headers['Content-Type'] = value if key == 'CONTENT_TYPE'
        headers['Content-Length'] = value if key == 'CONTENT_LENGTH'
      end
      headers
    end

    def build_response_body(response) # rubocop:disable Metrics/MethodLength
      response_headers = response.headers.dup
      # Check for chunked transfer encoding and remove it
      response_headers.delete('transfer-encoding') if response_headers['transfer-encoding']&.include?('chunked')

      response_body = response.body.to_s
      if response_headers['content-encoding']&.include?('gzip')
        response_body = safe_decompress_gzip(response_body)
        response_headers.delete('content-encoding') # Remove content-encoding since the content is decompressed
      elsif response_headers['content-encoding']&.include?('deflate')
        response_body = decompress_deflate(response_body)
        response_headers.delete('content-encoding') # Remove content-encoding since the content is decompressed
      end
      response_body
    end

    def handle(request) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      return [200, { 'Content-Type' => 'image/svg+xml' }, [HAWK_SVG]] if request.path == '/favicon.ico'

      begin
        mocksi_server_url = fetch_mocksi_server_url
        target_uri = URI.join(mocksi_server_url, request.fullpath)

        headers = prep_headers(request)
        headers['Cookie'] = request.cookies.map { |k, v| "#{k}=#{v}" }.join('; ') if request.cookies.any?

        # Initialize httpx with headers
        http_client = HTTPX.with(headers: headers)

        # Forward the body content if it's a POST or PUT request
        body = nil
        if %w[POST PUT].include?(request.request_method)
          request.body.rewind
          body = request.body.read
        end

        response = http_client.request(request.request_method.downcase.to_sym, target_uri, body: body)
        response_body = build_response_body(response)
        response_headers = response.headers.to_h

        # Return the response in a format compatible with Rack
        [response.status, response_headers, [response_body]]
      rescue StandardError => e
        # Handle any errors that occur during the reverse proxy operation
        [500, { 'Content-Type' => 'text/plain' }, ["Error: #{e.message}"]]
      end
    end

    private

    # Helper method to safely decompress gzip content, returning the original body if it's not in gzip format
    def safe_decompress_gzip(body)
      io = StringIO.new(body)
      begin
        gzip_reader = Zlib::GzipReader.new(io)
        decompressed_body = gzip_reader.read
        gzip_reader.close
        decompressed_body
      rescue Zlib::GzipFile::Error
        # If the body is not actually gzip, return the original body
        body
      end
    end

    # Helper method to decompress deflate content
    def decompress_deflate(body)
      Zlib::Inflate.inflate(body)
    end
  end
end
