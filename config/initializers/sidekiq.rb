Sidekiq.configure_server do |config|
  config.redis = { url: ENV["SIDEKID_URL"] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["SIDEKID_URL"] }
end
