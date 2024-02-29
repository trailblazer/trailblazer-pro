require "test_helper"

class WtfTest < Minitest::Spec
  class Create < Trailblazer::Activity::Railway
    step :model

    def model(ctx, **)
      ctx[:model] = Object.new
    end
  end

  #@ test if successive wtf? use global settings and token
  let(:session_static_options) do
    {
      api_key: api_key,
      trailblazer_pro_host: trailblazer_pro_host,
      firebase_upload_url: "https://firestore.googleapis.com/v1/projects/trb-pro-dev/databases/(default)/documents/traces",
      firestore_fields_template: {"version"=>{"stringValue"=>"1"}, "uid"=>{"stringValue"=>"8KwCOTLeK3QdmgtVNUPwr0ukJJc2"}},
      firebase_refresh_url: "https://securetoken.googleapis.com/v1/token?key=AIzaSyDVZOdUrI6wOji774hGU0yY_cQw9OAVwzs",
    }
  end

  it "{#wtf?} with global session options" do
    Trailblazer::Pro.initialize!(
      api_key:              api_key,
      trailblazer_pro_host: trailblazer_pro_host,
    )
  # Uninitialized session.
    assert_equal Trailblazer::Pro::Session.session.to_h, {api_key: api_key, trailblazer_pro_host: trailblazer_pro_host}

    signal, (ctx, _), _, output, (session, trace_id, debugger_url, _trace_envelope) = Trailblazer::Pro::Trace::Wtf.call(Create, [{}, {}])


    assert_equal trace_id.size, 20
    assert_equal debugger_url, "https://ide.trailblazer.to/#{trace_id}"
    assert_equal Trailblazer::Pro::Session.session, session # session got stored globally

    session_1_hash = assert_session({session: session}, **session_static_options)

  #@ while session is valid, do another call.
    signal, (ctx, _), _, output, (session_2, trace_id_2, debugger_url_2, _trace_envelope) = Trailblazer::Pro::Trace::Wtf.call(Create, [ctx, {}])

    assert_equal trace_id_2.size, 20
    assert_equal debugger_url_2, "https://ide.trailblazer.to/#{trace_id_2}"
    assert trace_id != trace_id_2
    assert_equal Trailblazer::Pro::Session.session, session # still the same session

    session_2_hash = assert_session({session: session_2}, **session_static_options)
    #@ id_token hasn't changed!
    assert_equal session_1_hash[:id_token], session_2_hash[:id_token]

  #@ simulate time out, new token required.
    signal, (ctx, _), _, output, (session_3, trace_id_3, debugger_url_3, _trace_envelope) =
      Trailblazer::Pro::Trace::Wtf.call(Create, [ctx, {}], present_options: {now: DateTime.now + (60 * 100)})

    assert_equal trace_id_3.size, 20
    assert_equal debugger_url_3, "https://ide.trailblazer.to/#{trace_id_3}"
    assert trace_id != trace_id_3
    assert_equal Trailblazer::Pro::Session.session, session_3 # new session

    session_3_hash = assert_session({session: session_3}, **session_static_options)
    #@ {id_token} has changed, {refresh_token} stays the same!
    refute_equal session_3_hash[:id_token],       session_2_hash[:id_token]
    assert_equal session_3_hash[:refresh_token],  session_2_hash[:refresh_token]

    # pp session_3

#@ deserialize test (used in pro-rails)
    session_3_serialized = Trailblazer::Pro::Session.serialize(session_3)
    assert session_3_serialized.size >= 1884 # TODO: assess test.

    session_4 = Trailblazer::Pro::Session.deserialize(session_3_serialized)

    Trailblazer::Pro.initialize!(**session_4)

    signal, (ctx, _), _, output, (session_5, trace_id_5, debugger_url_5, _trace_envelope) = Trailblazer::Pro::Trace::Wtf.call(Create, [ctx, {}])

    assert_equal trace_id_5.size, 20
    assert_equal debugger_url_5, "https://ide.trailblazer.to/#{trace_id_5}"
    assert trace_id_3 != trace_id_5
    assert_equal Trailblazer::Pro::Session.session, session_3 # new session

  #@ simulate refreshable token

  end

  it "allows global {render_wtf: false}" do
    Trailblazer::Pro.initialize!(
      api_key:              api_key,
      trailblazer_pro_host: trailblazer_pro_host,
      render_wtf: false,
    )

    signal, (ctx, _), _, output, (session, trace_id, debugger_url, _trace_envelope) = Trailblazer::Pro::Trace::Wtf.call(Create, [{}, {}])

    assert_equal output, %(\e[1m[TRB PRO] view trace (WtfTest::Create) at \e[22mhttps://ide.trailblazer.to/#{trace_id})
    assert_equal trace_id.size, 20
    assert_equal debugger_url, "https://ide.trailblazer.to/#{trace_id}"
    assert_equal Trailblazer::Pro::Session.session, session # session got stored globally

  # render trace on CLI.
    Trailblazer::Pro.initialize!(
      api_key:              api_key,
      trailblazer_pro_host: trailblazer_pro_host,
      render_wtf: true,
    )

    signal, (ctx, _), _, output, (session, trace_id, debugger_url, _trace_envelope) = Trailblazer::Pro::Trace::Wtf.call(Create, [{}, {}])

    assert_equal output, %(WtfTest::Create
|-- \e[32mStart.default\e[0m
|-- \e[32mmodel\e[0m
`-- End.success
\e[1m[TRB PRO] view trace (WtfTest::Create) at \e[22mhttps://ide.trailblazer.to/#{trace_id})
    assert_equal trace_id.size, 20
    assert_equal debugger_url, "https://ide.trailblazer.to/#{trace_id}"
    assert_equal Trailblazer::Pro::Session.session, session # session got stored globally
  end
end
