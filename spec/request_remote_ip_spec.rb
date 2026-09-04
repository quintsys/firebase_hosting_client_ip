# frozen_string_literal: true

require "spec_helper"
require "rails"
require "action_dispatch"

# Exercises the real middleware ordering the railtie produces:
#
#   ActionDispatch::RemoteIp -> FirebaseHostingClientIp::Middleware -> app
#
# ActionDispatch::RemoteIp installs a lazy GetIp object at
# env["action_dispatch.remote_ip"]; this gem replaces it. The app builds a
# fresh ActionDispatch::Request, exactly as a controller would.
RSpec.describe "request.remote_ip integration" do
  # The peer address a Cloud Run container sees, plus an X-Forwarded-For whose
  # right-most entry is a Google front-end address. Rails walks that header
  # right-to-left discarding *trusted* proxies, and a GFE address is public,
  # so stock Rails stops at 34.96.0.1 and reports it as the client.
  let(:remote_addr) { "169.254.1.1" }
  let(:forwarded_for) { "203.0.113.99, 34.96.0.1" }
  let(:gfe_ip) { "34.96.0.1" }

  let(:app) do
    lambda do |env|
      request = ActionDispatch::Request.new(env)
      [200, {}, [request.remote_ip.to_s]]
    end
  end

  let(:stack) do
    ActionDispatch::RemoteIp.new(FirebaseHostingClientIp::Middleware.new(app))
  end

  def request_for(headers = {})
    env = Rack::MockRequest.env_for(
      "/",
      { "REMOTE_ADDR" => remote_addr, "HTTP_X_FORWARDED_FOR" => forwarded_for }
        .merge(headers)
    )
    stack.call(env)
    ActionDispatch::Request.new(env)
  end

  context "when Fastly-Client-IP is present" do
    it "makes request.remote_ip return the client IP" do
      request = request_for("HTTP_FASTLY_CLIENT_IP" => "198.51.100.7")
      expect(request.remote_ip).to eq("198.51.100.7")
    end

    it "leaves request.ip reporting the real peer address" do
      request = request_for("HTTP_FASTLY_CLIENT_IP" => "198.51.100.7")
      expect(request.ip).to eq(remote_addr)
    end

    it "leaves REMOTE_ADDR untouched" do
      request = request_for("HTTP_FASTLY_CLIENT_IP" => "198.51.100.7")
      expect(request.env["REMOTE_ADDR"]).to eq(remote_addr)
    end

    it "returns an IPv6 client IP with the header's own spelling" do
      expanded = "2001:0db8:0000:0000:0000:0000:0000:0042"
      request = request_for("HTTP_FASTLY_CLIENT_IP" => expanded)
      expect(request.remote_ip).to eq(expanded)
    end
  end

  context "when Fastly-Client-IP is absent" do
    # This documents the problem the gem exists to solve: without the trusted
    # header, Rails reports a Google address as the client. The gem declines
    # to invent a better-looking answer.
    it "falls back to Rails' own value by default" do
      expect(request_for.remote_ip).to eq(gfe_ip)
    end

    it "returns the configured sentinel instead when one is set" do
      FirebaseHostingClientIp.config.missing_header_fallback = "0.0.0.0"
      expect(request_for.remote_ip).to eq("0.0.0.0")
    end
  end
end
