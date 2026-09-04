# frozen_string_literal: true

require "rails"
require_relative "middleware"

module FirebaseHostingClientIp
  # Inserts the middleware into the Rails middleware stack.
  # Supports Rails 7, Rails 8, and future versions.
  class Railtie < ::Rails::Railtie
    initializer "firebase_hosting_client_ip.insert_middleware",
                after: "action_dispatch.remote_ip" do |app|
      # Position matters: the middleware must run *after*
      # ActionDispatch::RemoteIp so it can replace the value that middleware
      # installs at env["action_dispatch.remote_ip"]. Inserting it earlier
      # would let RemoteIp overwrite the trusted Fastly value.
      app.middleware.insert_after(
        ActionDispatch::RemoteIp,
        FirebaseHostingClientIp::Middleware
      )
    end
  end
end
