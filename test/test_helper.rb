$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/pro"

require "minitest/autorun"

Minitest::Spec.class_eval do
  def assert_equal(asserted, expected)
    super(expected, asserted)
  end

  let(:api_key) { "tpka_909ae987_c834_43e4_9869_2eefd2aa9bcf" }
  let(:trailblazer_pro_host) { "https://testbackend-pro.trb.to" }

  after do
    Trailblazer::Pro::Session.session = nil
    Trailblazer::Pro::Session.wtf_present_options = nil
  end

  def assert_web_and_cli_trace(output, operation: Create)
    trace_id = output[-21..-2] # skip newline.

    assert_equal trace_id.size, 20

    assert_equal output, %(#{operation}
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
\e[1m[TRB PRO] view trace (#{operation}) at \e[22mhttps://ide.trailblazer.to/#{trace_id}
)
  end

  def assert_cli_trace(output, operation: Create)
    assert_equal output, %(#{operation}
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
)
  end

  def assert_session(ctx, old_id_token: "", session_updated: false, **session_static_options)
    session = ctx[:session]
    session_hash = session.to_h

    assert_equal session_hash.slice(:firebase_upload_url, :firestore_fields_template, :firebase_refresh_url, :api_key, :trailblazer_pro_host).sort,
      session_static_options.sort
    assert_equal session_hash[:refresh_token].size, 183
    assert_equal session_hash[:id_token].size, 1054
    # assert_equal session_hash[:token].valid?(now: DateTime.now), true # {:token} is {IdToken} instance
    # refute_equal session_hash[:id_token], old_id_token
    assert_equal Trailblazer::Pro::Client.valid?({}, expires_at: session[:expires_at], now: DateTime.now), true
    assert_equal ctx[:session_updated], session_updated

    session_hash
  end
end

require "trailblazer/operation"

class Minitest::Spec::Create < Trailblazer::Operation
  step :model

  def model(ctx, **)
    ctx[:model] = Object.new
  end
end

require "trailblazer/developer" # FIXME.

