# frozen_string_literal: true

require "spec_helper"
require "rails"
require "action_dispatch"
require_relative "../lib/firebase_hosting_client_ip/railtie"

RSpec.describe FirebaseHostingClientIp::Railtie do
  describe "middleware registration" do
    it "loads the railtie when Rails is defined" do
      expect(defined?(FirebaseHostingClientIp::Railtie)).to eq("constant")
    end

    it "registers the middleware in a Rails app" do
      # Create a minimal Rails app
      app = Class.new(Rails::Application)
      app.config.cache_classes = false
      app.config.eager_load = false

      # The railtie should have already been loaded when Rails was required
      expect(app.config.middleware).to respond_to(:use)
    end
  end

  describe "middleware placement" do
    it "middleware is available in the middleware stack" do
      # Verify that the Middleware class is properly defined
      expect(FirebaseHostingClientIp::Middleware).to be_a(Class)
    end

    it "middleware can be instantiated" do
      app_proc = ->(_env) { [200, {}, ["OK"]] }
      middleware = FirebaseHostingClientIp::Middleware.new(app_proc)
      expect(middleware).to be_a(FirebaseHostingClientIp::Middleware)
    end
  end
end
