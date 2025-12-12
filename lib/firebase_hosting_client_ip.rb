# frozen_string_literal: true

require_relative "firebase_hosting_client_ip/version"
require_relative "firebase_hosting_client_ip/middleware"

module FirebaseHostingClientIp
  class Error < StandardError; end
end

require_relative "firebase_hosting_client_ip/railtie" if defined?(Rails)
