# frozen_string_literal: true

module FirebaseHostingClientIp
  # Holds the gem's single configuration option.
  #
  # missing_header_fallback controls what request.remote_ip returns when the
  # Fastly-Client-IP header is absent or invalid:
  #
  #   :passthrough (default) - leave Rails' own value untouched. Behind
  #     Firebase Hosting -> Cloud Run this is typically a Google front-end
  #     address, not the client.
  #   any String - written to request.remote_ip as-is, so the application can
  #     recognize "client IP unknown" and act on it (e.g. fail closed). The
  #     gem imposes no semantics on the sentinel; any String is accepted,
  #     including "". It must be a String because Request#remote_ip is
  #     `(get_header("action_dispatch.remote_ip") || ip).to_s` - a nil or
  #     false env value silently falls through to Rack's calculation.
  class Configuration
    PASSTHROUGH = :passthrough

    attr_reader :missing_header_fallback

    def initialize
      @missing_header_fallback = PASSTHROUGH
    end

    def missing_header_fallback=(value)
      unless value == PASSTHROUGH || value.is_a?(String)
        raise ArgumentError,
              "missing_header_fallback must be :passthrough or a String, " \
              "got #{value.inspect}"
      end

      @missing_header_fallback = value
    end
  end

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def reset_configuration!
      @config = Configuration.new
    end
  end
end
