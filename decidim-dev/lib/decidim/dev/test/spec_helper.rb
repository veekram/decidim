# frozen_string_literal: true

require "rails-controller-testing"

#
# Make sure Rails hooks are available
#
require "action_dispatch/system_testing/test_helpers/setup_and_teardown"

#
# Monkeypatch after_teardown to just call "super". That super there is what
# rolls back transaction fixtures after each test.
#
::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown.module_eval do
  def after_teardown
    super
  end
end

#
# Save the previously monkeypatched method to call it when we need.
#
unbounded_after_teardown = ::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown.instance_method(:after_teardown)

#
# Fully disable the method now, make it do nothing
#
::ActionDispatch::SystemTesting::TestHelpers::SetupAndTeardown.module_eval do
  def after_teardown; end
end

#
# Finally, require rspec-rails, knowing that it will do no teardown stuff
# without our control.
#
require "rspec/rails"

require "rspec/cells"
require "byebug"
require "rectify/rspec"
require "wisper/rspec/stub_wisper_publisher"
require "db-query-matchers"
require "action_view/helpers/sanitize_helper"

# Requires supporting files with custom matchers and macros, etc,
# in ./rspec_support/ and its subdirectories.
Dir["#{__dir__}/rspec_support/**/*.rb"].each { |f| require f }

require_relative "factories"

RSpec.configure do |config|
  config.color = true
  config.fail_fast = ENV["FAIL_FAST"] == "true"
  config.infer_spec_type_from_file_location!
  config.mock_with :rspec
  config.order = :random
  config.raise_errors_for_deprecations!
  config.example_status_persistence_file_path = ".rspec-failures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include AttachmentHelpers
  config.include TranslationHelpers
  config.include Rectify::RSpec::Helpers
  config.include ActionView::Helpers::SanitizeHelper
  config.include ERB::Util
  config.include Capybara::ReactSelect, type: :system

  #
  # Do the following after each test:
  #
  # * First, take a screenshot if necessary.
  # * Second, reset sessions.
  # * Third, rollback transactional fixtures.
  #
  config.after :each, type: :system do |example|
    begin
      Capybara::Screenshot::RSpec.after_failed_example(example)
      Capybara.reset_sessions!
    ensure
      unbounded_after_teardown.bind(self).call
    end
  end
end
