# frozen_string_literal: true

require "spec_helper"
require "rails"
require "action_controller/railtie"
require "firebase_hosting_client_ip/railtie"

RSpec.describe FirebaseHostingClientIp::Railtie do
  # Boots a real Rails application so the railtie's initializer actually runs
  # and the middleware stack is assembled the way a host application would
  # assemble it. Only one application can be initialized per process, so the
  # resulting stack is built once and shared by the examples below.
  def self.middleware_classes
    @middleware_classes ||= begin
      app_class = Class.new(Rails::Application) do
        config.eager_load = false
        config.secret_key_base = "test"
        config.logger = Logger.new(IO::NULL)
      end
      app_class.initialize!
      app_class.instance.middleware.map(&:klass)
    end
  end

  let(:middlewares) { self.class.middleware_classes }

  it "inserts the middleware into the stack" do
    expect(middlewares).to include(FirebaseHostingClientIp::Middleware)
  end

  # The entire mechanism depends on this ordering: ActionDispatch::RemoteIp
  # installs a lazy value at env["action_dispatch.remote_ip"], and this gem
  # must run afterwards to replace it. Inserted earlier, RemoteIp would
  # overwrite the trusted Fastly value and the gem would silently do nothing.
  it "inserts the middleware after ActionDispatch::RemoteIp" do
    expect(middlewares.index(FirebaseHostingClientIp::Middleware))
      .to be > middlewares.index(ActionDispatch::RemoteIp)
  end
end
