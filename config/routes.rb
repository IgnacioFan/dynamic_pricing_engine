require "sidekiq/web"
require "sidekiq/cron/web"
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # mount Sidekiq::Web => "/sidekiq"
  Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(Rails.application.credentials.dig(:sidekiqweb, :username))) &
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(Rails.application.credentials.dig(:sidekiqweb, :password)))
  end
  mount(Sidekiq::Web => "/sidekiq")

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :products, only: [ :index, :show ] do
        post "import", on: :collection
      end
      resources :orders, only: [ :create ]
      resources :carts, only: [ :create ] do
        resources :items, only: [ :create, :destroy ], controller: "cart_items"
      end
    end
  end

  # Catch-all route for unmatched routes
  match "*unmatched", to: "errors#route_not_found", via: :all
end
