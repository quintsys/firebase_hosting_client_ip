# frozen_string_literal: true

require "ipaddr"

module FirebaseHostingClientIp
  # Makes request.remote_ip return the client IP reported by Firebase Hosting.
  #
  # Firebase Hosting fronts the application with Fastly, which sets
  # Fastly-Client-IP to the address of the end user. That header is the only
  # trustworthy source in this architecture: behind Cloud Run, the values Rails
  # derives on its own (from X-Forwarded-For) resolve to a Google front-end
  # address, and are attacker-controlled if the service can be reached directly.
  #
  # The middleware runs after ActionDispatch::RemoteIp and replaces the lazy
  # value that middleware installed at env["action_dispatch.remote_ip"], which
  # is exactly what ActionDispatch::Request#remote_ip reads. REMOTE_ADDR is
  # never modified, so request.ip continues to report the real peer address.
  #
  # When the header is absent or invalid, behavior is governed by
  # FirebaseHostingClientIp.config.missing_header_fallback.
  class Middleware
    REMOTE_IP_KEY = "action_dispatch.remote_ip"
    HEADER = "HTTP_FASTLY_CLIENT_IP"

    # Characters that make IPAddr accept something which is not a bare client
    # address. IPAddr.new is more permissive than this contract needs: it
    # parses CIDR ranges ("192.0.2.1/24"), bracketed IPv6 ("[2001:db8::42]"),
    # and zone identifiers ("2001:db8::42%eth0"). None of those are values
    # Rails should hand out as request.remote_ip, so they are rejected before
    # parsing rather than repaired.
    DISALLOWED = %r{[/\[\]%]}

    def initialize(app)
      @app = app
    end

    def call(env)
      ip = validated_fastly_ip(env)
      fallback = FirebaseHostingClientIp.config.missing_header_fallback

      if ip
        env[REMOTE_IP_KEY] = ip
      elsif fallback != Configuration::PASSTHROUGH
        env[REMOTE_IP_KEY] = fallback
      end

      @app.call(env)
    end

    private

    # Returns the trimmed header value verbatim when it is a single valid host
    # address, nil otherwise.
    #
    # This validates without transforming: IPAddr is used only as a gate, and
    # the string handed to Rails keeps the header's own spelling rather than a
    # canonicalized form. Resolving the trusted header is this gem's only
    # responsibility; imposing an IP canonicalization policy is not.
    def validated_fastly_ip(env)
      raw = env[HEADER]&.strip
      return nil if raw.nil? || raw.empty? || raw.match?(DISALLOWED)

      IPAddr.new(raw)
      raw
    rescue IPAddr::Error
      nil
    end
  end
end
