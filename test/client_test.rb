require "test_helper"
require "trailblazer/developer"

class ClientTest < Minitest::Spec
  class Create < Trailblazer::Activity::Railway
    step :model

    def model(ctx, **)
      ctx[:model] = Object.new
    end
  end

  it "manual Signin and Upload" do
    skip

    api_key = "tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604"

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Trace::Signin, [{api_key: api_key}, {}])

    assert_equal signal.to_h[:semantic], :success

    assert ctx[:model].valid?

    assert id_token = ctx[:id_token]

                        # FIXME: firebase => firestore
    assert_equal ctx[:firebase_upload_url], "https://firestore.googleapis.com/v1/projects/trb-pro-dev/databases/(default)/documents/traces"
    assert_equal ctx[:firestore_upload_template], {"version"=>{"stringValue"=>"1"}, "uid"=>{"stringValue"=>"8KwCOTLeK3QdmgtVNUPwr0ukJJc2"}}

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Trailblazer::Pro::Trace::Store, [{
      firebase_upload_url: ctx[:firebase_upload_url],
      data_to_store: {a: 1}.to_json,
      firestore_fields_template: ctx[:firestore_upload_template]}, {}])

    assert_equal ctx[:id].size, 20

# curl 'https://identitytoolkit.googleapis.com/v1/accounts:update?key=AIzaSyDnism7mVXtAExubmGQMFw7t_KlMD3nA2M' \
# -H 'Content-Type: application/json' \
# --data-binary \
# '{"idToken":"eyJhbGciOiJSUzI1NiIsImtpZCI6IjE2ZGE4NmU4MWJkNTllMGE4YYzNTgwNTJiYjUzYjUzYjE4MzA3NzMiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdHJiLXByby1kZXYiLCJhdWQiOiJ0cmItcHJvLWRldiIsImF1dGhfdGltZSI6MTY4MjQzNjQ2NywidXNlcl9pZCI6IjhYQmlKd09zdnRlMFJ1dkpKRFMwOEJKMmpPVjIiLCJzdWIiOiI4WEJpSndPc3Z0ZTBSdXZKSkRTMDhCSjJqT1YyIiwiaWF0IjoxNjgyNDM2NDY3LCJleHAiOjE2ODI0NDAwNjcsImVtYWlsIjoidXNlckBleGFtcGxlMi5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsidXNlckBleGFtcGxlMi5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJjdXN0b20ifX0.Ea3DgZRlmzwx-LEQSRsuuM6hIkS_iHPsQGh7_snotzs66lSsLkqbVNb2DSsPmO0Ucybd12YquA3MB0UNUUX2hIRN2uR2JVYN2BFzMDlal1Fes753ZPBuuRlGE6_b7qCNnL41p6UWY-Ucg_DF5hiQp6ksQCGbRujS74Yz_mZ0uvafmogCLaRbgO1f2ncoXqm0aVuE_t5Vlor4drKTW2LqM0jgHLuIZTVrQhq9mKhJCZ2SrHbhpLkSJPIdGYzw87HdvFP5G_I7kXd03OGLlUdTELs_JslhUF77naS1XcvtWQgzcRhraDuJ49xI6Lp7BSS9e7O822Vi6HgWacBY3aMc6Q","email":"nick@example2.com","returnSecureToken":true}'



#     curl 'https://securetoken.googleapis.com/v1/token?key=[API_KEY]' \
# -H 'Content-Type: application/x-www-form-urlencoded' \
# --data 'grant_type=refresh_token&refresh_token=[REFRESH_TOKEN]'



