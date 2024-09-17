require 'net/http'
require 'uri'

HAWK_SVG = <<~SVG
  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <text x="9" y="8" font-size="8" text-anchor="middle" font-family="sans-serif">Hwk</text>
  </svg>
SVG
module MocksiHandler
  class << self
    def handle(request)

      if request.path == '/favicon.ico'
        return [200, { 'Content-Type' => 'image/svg+xml' }, [HAWK_SVG]]
      end

      begin
        # Get the mocksi server URL from configuration
        mocksi_server_url = Hawksi.configuration.mocksi_server
        raise "Mocksi server URL not configured" if mocksi_server_url.nil? || mocksi_server_url.empty?

        # Prepare the full URL (mocksi_server + request path + query string)
        target_uri = URI.join(mocksi_server_url, request.fullpath)

        # Create a new HTTP request based on the Rack request method
        http_request = case request.request_method
                       when 'GET'
                         Net::HTTP::Get.new(target_uri)
                       when 'POST'
                         Net::HTTP::Post.new(target_uri)
                       when 'PUT'
                         Net::HTTP::Put.new(target_uri)
                       when 'DELETE'
                         Net::HTTP::Delete.new(target_uri)
                       else
                         raise "Unsupported HTTP method: #{request.request_method}"
                       end

        # Forward headers from the original request, including cookies
        request.env.each do |key, value|
          if key.start_with?('HTTP_')
            header_key = key.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
            http_request[header_key] = value
          end
        end

        # Forward the cookies
        if request.cookies.any?
          http_request['Cookie'] = request.cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
        end

        # Forward the body content if it's a POST or PUT request
        if %w[POST PUT].include?(request.request_method)
          request.body.rewind
          http_request.body = request.body.read
        end

        # Initialize HTTP connection
        http = Net::HTTP.new(target_uri.host, target_uri.port)
        http.use_ssl = (target_uri.scheme == 'https')

        # Make the HTTP request and get the response
        response = http.request(http_request)

        # Check if Transfer-Encoding is chunked, and if so, handle it correctly
        body = response.body
        headers = response.to_hash

        if headers['transfer-encoding']&.include?('chunked')
          # Remove chunked encoding header since Rack will handle the complete response
          headers.delete('transfer-encoding')
        end

        # Decompress the response body if needed
        if response['Content-Encoding'] == 'gzip'
          body = decompress_gzip(body)
        elsif response['Content-Encoding'] == 'deflate'
          body = decompress_deflate(body)
        end

        # Remove Content-Encoding header if the body has been decompressed
        headers.delete('content-encoding') if headers['content-encoding']

        # Ensure headers are in the correct format for Rack
        formatted_headers = format_headers(headers)

        # Return the response in a format compatible with Rack
        [response.code.to_i, formatted_headers, [body]]
      rescue => e
        # Handle any errors that occur during the reverse proxy operation
        [500, { 'Content-Type' => 'text/plain' }, ["Error: #{e.message}"]]
      end
    end

    private

    # Helper method to format headers for Rack compatibility
    def format_headers(headers_hash)
      formatted_headers = {}
      headers_hash.each do |key, value|
        formatted_headers[key.split('-').map(&:capitalize).join('-')] = Array(value).join(', ')
      end
      formatted_headers
    end

    # Helper method to decompress gzip content
    def decompress_gzip(body)
      io = StringIO.new(body)
      gzip_reader = Zlib::GzipReader.new(io)
      decompressed_body = gzip_reader.read
      gzip_reader.close
      decompressed_body
    end

    # Helper method to decompress deflate content
    def decompress_deflate(body)
      Zlib::Inflate.inflate(body)
    end
  end
end