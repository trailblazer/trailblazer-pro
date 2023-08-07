# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/pro"

require "minitest/autorun"

Minitest::Spec.class_eval do
  def assert_equal(asserted, expected)
    super(expected, asserted)
  end

  let(:api_key) { "tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604" }
  # let(:trailblazer_pro_host) { "http://localhost:3000" }
  let(:trailblazer_pro_host) { "https://test-pro-rails-jwt.onrender.com" }

  after do
    Trailblazer::Pro::Session.session = nil
    Trailblazer::Pro::Session.wtf_present_options = nil
  end
end

require "trailblazer/developer" # FIXME.
