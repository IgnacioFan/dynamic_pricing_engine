RSpec.configure do |config|
  # https://stackoverflow.com/questions/32655446/rspec-config-beforeeach-except-for-specific-types
  config.after :each, type: lambda { |v| [ :model, :service ].include?(v) } do
    Mongoid.truncate!
  end
end
