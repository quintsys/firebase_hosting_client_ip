# frozen_string_literal: true

require "spec_helper"
require "rack"

RSpec.describe FirebaseHostingClientIp::Middleware do
  let(:app) { ->(_env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }
  let(:remote_ip_key) { described_class::REMOTE_IP_KEY }

  # Builds a bare Rack env. REMOTE_ADDR mimics the peer address a Cloud Run
  # container actually sees; no action_dispatch.remote_ip key is present,
  # so its absence after the call means "Rails' own value was left alone".
  def env_for(headers = {})
    {
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/",
      "REMOTE_ADDR" => "169.254.1.1"
    }.merge(headers)
  end

  def call_with(headers = {})
    env = env_for(headers)
    middleware.call(env)
    env
  end

  describe "with a valid Fastly-Client-IP header" do
    it "sets the client IP for request.remote_ip to consume" do
      env = call_with("HTTP_FASTLY_CLIENT_IP" => "203.0.113.1")
      expect(env[remote_ip_key]).to eq("203.0.113.1")
    end

    it "accepts IPv6 addresses" do
      env = call_with("HTTP_FASTLY_CLIENT_IP" => "2001:db8::42")
      expect(env[remote_ip_key]).to eq("2001:db8::42")
    end

    it "passes IPv6 through verbatim rather than canonicalizing it" do
      expanded = "2001:0db8:0000:0000:0000:0000:0000:0042"
      env = call_with("HTTP_FASTLY_CLIENT_IP" => expanded)
      expect(env[remote_ip_key]).to eq(expanded)
    end

    it "strips surrounding whitespace" do
      env = call_with("HTTP_FASTLY_CLIENT_IP" => "  203.0.113.1  ")
      expect(env[remote_ip_key]).to eq("203.0.113.1")
    end

    it "never modifies REMOTE_ADDR" do
      env = call_with("HTTP_FASTLY_CLIENT_IP" => "203.0.113.1")
      expect(env["REMOTE_ADDR"]).to eq("169.254.1.1")
    end
  end

  describe "with an absent or invalid Fastly-Client-IP header" do
    # Each of these must be treated exactly like a missing header: the gem
    # refuses to hand Rails a value it cannot vouch for.
    {
      "absent" => {},
      "empty" => { "HTTP_FASTLY_CLIENT_IP" => "" },
      "whitespace only" => { "HTTP_FASTLY_CLIENT_IP" => "   " },
      "garbage" => { "HTTP_FASTLY_CLIENT_IP" => "not-an-ip" },
      "bracketed IPv6" => { "HTTP_FASTLY_CLIENT_IP" => "[2001:db8::42]" },
      "IPv6 zone identifier" => { "HTTP_FASTLY_CLIENT_IP" => "2001:db8::42%eth0" },
      # IPAddr.new accepts these, but a range is not a client address.
      "IPv4 CIDR" => { "HTTP_FASTLY_CLIENT_IP" => "192.0.2.1/24" },
      "IPv6 CIDR" => { "HTTP_FASTLY_CLIENT_IP" => "2001:db8::1/64" }
    }.each do |description, headers|
      it "leaves Rails' value untouched when the header is #{description}" do
        env = call_with(headers)
        expect(env).not_to have_key(remote_ip_key)
      end
    end

    it "never modifies REMOTE_ADDR" do
      env = call_with("HTTP_FASTLY_CLIENT_IP" => "not-an-ip")
      expect(env["REMOTE_ADDR"]).to eq("169.254.1.1")
    end
  end

  describe "missing_header_fallback" do
    it "defaults to leaving Rails' value untouched" do
      env = call_with
      expect(env).not_to have_key(remote_ip_key)
    end

    it "writes the configured sentinel when the header is absent" do
      FirebaseHostingClientIp.config.missing_header_fallback = "0.0.0.0"
      env = call_with
      expect(env[remote_ip_key]).to eq("0.0.0.0")
    end

    it "writes the configured sentinel when the header is invalid" do
      FirebaseHostingClientIp.config.missing_header_fallback = "0.0.0.0"
      env = call_with("HTTP_FASTLY_CLIENT_IP" => "not-an-ip")
      expect(env[remote_ip_key]).to eq("0.0.0.0")
    end

    it "does not apply when the header is valid" do
      FirebaseHostingClientIp.config.missing_header_fallback = "0.0.0.0"
      env = call_with("HTTP_FASTLY_CLIENT_IP" => "203.0.113.1")
      expect(env[remote_ip_key]).to eq("203.0.113.1")
    end

    # The gem imposes no semantics on the sentinel; the application owns it.
    it "accepts an empty string as a sentinel" do
      FirebaseHostingClientIp.config.missing_header_fallback = ""
      env = call_with
      expect(env[remote_ip_key]).to eq("")
    end
  end

  describe "X-Forwarded-For" do
    # A negative guarantee of 1.0: this gem never infers the client from
    # X-Forwarded-For. Behind Cloud Run that header resolves to a Google
    # front-end address, and is attacker-controlled on direct access.
    it "is never consumed when the Fastly header is absent" do
      env = call_with("HTTP_X_FORWARDED_FOR" => "203.0.113.99, 34.96.0.1")
      expect(env).not_to have_key(remote_ip_key)
    end

    it "loses to a valid Fastly header" do
      env = call_with(
        "HTTP_FASTLY_CLIENT_IP" => "198.51.100.7",
        "HTTP_X_FORWARDED_FOR" => "203.0.113.99, 34.96.0.1"
      )
      expect(env[remote_ip_key]).to eq("198.51.100.7")
    end
  end
end
