require 'spec_helper'
require 'file_storage'

RSpec.describe FileStorage do
  let(:storage_dir) { './spec/tmp/intercepted_data' }

  before do
    FileStorage.base_dir = storage_dir
    FileUtils.rm_rf(storage_dir)
  end

  describe '.store' do
    it 'stores data in a JSON file' do
      data = { 'key' => 'value' } # Use string keys
      type = 'request'

      FileStorage.store(type, data)

      sleep(0.5) # Increase wait time

      file_path = Dir.glob("#{storage_dir}/#{type}/*.json").first
      expect(file_path).to_not be_nil
      expect(JSON.parse(File.read(file_path))).to eq(data)
    end

    it 'creates the directory if it does not exist' do
      type = 'request'

      FileStorage.store(type, {})

      expect(Dir.exist?("#{storage_dir}/#{type}")).to be_truthy
    end

    it 'stores data asynchronously' do
      data = { key: 'value' }
      type = 'request'

      expect {
        FileStorage.store(type, data)
      }.to_not raise_error

      sleep(0.1) # Wait for the thread to finish

      file_path = Dir.glob("#{storage_dir}/#{type}/*.json").first
      expect(file_path).to_not be_nil
    end
  end
end
