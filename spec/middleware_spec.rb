# frozen_string_literal: true

require "spec_helper"
require "rack"
require_relative "../lib/firebase_hosting_client_ip/middleware"

RSpec.describe FirebaseHostingClientIp::Middleware do
  let(:app) { ->(_env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  def call_middleware(env)
    middleware.call(env)
  end

  def make_request(headers = {})
    env = {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/",
      "REMOTE_ADDR" => "127.0.0.1"
    }
    env.merge!(headers)
    call_middleware(env)
  end

  describe "IP extraction precedence" do
    it "prefers HTTP_FASTLY_CLIENT_IP when present" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "127.0.0.1",
        "HTTP_FASTLY_CLIENT_IP" => "203.0.113.1",
        "HTTP_X_FORWARDED_FOR" => "198.51.100.1, 198.51.100.2"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
    end

    it "uses HTTP_X_FORWARDED_FOR when HTTP_FASTLY_CLIENT_IP is absent" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "127.0.0.1",
        "HTTP_X_FORWARDED_FOR" => "198.51.100.1, 198.51.100.2"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("198.51.100.1")
    end

    it "extracts the left-most IP from HTTP_X_FORWARDED_FOR" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "127.0.0.1",
        "HTTP_X_FORWARDED_FOR" => "192.0.2.1, 192.0.2.2, 192.0.2.3"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("192.0.2.1")
    end

    it "falls back to REMOTE_ADDR when no headers are present" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "10.0.0.1"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("10.0.0.1")
    end

    it "handles X_FORWARDED_FOR with whitespace" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "127.0.0.1",
        "HTTP_X_FORWARDED_FOR" => "  203.0.113.1  ,  203.0.113.2  "
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
    end

    it "handles HTTP_FASTLY_CLIENT_IP with whitespace" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "127.0.0.1",
        "HTTP_FASTLY_CLIENT_IP" => "  203.0.113.1  "
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
    end
  end

  describe "edge cases" do
    it "handles empty HTTP_FASTLY_CLIENT_IP" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "10.0.0.1",
        "HTTP_FASTLY_CLIENT_IP" => "",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.1"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
    end

    it "handles empty HTTP_X_FORWARDED_FOR" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "10.0.0.1",
        "HTTP_X_FORWARDED_FOR" => ""
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("10.0.0.1")
    end

    it "handles HTTP_X_FORWARDED_FOR with only whitespace" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "10.0.0.1",
        "HTTP_X_FORWARDED_FOR" => "   ,   "
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("10.0.0.1")
    end

    it "handles nil REMOTE_ADDR gracefully" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => nil,
        "HTTP_FASTLY_CLIENT_IP" => "203.0.113.1"
      }
      aggregate_failures do
        expect { call_middleware(env) }.not_to raise_error
        expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
      end
    end
  end

  describe "middleware integration" do
    it "calls the next middleware in the stack" do
      app_called = false
      test_app = lambda do |_env|
        app_called = true
        [200, {}, ["OK"]]
      end
      test_middleware = described_class.new(test_app)

      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "10.0.0.1"
      }
      test_middleware.call(env)
      expect(app_called).to be true
    end

    it "does not modify response from next middleware" do
      response = [200, { "Content-Type" => "text/plain" }, ["Response body"]]
      test_app = ->(_env) { response }
      test_middleware = described_class.new(test_app)

      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "10.0.0.1"
      }
      result = test_middleware.call(env)
      expect(result).to eq(response)
    end

    it "preserves other request headers" do
      env = {
        "REQUEST_METHOD" => "POST",
        "PATH_INFO" => "/api",
        "REMOTE_ADDR" => "10.0.0.1",
        "HTTP_HOST" => "example.com",
        "HTTP_USER_AGENT" => "Test Agent",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.1"
      }
      call_middleware(env)

      aggregate_failures do
        expect(env["HTTP_HOST"]).to eq("example.com")
        expect(env["HTTP_USER_AGENT"]).to eq("Test Agent")
        expect(env["REQUEST_METHOD"]).to eq("POST")
        expect(env["PATH_INFO"]).to eq("/api")
      end
    end
  end

  describe "Firebase Hosting scenarios" do
    it "normalizes IP from Firebase Hosting proxy chain (X-Forwarded-For)" do
      # Typical Firebase Hosting request:
      # Client IP: 203.0.113.1
      # Firebase proxy adds IP chain: 203.0.113.1, 157.232.1.1 (Firebase IP)
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "157.232.1.1",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.1, 157.232.1.1"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
    end

    it "handles Fastly-fronted Firebase Hosting" do
      # Fastly CDN in front of Firebase Hosting
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "157.232.1.1",
        "HTTP_FASTLY_CLIENT_IP" => "203.0.113.1",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.1, 157.232.1.1"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
    end

    it "handles multiple intermediate proxies" do
      # Request through multiple proxies: Client -> Proxy1 -> Proxy2 -> App
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "10.0.0.5",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.1, 10.0.0.2, 10.0.0.3"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
    end
  end

  describe "IPv6 addresses" do
    it "handles IPv6 addresses in X-Forwarded-For" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "::1",
        "HTTP_X_FORWARDED_FOR" => "2001:db8::1, 2001:db8::2"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("2001:db8::1")
    end

    it "handles IPv6 addresses in Fastly header" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "::1",
        "HTTP_FASTLY_CLIENT_IP" => "2001:db8::1"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("2001:db8::1")
    end

    it "handles mixed IPv4 and IPv6" do
      env = {
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => "/",
        "REMOTE_ADDR" => "::1",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.1, 2001:db8::2"
      }
      call_middleware(env)
      expect(env["REMOTE_ADDR"]).to eq("203.0.113.1")
    end
  end
end
