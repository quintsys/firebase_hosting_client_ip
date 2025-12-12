# frozen_string_literal: true

module FirebaseHostingClientIp
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Extract the normalized client IP using the precedence rules
      normalized_ip = extract_client_ip(env)

      # Store the normalized IP in the REMOTE_ADDR so that Rails' request.remote_ip
      # will return it without needing ActionDispatch::RemoteIp to reprocess
      env["REMOTE_ADDR"] = normalized_ip if normalized_ip

      @app.call(env)
    end

    private

    def extract_client_ip(env)
      # Precedence:
      # 1. HTTP_FASTLY_CLIENT_IP (if present and not empty)
      # 2. Left-most value from HTTP_X_FORWARDED_FOR (if present and not empty)
      # 3. Fallback to REMOTE_ADDR (already processed by ActionDispatch::RemoteIp)

      # Check for Fastly header
      fastly_ip = env["HTTP_FASTLY_CLIENT_IP"]
      return fastly_ip if fastly_ip && !fastly_ip.empty?

      # Check for X-Forwarded-For header and extract the left-most IP
      x_forwarded_for = env["HTTP_X_FORWARDED_FOR"]
      if x_forwarded_for && !x_forwarded_for.empty?
        # X-Forwarded-For can contain multiple IPs separated by commas
        # The left-most (first) IP is the original client IP
        ips = x_forwarded_for.split(",").map(&:strip)
        first_ip = ips.first
        return first_ip if first_ip && !first_ip.empty?
      end

      # Fallback to REMOTE_ADDR (which may have been set by ActionDispatch::RemoteIp)
      env["REMOTE_ADDR"]
    end
  end
end
