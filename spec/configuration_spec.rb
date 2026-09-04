# frozen_string_literal: true

require "spec_helper"

RSpec.describe FirebaseHostingClientIp::Configuration do
  describe "missing_header_fallback" do
    it "defaults to :passthrough" do
      expect(FirebaseHostingClientIp.config.missing_header_fallback)
        .to eq(:passthrough)
    end

    it "accepts :passthrough" do
      FirebaseHostingClientIp.config.missing_header_fallback = :passthrough
      expect(FirebaseHostingClientIp.config.missing_header_fallback)
        .to eq(:passthrough)
    end

    it "accepts a String" do
      FirebaseHostingClientIp.config.missing_header_fallback = "0.0.0.0"
      expect(FirebaseHostingClientIp.config.missing_header_fallback)
        .to eq("0.0.0.0")
    end

    # Anything Rails would coerce with #to_s is a trap: a non-String value
    # cannot express "unknown" reliably, and nil/false silently falls through
    # to Rack's own calculation.
    [nil, :unknown, 0, false, IPAddr.new("0.0.0.0")].each do |value|
      it "rejects #{value.inspect}" do
        expect { FirebaseHostingClientIp.config.missing_header_fallback = value }
          .to raise_error(ArgumentError, /must be :passthrough or a String/)
      end
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      FirebaseHostingClientIp.configure do |config|
        config.missing_header_fallback = "0.0.0.0"
      end

      expect(FirebaseHostingClientIp.config.missing_header_fallback)
        .to eq("0.0.0.0")
    end
  end

  describe ".reset_configuration!" do
    it "restores the defaults" do
      FirebaseHostingClientIp.config.missing_header_fallback = "0.0.0.0"
      FirebaseHostingClientIp.reset_configuration!

      expect(FirebaseHostingClientIp.config.missing_header_fallback)
        .to eq(:passthrough)
    end
  end
end
