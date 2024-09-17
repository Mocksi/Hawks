require 'httpx'

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

        # Prepare headers from the request
        headers = {}
        request.env.each do |key, value|
          if key.start_with?('HTTP_')
            header_key = key.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
            headers[header_key] = value
          end
        end

        # Forward the cookies
        if request.cookies.any?
          headers['Cookie'] = request.cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
        end

        # Initialize httpx with headers
        http_client = HTTPX.with(headers: headers)

        # Forward the body content if it's a POST or PUT request
        body = nil
        if %w[POST PUT].include?(request.request_method)
          request.body.rewind
          body = request.body.read
        end

        # Make the HTTP request using the appropriate method
        response = http_client.request(request.request_method.downcase.to_sym, target_uri, body: body)

        # Clone headers to allow modification
        response_headers = response.headers.dup

        # Check for chunked transfer encoding and remove it
        if response_headers["transfer-encoding"]&.include?("chunked")
          response_headers.delete("transfer-encoding")
        end

        # Handle gzip or deflate content-encoding if present
        response_body = response.body.to_s
        if response_headers["content-encoding"]&.include?("gzip")
          response_body = safe_decompress_gzip(response_body)
          response_headers.delete("content-encoding") # Remove content-encoding since the content is decompressed
        elsif response_headers["content-encoding"]&.include?("deflate")
          response_body = decompress_deflate(response_body)
          response_headers.delete("content-encoding") # Remove content-encoding since the content is decompressed
        end

        # Return the response in a format compatible with Rack
        [response.status, response_headers, [response_body]]
      rescue => e
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