#     curl -X POST -d '{
#   "author": "alanisawesome",
#   "title": "The Turing Machine"
# }' 'https://trb-pro-dev-default-rtdb.europe-west1.firebasedatabase.app/traces/apotonick.json'


  end

  # test if trace has expected elements
  it "{#wtf?} with manual options" do
    api_key = "tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604"

    ctx = {}

    signal, (ctx, _), _, output, (token, trace_id, debugger_url, trace_envelope) = Trailblazer::Developer.wtf?(
      Create,
      [ctx, {}],
      present_options: {render_method: Trailblazer::Pro::Debugger, token: nil, api_key: api_key},
    )

    assert_equal token.valid?, true
    assert_equal trace_id.size, 20
    assert_equal debugger_url, "https://ide.trailblazer.to/#{trace_id}"

    assert_equal trace_envelope[:fields].keys, [:activity_name, :trace, :created_at]
    assert_equal trace_envelope[:fields][:activity_name], {:stringValue=>ClientTest::Create}
    assert trace_envelope[:fields][:created_at][:timestampValue] < DateTime.now

    trace_data = JSON.parse(trace_envelope[:fields][:trace][:stringValue])
    trace_nodes = trace_data["nodes"]
    trace_variable_versions = trace_data["variable_versions"]

    model_1_id = trace_variable_versions["model"].keys[0]

    assert_equal model_1_id.class, String

  # Assert trace/nodes
    assert_equal trace_nodes.size, 4
    assert_equal trace_nodes[0].slice("level", "runtime_id", "label"), {"level"=>0, "runtime_id"=>nil, "label"=>"ClientTest::Create"}
    assert_equal trace_nodes[0]["ctx_snapshots"], {
      "before"=>[],
      "after" => [["model", {"version"=>model_1_id, "has_changed"=>false}]]}

    assert_equal trace_nodes[1].slice("level", "runtime_id", "label"), {"level"=>1, "runtime_id"=>"Start.default", "label"=>"Start.default"}
    assert_equal trace_nodes[1]["ctx_snapshots"], {
      "before"=>[],
      "after" => []}

    assert_equal trace_nodes[2].slice("level", "runtime_id", "label"), {"level"=>1, "runtime_id"=>"model", "label"=>"model"}
    assert_equal trace_nodes[2]["ctx_snapshots"], {
      "before"=>[],
      "after" => [["model", {"version"=>model_1_id, "has_changed"=>true}]]}

    assert_equal trace_nodes[3].slice("level", "runtime_id", "label"), {"level"=>1, "runtime_id"=>"End.success", "label"=>"End.success"}
    assert_equal trace_nodes[3]["ctx_snapshots"], {
      "before"=>[["model", {"version"=>model_1_id, "has_changed"=>false}]],
      "after" => [["model", {"version"=>model_1_id, "has_changed"=>false}]]}

    assert_equal [trace_nodes[0]["id"], trace_nodes[1]["id"], trace_nodes[2]["id"], trace_nodes[3]["id"]].uniq.size, 4

  # Assert trace/variable_versions
    assert_equal trace_variable_versions, {"model"=>{model_1_id => ctx[:model].to_s}}

  # Assert version
    assert_equal trace_data["pro_version"], Trailblazer::Pro::VERSION
  end

  # test if successive wtf? use global settings and token

  let(:api_key) { "tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604" }
  let(:trailblazer_pro_host) { "http://localhost:3000" }
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

    session_1_hash = assert_session(session, **session_static_options)

  #@ while session is valid, do another call.
    signal, (ctx, _), _, output, (session_2, trace_id_2, debugger_url_2, _trace_envelope) = Trailblazer::Pro::Trace::Wtf.call(Create, [ctx, {}])

    assert_equal trace_id_2.size, 20
    assert_equal debugger_url_2, "https://ide.trailblazer.to/#{trace_id_2}"
    assert trace_id != trace_id_2
    assert_equal Trailblazer::Pro::Session.session, session # still the same session

    session_2_hash = assert_session(session_2, **session_static_options)
    #@ id_token hasn't changed!
    assert_equal session_1_hash[:id_token], session_2_hash[:id_token]

  #@ simulate time out, new token required.
    signal, (ctx, _), _, output, (session_3, trace_id_3, debugger_url_3, _trace_envelope) = Trailblazer::Pro::Trace::Wtf.call(Create, [ctx, {}], present_options: {now: DateTime.now + (60 * 6)})

    assert_equal trace_id_3.size, 20
    assert_equal debugger_url_3, "https://ide.trailblazer.to/#{trace_id_3}"
    assert trace_id != trace_id_3
    assert_equal Trailblazer::Pro::Session.session, session_3 # new session

    session_3_hash = assert_session(session_3, **session_static_options)
    #@ {id_token} has changed, {refresh_token} stays the same!
    refute_equal session_3_hash[:id_token],       session_2_hash[:id_token]
    assert_equal session_3_hash[:refresh_token],  session_2_hash[:refresh_token]

    # pp session_3

#@ deserialize test (used in pro-rails)
    session_3_serialized = Trailblazer::Pro::Session.serialize(session_3)
    assert_equal session_3_serialized.size, 1884 # TODO: assess test.

    session_4 = Trailblazer::Pro::Session.deserialize(session_3_serialized)

    Trailblazer::Pro.initialize!(**session_4)

    signal, (ctx, _), _, output, (session_5, trace_id_5, debugger_url_5, _trace_envelope) = Trailblazer::Pro::Trace::Wtf.call(Create, [ctx, {}])

    assert_equal trace_id_5.size, 20
    assert_equal debugger_url_5, "https://ide.trailblazer.to/#{trace_id_5}"
    assert trace_id_3 != trace_id_5
    assert_equal Trailblazer::Pro::Session.session, session_3 # new session

  #@ simulate refreshable token

    Trailblazer::Pro::Session.session = nil
    Trailblazer::Pro::Session.wtf_present_options = nil
  end

  def assert_session(session, old_id_token: "", **session_static_options)
    session_hash = session.to_h

    assert_equal session_hash.slice(:firebase_upload_url, :firestore_fields_template, :firebase_refresh_url, :api_key, :trailblazer_pro_host),
      session_static_options
    assert_equal session_hash[:refresh_token].size, 183
    assert_equal session_hash[:id_token].size, 1054
    # assert_equal session_hash[:token].valid?(now: DateTime.now), true # {:token} is {IdToken} instance
    # refute_equal session_hash[:id_token], old_id_token
    assert_equal Trailblazer::Pro::Trace.valid?({}, expires_at: session[:expires_at], now: DateTime.now), true

    session_hash
  end
end
