# frozen_string_literal: true

require "spec_helper"
require "rails"
require "action_dispatch"
require_relative "../lib/firebase_hosting_client_ip/middleware"

RSpec.describe "request.remote_ip integration" do
  let(:app) { ->(_env) { [200, {}, ["OK"]] } }
  let(:middleware) { FirebaseHostingClientIp::Middleware.new(app) }

  def make_request(env_overrides = {})
    env = Rack::MockRequest.env_for("/", env_overrides)
    middleware.call(env)
    ActionDispatch::Request.new(env)
  end

  describe "request.remote_ip behavior" do
    it "returns HTTP_FASTLY_CLIENT_IP when present" do
      request = make_request(
        "HTTP_FASTLY_CLIENT_IP" => "203.0.113.1",
        "HTTP_X_FORWARDED_FOR" => "198.51.100.1, 198.51.100.2",
        "REMOTE_ADDR" => "127.0.0.1"
      )
      expect(request.remote_ip).to eq("203.0.113.1")
    end

    it "returns left-most IP from HTTP_X_FORWARDED_FOR when HTTP_FASTLY_CLIENT_IP is absent" do
      request = make_request(
        "HTTP_X_FORWARDED_FOR" => "198.51.100.1, 198.51.100.2",
        "REMOTE_ADDR" => "127.0.0.1"
      )
      expect(request.remote_ip).to eq("198.51.100.1")
    end

    it "returns REMOTE_ADDR when no headers are present" do
      request = make_request(
        "REMOTE_ADDR" => "10.0.0.1"
      )
      expect(request.remote_ip).to eq("10.0.0.1")
    end

    it "handles multiple IPs in X-Forwarded-For correctly" do
      request = make_request(
        "HTTP_X_FORWARDED_FOR" => "192.0.2.1, 192.0.2.2, 192.0.2.3",
        "REMOTE_ADDR" => "127.0.0.1"
      )
      expect(request.remote_ip).to eq("192.0.2.1")
    end

    it "handles whitespace in headers" do
      request = make_request(
        "HTTP_X_FORWARDED_FOR" => "  203.0.113.1  ,  203.0.113.2  ",
        "REMOTE_ADDR" => "127.0.0.1"
      )
      expect(request.remote_ip).to eq("203.0.113.1")
    end

    it "falls back to REMOTE_ADDR when headers are empty" do
      request = make_request(
        "HTTP_FASTLY_CLIENT_IP" => "",
        "HTTP_X_FORWARDED_FOR" => "",
        "REMOTE_ADDR" => "10.0.0.1"
      )
      expect(request.remote_ip).to eq("10.0.0.1")
    end

    it "handles Firebase Hosting proxy chain scenario" do
      request = make_request(
        "REMOTE_ADDR" => "157.232.1.1",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.1, 157.232.1.1"
      )
      expect(request.remote_ip).to eq("203.0.113.1")
    end

    it "handles Fastly-fronted Firebase Hosting scenario" do
      request = make_request(
        "REMOTE_ADDR" => "157.232.1.1",
        "HTTP_FASTLY_CLIENT_IP" => "203.0.113.1",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.1, 157.232.1.1"
      )
      expect(request.remote_ip).to eq("203.0.113.1")
    end

    it "does not break default Rails behavior when middleware is present" do
      request = make_request(
        "REMOTE_ADDR" => "10.0.0.1"
      )
      expect(request.remote_ip).to eq("10.0.0.1")
    end
  end
end
