require "test_helper"

class ClientTest < Minitest::Spec
  let(:session_static_options) do
    {
      api_key: api_key,
      trailblazer_pro_host: trailblazer_pro_host,
      firebase_upload_url: "https://firestore.googleapis.com/v1/projects/trb-pro-dev/databases/(default)/documents/traces",
      firestore_fields_template: {"version"=>{"stringValue"=>"1"}, "uid"=>{"stringValue"=>"8KwCOTLeK3QdmgtVNUPwr0ukJJc2"}},
      firebase_refresh_url: "https://securetoken.googleapis.com/v1/token?key=AIzaSyDVZOdUrI6wOji774hGU0yY_cQw9OAVwzs",
    }
  end # FIXME: do we need this?


  it "Connect.() maintains a valid session/JWT for us" do
  #@ Uninitialized sigin
    initial_session = Trailblazer::Pro::Session::Uninitialized.new(trailblazer_pro_host: trailblazer_pro_host, api_key: api_key)

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Client::Connect, [{session: initial_session}, {}])

    assert_session ctx, **session_static_options, session_updated: true

  #@ reuse still valid session
    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Client::Connect, [{session: ctx[:session], now: DateTime.now}, {}])

    assert_session ctx, **session_static_options, session_updated: nil

  #@ refresh session
    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Client::Connect, [{session: ctx[:session], now: DateTime.now + 60*60*24}, {}])

    assert_session ctx, **session_static_options, session_updated: true
  end

  it "Connect.() edge case:" do
    invalid_session = Trailblazer::Pro::Session::Uninitialized.new(trailblazer_pro_host: trailblazer_pro_host, api_key: "incorrect api_key")

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Client::Connect, [{session: invalid_session}, {}])

    assert_equal signal.inspect, %(#<Trailblazer::Activity::End semantic=:failure>)
    assert_equal ctx[:error_message], %(Custom token couldn't be retrieved. HTTP status: 401)
    #@ we could, potentially, see the host on the outside, accessing {:session}.
    assert_equal ctx[:session].trailblazer_pro_host, "https://testbackend-pro.trb.to"

    #@ host not reachable/network/host name
  end
end
