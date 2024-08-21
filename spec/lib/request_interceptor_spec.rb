require 'spec_helper'
require 'hawksi'
require 'rack'
require 'rack/test'

describe Hawksi::RequestInterceptor do
  include Rack::Test::Methods

  let(:app) { lambda { |env| [200, { 'Content-Type' => 'text/plain' }, ['Hello']] } }
  let(:logger) { double('Logger') }
  let(:storage) { double('FileStorage') }
  let(:request_interceptor) { Hawksi::RequestInterceptor.new(app, logger: logger, storage: storage) }

  before do
    allow(logger).to receive(:info)
  end

  describe '#call' do
    context 'with a simple request' do
      before do
        allow(request_interceptor).to receive(:log_request)
        allow(request_interceptor).to receive(:log_response)
        get '/'
      end
      
      it 'logs the request' do
        expect(request_interceptor).to receive(:log_request).with(kind_of(Rack::Request), kind_of(String))
        request_interceptor.call(last_request.env)
      end

      it 'logs the response' do
        expect(request_interceptor).to receive(:log_response).with(200, kind_of(Hash), kind_of(Array), kind_of(String))
        request_interceptor.call(last_request.env)
      end

      it 'passes the request to the app' do
        expect(app).to receive(:call).with(last_request.env).and_call_original
        request_interceptor.call(last_request.env)
      end

      it 'returns the app response' do
        status, headers, body = request_interceptor.call(last_request.env)
        expect(status).to eq(200)
        expect(headers).to include('Content-Type' => 'text/plain')
        expect(body).to eq(['Hello'])
      end
    end
  end

  describe '#log_request' do
    let(:request) { Rack::Request.new(last_request.env) }

    before do
      allow(storage).to receive(:store)
      get '/'
    end

    it 'logs the request data' do
      expect(storage).to receive(:store).with('requests', kind_of(Hash))
      request_interceptor.send(:log_request, request, kind_of(String))
    end

    context 'when logging fails' do
      before do
        allow(storage).to receive(:store).and_raise(StandardError.new('Boom!'))
      end

      it 'logs the error' do
        expect(logger).to receive(:error).with('Error logging request: Boom!')
        request_interceptor.send(:log_request, request, kind_of(String))
      end
    end
  end

  describe '#log_response' do
    let(:status) { 200 }
    let(:headers) { { 'Content-Type' => 'text/plain', 'Content-Length' => '5' } }
    let(:response) { ['Hello'] }

    before do
      allow(storage).to receive(:store)
    end

    it 'logs the response data' do
      expect(storage).to receive(:store).with('responses', kind_of(Hash))
      request_interceptor.send(:log_response, status, headers, response, kind_of(String))
    end

    context 'when logging fails' do
      before do
        allow(storage).to receive(:store).and_raise(StandardError.new('Boom!'))
      end

      it 'logs the error' do
        expect(logger).to receive(:error).with('Error logging response: Boom!')
        request_interceptor.send(:log_response, status, headers, response, kind_of(String))
      end
    end
  end
end