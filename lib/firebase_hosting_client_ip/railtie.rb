# frozen_string_literal: true

require "rails"
require_relative "middleware"

module FirebaseHostingClientIp
  # Railtie for automatic middleware insertion in Rails applications.
  # Supports Rails 7, Rails 8, and future versions.
  class Railtie < ::Rails::Railtie
    initializer "firebase_hosting_client_ip.insert_middleware",
                after: "action_dispatch.remote_ip" do |app|
      # Insert the middleware after ActionDispatch::RemoteIp
      # This ensures ActionDispatch::RemoteIp has already processed the request
      # and we can normalize the IP accordingly
      app.middleware.insert_after(
        ActionDispatch::RemoteIp,
        FirebaseHostingClientIp::Middleware
      )
    end
  end
end
