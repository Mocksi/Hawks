require 'httpx'

module Hawksi
  class MocksiHandler
    def self.handle(request)
      proxy = HTTPX.proxy(URI.parse(Hawksi.configuration.mocksi_server))
      response = proxy.call(request.env)
      [response.status, response.headers, response.body]
    end
  end
end
