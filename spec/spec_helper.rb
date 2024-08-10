
require 'rspec'

# Requires supporting files with custom matchers and config.
Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  # Add settings here, for example:
  # config.example_status_persistence_file_path = ".rspec_status"

  # You can also configure RSpec to ignore certain files and directories:
  # config.filter_gems_from_backtrace!
end
