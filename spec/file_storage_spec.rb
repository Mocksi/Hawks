# frozen_string_literal: true

require 'spec_helper'
require 'file_storage'

RSpec.describe FileStorage do
  let(:storage_dir) { './spec/tmp/intercepted_data' }

  before do
    described_class.base_dir = storage_dir
    FileUtils.rm_rf(storage_dir)
  end

  describe '.store' do
    it 'stores data in a JSON file' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      data = { 'key' => 'value' } # Use string keys
      type = 'request'

      described_class.store(type, data)

      sleep(0.5) # Increase wait time

      file_path = Dir.glob("#{storage_dir}/#{type}/*.json").first
      expect(file_path).not_to be_nil
      expect(JSON.parse(File.read(file_path))).to eq(data)
    end

    it 'creates the directory if it does not exist' do
      type = 'request'

      described_class.store(type, {})

      expect(Dir).to exist("#{storage_dir}/#{type}")
    end

    it 'stores data asynchronously' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      data = { key: 'value' }
      type = 'request'

      expect do
        described_class.store(type, data)
      end.not_to raise_error

      sleep(0.1) # Wait for the thread to finish

      file_path = Dir.glob("#{storage_dir}/#{type}/*.json").first
      expect(file_path).not_to be_nil
    end
  end
end
